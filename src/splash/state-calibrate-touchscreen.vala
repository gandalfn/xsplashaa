/* state-calibrate-touchscreen.vala
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
     * Calibrate touchscreen state machine
     */
    public class StateCalibrateTouchscreen : StateMachine
    {
        // properties
        private unowned Devices m_Peripherals;
        private int             m_Number;

        // accessors
        public override GLib.Type next_state {
            get {
                return typeof (StateCheckPanel);
            }
        }

        public override GLib.Type error_state {
            get {
                return typeof (StateCheckPanel);
            }
        }

        /**
         * Create a new calibrate touchscreen state machine
         *
         * @param inPeripherals peripherals devices
         * @param inNumber display number
         */
        public StateCalibrateTouchscreen (Devices inPeripherals, int inNumber)
        {
            m_Peripherals = inPeripherals;
            m_Number = inNumber;
        }

        private void
        on_calibration_finished ()
        {
            base.on_run ();
        }

        protected override void
        on_run ()
        {
            try
            {
                if (m_Peripherals.touchscreen.need_calibration (":" + m_Number.to_string ()))
                {
                    message ("Please calibrate touchscreen");
                    m_Peripherals.touchscreen.calibrate (":" + m_Number.to_string ());
                    m_Peripherals.touchscreen.calibration_finished.connect (on_calibration_finished);
                }
                else
                {
                    base.on_run ();
                }
            }
            catch (GLib.Error err)
            {
                error ("Error on calibrate touchscreen");
            }
        }
    }
}

