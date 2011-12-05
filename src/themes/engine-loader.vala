/* engine-loader.vala
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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public errordomain EngineLoaderError
    {
        NOT_FOUND,
        PARSE,
        LOADING,
        INVALID
    }

    /**
     * Engine loader class
     */
    public class EngineLoader : GLib.Object
    {
        // types
        public delegate Engine? PluginInitFunc ();

        // properties
        private GLib.Module m_Module;
        private Engine      m_Engine;

        // accessors
        public Engine engine {
            get {
                return m_Engine;
            }
        }

        // methods
        /**
         * Create a new engine loader
         *
         * @param inName engine name
         *
         * @throw EngineLoaderError if somethings goes wrong
         */
        public EngineLoader (string inName) throws EngineLoaderError
        {
            //string filename = Config.PACKAGE_DATA_DIR + "/" + inName + "/" + inName + ".engine";
            string filename = inName + "/" + inName + ".engine";
            if (!FileUtils.test(filename, FileTest.EXISTS))
                throw new EngineLoaderError.NOT_FOUND ("Could not found %s", filename);

            try
            {
                XmlParser parser = new XmlParser (filename);
                foreach (Parser.Token token in parser)
                {
                    switch (token)
                    {
                        case Parser.Token.START_ELEMENT:
                            if (parser.element == "engine")
                            {
                                string name = parser.attributes.lookup ("id");

                                if (name != null)
                                {
                                    load (name);
                                    parser.attributes.foreach ((k, v) => {
                                        m_Engine.set_attribute (k, v);
                                    });
                                    m_Engine.parse (parser);
                                }
                            }
                            break;
                    }
                    if (m_Engine != null) break;
                }

                if (m_Engine == null)
                {
                    throw new EngineLoaderError.PARSE ("error on parse %s: could not found engine desscription", filename);
                }
            }
            catch (GLib.Error err)
            {
                throw new EngineLoaderError.PARSE ("error on parse %s: %s", filename, err.message);
            }
        }

        private void
        load (string inName) throws EngineLoaderError
        {
            //string filename = Config.PACKAGE_DATA_DIR + "/" + inName + "/" + inName + "-engine.so";
            string filename = inName + "/.libs/" + inName + "-engine.so";
            m_Module = GLib.Module.open (filename, GLib.ModuleFlags.BIND_LAZY);
            if (m_Module == null)
            {
                throw new EngineLoaderError.LOADING ("Error on loading %s: %s", filename, m_Module.error ());
            }

            void* function;
            if (!m_Module.symbol ("plugin_init", out function))
            {
                throw new EngineLoaderError.INVALID ("Error on loading %s: %s", filename, m_Module.error ());
            }
            PluginInitFunc plugin_init = (PluginInitFunc)function;

            m_Engine = plugin_init ();
            m_Engine.ref ();
        }
    }
}
