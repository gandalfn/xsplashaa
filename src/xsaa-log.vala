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
    // static methods
    public static void
    kmsg_log_handler (string? inLogDomain, LogLevelFlags inLogLevels, string inMessage)
    {
        int fd = Os.open("/dev/kmsg", Os.O_WRONLY);
        if (fd > 0)
        {
            string msg = "xsplashaa: %s\n".printf (inMessage);
            Os.write (fd, msg, msg.length);
            Os.close (fd);
        }
    }

    public static void
    syslog_log_handler (string? inLogDomain, LogLevelFlags inLogLevels, string inMessage)
    {
        int level = Os.LOG_CRIT;

        switch (inLogLevels)
        {
            case GLib.LogLevelFlags.LEVEL_ERROR:
                level = Os.LOG_ERR;
                break;
            case GLib.LogLevelFlags.LEVEL_CRITICAL:
                level = Os.LOG_CRIT;
                break;
            case GLib.LogLevelFlags.LEVEL_WARNING:
                level = Os.LOG_WARNING;
                break;
            case GLib.LogLevelFlags.LEVEL_MESSAGE:
                level = Os.LOG_INFO;
                break;
            case GLib.LogLevelFlags.LEVEL_DEBUG:
                level = Os.LOG_DEBUG;
                break;
            default:
                break;
        }

        Os.syslog (level, inMessage);
    }
}
