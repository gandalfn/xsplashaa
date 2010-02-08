/* xsaa-input-device.vala
 *
 * Copyright (C) 2009  Nicolas Bruguier
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

using GUdev;
using Gee;

namespace XSAA
{
    internal struct Tuple
    {
        string key;
        string val;
    }
    
    public class InputDevice : Object
    {
        int display_num = 0;
        const string[] subsystems = { "input", null };
        GUdev.Client client = null;
        DBus.Connection conn = null;
        Gee.HashMap<string, uint32> devices;

        public signal void keyboard_added ();
        
        public InputDevice (DBus.Connection conn, int display)
        {
            this.devices = new Gee.HashMap<string, uint32> ();
            this.display_num = display;
            this.conn = conn; 
            this.client = new GUdev.Client (subsystems);
        }

        private void
        on_device_added (GUdev.Device device)
        {
            string dev_name = device.get_device_file();
            string name = device.get_sysfs_attr ("device/name");
            string model = device.get_property("ID_MODEL");
            var message = new DBus.RawMessage.call ("org.x.config.display" + 
                                                    display_num.to_string (), 
                                                    "/org/x/config/" + 
                                                    display_num.to_string (),
                                                    "org.x.config",
                                                    "add");

            DBus.RawMessageIter iter = DBus.RawMessageIter ();
            DBus.RawMessageIter iterChild = DBus.RawMessageIter (); 
            GLib.List<Tuple?> list = new GLib.List<Tuple?> ();

            message.set_no_reply (false);
            message.init_append(iter);

            if (iter.open_container (DBus.RawType.ARRAY, "s", iterChild))
            {
                Tuple t = Tuple ();
                t.key = "identifier";
                t.val = name != null ? name : 
                        (model != null ? model : "generic");
                list.prepend(t);
                iterChild.append_basic (DBus.RawType.STRING, 
                                        &list.nth_data(0).key);
                iterChild.append_basic (DBus.RawType.STRING, 
                                        &list.nth_data(0).val);
                iter.close_container(iterChild);
            }
            if (iter.open_container (DBus.RawType.ARRAY, "s", iterChild))
            {
                Tuple t = Tuple ();
                t.key = "device";
                t.val = dev_name;
                list.prepend(t);
                iterChild.append_basic (DBus.RawType.STRING, 
                                        &list.nth_data(0).key);
                iterChild.append_basic (DBus.RawType.STRING, 
                                        &list.nth_data(0).val);
                iter.close_container(iterChild);
            }
            foreach (string key in device.get_property_keys())
            {
                if (key == "x11_driver")
                {                    
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = "driver";
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
                else if (key == "XKBLAYOUT")
                {                    
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = "xkb_layout";
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
                else if (key == "XKBMODEL")
                {                    
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = "xkb_model";
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
                else if (key == "XKBVARIANT")
                {                    
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = "xkb_variant";
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
                else if (key == "XKBOPTIONS")
                {                    
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = "xkb_options";
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
                else if ("x11_options." in key)
                {
                    if (iter.open_container (DBus.RawType.ARRAY, "s", 
                                             iterChild))
                    {
                        Tuple t = Tuple ();
                        t.key = key.offset("x11_options.".len ());
                        t.val = device.get_property(key);
                        list.prepend(t);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).key);
                        iterChild.append_basic (DBus.RawType.STRING, 
                                                &list.nth_data(0).val);
                        iter.close_container(iterChild);
                    }
                }
            }
            DBus.RawError err = DBus.RawError ();
            var reply = conn.get_connection().send_with_reply_and_block(message, 
                                                                        -1, 
                                                                        ref err);
            if (err.is_set())
            {
                GLib.stderr.printf("%s\n", err.message);
            }
            reply.iter_init(iter);
            if (iter.get_arg_type () == DBus.RawType.INT32)
            {
                int32 v = 0;
                iter.get_basic (&v);
                if (v > 0)
                {
                    devices.set (dev_name, v);
                    if (device.get_property ("ID_INPUT_KEYBOARD") != null)
                        keyboard_added ();
                }
            }
        }
        
        private void
        on_device_removed (GUdev.Device device)
        {
            string dev_name = device.get_device_file();

            if (devices.contains(dev_name))
            {
                var message = new DBus.RawMessage.call ("org.x.config.display" + 
                                                        display_num.to_string (), 
                                                        "/org/x/config/" + 
                                                        display_num.to_string (),
                                                        "org.x.config",
                                                        "remove");
                message.set_no_reply (false);
                DBus.RawMessageIter iter = DBus.RawMessageIter ();
                message.init_append(iter);
                uint32 v = devices[dev_name];
                iter.append_basic (DBus.RawType.UINT32, &v);
                DBus.RawError err = DBus.RawError ();
                var reply = conn.get_connection().send_with_reply_and_block(message, -1, ref err);
                if (err.is_set())
                {
                    GLib.stderr.printf("%s\n", err.message);       
                }
                reply.iter_init(iter);
                if (iter.get_arg_type () == DBus.RawType.INT32)
                {
                    int32 r = 0;
                    iter.get_basic (&r);
                    if (r == 0)
                    {
                        devices.unset (dev_name);
                    }
                }
            }
        }

        private void
        on_udev_event (string event, GUdev.Device device)
        {
            string x11_driver = device.get_property("x11_driver");
            string dev_name = device.get_device_file();
            
            if (x11_driver != null && "event" in dev_name)
            {
                if (event == "add")
                    on_device_added (device);
                else if (event == "remove")
                    on_device_removed (device);
            }
        }

        public void
        start ()
        {
            this.client.uevent.connect (on_udev_event);
            
            foreach (Device device in this.client.query_by_subsystem ("input"))
            {
                on_udev_event("add", device);
            }
        }
    }
}
