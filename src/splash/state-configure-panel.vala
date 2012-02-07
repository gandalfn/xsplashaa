/* state-configure-panel.vala
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
     * Configure panel state machine
     */
    public class StateConfigurePanel : StateMachine
    {
        // properties
        private unowned Devices m_Peripherals;
        private int             m_Number;

        /**
         * Create a new configure panel state machine
         *
         * @param inPeripherals peripherals devices
         */
        public StateConfigurePanel (Devices inPeripherals, int inNumber)
        {
            m_Peripherals = inPeripherals;
            m_Number = inNumber;
        }

        protected override void
        on_run ()
        {
            if (m_Peripherals.allied_panel == null)
            {
                error ("Unable to find Allied Panel device");
            }
            else
            {
                // configure panel
                if (!m_Peripherals.setup_panel (m_Number))
                {
                    error ("Unable to find Allied Panel device");
                }
                else
                {
                    base.on_run ();
                }
            }
        }
    }
}

