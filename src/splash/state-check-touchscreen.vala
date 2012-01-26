/* state-check-touchscreen.vala
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
     * Check touchscreen state machine
     */
    public class StateCheckTouchscreen : StateMachine
    {
        // constants
        const int WAIT_TOUCHSCREEN = 500;
        const int NB_RETRY = 10;

        // properties
        private unowned Devices m_Peripherals;
        private int             m_ScreenWidth = 1680;
        private int             m_ScreenHeight = 1050;
        private int             m_Number;
        private uint            m_IdTimeout;
        private int             m_NbRetry;

        /**
         * Create a new check touchscreen state machine
         *
         * @param inPeripherals peripherals devices
         * @param inNumber display number
         */
        public StateCheckTouchscreen (Devices inPeripherals, int inNumber)
        {
            m_Peripherals = inPeripherals;
            m_Number = inNumber;

            load_config ();
        }

        private void
        load_config ()
        {
            Log.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

            if (FileUtils.test (Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile ();
                    config.load_from_file (Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    m_ScreenWidth = config.get_integer ("display", "width");
                    m_ScreenHeight = config.get_integer ("display", "height");
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on read %s: %s", Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                Log.warning ("unable to find %s config file", Config.PACKAGE_CONFIG_FILE);
            }

        }

        private void
        check_screen ()
        {
            message ("Check touchscreen display");
            unowned Gdk.Display? display = Gdk.Display.open (":" + m_Number.to_string ());
            if (display != null)
            {
                try
                {
                    int num = m_Peripherals.touchscreen.get_screen_number (":" + m_Number.to_string ());
                    unowned Gdk.Screen screen = display.get_screen (num);

                    if (screen != null)
                    {
                        int[] pan = m_Peripherals.touchscreen.get_pan_viewport (":" + m_Number.to_string ());
                        if (pan != null && pan.length == 4)
                        {
                            Log.info ("touchscreen pos = %i,%i,%i,%i", pan[0], pan[1], pan[2], pan[3]);
                            if ((pan[0] + pan[2] > screen.get_width ()) || (pan[1] + pan[3] > screen.get_height ()))
                            {
                                error ("Unable to detect touchscreen display\nPlease check DVI connector");
                            }
                            else
                            {
                                base.on_run ();
                            }
                        }
                        else
                        {
                            error ("Error on check touchscreen screen");
                        }
                    }
                    else
                    {
                        error ("Error on check touchscreen screen");
                    }
                }
                catch (GLib.Error err)
                {
                    error ("Error on check touchscreen screen");
                }
            }
            else
            {
                error ("Error on check touchscreen screen");
            }
        }

        private bool
        on_timeout ()
        {
            if (m_IdTimeout != 0)
            {
                if (m_Peripherals.touchscreen == null)
                {
                    m_NbRetry++;
                    if (m_NbRetry > NB_RETRY)
                    {
                        error ("Unable to find touchscreen device");
                        m_IdTimeout = 0;
                    }
                }
                else
                {
                    check_screen ();
                    m_IdTimeout = 0;
                }
            }

            return m_IdTimeout != 0;
        }

        protected override void
        on_run ()
        {
            if (m_Peripherals.touchscreen == null)
            {
                if (m_IdTimeout != 0)
                {
                    GLib.Source.remove (m_IdTimeout);
                    m_IdTimeout = 0;
                }
                m_NbRetry = 0;
                m_IdTimeout = GLib.Timeout.add (WAIT_TOUCHSCREEN, on_timeout);
            }
            else
            {
                check_screen ();
            }
        }
    }
}

