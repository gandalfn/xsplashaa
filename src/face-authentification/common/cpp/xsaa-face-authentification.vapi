/* face-authentification.h
 *
 * Copyright (C) 2009-2011  Supersonic Imagine
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
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

[CCode (cheader_filename = "face-authentification.h")]
namespace XSAA.FaceAuthentification
{
    [Compact]
    [CCode (cname = "XSAAFaceAuthentificationWebcam", free_function = "xsaa_face_authentification_webcam_free")]
    public class Webcam
    {
        [Compact]
        [CCode (cname = "XSAAFaceAuthentificationWebcamImagePaint", free_function = "xsaa_face_authentification_webcam_image_paint_free")]
        public class ImagePaint
        {
            [CCode (cname = "xsaa_face_authentification_webcam_image_paint_new")]
            public ImagePaint ();

            public void cyclops (OpenCV.IPL.Image inImage, OpenCV.Point inLE, OpenCV.Point inRE);
            public void ellipse (OpenCV.IPL.Image inImage, OpenCV.Point inLE, OpenCV.Point inRE);
        }

        [CCode (cname = "xsaa_face_authentification_webcam_new")]
        public Webcam ();

        public OpenCV.IPL.Image? query_frame ();
        public bool start_camera ();
        public void stop_camera ();
    }

    [Compact]
    [CCode (cname = "XSAAFaceAuthentificationDetector", free_function = "xsaa_face_authentification_detector_free")]
    public class Detector
    {
        [CCode (cname = "xsaa_face_authentification_detector_new")]
        public Detector ();

        [CCode (array_length = false)]
        public OpenCV.IPL.Image[] get_clipped_face ();
        public int get_message_index ();
        [CCode (array_length = false)]
        public OpenCV.IPL.Image[] return_clipped_face ();
        public void start_clip_face (int inNum);
        public void stop_clip_face ();
        public bool finished_clip_face ();
        public void run_detector (OpenCV.IPL.Image inInput);
        public int query_message ();
        public OpenCV.IPL.Image? clip_face (OpenCV.IPL.Image inInputImage);
        public bool successfull ();

        public Eyes get_eyes_information ();
        public void run_eyes_detector (OpenCV.IPL.Image inInput, OpenCV.IPL.Image inFullImage, OpenCV.Point inLe);
        public bool check_eyes_detected ();

        public Face get_face_information ();
        public void run_face_detector (OpenCV.IPL.Image inInput);
        public OpenCV.IPL.Image clip_detected_face (OpenCV.IPL.Image inInputImage);
        public bool check_face_detected ();
    }

    [Compact]
    [CCode (cname = "XSAAFaceAuthentificationVerifier", free_function = "xsaa_face_authentification_verifier_free")]
    public class Verifier
    {
        [CCode (cname = "xsaa_face_authentification_verifier_new")]
        public Verifier ();

        [CCode (cname = "xsaa_face_authentification_verifier_new_for_uid")]
        public Verifier.for_uid (Posix.uid_t inUID);

        public void create_biometric_models (string inName);
        public void add_face_set (OpenCV.IPL.Image[] inImages);
        public void remove_face_set (string inName);
        public unowned SetFace? get_face_set ();
        public int verify_face (OpenCV.IPL.Image inImage);

        public string get_faces_directory ();
        public string get_model_directory ();
        public string get_config_directory ();
    }

    [CCode (cname = "XSAAFaceAuthentificationEyes")]
    public struct Eyes
    {
        OpenCV.Point le;
        OpenCV.Point re;
        int length;
    }

    [CCode (cname = "XSAAFaceAuthentificationFace")]
    public struct Face
    {
        OpenCV.Point lt;
        OpenCV.Point rb;
        int width;
        int height;
    }

    [CCode (cname = "XSAAFaceAuthentificationFaceSetImages")]
    public struct SetImages
    {
        [CCode (array_length_cname = "count")]
        OpenCV.IPL.Image[] faces;
    }

    [CCode (cname = "XSAAFaceAuthentificationFaceSetFace")]
    public struct SetFace
    {
        [CCode (array_length_cname = "count")]
        string[]    name;
        [CCode (array_length_cname = "count")]
        SetImages[] images;
        [CCode (array_length_cname = "count")]
        string[]    file_paths;
    }

    namespace Pam
    {
        [CCode (cname = "int")]
        public enum Status
        {
            [CCode (cname = "INPROGRESS")]
            INPROGRESS,
            [CCode (cname = "STOPPED")]
            STOPPED,
            [CCode (cname = "STARTED")]
            STARTED,
            [CCode (cname = "CANCEL")]
            CANCEL,
            [CCode (cname = "AUTHENTICATE")]
            AUTHENTICATE,
            [CCode (cname = "DISPLAY_ERROR")]
            DISPLAY_ERROR,
            [CCode (cname = "EXIT_GUI")]
            EXIT_GUI
        }

        [CCode (cname = "int")]
        public enum IpcKey
        {
            [CCode (cname = "IPC_KEY_IMAGE")]
            IMAGE,
            [CCode (cname = "IPC_KEY_STATUS")]
            STATUS
        }
    }

    [CCode (cname = "FA_IMAGE_SIZE")]
    public const int IMAGE_SIZE;

    [CCode (cname = "FA_IMAGE_WIDTH")]
    public const int IMAGE_WIDTH;

    [CCode (cname = "FA_IMAGE_HEIGHT")]
    public const int IMAGE_HEIGHT;
}
