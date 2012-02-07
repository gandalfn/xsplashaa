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
        private SSI.Devices.Module.Touchscreen.DeviceManager m_TouchscreenManager = null;
        private SSI.Devices.Module.Touchscreen.Device        m_Touchscreen = null;
        private SSI.Devices.Module.AlliedPanel.DeviceManager m_AlliedPanel = null;
        private SSI.Devices.Module.AlliedPanel.Panel         m_Panel = null;
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
                        Log.debug ("touchscreen path %s", path != null ? path : "null");
                        if (path != null && path.length > 0)
                        {
                            if (m_TouchscreenManager == null)
                            {
                                m_TouchscreenManager = (SSI.Devices.Module.Touchscreen.DeviceManager)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                                              "/fr/supersonicimagine/Devices/Module/Touchscreen/DeviceManager",
                                                                                                                              "fr.supersonicimagine.Devices.Module.Touchscreen.DeviceManager");
                            }
                            if (m_TouchscreenManager != null)
                            {
                                string[] devices = m_TouchscreenManager.get_device_list ();
                                Log.debug ("touchscreen nb devices %i", devices.length);
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

        public SSI.Devices.Module.AlliedPanel.Panel allied_panel_panel {
            get {
                if (m_AlliedPanel != null && m_Panel == null)
                {
                    string path = m_AlliedPanel.panel;
                    if (path != null && path.length > 0)
                    {
                        m_AlliedPanel.panel_changed.connect (() => { m_Panel = null; });
                        m_Panel = (SSI.Devices.Module.AlliedPanel.Panel)m_Connection.get_object ("fr.supersonicimagine.Devices",
                                                                                                 path,
                                                                                                 "fr.supersonicimagine.Devices.Module.AlliedPanel.Panel");
                    }
                }

                return m_Panel;
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

        private bool
        configure_select_button (int inNumber)
        {
            bool ret = false;

            var panel = allied_panel_panel;

            // panel not found
            if (panel == null)
            {
                Log.warning ("Unable to find Allied Panel device");
            }
            else
            {
                unowned Gdk.Display? display = Gdk.Display.open (":" + inNumber.to_string ());
                if (!panel.support_mouse_select || !panel.mouse_select_active)
                {
                    Log.info ("Configure select button has mouse key");
                    X.kb_change_enabled_controls (Gdk.x11_display_get_xdisplay (display), X.KbUseCoreKbd,
                                                  X.KbMouseKeysMask | X.KbMouseKeysAccelMask, X.KbMouseKeysMask | X.KbMouseKeysAccelMask);
                }
                else
                {
                    Log.info ("Configure select button has real mouse button");
                    X.kb_change_enabled_controls (Gdk.x11_display_get_xdisplay (display), X.KbUseCoreKbd,
                                                  X.KbMouseKeysMask | X.KbMouseKeysAccelMask, 0);
                }
                ret = true;
            }

            return ret;
        }

        private bool
        configure_virtual_pointer (int inNumber)
        {
            bool ret = false;

            // Open display for touchscreen
            try
            {
                var ts = touchscreen;

                if (ts != null && ts.open_display (":" + inNumber.to_string ()) == inNumber)
                {
                    // Create virtual pointer for display
                    if (!ts.create_virtual_pointer (":" + inNumber.to_string ()))
                    {
                        Log.warning ("Error on configure touchscreen for display %i !!", inNumber);
                    }
                    else
                    {
                        Log.info ("Touchscreen configured for %i", inNumber);
                        ret = true;
                    }
                }
                else
                {
                    Log.error ("Error on configure touchscreen for display %i !!", inNumber);
                }
            }
            catch (GLib.Error err)
            {
                Log.error ("Error on configure touchscreen for display %i: %s", inNumber, err.message);
            }

            return ret;
        }

        /**
         * Configure panel and keep configuration elsewhere it is deconnected and reconnected
         *
         * @param inNumber display number
         *
         * @return ``true`` on success
         */
        public bool
        setup_panel (int inNumber)
        {
            bool ret = configure_select_button (inNumber);

            if (ret)
            {
                m_AlliedPanel.panel_changed.connect (() => {
                    Log.info ("Panel has changed");
                    m_Panel = null;
                    m_Bootloader = null;
                    configure_select_button (inNumber);
                });
                m_AlliedPanel.bootloader_changed.connect (() => {
                    Log.info ("Bootloader has changed");
                    m_Panel = null;
                    m_Bootloader = null;
                    configure_select_button (inNumber);
                });
            }

            return ret;
        }

        /**
         * Configure touchscreen and keep configuration elsewhere it is deconnected and reconnected
         *
         * @param inNumber display number
         *
         * @return ``true`` on success
         */
        public bool
        setup_touchscreen (int inNumber)
        {
            bool ret = configure_virtual_pointer (inNumber);

            if (ret)
            {
                m_TouchscreenManager.touchscreen_added.connect (() => {
                    Log.info ("Touchscreen has been added");
                    GLib.Timeout.add_seconds (1, () => {
                        configure_virtual_pointer (inNumber);
                        return false;
                    });
                });
                m_TouchscreenManager.touchscreen_removed.connect (() => {
                    Log.info ("Touchscreen has been removed");
                    m_Touchscreen = null;
                });
            }

            return ret;
        }
    }
}

