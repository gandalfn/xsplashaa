/* state-check-peripherals.vala
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
     * Check peripherals state machine
     */
    public class StateCheckPeripherals : StateMachine
    {
        // properties
        private Devices m_Peripherals;

        /**
         * Create a new check peripherals state machine
         *
         * @param inConnection dbus connection
         * @param inNumber display number
         */
        public StateCheckPeripherals (DBus.Connection inConnection, int inNumber)
        {
            m_Peripherals = new Devices (inConnection);

            // create check service state
            add_state (new StateServiceCheck (m_Peripherals));

            // create check touchscreen state
            add_state (new StateCheckTouchscreen (m_Peripherals));

            // create configure touchscreen state
            add_state (new StateConfigureTouchscreen (m_Peripherals, inNumber));

            // create calibrate touchscreen state
            add_state (new StateCalibrateTouchscreen (m_Peripherals, inNumber));
        }

        protected override void
        on_run ()
        {
            start (typeof (StateServiceCheck));
        }
    }
}
