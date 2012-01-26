/* state-check-panel.vala
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
     * Check panel state machine
     */
    public class StateCheckPanel : StateMachine
    {
        // constants
        const int WAIT_PANEL = 20;

        // properties
        private unowned Devices m_Peripherals;
        private uint            m_IdTimeout;

        /**
         * Create a new check panel state machine
         *
         * @param inPeripherals peripherals devices
         */
        public StateCheckPanel (Devices inPeripherals)
        {
            m_Peripherals = inPeripherals;
        }

        private void
        on_panel_changed ()
        {
            if (m_IdTimeout != 0)
            {
                string panel = m_Peripherals.allied_panel.panel;

                m_Peripherals.allied_panel.panel_changed.disconnect (on_panel_changed);
                if (panel != null && panel.length > 0)
                {
                    base.on_run ();
                    GLib.Source.remove (m_IdTimeout);
                    m_IdTimeout = 0;
                }
            }
        }

        private bool
        on_timeout ()
        {
            if (m_IdTimeout != 0)
            {
                string panel = m_Peripherals.allied_panel.panel;

                m_Peripherals.allied_panel.panel_changed.disconnect (on_panel_changed);
                if (panel == null || panel.length == 0)
                    error ("Unable to find Allied Panel device");
                else
                    base.on_run ();
                m_IdTimeout = 0;
            }

            return false;
        }

        protected override void
        on_run ()
        {
            try
            {
                if (m_Peripherals.allied_panel == null)
                {
                    error ("Unable to find Allied Panel device");
                }
                else
                {
                    string panel = m_Peripherals.allied_panel.panel;
                    string bootloader = m_Peripherals.allied_panel.bootloader;

                    // panel not found
                    if (panel == null || panel.length == 0)
                    {
                        // check if bootloader is here
                        if (bootloader == null || bootloader.length == 0)
                        {
                            error ("Unable to find Allied Panel device");
                        }
                        // we found bootloader switch on panel
                        else
                        {
                            message ("Waiting for panel...");
                            m_Peripherals.allied_panel.panel_changed.connect (on_panel_changed);
                            m_Peripherals.allied_panel.start_panel ();
                            m_IdTimeout = GLib.Timeout.add_seconds (WAIT_PANEL, on_timeout);
                        }
                    }
                    else
                    {
                        base.on_run ();
                    }
                }
            }
            catch (GLib.Error err)
            {
                error ("Unable to find Allied Panel device");
            }
        }
    }
}

