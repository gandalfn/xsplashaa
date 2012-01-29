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

        /**
         * Query webcam frame cairo surface
         */
        public Cairo.Surface?
        frame_to_cairo_surface (OpenCV.IPL.Image inImage)
        {
            Cairo.ImageSurface? surface = null;

            surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                              Image.WIDTH, Image.HEIGHT);
            unowned uchar* dst = surface.get_data ();
            unowned uchar* src = inImage.image_data;
            int size = Image.WIDTH * Image.HEIGHT;

            for (int n = size; (--n) > 0;)
            {
                *(dst + 0) = *(src + 0);
                *(dst + 1) = *(src + 1);
                *(dst + 2) = *(src + 2);
                *(dst + 3) = 0xFF;
                dst += 4;
                src += 3;
           }

            surface.mark_dirty ();
            surface.flush ();

            return surface;
        }

        /**
         * Query webcam frame cairo surface with ellipse
         */
        public Cairo.Surface?
        paint_ellipse (OpenCV.IPL.Image inImage, OpenCV.Point inLeftEye, OpenCV.Point inRightEye)
        {
            Cairo.Surface? surface = frame_to_cairo_surface (inImage);

            OpenCV.Point p2 = OpenCV.Point (inLeftEye.x, inLeftEye.y);
            double yvalue = inRightEye.y - inLeftEye.y;
            double xvalue = inRightEye.x - inLeftEye.x;
            double width  = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2));
            double ratio  = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2)) / 80.0;

            p2.x += (int)(width / 2.0);
            p2.y += (int)(35 * ratio);

            double ang= -GLib.Math.atan (yvalue / xvalue) * (180.0 / GLib.Math.PI);

            Cairo.Context ctx = new Cairo.Context (surface);
            ctx.translate (inLeftEye.x, inLeftEye.y);
            ctx.move_to (p2.x, p2.y);
            ctx.rotate (ang / 360.0);
            ctx.move_to (-p2.x, -p2.y);
            double scale_x = ((width / 2.0) + (55.0 * ratio)) / (double)inImage.width;
            double scale_y = (120.0 * ratio) / (double)inImage.height;
            ctx.scale (scale_x, scale_y);
            ctx.arc (p2.x / scale_x, p2.y / scale_y, inImage.width, 0, 2 * GLib.Math.PI);
            ctx.set_source_rgb (1, 1, 1);
            ctx.fill ();

            return surface;
        }
    }
}
