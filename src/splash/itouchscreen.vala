/* itouchscreen.vala
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

namespace SSI.Devices.Module.Touchscreen
{
    [DBus (name = "fr.supersonicimagine.Devices.Module.Touchscreen.DeviceManager")]
    public interface DeviceManager : DBus.Object
    {
        public signal void touchscreen_added ();
        public signal void touchscreen_removed ();

        public abstract string[] get_device_list () throws DBus.Error;
    }

    [DBus (name = "fr.supersonicimagine.Devices.Module.Touchscreen.Device")]
    public interface Device : DBus.Object
    {
        public abstract uint pci_vendor_id { get; }
        public abstract uint pci_product_id { get; }

        public signal void calibration_finished ();

        public abstract int open_display (string inDisplay) throws DBus.Error;
        [DBus (no_reply = true)]
        public abstract void close_display (string inDisplay) throws DBus.Error;

        public abstract bool have_virtual_pointer (string inDisplay) throws DBus.Error;
        public abstract bool create_virtual_pointer (string inDisplay) throws DBus.Error;
        public abstract bool remove_virtual_pointer (string inDisplay) throws DBus.Error;

        [DBus (no_reply = true)]
        public abstract void calibrate (string inDisplay) throws DBus.Error;

        public abstract int get_screen_number (string inDisplay) throws DBus.Error;

        public abstract bool[] get_axis_inversion (string inDisplay) throws DBus.Error;
        public abstract bool set_axis_inversion (string inDisplay, bool[] inAxis) throws DBus.Error;

        public abstract bool get_axes_swap (string inDisplay) throws DBus.Error;
        public abstract bool set_axes_swap (string inDisplay, bool inAxesSwap) throws DBus.Error;

        public abstract bool get_rotation (string inDisplay) throws DBus.Error;
        public abstract bool set_rotation (string inDisplay, bool inRotation) throws DBus.Error;

        public abstract int[] get_pan_viewport (string inDisplay) throws DBus.Error;
        public abstract bool set_pan_viewport (string inDisplay, int[] inPanViewport) throws DBus.Error;

        public abstract bool need_calibration (string inDisplay) throws DBus.Error;

        public abstract int[] get_axis_calibration (string inDisplay) throws DBus.Error;
        public abstract bool set_axis_calibration (string inDisplay, int[] inAxisCalibration) throws DBus.Error;

        public abstract int[] get_axis_diff_calibration (string inDisplay) throws DBus.Error;
        public abstract bool set_axis_diff_calibration (string inDisplay, int[] inAxisDiffCalibration) throws DBus.Error;

        public abstract int get_tap_timeout (string inDisplay) throws DBus.Error;
        public abstract bool set_tap_timeout (string inDisplay, int inTapTimeout) throws DBus.Error;

        public abstract int get_long_touch_timeout (string inDisplay) throws DBus.Error;
        public abstract bool set_long_touch_timeout (string inDisplay, int inLongTouchTimeout) throws DBus.Error;

        public abstract int get_move_limit (string inDisplay) throws DBus.Error;
        public abstract bool set_move_limit (string inDisplay, int inMoveLimit) throws DBus.Error;

        public abstract string[] get_display_list () throws DBus.Error;
    }
}

