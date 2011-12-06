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
    const int ICON_SIZE = 90;

    [DBus (name = "fr.supersonicimagine.XSAA.Manager.User")]
    public class User : GLib.Object
    {
        // properties
        private string          m_Login;
        private string          m_RealName;
        private string          m_FaceIconFilename;
        private Os.key_t        m_FaceIconShmKey;
        private int             m_FaceIconShmId;
        private unowned uchar[] m_FaceIconPixels;
        public uint             m_Frequency;

        public Os.uid_t         uid;
        public Os.gid_t         gid;
        public string           home_dir;
        public string           shell;

        // accessors
        public string login {
            get {
                return m_Login;
            }
        }

        public string real_name {
            get {
                return m_RealName;
            }
        }

        public uint frequency {
            get {
                return (int)m_Frequency;
            }
        }

        public int face_icon_shm_id {
            get {
                return m_FaceIconShmId;
            }
        }

        // methods
        public User (Os.Passwd inEntry)
        {
            m_Login  = inEntry.pw_name;
            uid      = inEntry.pw_uid;
            gid      = inEntry.pw_gid;
            home_dir = inEntry.pw_dir;
            shell    = inEntry.pw_shell;

            m_RealName = inEntry.pw_name;
            if (inEntry.pw_gecos != null)
            {
                m_RealName = inEntry.pw_gecos.split (",")[0];
                if (m_RealName == null || m_RealName[0] == '\0')
                {
                    m_RealName = inEntry.pw_name;
                }
            }

            m_FaceIconFilename = inEntry.pw_dir + "/.face";
            if (!FileUtils.test(m_FaceIconFilename, FileTest.EXISTS))
            {
                m_FaceIconFilename = inEntry.pw_dir + "/.face.icon";
                if (!FileUtils.test(m_FaceIconFilename, FileTest.EXISTS))
                {
                    m_FaceIconFilename = null;
                }
            }

            create_face_icon_shm ();

            m_Frequency = 0;
        }

        ~User ()
        {
            Os.shmdt (m_FaceIconPixels);
        }

        private void
        create_face_icon_shm ()
        {
            Gdk.Pixbuf? face_pixbuf = null;
            if (m_FaceIconFilename != null)
            {
                try
                {
                    face_pixbuf = new Gdk.Pixbuf.from_file_at_scale (m_FaceIconFilename,
                                                                     ICON_SIZE,
                                                                     ICON_SIZE,
                                                                     true);
                }
                catch (GLib.Error err)
                {
                    GLib.warning ("error on load %s", m_FaceIconFilename);
                }
            }

            if (face_pixbuf != null)
            {
                Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                                     ICON_SIZE, ICON_SIZE);

                CairoContext ctx = new CairoContext (surface);
                ctx.set_operator (Cairo.Operator.CLEAR);
                ctx.paint ();
                ctx.set_operator (Cairo.Operator.OVER);

                double scale = ICON_SIZE / (double)(face_pixbuf.width + 4);
                ctx.scale (scale, scale);
                ctx.rounded_rectangle (((ICON_SIZE - ((double)(face_pixbuf.width + 4) * scale)) / 2.0) + 2.0,
                                       ((ICON_SIZE - ((double)(face_pixbuf.height + 4) * scale)) / 2.0) + 2.0,
                                       face_pixbuf.width, face_pixbuf.height, 4, CairoCorner.ALL);
                ctx.clip ();
                Gdk.cairo_set_source_pixbuf (ctx, face_pixbuf, 
                                             ((ICON_SIZE - ((double)(face_pixbuf.width + 4) * scale)) / 2.0) + 2.0,
                                             ((ICON_SIZE - ((double)(face_pixbuf.height + 4) * scale)) / 2.0) + 2.0);
                ctx.paint ();
                surface.finish ();

                m_FaceIconShmKey = GLib.Quark.from_string (login);
                m_FaceIconShmId = Os.shmget(m_FaceIconShmKey,
                                            ICON_SIZE * ICON_SIZE *  4,
                                            Os.IPC_CREAT | 0666);

                GLib.debug ("Face icon %s: key = 0x%x, id = %i",
                            login, (int)m_FaceIconShmKey, m_FaceIconShmId);

                m_FaceIconPixels = (uchar[])Os.shmat(face_icon_shm_id, null, 0);

                GLib.Memory.copy (m_FaceIconPixels, surface.get_data (), ICON_SIZE * ICON_SIZE * 4);
            }
        }

        internal int
        compare (User inOther)
        {
                if (m_Frequency > inOther.m_Frequency)
                return -1;

            if (m_Frequency < inOther.m_Frequency)
                return 1;

            if (uid < inOther.uid)
                return -1;

            if (uid > inOther.uid)
                return 1;

            return GLib.strcmp (m_RealName, inOther.m_RealName);
        }
    }

    public class Users
    {
        // types
        private struct Node
        {
            public User val;
        }

        public class Iterator
        {
            // properties
            private Users m_Users;
            private int   m_Index;

            // methods
            internal Iterator (Users inUsers)
            {
                m_Users = inUsers;
                m_Index = -1;
            }

            public bool
            next ()
            {
                bool ret = false;

                if (m_Index == -1 && m_Users.m_Size > 0)
                {
                    m_Index = 0;
                    ret = true;
                }
                else if (m_Index < m_Users.m_Size)
                {
                    m_Index++;
                    ret = m_Index < m_Users.m_Size;
                }

                return ret;
            }

            public unowned User?
            get ()
                requires (m_Index >= 0)
                requires (m_Index < m_Users.m_Size)
            {
                return m_Users.m_Content[m_Index].val;
            }
        }

        // properties
        private DBus.Connection m_Connection;
        private int             m_Size = 0;
        private int             m_Reserved = 4;
        private Node*           m_Content;
        private string          m_IgnoreUsers = "nobody nobody4 noaccess";
        private string          m_IgnoreShells = "/bin/false /usr/sbin/nologin";
        private int             m_MinimumUid = 1000;

        // accessors
        public int nb_users {
            get {
                return m_Size;
            }
        }

        // methods
        public Users (DBus.Connection inConn)
        {
            m_Connection = inConn;

            m_Content = new Node [m_Reserved];

            load_config ();

            Os.setpwent ();
            while (true)
            {
                unowned Os.Passwd? entry = Os.getpwent ();
                if (entry == null)
                    break;

                User user = new User (entry);

                if (user.uid < m_MinimumUid)
                    continue;

                if (user.shell != null)
                {
                    bool found = false;
                    foreach (string shell in m_IgnoreShells.split (" "))
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
                foreach (string hidden in m_IgnoreUsers.split (" "))
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
            Os.endpwent ();
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
                    m_MinimumUid = config.get_integer ("users", "minimum-uid");
                    m_IgnoreUsers = config.get_string ("users", "hidden-users");
                    m_IgnoreShells = config.get_string ("users", "hidden-shells");
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
            int ret = m_Size;
            int left = 0, right = m_Size - 1;

            if (right != -1)
            {
                while (right >= left)
                {
                    int medium = (left + right) / 2;
                    int res = m_Content[medium].val.compare (user);

                    if (res == 0)
                    {
                        while (medium < m_Size && m_Content[medium].val.compare (user) == 0)
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

                    ret = (int)GLib.Math.ceil((double)(left + right) / 2);
                }
            }

            return ret;
        }

        private void
        grow ()
        {
            if (m_Size > m_Reserved)
            {
                int oldReserved = m_Reserved;
                m_Reserved = 2 * m_Reserved;
                m_Content = GLib.realloc (m_Content, m_Reserved * sizeof (Node));
                GLib.Memory.set (&m_Content[oldReserved], 0, oldReserved * sizeof (Node));
            }
        }

        private void
        add (User user)
        {
            GLib.debug ("add user %s", user.login);

            int pos = get_nearest_user (user);

            m_Size++;
            grow ();

            if (pos < m_Size - 1)
                GLib.Memory.move (&m_Content[pos + 1], &m_Content[pos],
                                  (m_Size - pos - 1) * sizeof (Node));

            m_Content[pos].val = user;

            DBus.ObjectPath path = new DBus.ObjectPath ("/fr/supersonicimagine/XSAA/Manager/User/" +
                                                        pos.to_string());

            m_Connection.register_object(path, user);
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