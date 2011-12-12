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
        private unowned DBus.Connection               m_Connection;
        private SSI.Devices.Service                   m_Service;
        private SSI.Devices.Module.Touchscreen.Device m_Touchscreen = null;

        // accessors
        public bool service_available {
            get {
                return m_Service != null;
            }
        }

        public SSI.Devices.Module.Touchscreen.Device touchscreen {
            owned get {
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

        // methods
        /**
         * Create a new devices check
         */
        public Devices (DBus.Connection inConnection)
        {
            m_Connection = inConnection;

            try
            {
                // Try to get devices service
                m_Service = (SSI.Devices.Service)inConnection.get_object ("fr.supersonicimagine.Devices",
                                                                          "/fr/supersonicimagine/Devices/Service",
                                                                          "fr.supersonicimagine.Devices.Service");
            }
            catch (GLib.Error err)
            {
                Log.warning ("Error on get devices service: %s", err.message);
            }
        }
    }
}

