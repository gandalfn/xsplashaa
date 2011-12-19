/* state-check-touchscreen.vala
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
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    /**
     * Check touchscreen state machine
     */
    public class StateCheckTouchscreen : StateMachine
    {
        // properties
        private unowned Devices m_Peripherals;

        // accessors
        public override GLib.Type next_state {
            get {
                return typeof (StateConfigureTouchscreen);
            }
        }

        public override GLib.Type error_state {
            get {
                return typeof (StateCheckPanel);
            }
        }

        /**
         * Create a new check touchscreen state machine
         *
         * @param inPeripherals peripherals devices
         */
        public StateCheckTouchscreen (Devices inPeripherals)
        {
            m_Peripherals = inPeripherals;
        }

        protected override void
        on_run ()
        {
            if (m_Peripherals.touchscreen == null)
            {
                error ("Unable to found touchscreen device");
            }
            else
            {
                base.on_run ();
            }
        }
    }
}

