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
        public StateCheckPeripherals (DBus.Connection inConnection, CheckFlags inCheckFlags, int inNumber)
        {
            m_Peripherals = new Devices (inConnection);

            // create check service state
            if ((inCheckFlags & CheckFlags.PERIPHERALS) == CheckFlags.PERIPHERALS)
            {
                var service_state = new StateServiceCheck (m_Peripherals);

                if ((inCheckFlags & CheckFlags.TOUCHSCREEN) == CheckFlags.TOUCHSCREEN)
                {
                    service_state.next_state = typeof (StateCheckTouchscreen);
                }
                else if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                {
                    service_state.next_state = typeof (StateCheckPanel);
                }
                else if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                {
                    service_state.next_state = typeof (StateCheckSSIDab);
                }

                add_state (service_state);

                // create check touchscreen state
                if ((inCheckFlags & CheckFlags.TOUCHSCREEN) == CheckFlags.TOUCHSCREEN)
                {
                    var check_touchscreen_state = new StateCheckTouchscreen (m_Peripherals, inNumber);

                    check_touchscreen_state.next_state = typeof (StateConfigureTouchscreen);
                    if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                    {
                        check_touchscreen_state.error_state = typeof (StateCheckPanel);
                    }
                    else if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        check_touchscreen_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (check_touchscreen_state);
                }

                // create configure touchscreen state
                if ((inCheckFlags & CheckFlags.TOUCHSCREEN) == CheckFlags.TOUCHSCREEN)
                {
                    var configure_touchscreen_state = new StateConfigureTouchscreen (m_Peripherals, inNumber);

                    configure_touchscreen_state.next_state = typeof (StateCalibrateTouchscreen);
                    if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                    {
                        configure_touchscreen_state.error_state = typeof (StateCheckPanel);
                    }
                    else if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        configure_touchscreen_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (configure_touchscreen_state);
                }

                // create calibrate touchscreen state
                if ((inCheckFlags & CheckFlags.TOUCHSCREEN) == CheckFlags.TOUCHSCREEN)
                {
                    var calibrate_touchscreen_state = new StateCalibrateTouchscreen (m_Peripherals, inNumber);

                    if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                    {
                        calibrate_touchscreen_state.next_state = typeof (StateCheckPanel);
                        calibrate_touchscreen_state.error_state = typeof (StateCheckPanel);
                    }
                    else if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        calibrate_touchscreen_state.next_state = typeof (StateCheckSSIDab);
                        calibrate_touchscreen_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (calibrate_touchscreen_state);
                }

                // create check panel state
                if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                {
                    var check_panel_state = new StateCheckPanel (m_Peripherals);

                    check_panel_state.next_state = typeof (StateCheckPanelFirmware);
                    if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        check_panel_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (check_panel_state);
                }

                // create check panel firmware state
                if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                {
                    var check_firmware_panel_state = new StateCheckPanelFirmware (m_Peripherals);

                    check_firmware_panel_state.next_state = typeof (StateConfigurePanel);

                    if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        check_firmware_panel_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (check_firmware_panel_state);
                }

                // create configure panel state
                if ((inCheckFlags & CheckFlags.PANEL) == CheckFlags.PANEL)
                {
                    var configure_panel_state = new StateConfigurePanel (m_Peripherals, inNumber);

                    if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                    {
                        configure_panel_state.next_state = typeof (StateCheckSSIDab);
                        configure_panel_state.error_state = typeof (StateCheckSSIDab);
                    }

                    add_state (configure_panel_state);
                }

                // create check ssidab state
                if ((inCheckFlags & CheckFlags.SSIDAB) == CheckFlags.SSIDAB)
                {
                    var check_ssidab_state = new StateCheckSSIDab (m_Peripherals);
                    add_state (check_ssidab_state);
                }
            }
        }

        protected override void
        on_run ()
        {
            start (typeof (StateServiceCheck));
        }
    }
}

