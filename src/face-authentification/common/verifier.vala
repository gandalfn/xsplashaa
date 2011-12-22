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
    public enum VerifyStatus
    {
        IMPOSTER,
        OK,
        NO_BIOMETRICS
    }

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

        // static methods
        private static int
        cmp_double (double? inA, double? inB)
        {
            if (inA < inB)
                return -1;
            if (inA > inB)
                return 1;
            return 0;
        }

        private static int
        cmp_int (int? inA, int? inB)
        {
            if (inA < inB)
                return -1;
            if (inA > inB)
                return 1;
            return 0;
        }

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
                OpenCV.IPL.Image[] eye        = new OpenCV.IPL.Image [temp.face_images[i].faces.length];
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

                OpenCV.Matrix maceFilterFace       = compute_mace (temp.face_images[i].faces, FACE_MACE_SIZE);
                OpenCV.Matrix maceFilterEye        = compute_mace (eye, EYE_MACE_SIZE);
                OpenCV.Matrix maceFilterInsideFace = compute_mace (insideFace, INSIDE_FACE_MACE_SIZE);

                OpenCV.IPL.Image averageImage = new OpenCV.IPL.Image (temp.face_images[i].faces[0].get_size (), OpenCV.IPL.DEPTH_64F, 1);
                averageImage.zero ();
                int avFace = 0, avEye = 0, avInsideFace = 0;

                GLib.List<int?> maceFaceValuesPSLR          = new GLib.List<int?> ();
                GLib.List<double?> maceFaceValuesPCER       = new GLib.List<double?> ();
                GLib.List<int?> maceEyeValuesPSLR           = new GLib.List<int?> ();
                GLib.List<double?> maceEyeValuesPCER        = new GLib.List<double?> ();
                GLib.List<int?> maceInsideFaceValuesPSLR    = new GLib.List<int?> ();
                GLib.List<double?> maceInsideFaceValuesPCER = new GLib.List<double?> ();

                for (int index = 0; index < temp.face_images[i].faces.length; ++index)
                {
                    OpenCV.IPL.Image averageImageFace = new OpenCV.IPL.Image (temp.face_images[i].faces[index].get_size (), OpenCV.IPL.DEPTH_64F, 1);
                    OpenCV.IPL.Image averageImageFace64 = new OpenCV.IPL.Image (temp.face_images[i].faces[index].get_size (), 8, 1);
                    temp.face_images[i].faces[index].convert_color (averageImageFace64, OpenCV.ColorConvert.BGR2GRAY);
                    averageImageFace64.convert_scale (averageImageFace, 1.0, 0.0);
                    averageImage.add (averageImageFace, averageImage);

                    double macePCERValue = peak_corr_plane_energy (maceFilterFace, temp.face_images[i].faces[index], FACE_MACE_SIZE);
                    int macePSLRValue = peak_to_side_lobe_ratio (maceFilterFace, temp.face_images[i].faces[index], FACE_MACE_SIZE);
                    avFace += macePSLRValue;
                    maceFaceValuesPSLR.append (macePSLRValue);
                    maceFaceValuesPCER.append (macePCERValue);

                    macePCERValue = peak_corr_plane_energy (maceFilterEye, eye[index], EYE_MACE_SIZE);
                    macePSLRValue = peak_to_side_lobe_ratio (maceFilterEye, eye[index], EYE_MACE_SIZE);
                    avEye += macePSLRValue;
                    maceEyeValuesPSLR.append (macePSLRValue);
                    maceEyeValuesPCER.append (macePCERValue);

                    macePCERValue = peak_corr_plane_energy (maceFilterInsideFace, insideFace[index], INSIDE_FACE_MACE_SIZE);
                    macePSLRValue = peak_to_side_lobe_ratio (maceFilterInsideFace, insideFace[index], INSIDE_FACE_MACE_SIZE);
                    avInsideFace += macePSLRValue;
                    maceInsideFaceValuesPSLR.append (macePSLRValue);
                    maceInsideFaceValuesPCER.append (macePCERValue);
                }

                avFace /= temp.face_images[i].faces.length;
                avEye /= temp.face_images[i].faces.length;
                avInsideFace /= temp.face_images[i].faces.length;

                int Nx = (int)GLib.Math.floor ((averageImage.width ) / 35);
                int Ny = (int)GLib.Math.floor ((averageImage.height) / 30);
                OpenCV.Matrix featureLBPHistMatrix = new OpenCV.Matrix (Nx * Ny * 59, 1, OpenCV.Type.FC64_1);
                feature_lbp_hist (averageImage, featureLBPHistMatrix);

                OpenCV.IPL.Image weights = new OpenCV.IPL.Image (OpenCV.Size (5 * 4, temp.face_images[i].faces.length), OpenCV.IPL.DEPTH_64F, 1);
                for (int index = 0; index < temp.face_images[i].faces.length; ++index)
                {
                    OpenCV.IPL.Image averageImageFace = new OpenCV.IPL.Image (temp.face_images[i].faces[index].get_size (), OpenCV.IPL.DEPTH_64F, 1);
                    OpenCV.IPL.Image averageImageFace64 = new OpenCV.IPL.Image (temp.face_images[i].faces[index].get_size (), 8, 1);
                    temp.face_images[i].faces[index].convert_color (averageImageFace64, OpenCV.ColorConvert.BGR2GRAY);
                    averageImageFace64.convert_scale (averageImageFace, 1.0, 0.0);

                    OpenCV.Matrix featureLBPHistMatrixFace = new OpenCV.Matrix (Nx * Ny * 59, 1, OpenCV.Type.FC64_1);
                    feature_lbp_hist (averageImageFace, featureLBPHistMatrixFace);

                    for (int l = 0; l < 5; ++l)
                    {
                        for (int j = 0; j < 4; ++j)
                        {
                            double chiSquare = 0;

                            for (int k = 0; k < 59; ++k)
                            {
                                OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (featureLBPHistMatrixFace, l * 4 * 59 + j * 59 + k, 0);
                                OpenCV.Scalar s2 = OpenCV.Scalar.get_2D (featureLBPHistMatrix, l * 4 * 59 + j * 59 + k, 0);

                                double hist1 = s1.val[0];
                                double hist2 = s2.val[0];

                                if ((hist1 + hist2) != 0)
                                    chiSquare += GLib.Math.pow (hist1 - hist2, 2) / (hist1 + hist2);
                            }
                            OpenCV.Scalar s1 = OpenCV.Scalar (chiSquare);
                            weights.set_2d (index, j * 5 + l, s1);
                        }
                    }
                }

                OpenCV.IPL.Image variance = new OpenCV.IPL.Image (OpenCV.Size (5 * 4, 1), OpenCV.IPL.DEPTH_64F, 1);
                OpenCV.IPL.Image sum      = new OpenCV.IPL.Image (OpenCV.Size (5 * 4, 1), OpenCV.IPL.DEPTH_64F, 1);
                OpenCV.IPL.Image sumSq    = new OpenCV.IPL.Image (OpenCV.Size (5 * 4, 1), OpenCV.IPL.DEPTH_64F, 1);
                OpenCV.IPL.Image meanSq   = new OpenCV.IPL.Image (OpenCV.Size (5 * 4, 1), OpenCV.IPL.DEPTH_64F, 1);
                variance.zero ();
                sum.zero ();
                sumSq.zero ();

                for (int index = 0; index < temp.face_images[i].faces.length; ++index)
                {
                    for (int l = 0; l < 5; ++l)
                    {
                        for (int j = 0; j < 4; ++j)
                        {
                            OpenCV.Scalar s1, s2, s3, s4;

                            s1 = OpenCV.Scalar.get_2D (weights, index, j * 5 + l);
                            s2 = OpenCV.Scalar.get_2D (sum, 0, j * 5 + l);
                            s3 = OpenCV.Scalar (s1.val[0] + s2.val[0]);
                            s4 = OpenCV.Scalar.get_2D (sumSq, 0, j * 5 + l);

                            sum.set_2d (0, j * 5 + l, s3);
                            s1.val[0] *= s1.val[0];
                            s1.val[0] += s4.val[0];
                            sumSq.set_2d (0, j * 5 + l, s1);
                        }
                    }
                }

                sum.convert_scale (sum, 1 / (double)temp.face_images[i].faces.length);
                sumSq.convert_scale (sumSq, 1 / (double)temp.face_images[i].faces.length);
                sum.multiply (sum, meanSq);
                sumSq.subtract (meanSq, variance);

                ((OpenCV.Array)null).divide (variance, variance);
                OpenCV.Scalar totalVariance = variance.sum ();
                OpenCV.Matrix finalWeights = new OpenCV.Matrix (4, 5, OpenCV.Type.FC64_1);
                for (int j = 0; j < 4; ++j)
                {
                    for (int l = 0; l < 5; ++l)
                    {
                        OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (variance, 0, j * 5 + l);
                        s1.val[0] = (s1.val[0] * 20) / totalVariance.val[0];
                        finalWeights.set_2d(j, l, s1);
                    }
                }

                string lbpFacePath = "%s/%s_face_lbp.xml".printf (model_directory, temp.name[i]);
                OpenCV.File.Storage fs = new OpenCV.File.Storage (lbpFacePath, null, OpenCV.File.Mode.WRITE);
                fs.write ("lbp", featureLBPHistMatrix, OpenCV.File.AttributeList ());
                fs.write("weights", finalWeights, OpenCV.File.AttributeList ());

                GLib.List<double?> lbpAv = new GLib.List<double?> ();

                for (int index = 0; index < temp.face_images[i].faces.length; ++index)
                {
                    OpenCV.Matrix featureLBPHistMatrixTest = new OpenCV.Matrix (Nx * Ny * 59, 1, OpenCV.Type.FC64_1);
                    OpenCV.IPL.Image imageFace = new OpenCV.IPL.Image (temp.face_images[i].faces[index].get_size (), 8, 1);
                    temp.face_images[i].faces[index].convert_color (imageFace, OpenCV.ColorConvert.BGR2GRAY);

                    feature_lbp_hist (imageFace, featureLBPHistMatrixTest);
                    lbpAv.append (lbp_custom_diff (featureLBPHistMatrixTest, featureLBPHistMatrix, finalWeights));
                }
                lbpAv.sort (cmp_double);
                int half = (temp.face_images[i].faces.length / 2) - 1;
                if (half > 0)
                {
                    while (half >= 0)
                    {
                        unowned GLib.List? f = lbpAv.first ();
                        lbpAv.delete_link (f);
                        --half;
                    }
                }
                fs.write_real ("thresholdLbp", lbpAv.first ().data);

                maceFaceValuesPSLR.sort (cmp_int);
                maceFaceValuesPCER.sort (cmp_double);
                maceEyeValuesPSLR.sort (cmp_int);
                maceEyeValuesPCER.sort (cmp_double);
                maceInsideFaceValuesPSLR.sort (cmp_int);
                maceInsideFaceValuesPCER.sort (cmp_double);

                Mace faceMaceFilter = Mace ();
                faceMaceFilter.threshold_pcer = maceFaceValuesPCER.first ().data;
                int pslr = maceFaceValuesPSLR.first ().data;
                faceMaceFilter.threshold_pslr = pslr + (avFace - pslr) / 10;
                faceMaceFilter.filter = maceFilterFace;
                faceMaceFilter.mace_filter_name = "%s_face_mace.xml".printf (temp.name[i]);
                faceMaceFilter.save (model_directory);

                Mace eyeMaceFilter = Mace ();
                eyeMaceFilter.threshold_pcer = maceEyeValuesPCER.first ().data;
                pslr = maceEyeValuesPSLR.first ().data;
                eyeMaceFilter.threshold_pslr = pslr + (avEye - pslr) / 10;
                eyeMaceFilter.filter = maceFilterEye;
                eyeMaceFilter.mace_filter_name = "%s_eye_mace.xml".printf (temp.name[i]);
                eyeMaceFilter.save (model_directory);

                Mace insideFaceMaceFilter = Mace ();
                insideFaceMaceFilter.threshold_pcer = maceInsideFaceValuesPCER.first().data;
                pslr = maceInsideFaceValuesPSLR.first ().data;
                insideFaceMaceFilter.threshold_pslr = pslr + (avInsideFace - pslr) / 10;
                insideFaceMaceFilter.filter = maceFilterInsideFace;
                insideFaceMaceFilter.mace_filter_name = "%s_inside_face_mace.xml".printf (temp.name[i]);
                insideFaceMaceFilter.save (model_directory);
            }
        }

        /**
         * Adds a set of face images and calls createBiometricModels
         *
         * @param inSet Set of IplImage of Faces
         */
        public void
        add_face_set (OpenCV.IPL.Image[] inSet)
        {
            string dirNameUnique = create_set_dir ();
            string dirName = faces_directory + "/" + dirNameUnique;

            for (int i = 0; i < inSet.length; ++i)
            {
                string filename = "%s/%d.jpg".printf (dirName, i);
                inSet[i].save_image (filename);
            }

            create_biometric_models (dirNameUnique);
        }

        /**
         * Removes the Set from $HOME/.pam-face-authentication/faces/$SETNAME/
         * and its models call createBiometricModels afterwards
         *
         * @param inSetName Name of the Set
         */
        public void
        remove_face_set (string inSetName)
        {
            try
            {
                string dirname = "%s/%s".printf (faces_directory, inSetName);

                GLib.Dir dir = GLib.Dir.open (faces_directory);
                unowned string file = null;

                while ((file = dir.read_name ()) != null)
                {
                    if (file.substring (file.length - 3) == "jpg")
                    {
                        GLib.FileUtils.remove (dirname + "/" + file);
                    }
                }

                GLib.FileUtils.remove("%s/%s_face_lbp.xml".printf (model_directory, inSetName));
                GLib.FileUtils.remove("%s/%s_face_mace.xml".printf (model_directory, inSetName));
                GLib.FileUtils.remove("%s/%s_eye_mace.xml".printf (model_directory, inSetName));
                GLib.FileUtils.remove("%s/%s_inside_face_mace.xml".printf (model_directory, inSetName));
                GLib.DirUtils.remove(dirname);
            }
            catch (GLib.FileError err)
            {
                Log.critical ("Error on remove %s: %s", inSetName, err.message);
            }
        }

        /**
         * VerifyFace - Does the verification of the param image with the current user
         *
         * @param inFace face image
         *
         * @return status of verification
         */
        public VerifyStatus
        verify_face (OpenCV.IPL.Image? inFace)
        {
            VerifyStatus status = VerifyStatus.IMPOSTER;

            if (inFace == null) return status;

            OpenCV.IPL.Image face = new OpenCV.IPL.Image (OpenCV.Size (140, 150), 8, inFace.n_channels);
            OpenCV.IPL.Image faceGray = new OpenCV.IPL.Image (OpenCV.Size (140, 150), 8, 1);

            int Nx = (int)GLib.Math.floor(faceGray.width / 35);
            int Ny = (int)GLib.Math.floor(faceGray.height / 30);

            OpenCV.Matrix featureLBPHistMatrix = new OpenCV.Matrix (Nx * Ny * 59, 1, OpenCV.Type.FC64_1);
            inFace.resize (inFace, OpenCV.IPL.InterpolationType.LINEAR);
            face.convert_color (faceGray, OpenCV.ColorConvert.BGR2GRAY);
            feature_lbp_hist (faceGray, featureLBPHistMatrix);

            OpenCV.IPL.Image eye = new OpenCV.IPL.Image  (OpenCV.Size (140, 60), 8, face.n_channels);
            face.set_roi (OpenCV.Rectangle (0, 0, 140, 60));
            face.resize (eye, OpenCV.IPL.InterpolationType.LINEAR);
            face.reset_roi ();

            OpenCV.IPL.Image insideFace = new OpenCV.IPL.Image  (OpenCV.Size (80, 105), 8, face.n_channels);
            face.set_roi (OpenCV.Rectangle (30, 45, 80, 105));
            face.resize (insideFace, OpenCV.IPL.InterpolationType.LINEAR);
            face.reset_roi ();

            Config newConfig = Config.file (config_directory);
            int nb_files = 0;

            try
            {
                GLib.Dir dir = GLib.Dir.open (faces_directory);
                unowned string file = null;
                while ((file = dir.read_name ()) != null)
                {
                    if (file != "." && file != "..")
                    {
                        string lbp = "%s/%s_face_lbp.xml".printf (model_directory, file);
                        OpenCV.File.Storage fileStorage = new OpenCV.File.Storage (lbp, null, OpenCV.File.Mode.READ);
                        if (fileStorage == null) continue;

                        unowned OpenCV.Matrix? lbpModel = (OpenCV.Matrix)fileStorage.read_by_name (null, "lbp", null);
                        unowned OpenCV.Matrix? weights = (OpenCV.Matrix)fileStorage.read_by_name (null, "weights", null);
                        if (lbpModel == null) continue;
                        if (weights == null) continue;

                        double lbpThresh = fileStorage.read_real_by_name (null, "thresholdLbp", 8000.0);
                        double val = lbp_custom_diff (lbpModel, featureLBPHistMatrix, weights);
                        double step = lbpThresh / 8;

                        double thresholdLBP = lbpThresh;
                        double percentageModifier = ((0.80 - newConfig.percentage) * 100);
                        int baseIncrease = (int)GLib.Math.floor (GLib.Math.log10 (lbpThresh)) - 2;
                        while (baseIncrease > 0)
                        {
                            percentageModifier *= 10;
                            baseIncrease--;
                        }
                        thresholdLBP += percentageModifier * 1.2;

                        if (val < (thresholdLBP + step))
                        {
                            string facePath = "%s/%s_face_mace.xml".printf (model_directory, file);
                            fileStorage = new OpenCV.File.Storage (facePath, null, OpenCV.File.Mode.READ);
                            if (fileStorage == null) continue;
                            unowned OpenCV.Matrix? maceFilterUser = (OpenCV.Matrix)fileStorage.read_by_name (null, "maceFilter", null);
                            int PSLR = fileStorage.read_int_by_name (null, "thresholdPSLR", 100);
                            int valu = peak_to_side_lobe_ratio (maceFilterUser, face, FACE_MACE_SIZE);

                            string eyePath = "%s/%s_eye_mace.xml".printf (model_directory, file);
                            fileStorage = new OpenCV.File.Storage (eyePath, null, OpenCV.File.Mode.READ);
                            if (fileStorage == null) continue;
                            maceFilterUser = (OpenCV.Matrix)fileStorage.read_by_name (null, "maceFilter", null);
                            PSLR += fileStorage.read_int_by_name (null, "thresholdPSLR", 100);
                            valu += peak_to_side_lobe_ratio (maceFilterUser, eye, EYE_MACE_SIZE);

                            string insideFacePath = "%s/%s_inside_face_mace.xml".printf (model_directory, file);
                            fileStorage = new OpenCV.File.Storage (insideFacePath, null, OpenCV.File.Mode.READ);
                            if (fileStorage == null) continue;
                            maceFilterUser = (OpenCV.Matrix)fileStorage.read_by_name (null, "maceFilter", null);
                            PSLR += fileStorage.read_int_by_name (null, "thresholdPSLR", 100);
                            valu += peak_to_side_lobe_ratio (maceFilterUser, insideFace, INSIDE_FACE_MACE_SIZE);

                            int pcent = (int)(((double)valu / (double)PSLR) * 100);
                            int lowerPcent = (int)(newConfig.percentage * 100.0);
                            int upperPcent = (int)((newConfig.percentage + ((1 - newConfig.percentage) / 4)) * 100.0);

                            if (pcent >= upperPcent)
                            {
                                status = VerifyStatus.OK;
                                break;
                            }
                            else if (pcent < lowerPcent)
                            {
                            }
                            else
                            {
                                double newThres = thresholdLBP + ((double)((double)(pcent - lowerPcent) / (double)(upperPcent - lowerPcent)) * (double)(step));
                                if (val < newThres)
                                {
                                    status = VerifyStatus.OK;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            catch (GLib.FileError err)
            {
                status = VerifyStatus.NO_BIOMETRICS;
            }

            return nb_files > 0 ? status : VerifyStatus.NO_BIOMETRICS;
        }
    }
}

