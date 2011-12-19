/* webcam.vala
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
     * Webcam class
     */
    public class Webcam : GLib.Object
    {
        // properties
        private int            m_CameraIndex;
        private OpenCV.Capture m_Capture;

        // accessors

        // signals

        // methods
        /**
         * Create a new webcam
         *
         * @param inCameraIndex camera index
         */
        public Webcam (int inCameraIndex = 0)
        {
            m_CameraIndex = inCameraIndex;
        }

        /**
         * Start webcam
         */
        public bool
        start ()
        {
            m_Capture = new OpenCV.Capture.from_camera (m_CameraIndex);
            if (m_Capture == null)
            {
                m_Capture = new OpenCV.Capture.from_camera (OpenCV.Capture.Domain.ANY);
            }

            return m_Capture != null;
        }

        /**
         * Stop camera
         */
        public void
        stop ()
        {
            m_Capture = null;
        }

        /**
         * Query webcam frame
         */
        public OpenCV.IPL.Image?
        query_frame ()
            requires (m_Capture != null)
        {
            unowned OpenCV.IPL.Image? original_frame = m_Capture.query_frame ();
            if (original_frame == null)
                return null;

            OpenCV.IPL.Image frame = new OpenCV.IPL.Image (OpenCV.Size (Image.WIDTH, Image.HEIGHT),
                                                           OpenCV.IPL.DEPTH_8U,
                                                           original_frame.n_channels);
            original_frame.resize (frame, OpenCV.IPL.InterpolationType.LINEAR);

            OpenCV.IPL.Image frame_copy = new OpenCV.IPL.Image (OpenCV.Size (frame.width, frame.height),
                                                                OpenCV.IPL.DEPTH_8U,
                                                                frame.n_channels);
            if (frame.origin == OpenCV.IPL.Origin.TL)
                frame.copy (frame_copy);
            else
                frame.flip (frame_copy);

            return frame_copy;
        }
    }
}
