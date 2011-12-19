/* face-authentification.vala
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

namespace XSAA.Aixplorer
{
    public class FaceAuthentification : Item
    {
        // types
        public enum Status
        {
            STOPPED         = 28,
            STARTED         = 21
        }

        // constants
        private const Os.key_t FACE_AUTHENTICATION_IPC_KEY_IMAGE     = 567814;
        private const Os.key_t FACE_AUTHENTICATION_IPC_KEY_STATUS    = 567813;

        private const int      FACE_AUTHENTICATION_IMAGE_WIDTH       = 320;
        private const int      FACE_AUTHENTICATION_IMAGE_HEIGHT      = 240;
        private const int      FACE_AUTHENTICATION_IMAGE_SIZE        = 307200;

        private const int      SHM_ERR                               = -1;

        // properties
        private Timeline        m_Refresh;
        private int             m_PixelsId    = SHM_ERR;
        private int             m_StatusId    = SHM_ERR;
        private unowned uchar[] m_Pixels      = (uchar[])SHM_ERR;
        private int*            m_Status      = (int*)SHM_ERR;

        // accessors
        public override string node_name {
            get {
                return "faceauth";
            }
        }

        // methods
        construct
        {
            m_Refresh = new Timeline (60, 60);
            m_Refresh.loop = true;
            m_Refresh.new_frame.connect (on_refresh);

            width = FACE_AUTHENTICATION_IMAGE_WIDTH;
            height = FACE_AUTHENTICATION_IMAGE_HEIGHT;
        }

        private void
        ipc_start ()
        {
            if (m_PixelsId == SHM_ERR)
            {
                m_PixelsId = Os.shmget (FACE_AUTHENTICATION_IPC_KEY_IMAGE, FACE_AUTHENTICATION_IMAGE_SIZE, 0666);
                if (m_PixelsId == SHM_ERR)
                {
                    Log.critical ("error on get face authentication pixels mem: %s", GLib.strerror (GLib.errno));
                }
            }
            if (m_PixelsId != SHM_ERR && (void*)m_Pixels == (void*)SHM_ERR)
            {
                m_Pixels = (uchar[])Os.shmat (m_PixelsId, null, 0);
                if ((void*)m_Pixels == (void*)(SHM_ERR))
                {
                    Log.critical ("error on get face authentication pixels mem: %s", GLib.strerror (GLib.errno));
                }
            }

            if (m_StatusId == SHM_ERR)
            {
                m_StatusId = Os.shmget (FACE_AUTHENTICATION_IPC_KEY_STATUS, sizeof (int), 0666);
                if (m_StatusId == SHM_ERR)
                {
                    Log.critical ("error on get face authentication status mem: %s", GLib.strerror (GLib.errno));
                }
            }
            if (m_StatusId != SHM_ERR && (void*)m_Status == (void*)(SHM_ERR))
            {
                m_Status = (int*)Os.shmat (m_StatusId, null, 0);
                if ((void*)m_Status == (void*)(SHM_ERR))
                {
                    Log.critical ("error on get face authentication status mem: %s", GLib.strerror (GLib.errno));
                }
            }
        }

        private void
        on_refresh (int inFrameNum)
        {
            if (m_StatusId == SHM_ERR || (void*)m_Status == (void*)(SHM_ERR))
                ipc_start ();

            if ((void*)m_Status != (void*)(SHM_ERR))
            {
                switch (*m_Status)
                {
                    case Status.STARTED:
                        changed (false);
                        break;
                    case Status.STOPPED:
                        GLib.Idle.add (() => {
                            Log.debug ("face authentification stopped");
                            stop ();
                            return false;
                        });
                        break;
                    default:
                        break;
                }
                changed (false);
            }
        }

        private Cairo.ImageSurface?
        get_face_surface ()
        {
            if (m_PixelsId == SHM_ERR || (void*)m_Pixels == (void*)(SHM_ERR))
                ipc_start ();

            Cairo.ImageSurface? surface = null;
            if ((void*)m_Pixels != (void*)(SHM_ERR))
            {
                surface = new Cairo.ImageSurface.for_data (m_Pixels, Cairo.Format.ARGB32,
                                                           FACE_AUTHENTICATION_IMAGE_WIDTH,
                                                           FACE_AUTHENTICATION_IMAGE_HEIGHT,
                                                           Cairo.Format.ARGB32.stride_for_width (FACE_AUTHENTICATION_IMAGE_WIDTH));
            }

            return surface;
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            Cairo.ImageSurface surface = get_face_surface ();
            if (surface != null)
            {
                inContext.save ();
                Cairo.Pattern pattern = new Cairo.Pattern.for_surface (surface);
                Cairo.Matrix matrix = Cairo.Matrix.identity ();
                matrix.scale (surface.get_width () / width, surface.get_height () / height);
                matrix.translate (-x, -y);
                pattern.set_matrix (matrix);
                get_style ().set_fill_options (inContext);
                inContext.set_source (pattern);
                ((CairoContext)inContext).rounded_rectangle (x, y, width, height, 12, CairoCorner.ALL);
                inContext.fill ();
                inContext.restore ();
            }
        }

        public void
        start ()
        {
            ipc_start ();

            m_Refresh.start ();
        }

        public void
        stop ()
        {
            if ((int)m_Pixels > 0 && (int)m_Status > 0)
            {
                Os.shmdt (m_Pixels);
                Os.shmdt (m_Status);
                m_Pixels = null;
                m_Status = null;
            }

            if (m_Refresh.is_playing)
            {
                m_Refresh.stop ();
            }
        }
    }
}
