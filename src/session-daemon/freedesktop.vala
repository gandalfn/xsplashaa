/* session-daemon.vala
 *
 * Copyright (C) 2009-2010  Nicolas Bruguier
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

namespace FreeDesktop
{
    public enum DBusRequestNameReply
    {
        PRIMARY_OWNER = 1,
        IN_QUEUE,
        EXISTS,
        ALREADY_OWNER
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBusObject : GLib.Object
    {
        public abstract signal void name_owner_changed (string name, string old_owner, string new_owner);

        public abstract uint32
        request_name (string name, uint32 flags) throws DBus.Error;
    }

    public struct ConsoleKit.SessionParameter
    {
        // properties
        public string       key;
        public GLib.Value?  value ;

        public SessionParameter (string a, Value? b)
        {
            key = a;
            value = b;
        }
    }

    [DBus (name = "org.freedesktop.ConsoleKit.Session")]
    public interface ConsoleKit.Session : DBus.Object
    {
        public abstract void activate() throws DBus.Error;
    }

    [DBus (name = "org.freedesktop.ConsoleKit.Manager")]
    public interface ConsoleKit.Manager : DBus.Object
    {
        public abstract string
        open_session_with_parameters (ConsoleKit.SessionParameter[] inParameters) throws DBus.Error;

        public abstract bool
        close_session(string inCookie) throws DBus.Error;

        public abstract DBus.ObjectPath?
        get_session_for_cookie(string inCookie) throws DBus.Error;

        public abstract void
        restart() throws DBus.Error;

        public abstract void
        stop() throws DBus.Error;
    }
}

