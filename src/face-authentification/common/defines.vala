/* defines.vala
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
    public enum Status
    {
        STOPPED         = 28,
        STARTED         = 21
    }

    // constants
    namespace IpcKey
    {
        /**
         * Shared Memory Key Value for Image
         */
        public const Os.key_t IMAGE = 567814;

        /**
         * Shared Memory Key Value for Communication
         */
        public const Os.key_t STATUS = 567813;
    }

    namespace Image
    {
        /**
         * Image Width of Webcam
         */
        public const int WIDTH = 320;

        /**
         * Image Height of Webcam
         */
        public const int HEIGHT = 240;

        /**
         * Shared Memory Size for Image , 320X240
         */
        public const int SIZE = 307200;
    }

    public enum MaceDefault
    {
        /**
         * Mace Filter Face Threshold Value
         */
        FACE = 24,
        /**
         * Mace Filter Eye Threshold Value
         */
        EYE = 25,
        /**
         * Mace Filter Inside Face Threshold Value
         */
        INSIDE_FACE = 26
    }

    public const string USER_CONFIG_PATH = "/.config/xsplashaa/face-authentification";
}
