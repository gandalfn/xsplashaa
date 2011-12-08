/* engine.vala
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
    public interface EngineItem : GLib.Object
    {
        // types
        public class Iterator : GLib.Object
        {
            // properties
            private EngineItem m_Item;
            private int        m_Index;

            // methods
            /**
             * description
             */
            public Iterator (EngineItem inItem)
            {
                m_Item = inItem;
                m_Index = -1;
            }

            public bool
            next ()
            {
                if (m_Index < 0)
                    m_Index = 0;
                else
                    m_Index++;
                return m_Item.childs != null && m_Index < (int)m_Item.childs.size ();
            }

            public new unowned EngineItem?
            @get ()
            {
                return m_Item.childs.lookup (m_Item.childs.get_keys ().nth_data (m_Index));
            }
        }

        // static properties
        private static GLib.HashTable<string, GLib.Type> s_Factory;

        // accessors
        /**
         * Item node name
         */
        public abstract string node_name { get; }

        /**
         * Item id name
         */
        public abstract string id { get; set; }

        /**
         * Item layer
         */
        public abstract int layer { get; set; default = -1; }

        /**
         * Childs list
         */
        public abstract GLib.HashTable<string, EngineItem>? childs { get; }

        // static methods
        public static void
        register_item (string inName, GLib.Type inType)
        {
            if (s_Factory == null)
            {
                s_Factory = new GLib.HashTable<string, GLib.Type> (GLib.str_hash, GLib.str_equal);
            }

            s_Factory.insert (inName, inType);
        }

        /**
         * Format an attribute name: all leading upper case characters
         * are replaced by lower case characters preceed by underscore.
         *
         * @param inName attribute name
         *
         * @return formatted attribute name
         */
        protected static string
        format_attribute_name (string inName)
        {
            GLib.StringBuilder ret = new GLib.StringBuilder("");
            bool previous_is_upper = true;

            unowned char[] s = (char[])inName;
            for (int cpt = 0; s[cpt] != 0; ++cpt)
            {
                char c = s [cpt];
                if (c.isupper())
                {
                    if (!previous_is_upper) ret.append_unichar ('_');
                    ret.append_unichar (c.tolower());
                    previous_is_upper = true;
                }
                else
                {
                    ret.append_unichar (c);
                    previous_is_upper = false;
                }
            }

            return ret.str;
        }

        internal static EngineItem?
        create (string inName, GLib.HashTable<string, string>? inParams)
        {
            EngineItem? item = null;

            if (s_Factory != null)
            {
                GLib.Type type = s_Factory.lookup (inName);
                if (type != GLib.Type.INVALID)
                {
                    item = (EngineItem)GLib.Object.new (type);
                    inParams.foreach ((k, v) => {
                        item.set_attribute (k, v);
                    });
                }
            }

            return item;
        }

        // methods
        public void
        parse (Parser inParser) throws ParseError
        {
            foreach (Parser.Token token in inParser)
            {
                switch (token)
                {
                    case Parser.Token.START_ELEMENT:
                        {
                            GLib.HashTable<string, string> params = inParser.attributes;
                            Log.debug ("element %s", inParser.element);
                            EngineItem item = create (inParser.element, params);
                            if (item != null)
                            {
                                Log.debug ("append child %s to %s %i", item.node_name, node_name, item.layer);

                                append_child (item);
                                item.parse (inParser);
                            }
                        }
                        break;
                    case Parser.Token.END_ELEMENT:
                        if (inParser.element == node_name)
                            return;
                        break;
                    case Parser.Token.CHARACTERS:
                        on_text (inParser.characters);
                        break;
                    case Parser.Token.EOF:
                        return;
                }
            }
        }

        public virtual void
        on_text (string inContent)
        {
        }

        public virtual void
        append_child (EngineItem inChild)
        {
        }

        public Iterator
        iterator ()
        {
            return new Iterator (this);
        }

        /**
         * Return the corresponding child item
         *
         * @param inNodeId child node id
         *
         * @return child item
         */
        public unowned EngineItem?
        get (string inNodeId)
        {
            return childs != null ? childs.lookup (inNodeId) : null;
        }

        /**
         * Find an child item in this and its childrens
         *
         * @param inNodeId child node id
         *
         * @return child item
         */
        public unowned EngineItem?
        find (string inNodeId)
        {
            unowned EngineItem? ret = get (inNodeId);

            if (ret == null && childs != null)
            {
                foreach (unowned EngineItem? item in this)
                {
                    ret = item.find (inNodeId);
                    if (ret != null) return ret;
                }
            }

            return ret;
        }

        /**
         * Find child items by type in this and its childrens
         *
         * @param inType child node type
         *
         * @return child items array
         */
        public EngineItem[]
        find_by_type (GLib.Type inType)
        {
            EngineItem[] ret = {};

            foreach (unowned EngineItem item in this)
            {
                if (item.get_type ().is_a (inType))
                {
                    ret += item;
                }
                foreach (unowned EngineItem child in item.find_by_type (inType))
                {
                    ret += child;
                }
            }

            return ret;
        }

        /**
         * Get value in string format of element inName attribute.
         *
         * @param inName attribute name
         *
         * @return attribute value in string format
         */
        public virtual string
        get_attribute (string inName)
        {
            // Search property in object class
            string ret = null;
            string name = format_attribute_name (inName);
            unowned GLib.ParamSpec param = get_class ().find_property (name);

            // We found property which correspond to attribute name convert it to
            // string format
            if (param != null)
            {
                GLib.Value val = GLib.Value (param.value_type);
                get_property (name, ref val);
                ret = (string)val;
            }

            return ret;
        }

        /**
         * Set value of element inName attribute.
         *
         * @param inName attribute name
         * @param inValue new attribute value
         */
        public virtual void
        set_attribute (string inName, string inValue)
        {
            Log.debug ("set_attribute %s for %s", inName, get_type ().name ());
            // Search property in object class
            string name = format_attribute_name (inName);
            unowned GLib.ParamSpec param = get_class ().find_property (name);

            // We found property which correspond to attribute name convert value
            // to property type and set
            if (param != null)
            {
                set_property (name, XSAA.Value.from_string (param.value_type, inValue));
            }
        }
    }
}
