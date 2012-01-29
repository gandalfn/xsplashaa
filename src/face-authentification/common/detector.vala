/* detector.vala
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
     * Detector class. This class subclasses the face and eyes detector classes.
     */
    public class Detector : GLib.Object
    {
        // types
        public enum Status
        {
            INVALID = -1,
            TO_FAR,
            TO_CLOSER,
            UNABLE_TO_DETECT,
            LOST_TRACKER,
            TRACKING,
            CAPTURE,
            FINISHED;

            public string
            to_string ()
            {
                switch (this)
                {
                    case TO_FAR:
                        return "Please come closer to the camera.";
                    case TO_CLOSER:
                        return "Please go little far from the camera.";
                    case UNABLE_TO_DETECT:
                        return "Unable to Detect Your Face.";
                    case LOST_TRACKER:
                        return "Tracker lost, trying to reinitialize.";
                    case TRACKING:
                        return "Tracking in progress.";
                    case CAPTURE:
                        return "Captured %i/%i faces.";
                    case FINISHED:
                        return "Capturing Image Finished.";
                }

                return "";
            }
        }

        // constants
        const int eyeSidePad  = 30;
        const int eyeTopPad = 30;
        const int eyeBottomPad = 120;

        // properties
        private FaceDetector       m_FaceDetector;
        private EyesDetector       m_EyesDetector;
        private OpenCV.IPL.Image[] m_ClippedFaces;
        private OpenCV.Point       m_LeftEyePoint;
        private OpenCV.Point       m_RightEyePoint;
        private OpenCV.Point       m_LeftEyePointRelative;
        private OpenCV.Point       m_RightEyePointRelative;
        private double             m_Angle;
        private int                m_LengthEye;
        private int                m_WidthEyeWindow;
        private int                m_HeightEyeWindow;
        private int                m_PrevLengthEye;
        private Tracker            m_LeftEye;
        private Tracker            m_RightEye;

        // accessors
        public Status status { get; set; default = Status.INVALID; }
        public bool detected {
            get {
                return status == Status.TRACKING;
            }
        }

        public Face face_information {
            get {
                return m_FaceDetector.face_information;
            }
        }

        public bool face_detected {
            get {
                return m_FaceDetector.face_detected;
            }
        }

        public Eyes eyes_information {
            get {
                return m_EyesDetector.eyes_information;
            }
        }

        public bool eyes_detected {
            get {
                return m_EyesDetector.eyes_detected;
            }
        }

        // static methods
        private static OpenCV.IPL.Image
        preprocess (OpenCV.IPL.Image inImg, OpenCV.Point inLeftEye, OpenCV.Point inRightEye)
        {
            OpenCV.IPL.Image face = new OpenCV.IPL.Image (OpenCV.Size (140, 150), 8, 3);
            OpenCV.IPL.Image imgDest = new OpenCV.IPL.Image (OpenCV.Size (inImg.width, inImg.height), 8, 3);
            face.zero ();

            double xvalue = inRightEye.x - inLeftEye.x;
            double yvalue = inRightEye.y - inLeftEye.y;
            double ang = GLib.Math.atan (yvalue / xvalue) * (180 / GLib.Math.PI);
            double width = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2));
            double ratio = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2)) / 80;
            double sidePad = eyeSidePad * ratio;
            double topPad = eyeTopPad * ratio;
            double bottomPad = eyeBottomPad * ratio;
            OpenCV.Point p1LeftTop = OpenCV.Point ((int)(inLeftEye.x - sidePad), (int)(inLeftEye.y - topPad));
            OpenCV.Point p1RightBottom = OpenCV.Point ((int)(inLeftEye.x + width + sidePad), (int)(inLeftEye.y + bottomPad));

            rotate (ang, inLeftEye.x, inLeftEye.y, inImg, imgDest);
            imgDest.set_roi (OpenCV.Rectangle (p1LeftTop.x, p1LeftTop.y, p1RightBottom.x - p1LeftTop.x, p1RightBottom.y - p1LeftTop.y));
            imgDest.resize (face, OpenCV.IPL.InterpolationType.LINEAR);
            imgDest.reset_roi ();

            return face;
        }

        // methods
        /**
         * Create a new detector object
         */
        public Detector ()
        {
            m_FaceDetector = new FaceDetector ();
            m_EyesDetector = new EyesDetector ();

            m_ClippedFaces = {};

            m_LeftEye = new Tracker ();
            m_RightEye = new Tracker ();
        }

        /**
         * Returns the face image of the detected face
         *
         * @param inputImage, the input image.
         *
         * @result IplImage on success, 0 on failure
         */
        public OpenCV.IPL.Image?
        clip_face (OpenCV.IPL.Image? inInputImage)
        {
            if (inInputImage == null) return null;

            if (m_EyesDetector.eyes_information.le.x > 0 && m_EyesDetector.eyes_information.le.y > 0 &&
                m_EyesDetector.eyes_information.re.x > 0 && m_EyesDetector.eyes_information.re.y > 0)
            {
                return preprocess (inInputImage, m_EyesDetector.eyes_information.le, m_EyesDetector.eyes_information.re);
            }

            return null;
        }

        /**
         * Function to run the detection / tracking algorithm on param image
         *
         * @param inInput the IplImage on which the algorithm should be run on
         */
        public void
        run (OpenCV.IPL.Image? inInput)
        {
            status = Status.INVALID;

            if (inInput == null) return;

            m_FaceDetector.run (inInput);
            if (m_FaceDetector.face_detected)
            {
                if (m_FaceDetector.face_information.width < 60 || m_FaceDetector.face_information.height < 60)
                {
                    status = Status.TO_FAR;
                }
                else if (m_FaceDetector.face_information.width > 200 || m_FaceDetector.face_information.height > 200)
                {
                    status = Status.TO_CLOSER;
                }
                else
                {
                    OpenCV.IPL.Image clipFaceImage = m_FaceDetector.clip_detected_face (inInput);

                    m_EyesDetector.run (clipFaceImage, m_FaceDetector.face_information.lt);
                    if (m_EyesDetector.eyes_detected)
                    {
                        OpenCV.IPL.Image gray = new OpenCV.IPL.Image (OpenCV.Size (clipFaceImage.width, clipFaceImage.height / 2), 8, 1);
                        clipFaceImage.set_roi (OpenCV.Rectangle (0, clipFaceImage.height / 8, clipFaceImage.width, clipFaceImage.height / 2));
                        clipFaceImage.convert_color (gray, OpenCV.ColorConvert.BGR2GRAY);
                        clipFaceImage.reset_roi ();

                        m_LeftEyePoint.x = m_EyesDetector.eyes_information.le.x;
                        m_LeftEyePoint.y = m_EyesDetector.eyes_information.le.y;
                        m_RightEyePoint.x = m_EyesDetector.eyes_information.re.x;
                        m_RightEyePoint.y = m_EyesDetector.eyes_information.re.y;

                        double xvalue = m_RightEyePoint.x - m_LeftEyePoint.x;
                        double yvalue = m_RightEyePoint.y - m_LeftEyePoint.y;

                        m_Angle = GLib.Math.atan (yvalue / xvalue);
                        m_LeftEyePointRelative.x = m_EyesDetector.eyes_information.le.x - m_FaceDetector.face_information.lt.x;
                        m_LeftEyePointRelative.y = m_EyesDetector.eyes_information.le.y - m_FaceDetector.face_information.lt.y - clipFaceImage.height / 8;
                        m_RightEyePointRelative.x = m_EyesDetector.eyes_information.re.x - m_FaceDetector.face_information.lt.x - gray.width / 2;
                        m_RightEyePointRelative.y = m_EyesDetector.eyes_information.re.y - m_FaceDetector.face_information.lt.y - clipFaceImage.height / 8;

                        m_LengthEye = m_EyesDetector.eyes_information.length;
                        m_PrevLengthEye = m_EyesDetector.eyes_information.length;
                        m_WidthEyeWindow = gray.width / 2;
                        m_HeightEyeWindow = gray.height;

                        OpenCV.IPL.Image grayIm1 = new OpenCV.IPL.Image (OpenCV.Size (gray.width / 2, gray.height), 8, 1);
                        gray.set_roi (OpenCV.Rectangle (0, 0, gray.width / 2, gray.height));
                        gray.resize (grayIm1, OpenCV.IPL.InterpolationType.LINEAR);
                        gray.reset_roi ();
                        m_LeftEye.set_model (grayIm1);
                        m_LeftEye.anchor_point = m_LeftEyePointRelative;

                        OpenCV.IPL.Image grayIm2 = new OpenCV.IPL.Image (OpenCV.Size (gray.width / 2, gray.height), 8, 1);
                        gray.set_roi (OpenCV.Rectangle (gray.width / 2, 0, gray.width / 2, gray.height));
                        gray.resize (grayIm2, OpenCV.IPL.InterpolationType.LINEAR);
                        gray.reset_roi ();
                        m_RightEye.set_model (grayIm2);
                        m_RightEye.anchor_point = m_RightEyePointRelative;
                    }
                    else
                    {
                        status = Status.UNABLE_TO_DETECT;
                    }
                }
            }
            else
            {
                status = Status.UNABLE_TO_DETECT;
            }

            int newWidth = 0, newHeight = 0;
            if (m_FaceDetector.face_detected && m_EyesDetector.eyes_detected && m_LengthEye != 0)
            {
                newWidth = (int)GLib.Math.floor ((m_PrevLengthEye * m_WidthEyeWindow) / m_LengthEye);
                newHeight =  (int)GLib.Math.floor ((m_PrevLengthEye * m_HeightEyeWindow) / m_LengthEye);
            }

            if (m_FaceDetector.face_detected && m_EyesDetector.eyes_detected && m_LengthEye > 0 &&
                newWidth > 0 && newHeight > 0 && m_PrevLengthEye > 0)
            {
                double xvalue = m_RightEyePoint.x - m_LeftEyePoint.x;
                double yvalue = m_RightEyePoint.y - m_LeftEyePoint.y;
                double currentAngle = GLib.Math.atan (yvalue / xvalue) * (180 / GLib.Math.PI);
                currentAngle -= m_Angle;

                OpenCV.Matrix rotateMatrix = new OpenCV.Matrix (2, 3, OpenCV.Type.FC32_1);
                OpenCV.Point2D32f centre = OpenCV.Point2D32f (m_LeftEyePoint.x, m_LeftEyePoint.y);
                centre.rotation_matrix (currentAngle, 1.0, rotateMatrix);

                OpenCV.IPL.Image dstimg = new OpenCV.IPL.Image (OpenCV.Size (inInput.width, inInput.height), 8, inInput.n_channels);
                inInput.warp_affine (dstimg, rotateMatrix, OpenCV.WARP_FILL_OUTLIERS, OpenCV.Scalar.all (0));

                OpenCV.Point rotatedRightP =  OpenCV.Point (0, 0);
                rotatedRightP.x = (int)GLib.Math.floor (m_RightEyePoint.x * rotateMatrix[0, 0] +
                                                        m_RightEyePoint.y * rotateMatrix[0, 1] +
                                                        rotateMatrix[0, 2]);
                rotatedRightP.y = (int)GLib.Math.floor (m_RightEyePoint.x * rotateMatrix[1, 0] +
                                                        m_RightEyePoint.y * rotateMatrix[1, 1] +
                                                        rotateMatrix[1, 2]);
                m_RightEyePoint.x = rotatedRightP.x;
                m_RightEyePoint.y = rotatedRightP.y;

                double newWidthR = newWidth;
                double newHeightR = newHeight;
                double newWidthL = newWidth;
                double newHeightL = newHeight;

                int ly = m_LeftEyePoint.y - (int)(GLib.Math.floor ((m_LeftEyePointRelative.y * newWidth) / m_WidthEyeWindow));
                int lx = m_LeftEyePoint.x - (int)(GLib.Math.floor ((m_LeftEyePointRelative.x * newWidth) / m_WidthEyeWindow));
                int lxdiff = 0, lydiff = 0;

                if (lx < 0)
                {
                    lxdiff = -lx;
                    lx = 0;
                }

                if (ly < 0)
                {
                    lydiff = -ly;
                    ly = 0;
                }

                if ((lx + newWidth) > Image.WIDTH) newWidthL = Image.WIDTH - lx;
                if ((ly + newHeight) > Image.HEIGHT) newHeightL = Image.HEIGHT - ly;

                OpenCV.IPL.Image grayIm1 = new OpenCV.IPL.Image (OpenCV.Size ((int)newWidthL, (int)newHeightL), 8, 1);
                dstimg.set_roi (OpenCV.Rectangle (lx, ly, (int)newWidthL, (int)newHeightL));
                dstimg.convert_color (grayIm1, OpenCV.ColorConvert.BGR2GRAY);
                dstimg.reset_roi ();

                int rx = m_RightEyePoint.x - (int)(GLib.Math.floor ((m_RightEyePointRelative.x * newWidth) / m_WidthEyeWindow));
                int ry = m_RightEyePoint.y - (int)(GLib.Math.floor ((m_RightEyePointRelative.y * newWidth) / m_WidthEyeWindow));
                int rxdiff = 0, rydiff = 0;

                if (ry < 0)
                {
                  rydiff = -ry;
                  ry = 0;
                }

                if (rx < 0)
                {
                  rxdiff = -rx;
                  rx = 0;
                }

                if ((rx + newWidth) > Image.WIDTH) newWidthR = Image.WIDTH - rx;
                if ((ry + newHeight) > Image.HEIGHT) newHeightR = Image.HEIGHT - ry;

                OpenCV.IPL.Image grayIm2 = new OpenCV.IPL.Image (OpenCV.Size ((int)newWidthR, (int)newHeightR), 8, 1);
                dstimg.set_roi (OpenCV.Rectangle (rx, ry, (int)newWidthR, (int)newHeightR));
                dstimg.convert_color (grayIm2, OpenCV.ColorConvert.BGR2GRAY);
                dstimg.reset_roi ();

                m_LeftEye.track_image (grayIm1);
                m_RightEye.track_image (grayIm2);

                OpenCV.Point temp = OpenCV.Point (0, 0);
                OpenCV.Point leftEyePTemp = OpenCV.Point (0, 0);
                OpenCV.Point leftEyePointRelativeTemp = OpenCV.Point (0, 0);

                m_LeftEye.find_point (m_LeftEyePointRelative, ref temp);
                leftEyePTemp.y = m_LeftEyePoint.y -((m_LeftEyePointRelative.y * newWidth) / m_WidthEyeWindow) + lydiff + temp.y;
                leftEyePTemp.x = m_LeftEyePoint.x -(((m_LeftEyePointRelative.x) * newWidth) / m_WidthEyeWindow) + lxdiff + temp.x;
                leftEyePointRelativeTemp.x = temp.x;
                leftEyePointRelativeTemp.y = temp.y;

                OpenCV.Point rightEyePTemp = OpenCV.Point (0, 0);
                OpenCV.Point rightEyePointRelativeTemp = OpenCV.Point (0, 0);
                m_RightEye.find_point (m_RightEyePointRelative, ref temp);
                rightEyePTemp.y = m_RightEyePoint.y - ((m_RightEyePointRelative.y * newWidth) / m_WidthEyeWindow) + rydiff + temp.y;
                rightEyePTemp.x = m_RightEyePoint.x - ((m_RightEyePointRelative.x * newWidth) / m_WidthEyeWindow) + rxdiff + temp.x;
                rightEyePointRelativeTemp.x = temp.x;
                rightEyePointRelativeTemp.y = temp.y;

                double angle = GLib.Math.atan ((double)(rightEyePTemp.y - leftEyePTemp.y) / (double)(rightEyePTemp.x - leftEyePTemp.x)) * 180 / GLib.Math.PI;
                double angle2 = GLib.Math.atan ((double)(m_RightEyePoint.y - m_LeftEyePoint.y) / (double)(m_RightEyePoint.x - m_LeftEyePoint.x)) * 180 / GLib.Math.PI;
                double v1 = GLib.Math.sqrt (GLib.Math.pow (rightEyePTemp.y - m_RightEyePoint.y, 2) + GLib.Math.pow (rightEyePTemp.x - m_RightEyePoint.x, 2));
                double v2 = GLib.Math.sqrt (GLib.Math.pow (leftEyePTemp.y - m_LeftEyePoint.y, 2) + GLib.Math.pow (leftEyePTemp.x - m_LeftEyePoint.x, 2));
                double lengthTemp = GLib.Math.sqrt (GLib.Math.pow (rightEyePTemp.y - leftEyePTemp.y, 2) + GLib.Math.pow (rightEyePTemp.x - leftEyePTemp.x, 2));

                if (GLib.Math.pow ((angle2 - angle), 2) < 300 && v1 < 140 && v2 < 144 && lengthTemp > 1)
                {
                    status = Status.TRACKING;
                    m_LeftEyePoint = leftEyePTemp;
                    m_RightEyePoint  = rightEyePTemp;

                    centre.rotation_matrix (-currentAngle, 1.0, rotateMatrix);
                    OpenCV.Point antiRotateR = OpenCV.Point (0, 0);
                    OpenCV.Point antiRotateL = OpenCV.Point (0, 0);
                    antiRotateR.x = (int)GLib.Math.floor (m_RightEyePoint.x * rotateMatrix[0, 0] +
                                                          m_RightEyePoint.y * rotateMatrix [0, 1] +
                                                          rotateMatrix [0, 2]);
                    antiRotateR.y = (int)GLib.Math.floor (m_RightEyePoint.x * rotateMatrix[1, 0] +
                                                          m_RightEyePoint.y * rotateMatrix [1, 1] +
                                                          rotateMatrix [1, 2]);
                    antiRotateL.x = (int)GLib.Math.floor (m_LeftEyePoint.x * rotateMatrix[0, 0] +
                                                          m_LeftEyePoint.y * rotateMatrix [0, 1] +
                                                          rotateMatrix [0, 2]);
                    antiRotateL.y = (int)GLib.Math.floor (m_LeftEyePoint.x * rotateMatrix[1, 0] +
                                                          m_LeftEyePoint.y * rotateMatrix [1, 1] +
                                                          rotateMatrix [1, 2]);

                    m_LeftEyePoint = antiRotateL;
                    m_RightEyePoint = antiRotateR;

                    m_EyesDetector.eyes_information.le.x = m_LeftEyePoint.x;
                    m_EyesDetector.eyes_information.le.y = m_LeftEyePoint.y;
                    m_EyesDetector.eyes_information.re.x = m_RightEyePoint.x;
                    m_EyesDetector.eyes_information.re.y = m_RightEyePoint.y;

                    m_EyesDetector.eyes_information.length = (int)GLib.Math.sqrt (GLib.Math.pow (m_EyesDetector.eyes_information.re.y - m_EyesDetector.eyes_information.le.y, 2) +
                                                                                  GLib.Math.pow (m_EyesDetector.eyes_information.re.x - m_EyesDetector.eyes_information.le.x, 2));

                    m_PrevLengthEye = m_EyesDetector.eyes_information.length;
                }
            }
        }
    }
}
