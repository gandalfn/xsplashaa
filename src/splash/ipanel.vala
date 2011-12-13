/* ipanel.vala
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

namespace SSI.Devices.Module.AlliedPanel
{
    [DBus (name = "fr.supersonicimagine.Devices.Module.AlliedPanel.DeviceManager")]
    public interface DeviceManager : DBus.Object
    {
        public abstract string panel { owned get; }
        public abstract string bootloader { owned get; }

        public signal void bootloader_changed ();
        public signal void panel_changed ();

        public abstract string get_bootloader_firmware_version () throws DBus.Error;
        public abstract string get_panel_firmware_version () throws DBus.Error;

        public abstract void start_bootloader () throws DBus.Error;
        public abstract void start_panel () throws DBus.Error;
    }

    [DBus (name = "fr.supersonicimagine.Devices.Module.AlliedPanel.Bootloader")]
    public interface Bootloader : DBus.Object
    {
        public abstract uint pci_vendor_id { get; }
        public abstract uint pci_product_id { get; }
        public abstract string version { owned get; }
        public abstract string serial { owned get; }

        public abstract int device_type { get; }
        public abstract int device_page_size { get; }
        public abstract int device_num_pages { get; }

        public abstract string bootloader_version { owned get; }
        public abstract string bootloader_serial { owned get; }
        public abstract bool bootloader_loaded { get; }
        public abstract string bootloader_filename { owned get; }
        public abstract string bootloader_file_version { owned get; }
        public abstract bool bootloader_need_upgrade { get; }
        public abstract string bootloader_statistics { owned get; }

        public abstract string firmware_version { owned get; }
        public abstract string firmware_serial { owned get; }
        public abstract bool firmware_loaded { get; }
        public abstract string firmware_filename { owned get; }
        public abstract string firmware_file_version { owned get; }
        public abstract bool firmware_need_upgrade { get; }
        public abstract string firmware_statistics { owned get; }

        public abstract string hardware_version { owned get; }
        public abstract string hardware_product_number { owned get; }
        public abstract string hardware_serial { owned get; }

        public signal void device_info_updated (uint inType, uint inPageSize, uint inNumPages);

        public signal void bootloader_file_changed ();
        public signal void bootloader_info_updated (uint32 inVersion, string inSerial);
        public signal void bootloader_flash_progress (uint inProgress);
        public signal void bootloader_flash_finished (bool inSuccess);

        public signal void firmware_file_changed ();
        public signal void firmware_info_updated (uint32 inVersion, string inSerial);
        public signal void firmware_flash_progress (uint inProgress);
        public signal void firmware_flash_finished (bool inSuccess);

        public signal void hardware_info_updated (uint32 inVersion, string inSerial);

        [DBus (no_reply = true)]
        public abstract void run () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void query_device_info () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void query_bootloader_info () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void query_firmware_info () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void query_hardware_info () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void set_hardware_info (int inVersion, string inProductNumber, string inSerial) throws DBus.Error;

        public abstract bool load_firmware (string inFilename) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void flash_firmware () throws DBus.Error;

        public abstract bool load_bootloader (string inFilename) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void flash_bootloader () throws DBus.Error;

        public abstract void load_default_firmwares () throws DBus.Error;
    }

    [DBus (name = "fr.supersonicimagine.Devices.Module.AlliedPanel.Panel")]
    public interface Panel : DBus.Object
    {
        public abstract uint pci_vendor_id { get; }
        public abstract uint pci_product_id { get; }
        public abstract string firmware_version { owned get; }
        public abstract string serial { owned get; }

        [DBus (timeout = 5000)]
        public abstract string default_profile { owned get; set; }
        [DBus (timeout = 5000)]
        public abstract string current_profile { owned get; set; }
        public abstract string[] profiles { owned get; }

        public abstract bool support_mouse_select { get; }
        public abstract bool mouse_select_active { get; set; }
        public abstract bool lights_active { get; set; }
        public abstract int brightness { get; set; }

        [DBus (no_reply = true, timeout = 5000)]
        public abstract void initialize () throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void set_light_active (int inLight, bool inState) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void set_light_brightness (int inLight, int inBrightness) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void reset () throws DBus.Error;
        public abstract bool create_profile (string inTemplate, string inName, string inDescription) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void remove_profile (string inName) throws DBus.Error;
    }

    [DBus (name = "fr.supersonicimagine.Devices.Module.AlliedPanel.Panel.Profile")]
    public interface PanelProfile : DBus.Object
    {
        public abstract string name { owned get; }
        public abstract string description { owned get; }
        public abstract bool deletable { get; }
        public abstract int[] lights { owned get; set; }

        [DBus (no_reply = true)]
        public abstract void add_brightness_delta (int inLight, int inDelta) throws DBus.Error;
        public abstract int get_brightness_delta (int inLight) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void remove_brightness_delta (int inLight) throws DBus.Error;
    }
}

