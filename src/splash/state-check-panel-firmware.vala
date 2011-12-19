/* state-check-panel-firmware.vala
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
     * Check panel firmware state machine
     */
    public class StateCheckPanelFirmware : StateMachine
    {
        // types
        public enum WaitResponseType
        {
            NONE,
            FLASH_BOOTLOADER,
            FLASH_FIRMWARE
        }

        public enum FlashResponse
        {
            NONE,
            YES,
            NO
        }

        // constants
        const int WAIT_BOOTLOADER = 60;
        const int WAIT_PANEL = 90;

        // properties
        private unowned Devices  m_Peripherals;
        private uint             m_IdBootloaderTimeout;
        private uint             m_IdPanelTimeout;
        private WaitResponseType m_WaitResponse = WaitResponseType.NONE;
        private FlashResponse    m_BootFlashResponse = FlashResponse.NONE;
        private FlashResponse    m_FirmwareFlashResponse = FlashResponse.NONE;

        /**
         * Create a new check panel firmware state machine
         *
         * @param inPeripherals peripherals devices
         */
        public StateCheckPanelFirmware (Devices inPeripherals)
        {
            m_Peripherals = inPeripherals;
        }

        private void
        on_bootloader_flash_progress (uint inProgress)
        {
            progress ((int)inProgress);
        }

        private void
        on_bootloader_flash_finished ()
        {
            SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;

            bootloader.bootloader_flash_progress.disconnect (on_bootloader_flash_progress);
            bootloader.bootloader_flash_finished.disconnect (on_bootloader_flash_finished);

            // wait on panel connection
            m_Peripherals.allied_panel.panel_changed.connect (on_panel_changed_after_bootloader_flash);
            m_IdPanelTimeout = GLib.Timeout.add_seconds (WAIT_PANEL, on_wait_panel_timeout);
        }

        private void
        on_panel_flash_progress (uint inProgress)
        {
            progress ((int)inProgress);
        }

        private void
        on_panel_flash_finished ()
        {
            SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;

            bootloader.firmware_flash_progress.disconnect (on_panel_flash_progress);
            bootloader.firmware_flash_finished.disconnect (on_panel_flash_finished);

            try
            {
                message ("Restart panel...");
                // start panel
                m_Peripherals.allied_panel.start_panel ();

                // wait on panel connection
                m_Peripherals.allied_panel.panel_changed.connect (on_panel_changed_after_panel_flash);
                m_IdPanelTimeout = GLib.Timeout.add_seconds (WAIT_PANEL, on_wait_panel_timeout);
            }
            catch (GLib.Error err)
            {
                error ("Error on flash panel");
            }
        }

        private void
        check_bootloader_firmware ()
        {
            SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;
            if (bootloader != null && bootloader.bootloader_need_upgrade && bootloader.bootloader_filename != "N/A" && m_BootFlashResponse == FlashResponse.NONE)
            {
                if (m_WaitResponse == WaitResponseType.NONE)
                {
                    m_WaitResponse = WaitResponseType.FLASH_BOOTLOADER;
                    question ("Your panel currently running\nwith bootloader %s version\nA newer %s version is available\nDo you want flash it ?".printf (bootloader.bootloader_version, bootloader.bootloader_file_version));
                }
            }
            else
            {
                check_panel_firmware ();
            }
        }

        private void
        check_panel_firmware ()
        {
            try
            {
                SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;
                if (bootloader != null && bootloader.firmware_need_upgrade && bootloader.firmware_filename != "N/A" && m_FirmwareFlashResponse == FlashResponse.NONE)
                {
                    if (m_WaitResponse == WaitResponseType.NONE)
                    {
                        m_WaitResponse = WaitResponseType.FLASH_FIRMWARE;
                        question ("Your panel currently running\nwith firmware %s version\nA newer %s version is available\nDo you want flash it ?".printf (bootloader.firmware_version, bootloader.firmware_file_version));
                    }
                }
                else
                {
                    message ("Wait for panel...");

                    // start panel
                    m_Peripherals.allied_panel.start_panel ();

                    // wait on panel connection
                    m_Peripherals.allied_panel.panel_changed.connect (on_panel_changed_after_panel_flash);
                    m_IdPanelTimeout = GLib.Timeout.add_seconds (WAIT_PANEL, on_wait_panel_timeout);
                }
            }
            catch (GLib.Error err)
            {
                error ("Error on check panel firmware version");
            }
        }

        private void
        on_bootloader_changed ()
        {
            if (m_IdBootloaderTimeout != 0)
            {
                string bootloader = m_Peripherals.allied_panel.bootloader;

                m_Peripherals.allied_panel.bootloader_changed.disconnect (on_bootloader_changed);
                if (bootloader != null && bootloader.length > 0)
                {
                    check_bootloader_firmware ();
                    GLib.Source.remove (m_IdBootloaderTimeout);
                    m_IdBootloaderTimeout = 0;
                }
            }
        }

        private void
        on_panel_changed_after_bootloader_flash ()
        {
            if (m_IdPanelTimeout != 0)
            {
                try
                {
                    string panel = m_Peripherals.allied_panel.panel;

                    m_Peripherals.allied_panel.bootloader_changed.disconnect (on_panel_changed_after_bootloader_flash);
                    if (panel != null && panel.length > 0)
                    {
                        m_Peripherals.allied_panel.bootloader_changed.connect (on_bootloader_changed);
                        m_IdBootloaderTimeout = GLib.Timeout.add_seconds (WAIT_BOOTLOADER, on_wait_bootloader_timeout);
                        m_Peripherals.allied_panel.start_bootloader ();
                        GLib.Source.remove (m_IdPanelTimeout);
                        m_IdPanelTimeout = 0;
                    }
                }
                catch (GLib.Error err)
                {
                    GLib.Source.remove (m_IdPanelTimeout);
                    m_IdPanelTimeout = 0;
                    error ("Error on flash bootloader");
                }
            }
        }

        private void
        on_panel_changed_after_panel_flash ()
        {
            if (m_IdPanelTimeout != 0)
            {
                string panel = m_Peripherals.allied_panel.panel;

                m_Peripherals.allied_panel.panel_changed.disconnect (on_panel_changed_after_panel_flash);
                if (panel != null && panel.length > 0)
                {
                    base.on_run ();
                    GLib.Source.remove (m_IdPanelTimeout);
                    m_IdPanelTimeout = 0;
                }
            }
        }

        private bool
        on_wait_bootloader_timeout ()
        {
            if (m_IdBootloaderTimeout != 0)
            {
                string bootloader = m_Peripherals.allied_panel.bootloader;

                m_Peripherals.allied_panel.bootloader_changed.disconnect (on_bootloader_changed);
                if (bootloader == null || bootloader.length == 0)
                    error ("Unable to check Allied Panel firmware version");
                m_IdBootloaderTimeout = 0;
            }

            return false;
        }

        private bool
        on_wait_panel_timeout ()
        {
            if (m_IdPanelTimeout != 0)
            {
                string panel = m_Peripherals.allied_panel.panel;

                m_Peripherals.allied_panel.panel_changed.disconnect (on_panel_changed_after_bootloader_flash);
                m_Peripherals.allied_panel.panel_changed.disconnect (on_panel_changed_after_panel_flash);
                if (panel == null || panel.length == 0)
                    error ("Unable to check Allied Panel firmware version");
                m_IdPanelTimeout = 0;
            }

            return false;
        }

        protected override void
        on_run ()
        {
            try
            {
                // Get bootloader firmware
                string bootloader_firmware = m_Peripherals.allied_panel.get_bootloader_firmware_version ();

                // If bootloader version is not set
                if (bootloader_firmware == null || bootloader_firmware.length == 0)
                {
                    message ("Starting bootloader...");
                    m_Peripherals.allied_panel.bootloader_changed.connect (on_bootloader_changed);
                    m_Peripherals.allied_panel.start_bootloader ();
                    m_IdBootloaderTimeout = GLib.Timeout.add_seconds (WAIT_BOOTLOADER, on_wait_bootloader_timeout);
                }
                else
                {
                    base.on_run ();
                }
            }
            catch (GLib.Error err)
            {
                error ("Error on check panel firmware");
            }
        }

        internal override void
        question_response (bool inResponse)
        {
            switch (m_WaitResponse)
            {
                case WaitResponseType.FLASH_BOOTLOADER:
                    try
                    {
                        SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;
                        if (inResponse)
                        {
                            m_BootFlashResponse = FlashResponse.YES;

                            bootloader.load_bootloader (bootloader.bootloader_filename);
                            if (bootloader.bootloader_loaded)
                            {
                                message ("Flashing bootloader, please wait...");
                                bootloader.bootloader_flash_progress.connect (on_bootloader_flash_progress);
                                bootloader.bootloader_flash_finished.connect (on_bootloader_flash_finished);

                                bootloader.flash_bootloader ();
                            }
                            else
                            {
                                error ("Error on check bootloader firmware version");
                            }
                        }
                        else
                        {
                            m_BootFlashResponse = FlashResponse.NO;
                            check_panel_firmware ();
                        }
                    }
                    catch (GLib.Error err)
                    {
                        error ("Error on check bootloader firmware version");
                    }
                    break;

                case WaitResponseType.FLASH_FIRMWARE:
                    try
                    {
                        SSI.Devices.Module.AlliedPanel.Bootloader bootloader = m_Peripherals.allied_panel_bootloader;
                        if (inResponse)
                        {
                            m_FirmwareFlashResponse = FlashResponse.YES;
                            bootloader.load_firmware (bootloader.firmware_filename);
                            if (bootloader.firmware_loaded)
                            {
                                message ("Flashing panel, please wait...");
                                bootloader.firmware_flash_progress.connect (on_panel_flash_progress);
                                bootloader.firmware_flash_finished.connect (on_panel_flash_finished);

                                bootloader.flash_firmware ();
                            }
                            else
                            {
                                error ("Error on check bootloader firmware version");
                            }
                        }
                        else
                        {
                            m_FirmwareFlashResponse = FlashResponse.NO;

                            message ("Wait for panel...");

                            // start panel
                            m_Peripherals.allied_panel.start_panel ();

                            // wait on panel connection
                            m_Peripherals.allied_panel.panel_changed.connect (on_panel_changed_after_panel_flash);
                            m_IdPanelTimeout = GLib.Timeout.add_seconds (WAIT_PANEL, on_wait_panel_timeout);
                        }
                    }
                    catch (GLib.Error err)
                    {
                        error ("Error on check bootloader firmware version");
                    }
                    break;
            }

            m_WaitResponse = WaitResponseType.NONE;
        }
    }
}

