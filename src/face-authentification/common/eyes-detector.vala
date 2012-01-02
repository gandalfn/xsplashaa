/* eyes-detector.vala
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
     * Eye structure. Information that describe the detected eyes on the face image
     */
    public struct Eyes
    {
        OpenCV.Point le; /** Coordinates of the Left Eye */
        OpenCV.Point re; /** Coordinates of the Right Eye */
        int length; /** Length Eye */
    }

    /**
     * Eye detector class. This class runs the OpenCV Haar detection functions for finding eyes.
     */
    public class EyesDetector : GLib.Object
    {
        // properties
        private unowned OpenCV.HaarClassifierCascade? m_NestedCascade;
        private unowned OpenCV.HaarClassifierCascade? m_NestedCascade2;
        private OpenCV.Memory.Storage                 m_Storage;
        private bool                                  m_BothEyesDetected = false;
        private Eyes                                  m_Eyes;

        // accessors
        public Eyes eyes_information {
            get {
                return m_Eyes;
            }
        }

        public bool eyes_detected {
            get {
                return m_BothEyesDetected;
            }
        }

        // methods
        /**
         * Create a new eyes detector object
         */
        public EyesDetector ()
        {
            // Load two cascade files
            m_NestedCascade = OpenCV.HaarClassifierCascade.load (global::Config.PACKAGE_FACEAUTH_DATA_DIR + "/haarcascade_eye_tree_eyeglasses.xml",
                                                                 null, null, null);
            m_NestedCascade2 = OpenCV.HaarClassifierCascade.load (global::Config.PACKAGE_FACEAUTH_DATA_DIR + "/haarcascade_eye.xml",
                                                                  null, null, null);

            // Setup the storage and clear it
            m_Storage = new OpenCV.Memory.Storage ();
            m_Storage.clear ();

            // Initialize eyesInformation Params
            m_Eyes.le = OpenCV.Point (0, 0);
            m_Eyes.re = OpenCV.Point (0, 0);
            m_Eyes.length = 0;
        }

        /**
         * Function to run the detection algorithm on param image
         *
         * @param inInput The IplImage on which the algorithm should be run on
         * @param inFullImage The full image
         * @param inLT ?
         */
        public void
        run (OpenCV.IPL.Image? inInput, OpenCV.IPL.Image inFullImage, OpenCV.Point inLT)
        {
            m_BothEyesDetected = false;

            // (Re-)initialize eyesInformation params
            m_Eyes.le = OpenCV.Point (0, 0);
            m_Eyes.re = OpenCV.Point (0, 0);
            m_Eyes.length = 0;

            m_Storage.clear ();

            if (inInput == null) return;

            int scale = 1;

            OpenCV.IPL.Image gray = new OpenCV.IPL.Image (OpenCV.Size (inInput.width, inInput.height / 2), 8, 1);
            OpenCV.IPL.Image gray_fullimage = new OpenCV.IPL.Image (inFullImage.get_size (), 8, 1);
            OpenCV.IPL.Image gray_scale = new OpenCV.IPL.Image (OpenCV.Size (inInput.width / scale, inInput.height / (2 * scale)), 8, 1);

            inInput.set_roi (OpenCV.Rectangle (0, inInput.height / 8, inInput.width, inInput.height / 2));
            inInput.convert_color (gray, OpenCV.ColorConvert.BGR2GRAY);
            inInput.reset_roi ();

            inFullImage.convert_color (gray_fullimage, OpenCV.ColorConvert.BGR2GRAY);
            gray_fullimage.resize (gray_scale, OpenCV.IPL.InterpolationType.LINEAR);

            // Perform histogram equalization (increases contrast and dynamic range)
            gray_scale.equalize_hist (gray_scale);

            unowned OpenCV.Sequence<OpenCV.Rectangle?> nested_objects = m_NestedCascade.detect_objects (gray_scale, m_Storage, 1.4, 2, 0);
            int count = nested_objects != null ? nested_objects.total : 0;
            if (count == 0)
            {
                // Second round of detection using m_NestedCascade2
                nested_objects = m_NestedCascade2.detect_objects (gray_scale, m_Storage, 1.4, 2, 0);

                count = nested_objects != null ? nested_objects.total : 0;
            }

            bool leftT = false;
            bool rightT = false;

            if (count > 0)
            {
                for (int j = 0; j < nested_objects.total; ++j)
                {
                    OpenCV.Point center = OpenCV.Point (0, 0);
                    unowned OpenCV.Rectangle? nr = nested_objects [j];
                    center.x = OpenCV.Math.round ((inLT.x + (nr.x + nr.width * 0.5) * scale));
                    center.y = OpenCV.Math.round ((inLT.y + (inInput.height) / 8 + (nr.y + nr.height * 0.5) * scale));

                    if ((center.x - 4) > 0 && ((center.x - 4) < (Image.WIDTH - 8)) &&
                        (center.y - 4) > 0 && ((center.y - 4) < (Image.HEIGHT - 8)))
                    {
                        gray_fullimage.set_roi (OpenCV.Rectangle (center.x - 4, center.y - 4, 8, 8));

                        OpenCV.IPL.Image eyeDetect = new OpenCV.IPL.Image (OpenCV.Size (8, 8), 8, 1);
                        gray_fullimage.resize (eyeDetect, OpenCV.IPL.InterpolationType.LINEAR);
                        gray_fullimage.reset_roi ();

                        double xCordinate = (center.x - 4 + center_of_mass (eyeDetect, false));
                        double yCordinate = (center.y - 4 + center_of_mass (eyeDetect, true));

                        if (center.x < OpenCV.Math.round (inLT.x + inInput.width * 0.5))
                        {
                            m_Eyes.le.x = (int)xCordinate;
                            m_Eyes.le.y = (int)yCordinate;

                            leftT = true;
                        }
                        else
                        {
                            m_Eyes.re.x = (int)xCordinate;
                            m_Eyes.re.y = (int)yCordinate;

                            rightT = true;
                        }
                    }
                }

                if (leftT && rightT)
                {
                    m_Eyes.length = (int)GLib.Math.sqrt (GLib.Math.pow (m_Eyes.re.y - m_Eyes.le.y, 2) + GLib.Math.pow (m_Eyes.re.x - m_Eyes.le.x, 2));
                    m_BothEyesDetected = true;
                }
            }
        }
    }
}