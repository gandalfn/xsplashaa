/* state-check-ssidab.vala
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
     * Check ssidab state machine
     */
    public class StateCheckSSIDab : StateMachine
    {
        // properties
        private unowned Devices  m_Peripherals;

        // methods
        /**
         * Create a new check ssidab state machine
         *
         * @param inPeripherals peripherals devices
         */
        public StateCheckSSIDab (Devices inPeripherals)
        {
            m_Peripherals = inPeripherals;
        }

        private void
        check_dabs ()
        {
            if (!m_Peripherals.ssidab.driver_loaded)
            {
                error ("DAB driver is not loaded");
            }
            else if (m_Peripherals.ssidab.nbcg != m_Peripherals.ssidab.required_device_count)
            {
                error ("Failure: detected CG = %i / expected = %i".printf (m_Peripherals.ssidab.nbcg, m_Peripherals.ssidab.required_device_count));
            }
            else
            {
                base.on_run ();
            }
        }

        protected override void
        on_run ()
        {
            if (m_Peripherals.ssidab == null)
            {
                error ("Unable to find DAB devices");
            }
            else
            {
                check_dabs ();
            }
        }
    }
}

