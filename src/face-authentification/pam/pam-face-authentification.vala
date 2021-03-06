/* pam-face-authentification.vala
 *
 * Copyright (C) 2009-2011  Nicolas Bruguier
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public errordomain PamFaceAuthentificationError
    {
        USER,
        WEBCAM,
        IPC,
        MODEL
    }

    public class PamFaceAuthentification : GLib.Object
    {
        // types
        private class IPC : GLib.Object
        {
            private int             m_PixelsId    = 0;
            private int             m_StatusId    = 0;
            private unowned uchar[] m_Pixels      = null;
            private int*            m_pStatus     = null;

            public int status {
                get {
                    return *m_pStatus;
                }
                set {
                    *m_pStatus = value;
                }
            }

            public OpenCV.IPL.Image image {
                set {
                    unowned uchar* dst = m_Pixels;

                    for (int n = 0; n < FaceAuthentification.IMAGE_HEIGHT; ++n)
                    {
                        for (int m = 0; m < FaceAuthentification.IMAGE_WIDTH; ++m)
                        {
                            OpenCV.Scalar s = OpenCV.Scalar.get_2D (value, n, m);
                            dst[0] = (uchar)s.val[0];
                            dst[1] = (uchar)s.val[1];
                            dst[2] = (uchar)s.val[2];
                            dst[3] = 0xFF;
                            dst += 4;
                        }
                    }
                }
            }

            public IPC () throws PamFaceAuthentificationError
            {
                int err = -1;
                m_PixelsId = Os.shmget (FaceAuthentification.Pam.IpcKey.IMAGE, FaceAuthentification.IMAGE_SIZE, Os.IPC_CREAT | 0666);
                if (m_PixelsId == err)
                    throw new PamFaceAuthentificationError.IPC ("Unable to get shared memory");
                m_Pixels = (uchar[])Os.shmat (m_PixelsId, null, 0);
                if ((void*)m_Pixels == (void*)err)
                    throw new PamFaceAuthentificationError.IPC ("Unable to get shared memory");

                m_StatusId = Os.shmget (FaceAuthentification.Pam.IpcKey.STATUS, sizeof (int), Os.IPC_CREAT | 0666);
                if (m_StatusId == err)
                    throw new PamFaceAuthentificationError.IPC ("Unable to get shared memory");
                m_pStatus = Os.shmat (m_StatusId, null, 0);
                if ((void*)m_pStatus == (void*)err)
                    throw new PamFaceAuthentificationError.IPC ("Unable to get shared memory");
            }

            ~IPC ()
            {
                Os.shmdt (m_Pixels);
                Os.shmdt (m_pStatus);
            }
        }

        // properties
        private FaceAuthentification.Verifier m_Verifier = null;
        private FaceAuthentification.Webcam   m_Webcam = null;
        private IPC                           m_Shared = null;
        private OpenCV.IPL.Image              m_Empty = null;

        // methods
        public PamFaceAuthentification (string inUsername) throws PamFaceAuthentificationError
        {
            unowned Os.Passwd? passwd = Os.getpwnam (inUsername);
            if (passwd == null)
                throw new PamFaceAuthentificationError.USER ("Invalid username !");

            m_Verifier = new FaceAuthentification.Verifier.for_uid (passwd.pw_uid);

            // create shared memory
            m_Shared = new IPC ();
            m_Shared.status = 0;

            // cleanup shared memory
            m_Empty = new OpenCV.IPL.Image (OpenCV.Size (FaceAuthentification.IMAGE_WIDTH,
                                                         FaceAuthentification.IMAGE_HEIGHT),
                                            OpenCV.IPL.DEPTH_8U, 3);
            m_Empty.zero ();
            m_Shared.image = m_Empty;

            // Create webcam
            m_Webcam = new FaceAuthentification.Webcam ();
            if (!m_Webcam.start_camera ())
                throw new PamFaceAuthentificationError.WEBCAM ("Unable to get hold of your webcam. Please check if it is plugged in.");

            // Check if user have biometric model
            if (m_Verifier.verify_face (m_Empty) == 2)
                throw new PamFaceAuthentificationError.MODEL ("Biometrics Model not Generated for the User.");

        }

        ~PamFaceAuthentification ()
        {
            if (m_Webcam != null)
                m_Webcam.stop_camera ();
        }

        public bool
        check (Pam.Handle inHandle)
        {
            double t1 = (double)OpenCV.get_tick_count ();
            double t2 = 0;

            // Create detector
            FaceAuthentification.Detector detector = new FaceAuthentification.Detector ();

            // Create paint webcam
            FaceAuthentification.Webcam.ImagePaint paint = new FaceAuthentification.Webcam.ImagePaint ();

            // Set state to started
            m_Shared.status = (int)FaceAuthentification.Pam.Status.STARTED;

            // Refresh loop
            while (t2 < 25000)
            {
                t2 = (double)OpenCV.get_tick_count () - t1;
                t2 = t2 / (OpenCV.get_tick_frequency () * 1000.0);

                OpenCV.IPL.Image query_image = m_Webcam.query_frame ();
                if (query_image != null)
                {
                    detector.run_detector (query_image);
                    FaceAuthentification.Eyes eyes = detector.get_eyes_information ();

                    if (GLib.Math.sqrt (GLib.Math.pow (eyes.le.x - eyes.re.x, 2) + GLib.Math.pow (eyes.le.y - eyes.re.y, 2)) > 28 &&
                        GLib.Math.sqrt (GLib.Math.pow (eyes.le.x - eyes.re.x, 2) + GLib.Math.pow (eyes.le.y - eyes.re.y, 2)) < 120)
                    {
                        double yvalue = eyes.re.y - eyes.le.y;
                        double xvalue = eyes.re.x - eyes.le.x;
                        double ang = GLib.Math.atan (yvalue / xvalue) * (180 / GLib.Math.PI);

                        if (GLib.Math.pow (ang, 2) < 200)
                        {
                            send_info_msg (inHandle, "Verifying Face ...");
                            OpenCV.IPL.Image im = detector.clip_face (query_image);
                            if (im != null)
                            {
                                // verification sucessfull
                                if (m_Verifier.verify_face (im) == 1)
                                {
                                    // Set state to stopped
                                    m_Shared.status = (int)FaceAuthentification.Pam.Status.STOPPED;
                                    send_info_msg (inHandle, "Verification successful.");

                                    // clear shared memory
                                    m_Shared.image = m_Empty;
                                    return true;
                                }
                            }
                        }
                        else
                        {
                            send_info_msg(inHandle, "Align your face.");
                        }

                        paint.cyclops (query_image, eyes.le, eyes.re);
                        paint.ellipse (query_image, eyes.le, eyes.re);
                    }
                    else
                    {
                        send_info_msg(inHandle, "Keep proper distance with the camera.");
                    }

                    // refresh shared memory
                    m_Shared.image = query_image;
                }
                else
                {
                    send_error_msg (inHandle, "Unable query image from your webcam.");
                }
            }

            // Set state to stopped
            m_Shared.status = (int)FaceAuthentification.Pam.Status.STOPPED;

            // clear shared memory
            m_Shared.image = m_Empty;

            return false;
        }
    }

    // static properties
    private static string s_LastMessage = null;

    // static methods
    public static void
    send_info_msg (Pam.Handle inHandle, string inMessage)
    {
        if (s_LastMessage == inMessage)
            return;

        s_LastMessage = inMessage;

        Pam.Message[] msg = new Pam.Message[1];

        msg[0] = { Pam.TEXT_INFO, inMessage };
        unowned Pam.Conv? conv = null;
        if (inHandle.get_item (Pam.CONV, &conv) != Pam.SUCCESS)
            return;
        if (conv == null || conv.conv == null)
            return;

        Pam.Response* resp = null;
        conv.conv (1, ref msg, out resp, conv.appdata_ptr);
    }

    public static void
    send_error_msg (Pam.Handle inHandle, string inMessage)
    {
        if (s_LastMessage == inMessage)
            return;

        s_LastMessage = inMessage;

        Pam.Message[] msg = new Pam.Message[1];

        msg[0] = { Pam.ERROR_MSG, inMessage };
        unowned Pam.Conv? conv = null;
        if (inHandle.get_item (Pam.CONV, &conv) != Pam.SUCCESS)
            return;
        if (conv == null || conv.conv == null)
            return;

        Pam.Response* resp = null;
        conv.conv (1, ref msg, out resp, conv.appdata_ptr);
    }

    // methods
    public int
    sm_authenticate (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        unowned string username = null;

        int ret = inHandle.get_user (ref username, null);
        if (ret != Pam.SUCCESS)
        {
            //Pam.output_debug ("get user returned error: %s", inHandle.strerror (ret));
            return ret;
        }
        if (username == null || username.length == 0)
        {
            //Pam.output_debug ("username not known");
            inHandle.set_item (Pam.USER, "nobody");
            send_error_msg (inHandle, "Username Not Set.");
            return Pam.AUTHINFO_UNAVAIL;
        }

        try
        {
            PamFaceAuthentification auth = new PamFaceAuthentification (username);
            if (auth.check (inHandle))
            {
                return Pam.SUCCESS;
            }
            send_error_msg (inHandle, "Giving Up Face Authentication. Try Again=(.");
        }
        catch (PamFaceAuthentificationError err)
        {
            send_error_msg (inHandle, err.message);
        }

        return Pam.AUTHINFO_UNAVAIL;
    }

    public int
    sm_setcred (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        return Pam.SUCCESS;
    }

    public int
    sm_acct_mgmt (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        return Pam.SUCCESS;
    }

    public int
    sm_chauthtok (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        return Pam.SUCCESS;
    }

    public int
    sm_open_session (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        return Pam.SUCCESS;
    }

    public int
    sm_close_session (Pam.Handle inHandle, int inFlags, string[] inArgs)
    {
        return Pam.SUCCESS;
    }
}
