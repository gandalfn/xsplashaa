/* xsaa-log.vala
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
 
namespace XSAA.Log
{
    public static void
    kmsg_log_handler (string? log_domain, LogLevelFlags log_levels, string message)
    {
        int fd = Posix.open("/dev/kmsg", Posix.O_WRONLY);
        if (fd > 0)
        {
            string msg = "xsplashaa: %s\n".printf (message);
            Posix.write (fd, msg, Posix.strlen (msg));
            Posix.close (fd);
        }
    }

    public static void
    syslog_log_handler (string? log_domain, GLib.LogLevelFlags log_levels, string message)
    {
        int level = Posix.LOG_CRIT;

        switch (log_levels)
        {
            case GLib.LogLevelFlags.LEVEL_ERROR:
                level = Posix.LOG_ERR;
                break;
            case GLib.LogLevelFlags.LEVEL_CRITICAL:
                level = Posix.LOG_CRIT;
                break;
            case GLib.LogLevelFlags.LEVEL_WARNING:
                level = Posix.LOG_WARNING;
                break;
            case GLib.LogLevelFlags.LEVEL_MESSAGE:
                level = Posix.LOG_INFO;
                break;
            case GLib.LogLevelFlags.LEVEL_DEBUG:
                level = Posix.LOG_DEBUG;
                break;
            default:
                break;
        }

        Posix.syslog (level, message);
    }
}
