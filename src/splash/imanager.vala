/* imanager.vala
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

[DBus (name = "fr.supersonicimagine.XSAA.Manager")]
public interface XSAA.Manager : DBus.Object
{
    public abstract bool open_session (string inUser, int inDisplay, string inDevice,
                                       bool inFaceAuthentication, bool inAutologin,
                                       out DBus.ObjectPath? inPath) throws DBus.Error;
    public abstract void close_session(DBus.ObjectPath inPath) throws DBus.Error;
    public abstract void reboot() throws DBus.Error;
    public abstract void halt() throws DBus.Error;
    public abstract int get_nb_users () throws DBus.Error;
}

