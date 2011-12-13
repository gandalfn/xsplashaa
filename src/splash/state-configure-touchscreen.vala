/* state-configure-touchscreen.vala
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
     * Configure touchscreen state machine
     */
    public class StateConfigureTouchscreen : StateMachine
    {
        // properties
        private unowned Devices m_Peripherals;
        private int             m_Number;

        // accessors
        public override GLib.Type next_state {
            get {
                return typeof (StateCalibrateTouchscreen);
            }
        }

        /**
         * Create a new configure touchscreen state machine
         *
         * @param inPeripherals peripherals devices
         * @param inNumber display number
         */
        public StateConfigureTouchscreen (Devices inPeripherals, int inNumber)
        {
            m_Peripherals = inPeripherals;
            m_Number = inNumber;
        }

        protected override void
        on_run ()
        {
            try
            {
                // Open display for touchscreen
                if (m_Peripherals.touchscreen.open_display (":" + m_Number.to_string ()) == m_Number)
                {
                    // Create virtual pointer for display
                    if (!m_Peripherals.touchscreen.create_virtual_pointer (":" + m_Number.to_string ()))
                    {
                        error ("Error on configure touchscreen for display !!");
                    }
                    else
                    {
                        base.on_run ();
                    }
                }
                else
                {
                    error ("Error on configure touchscreen for display !!");
                }
            }
            catch (GLib.Error err)
            {
                error ("Error on configure touchscreen for display !!");
            }
        }
    }
}
