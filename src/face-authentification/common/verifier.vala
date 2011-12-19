/* verifier.vala
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

namespace XSAA.FaceAuthentification
{
    public class FaceImages
    {
        public OpenCV.IPL.Image[] faces;
    }

    public class FaceSet
    {
        public string[]     name;
        public FaceImages[] face_images;
        public string[]     thumbnails;
        public int          count;
    }

    /**
     * Verifier class. This is the Verifier class used to verify a face.
     */
    public class Verifier : GLib.Object
    {
        // constants
        const int FACE_MACE_SIZE = 64;
        const int EYE_MACE_SIZE = 64;
        const int INSIDE_FACE_MACE_SIZE = 64;

        // properties
        private unowned Os.Passwd? m_User;

        // accessors
        public string faces_directory { get; private set; default = ""; }
        public string model_directory { get; private set; default = ""; }
        public string config_directory { get; private set; default = ""; }

        // methods
        /**
         * Create a new verifier object for current user
         */
        public Verifier ()
        {
            Os.uid_t uid = (Os.uid_t)Posix.getuid ();
            m_User = Os.getpwuid (uid);

            string basePath = m_User.pw_dir + USER_CONFIG_PATH;
            faces_directory = basePath + "/faces";
            model_directory = basePath + "/model";
            config_directory = basePath + "/config";

            GLib.DirUtils.create_with_parents (faces_directory, 0755);
            GLib.DirUtils.create_with_parents (model_directory, 0755);
            GLib.DirUtils.create_with_parents (config_directory, 0755);

            string maceConfig = config_directory + "/mace.xml";
            if (!GLib.FileUtils.test (maceConfig, GLib.FileTest.EXISTS))
            {
                Config config = Config (0.80);
                config.save (config_directory);
            }
        }

        /**
         * Create a new verifier object for user uid
         *
         * @param inUid user id
         */
        public Verifier.uid (Os.uid_t inUid)
        {
            m_User = Os.getpwuid (inUid);

            string basePath = m_User.pw_dir + USER_CONFIG_PATH;
            faces_directory = basePath + "/faces";
            model_directory = basePath + "/model";
            config_directory = basePath + "/config";
        }

        /**
         * Returns a unique name required to create a new set
         *
         * @return returns a unique string, uses date+time
         */
        private string
        create_set_dir ()
        {
            time_t now = time_t ();
            GLib.Time now_time = Time.local (now);
            GLib.TimeVal detail_time = GLib.TimeVal ();
            detail_time.get_current_time ();

            string unique_name = "%d%d%d%d%d%d%ld%ld%d".printf (now_time.year, now_time.month, now_time.day,
                                                                now_time.hour, now_time.minute, now_time.second,
                                                                (detail_time.tv_usec / 1000), detail_time.tv_usec,
                                                                now_time.weekday);
            string set_dir = faces_directory + "/" + unique_name;
            GLib.DirUtils.create_with_parents (set_dir, 0755);

            return unique_name;
        }

        /**
         * Returns all sets of face images of the current user
         *
         * @return returns the all face sets in a setFace structure
         */
        public FaceSet
        get_face_set ()
        {
            FaceSet setFaceStruct = null;
            try
            {
                GLib.Dir dir = GLib.Dir.open (faces_directory);
                unowned string file = null;
                GLib.List<string> my_list = new GLib.List<string> ();

                while ((file = dir.read_name ()) != null)
                {
                    if (file != "." && file != "..")
                    {
                        my_list.prepend (file);
                    }
                }
                my_list.sort (GLib.strcmp);

                setFaceStruct = new FaceSet ();
                setFaceStruct.name = new string[my_list.length ()];
                setFaceStruct.thumbnails = new string[my_list.length ()];
                setFaceStruct.face_images = new FaceImages[my_list.length ()];
                setFaceStruct.count = (int)my_list.length ();

                int k = 0;
                foreach (string p in my_list)
                {
                    setFaceStruct.name[k] = p;
                    setFaceStruct.thumbnails[k] = "%s/%s/1.jpg".printf (faces_directory, p);

                    string imagesDir = "%s/%s".printf (faces_directory, p);
                    GLib.List<string> mylistImages = new GLib.List<string> ();

                    dir = GLib.Dir.open (imagesDir);
                    unowned string image = null;
                    int imageK = 0;

                    while ((image = dir.read_name ()) != null)
                    {
                        if (image != "." && image != "..")
                        {
                            mylistImages.prepend (imagesDir + "/" + image);
                            imageK++;
                        }
                    }
                    mylistImages.sort (GLib.strcmp);

                    int imageIndex = 0;
                    setFaceStruct.face_images[k].faces = new OpenCV.IPL.Image [imageK];
                    foreach (string l in mylistImages)
                    {
                        setFaceStruct.face_images[k].faces[imageIndex] = new OpenCV.IPL.Image.load (l, (OpenCV.IPL.Image.LoadType)1);
                        imageIndex++;
                    }

                    k++;
                }
            }
            catch (GLib.Error err)
            {
                setFaceStruct = null;
                Log.critical ("Error on get face set: %s", err.message);
            }

            return setFaceStruct;
        }

        /**
         * Creates the MACE Filter and LBP Feature Hist
         * It creates $HOME/.config/xsplashaa/face-authentication/model/$SET NAME_(FACE | EYE | INSIDE_FACE)_(MACE | LBP).XML
         *
         * @param inSetName if set name is NULL, then all the faces sets are retrained
         */
        public void
        create_biometric_models (string? inSetName = null)
        {
            FaceSet temp = get_face_set ();
            int leftIndex = 0;
            int rightIndex = temp.count;

            if (inSetName != null)
            {
                for (int i = 0; i < temp.count; ++i)
                {
                    if (temp.name[i] == inSetName)
                    {
                        leftIndex = i;
                        rightIndex = leftIndex + 1;
                    }
                }
            }

            for (int i = leftIndex; i < rightIndex; ++i)
            {
                OpenCV.IPL.Image[] eye = new OpenCV.IPL.Image [temp.face_images[i].faces.length];
                OpenCV.IPL.Image[] insideFace = new OpenCV.IPL.Image [temp.face_images[i].faces.length];

                for (int index = 0; index < temp.face_images[i].faces.length; ++index)
                {
                    eye[index] = new OpenCV.IPL.Image (OpenCV.Size (EYE_MACE_SIZE, EYE_MACE_SIZE), 8,
                                                       temp.face_images[i].faces[index].n_channels);
                    temp.face_images[i].faces[index].set_roi (OpenCV.Rectangle (0, 0, 140, 60));
                    temp.face_images[i].faces[index].resize (eye[index], OpenCV.IPL.InterpolationType.LINEAR);
                    temp.face_images[i].faces[index].reset_roi ();

                    insideFace[index] = new OpenCV.IPL.Image (OpenCV.Size (INSIDE_FACE_MACE_SIZE, INSIDE_FACE_MACE_SIZE), 8,
                                                              temp.face_images[i].faces[index].n_channels);
                    temp.face_images[i].faces[index].set_roi (OpenCV.Rectangle (30, 45, 80, 105));
                    temp.face_images[i].faces[index].resize (insideFace[index], OpenCV.IPL.InterpolationType.LINEAR);
                    temp.face_images[i].faces[index].reset_roi ();
                }

                OpenCV.Matrix maceFilterFace = compute_mace (temp.face_images[i].faces, FACE_MACE_SIZE);
                OpenCV.Matrix maceFilterEye = compute_mace (eye, EYE_MACE_SIZE);
                OpenCV.Matrix maceFilterInsideFace = compute_mace (insideFace, INSIDE_FACE_MACE_SIZE);

                OpenCV.IPL.Image averageImage = new OpenCV.IPL.Image (temp.face_images[i].faces[0].get_size (), OpenCV.IPL.DEPTH_64F, 1);
                averageImage.zero ();
            }
        }
    }
}
