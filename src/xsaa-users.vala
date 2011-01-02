/* xsaa-users.vala
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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public struct User
    {
        public string      login;
        public Posix.uid_t uid;
        public Posix.gid_t gid;
        public string      real_name;
        public string      home_dir;
        public string      shell;
        public string      face_icon_filename;
        public uint        frequency;

        public User (Posix.Passwd entry)
        {
            login    = entry.pw_name;
            uid      = entry.pw_uid;
            gid      = entry.pw_gid;
            home_dir = entry.pw_dir;
            shell    = entry.pw_shell;

            real_name = entry.pw_name;
            if (entry.pw_gecos != null)
            {
                real_name = entry.pw_gecos.split (",")[0];
                if (real_name == null || real_name[0] == '\0')
                {
                    real_name = entry.pw_name;
                }
            }

            face_icon_filename = entry.pw_dir + "/.face";
            if (!FileUtils.test(face_icon_filename, FileTest.EXISTS))
            {
                face_icon_filename = entry.pw_dir + "/.face.icon";
                if (!FileUtils.test(face_icon_filename, FileTest.EXISTS))
                {
                    face_icon_filename = null;
                }
            }

            frequency = 0;
        }

        public int
        compare (User other)
        {
            if (frequency > other.frequency)
                return -1;

            if (frequency < other.frequency)
                return 1;

            if (uid < other.uid)
                return -1;

            if (uid > other.uid)
                return 1;

            return GLib.strcmp (real_name, other.real_name);
        }
    }

    public class Users
    {
        private struct Node
        {
            public User val;
        }

        public class Iterator
        {
            private Users users;
            private int index;

            internal Iterator (Users users)
            {
                this.users = users;
                this.index = -1;
            }

            public bool
            next ()
            {
                bool ret = false;

                if (index == -1 && users.size > 0)
                {
                    index = 0;
                    ret = true;
                }
                else if (index < users.size)
                {
                    index++;
                    ret = index < users.size;
                }

                return ret;
            }

            public unowned User?
            get ()
                requires (index >= 0)
                requires (index < users.size)
            {
                return users.content[index].val;
            }
        }

        private int      size = 0;
        private int      reserved = 4;
        private Node*    content;
        private string   ignore_users = "nobody nobody4 noaccess";
        private string   ignore_shells = "/bin/false /usr/sbin/nologin";
        private int      minimum_uid = 1000;

        public Users ()
        {
            content = new Node [reserved];

            load_config ();

            Posix.setpwent ();
            while (true)
            {
                unowned Posix.Passwd? entry = Posix.getpwent ();
                if (entry == null)
                    break;

                User user = User (entry);

                if (user.uid < minimum_uid)
                    continue;

                if (user.shell != null)
                {
                    bool found = false;
                    foreach (string shell in ignore_shells.split (" "))
                    {
                        if (shell == user.shell)
                        {
                            found = true;
                            break;
                        }
                    }
                    if (found) continue;
                }

                bool found = false;
                foreach (string hidden in ignore_users.split (" "))
                {
                    if (hidden == user.login)
                    {
                        found = true;
                        break;
                    }
                }
                if (found) continue;

                add (user);
            }
            Posix.endpwent ();
        }

        private void
        load_config()
        {
            GLib.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

            if (FileUtils.test(Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    minimum_uid = config.get_integer ("users", "minimum-uid");
                    ignore_users = config.get_string ("users", "hidden-users");
                    ignore_shells = config.get_string ("users", "hidden-shells");
                }
                catch (GLib.Error err)
                {
                    GLib.warning ("error on read %s: %s",
                                  Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                GLib.warning ("unable to found %s", Config.PACKAGE_CONFIG_FILE);
            }
        }

        private int
        get_nearest_user (User user)
        {
            int ret = size;
            int left = 0, right = size - 1;

            if (right != -1)
            {
                while (right >= left)
                {
                    int medium = (left + right) / 2;
                    int res = content[medium].val.compare (user);

                    if (res == 0)
                    {
                        while (medium < size && content[medium].val.compare (user) == 0)
                            medium++;
                        return medium;
                    }
                    else if (res > 0)
                    {
                        right = medium - 1;
                    }
                    else
                    {
                        left = medium + 1;
                    }

                    ret = (int)Posix.ceil((double)(left + right) / 2);
                }
            }

            return ret;
        }

        private void
        grow ()
        {
            if (size > reserved)
            {
                int oldReserved = reserved;
                reserved = 2 * reserved;
                content = GLib.realloc (content, reserved * sizeof (Node));
                GLib.Memory.set (&content[oldReserved], 0, oldReserved * sizeof (Node));
            }
        }

        private void
        add (User user)
        {
            GLib.debug ("add user %s", user.login);

            int pos = get_nearest_user (user);

            size++;
            grow ();

            if (pos < size - 1)
                GLib.Memory.move (&content[pos + 1], &content[pos],
                                  (size - pos - 1) * sizeof (Node));

            content[pos].val = user;
        }

        public unowned User?
        get (string login)
        {
            foreach (unowned User user in this)
            {
                if (user.login == login)
                    return user;
            }

            return null;
        }

        public Iterator
        iterator ()
        {
            return new Iterator (this);
        }
    }
}
