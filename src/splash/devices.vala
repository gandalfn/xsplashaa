/* devices.vala
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
     * Devices check class
     */
    public class Devices : GLib.Object
    {
        // properties
        private unowned DBus.Connection                      m_Connection;
        private SSI.Devices.Service                          m_Service;
        private SSI.Devices.Module.Touchscreen.Device        m_Touchscreen = null;
        private SSI.Devices.Module.AlliedPanel.DeviceManager m_AlliedPanel = null;
        private SSI.Devices.Module.AlliedPanel.Bootloader    m_Bootloader = null;
        private SSI.Devices.Module.SSIDab.DeviceManager      m_SSIDab = null;

        // accessors
        public bool service_available {
            get {
                return m_Service != null;
            }
        }

        public SSI.Devices.Module.Touchscreen.Device touchscreen {
            get {
                if (m_Touchscreen == null && m_Service != null)
                {
                    try
                    {
                        string path = m_Service.get_module_dbus_object ("Touchscreen");
                        if (path != null && path.length > 0)
                        {
                            SSI.Devices.Module.Touchscreen.DeviceManager device_manager =
                                        (SSI.Devices.Module.Touchscreen.DeviceManager)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                               "/fr/supersonicimagine/Devices/Module/Touchscreen/DeviceManager",
                                                                                                               "fr.supersonicimagine.Devices.Module.Touchscreen.DeviceManager");
                            if (device_manager != null)
                            {
                                string[] devices = device_manager.get_device_list ();
                                if (devices.length > 0)
                                {
                                    m_Touchscreen = (SSI.Devices.Module.Touchscreen.Device)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                                    devices[0],
                                                                                                                    "fr.supersonicimagine.Devices.Module.Touchscreen.Device");
                                }
                            }
                        }
                    }
                    catch (GLib.Error err)
                    {
                        Log.critical ("Error on get touchscreen: %s", err.message);
                    }
                }

                return m_Touchscreen;
            }
        }

        public SSI.Devices.Module.AlliedPanel.DeviceManager allied_panel {
            get {
                if (m_AlliedPanel == null && m_Service != null)
                {
                    try
                    {
                        string path = m_Service.get_module_dbus_object ("AlliedPanel");
                        if (path != null && path.length > 0)
                        {
                            m_AlliedPanel = (SSI.Devices.Module.AlliedPanel.DeviceManager)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                                   "/fr/supersonicimagine/Devices/Module/AlliedPanel/DeviceManager",
                                                                                                                   "fr.supersonicimagine.Devices.Module.AlliedPanel.DeviceManager");
                        }
                    }
                    catch (GLib.Error err)
                    {
                        Log.critical ("Error on get allied panel: %s", err.message);
                    }
                }

                return m_AlliedPanel;
            }
        }

        public SSI.Devices.Module.AlliedPanel.Bootloader allied_panel_bootloader {
            get {
                if (m_AlliedPanel != null && m_Bootloader == null)
                {
                    string path = m_AlliedPanel.bootloader;
                    if (path != null && path.length > 0)
                    {
                        m_AlliedPanel.bootloader_changed.connect (() => { m_Bootloader = null; });
                        m_Bootloader = (SSI.Devices.Module.AlliedPanel.Bootloader)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                           path,
                                                                                                           "fr.supersonicimagine.Devices.Module.AlliedPanel.Bootloader");
                    }
                }

                return m_Bootloader;
            }
        }

        public SSI.Devices.Module.SSIDab.DeviceManager ssidab {
            get {
                if (m_SSIDab == null && m_Service != null)
                {
                    try
                    {
                        string path = m_Service.get_module_dbus_object ("SSIDab");
                        if (path != null && path.length > 0)
                        {
                            m_SSIDab = (SSI.Devices.Module.SSIDab.DeviceManager)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                         "/fr/supersonicimagine/Devices/Module/SSIDab/DeviceManager",
                                                                                                         "fr.supersonicimagine.Devices.Module.SSIDab.DeviceManager");
                        }
                    }
                    catch (GLib.Error err)
                    {
                        Log.critical ("Error on get ssidab: %s", err.message);
                    }
                }

                return m_SSIDab;
            }
        }

        // methods
        /**
         * Create a new devices check
         */
        public Devices (DBus.Connection inConnection)
        {
            m_Connection = inConnection;

            // Try to get devices service
            m_Service = (SSI.Devices.Service)inConnection.get_object ("fr.supersonicimagine.Devices",
                                                                      "/fr/supersonicimagine/Devices/Service",
                                                                      "fr.supersonicimagine.Devices.Service");
        }
    }
}

