/* iservice.vala
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

namespace SSI.Devices
{
    [DBus (name = "fr.supersonicimagine.Devices.Service")]
    public interface Service : DBus.Object
    {
        public enum MessageType
        {
            ERROR,
            CRITICAL,
            WARNING,
            INFO,
            DEBUG
        }

        public signal void message (MessageType inType, string inMessage);
        public abstract string[] get_module_list () throws DBus.Error;
        public abstract string get_module_description (string inName) throws DBus.Error;
        public abstract string get_module_dbus_object (string inName) throws DBus.Error;
    }
}

