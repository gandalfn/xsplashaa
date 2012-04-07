/* face-detector.vala
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
    /**
     * Face structure, information that can describe the detected face on the image
     */
    public struct Face
    {
        public OpenCV.Point lt;  /** Co-ordinates of Left Top of the Face */
        public OpenCV.Point rb;  /** Co-ordinates of Right Top of the Face */
        public int width;   /** Width of the Face */
        public int height;  /** Height of the Face */
    }

    /**
     * Face Detector class. This class runs the OpenCV Haar detect functions
     * for finding the face.
     */
    public class FaceDetector : GLib.Object
    {
        // properties
        private unowned OpenCV.HaarClassifierCascade? m_Cascade;
        private OpenCV.Memory.Storage                 m_Storage;
        private Face                                  m_Face;

        // accessors
        public Face face_information {
            get {
                return m_Face;
            }
        }

        public bool face_detected {
            get {
                return m_Face.width != 0 && m_Face.height != 0;
            }
        }

        // methods
        /**
         * Create a new face detector object
         */
        public FaceDetector ()
        {
            // Load cascade file
            m_Cascade = OpenCV.HaarClassifierCascade.load (global::Config.PACKAGE_FACEAUTH_DATA_DIR + "/haarcascade.xml",
                                                           null, null, null);

            // Setup the storage and clear it
            m_Storage = new OpenCV.Memory.Storage ();
            m_Storage.clear ();

            // Initialize eyesInformation Params
            m_Face.lt = OpenCV.Point (0, 0);
            m_Face.rb = OpenCV.Point (0, 0);
            m_Face.width = 0;
            m_Face.height = 0;
        }

        /**
         * Runs the face detection algorithm on the param image
         *
         * @param inInput The input image on which the algorithm should be run on.
         */
        public void
        run (OpenCV.IPL.Image? inInput)
        {
            m_Storage.clear ();

            // Initialize eyesInformation Params
            m_Face.lt = OpenCV.Point (0, 0);
            m_Face.rb = OpenCV.Point (0, 0);
            m_Face.width = 0;
            m_Face.height = 0;

            if (inInput == null) return;

            int scale = 1;

            OpenCV.IPL.Image gray = new OpenCV.IPL.Image (inInput.get_size (), 8, 1);
            OpenCV.IPL.Image small_img = new OpenCV.IPL.Image (OpenCV.Size (OpenCV.Math.round (inInput.width / scale), OpenCV.Math.round (inInput.height / scale)), 8, 1);

            // The classifier works on grey scale images,
            // so the incoming BGR image input is converted to greyscale
            // and then optionally resized.
            inInput.convert_color (gray, OpenCV.ColorConvert.BGR2GRAY);
            gray.resize (small_img, OpenCV.IPL.InterpolationType.LINEAR);

            // Perform histogram equalization (increases contrast and dynamic range)
            small_img.equalize_hist (small_img);

            int maxI = -1, max0 = 0;

            if (m_Cascade != null)
            {
                unowned OpenCV.Sequence<OpenCV.Rectangle?> faces =
                                m_Cascade.detect_objects (small_img, m_Storage, 1.1, 2,
                                                          OpenCV.HaarClassifierCascade.Flags.SCALE_IMAGE,
                                                          OpenCV.Size (50 / scale, 50 / scale));
                for (int i = 0; i < (faces != null ? faces.total : 0); ++i)
                {
                    // Create a new rectangle for the face
                    unowned OpenCV.Rectangle? r = faces [i];

                    // When looping faces, select the biggest one
                    if (max0 < (r.width * r.height));
                    {
                        max0 = (r.width * r.height);
                        maxI = i;
                    }
                }

                if (maxI != -1)
                {
                    unowned OpenCV.Rectangle? r = faces [maxI];

                    // Set the dimensions of the face and scale them
                    m_Face.lt.x = (r.x) * scale;
                    m_Face.lt.y = (r.y) * scale;
                    m_Face.rb.x = (r.x + r.width) * scale;
                    m_Face.rb.y = (r.y + r.height) * scale;
                    m_Face.width = (r.width) * scale;
                    m_Face.height = (r.height) * scale;
                }
            }
        }

        /**
         * Returns the Face image of the detected face
         *
         * @param inInput The Input image.
         *
         * @return IplImage on success, null on failure
         */
        public OpenCV.IPL.Image?
        clip_detected_face (OpenCV.IPL.Image inInput)
        {
            if (m_Face.width == 0 || m_Face.height == 0) return null;

            OpenCV.IPL.Image faceImage = new OpenCV.IPL.Image (OpenCV.Size (m_Face.width, m_Face.height), OpenCV.IPL.DEPTH_8U, inInput.n_channels);

            inInput.set_roi (OpenCV.Rectangle (m_Face.lt.x, m_Face.lt.y, m_Face.width, m_Face.height));
            inInput.resize (faceImage, OpenCV.IPL.InterpolationType.LINEAR);
            inInput.reset_roi ();

            return faceImage;
        }
    }
}
