/* isession.vala
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

[DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")]
public interface XSAA.Session : DBus.Object
{
    public signal void died();
    public signal void exited();

    public signal void ask_passwd ();
    public signal void ask_face_authentication ();
    public signal void authenticated ();
    public signal void info (string inMsg);
    public signal void error_msg (string inMsg);

    public abstract void set_passwd(string inPass) throws DBus.Error;
    public abstract void authenticate() throws DBus.Error;
    public abstract void launch(string cmd) throws DBus.Error;
}

