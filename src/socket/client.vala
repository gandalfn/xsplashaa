/* client.vala
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

namespace XSAA
{
    /**
     * Client socket class
     */
    public class Client : Socket
    {
        // methods
        /**
         * Create a new xsplashaa client socket
         *
         * @param inSocketName the unix socket filename
         */
        public Client(string inSocketName) throws SocketError
        {
            Log.debug ("Create client on %s", inSocketName);

            base(inSocketName);

            Os.fcntl(fd, Os.O_NONBLOCK);

            Os.SockAddrUn addr = saddr;
            if (Os.connect(fd, &addr, 110) != 0)
            {
                throw new SocketError.CREATE("error on connect %s", inSocketName);
            }
        }

        /**
         * Send ping message and wait for pong
         */
        public void
        ping ()
        {
            Log.debug ("send ping");

            MainLoop loop = new MainLoop(null, false);

            in.connect(() => {
                Log.debug ("pong received");

                Message message = null;
                if (recv(out message) && message.message_type == MessageType.PONG)
                {
                    loop.quit ();
                }
            });

            send(new Message.ping ());
            loop.run();
        }

        /**
         * Send quit message
         */
        public void
        quit ()
        {
            Log.debug ("send quit");

            send(new Message.quit ());
        }

        /**
         * Send dbus message
         */
        public void
        dbus ()
        {
            Log.debug ("send dbus message");

            send(new Message.dbus ());
        }

        /**
         * Send session message
         */
        public void
        session()
        {
            Log.debug ("send session message");

            send(new Message.session ());
        }

        /**
         * Send phase message
         *
         * @param inPhase phase number
         */
        public void
        phase (int inPhase)
        {
            Log.debug ("send phase %i message", inPhase);

            send(new Message.phase (inPhase - 1));
        }

        /**
         * Send progress message
         *
         * @param inProgress progress value
         */
        public void
        progress (int inProgress)
        {
            Log.debug ("send progress %i message", inProgress);

            send(new Message.progress (inProgress));
        }

        /**
         * Send pulse message
         */
        public void
        pulse()
        {
            Log.debug ("send pulse message");

            send(new Message.pulse ());
        }

        /**
         * Send close session message
         */
        public void
        close_session()
        {
            Log.debug ("send close session message");

            send(new Message.close_session ());
        }

        /**
         * Send message message
         */
        public void
        message(string inMessage)
        {
            Log.debug ("send message %s message", inMessage);

            send(new Message.message (inMessage));
        }

        /**
         * Send error message
         */
        public void
        error(string inMessage)
        {
            Log.debug ("send error %s message", inMessage);

            send(new Message.error (inMessage));
        }

        /**
         * Send fatal error message
         */
        public void
        fatal_error(string inMessage)
        {
            Log.debug ("send fatal error %s message", inMessage);

            send(new Message.fatal_error (inMessage));
        }
    }
}

