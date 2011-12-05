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

namespace XSAA.Aixplorer
{
    /**
     * Aixplorer theme engine
     */
    public class Engine : Goo.Canvas, XSAA.EngineItem, XSAA.Engine
    {
        // private
        private string                             m_Id;
        private int                                m_Layer = -1;
        private unowned Goo.CanvasItem?            m_Root;
        private GLib.HashTable<string, EngineItem> m_Childs;

        // accessors
        protected GLib.HashTable<string, EngineItem>? childs {
            get {
                if (m_Childs == null)
                    m_Childs = new GLib.HashTable<string, EngineItem> (GLib.str_hash, GLib.str_equal);
                return m_Childs;
            }
        }

        internal string node_name {
            get {
                return "engine";
            }
        }

        public string id {
            get {
                return m_Id;
            }
            set {
                m_Id = value;
            }
        }

        public int layer {
            get {
                return m_Layer;
            }
            set {
                m_Layer = value;
            }
        }

        // static methods
        static construct
        {
            EngineItem.register_item ("background", typeof (Background));
            EngineItem.register_item ("logo", typeof (Logo));
            EngineItem.register_item ("text", typeof (Text));
            EngineItem.register_item ("button", typeof (Button));
            EngineItem.register_item ("entry", typeof (Entry));
            EngineItem.register_item ("table", typeof (Table));

            GLib.Value.register_transform_func (typeof (string), typeof (Goo.CanvasItemVisibility),
                                                (ValueTransform)string_to_canvas_item_visibility);
            GLib.Value.register_transform_func (typeof (Goo.CanvasItemVisibility), typeof (string),
                                                (ValueTransform)canvas_item_visibility_to_string);
        }

        private static void
        canvas_item_visibility_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (Goo.CanvasItemVisibility)))
        {
            Goo.CanvasItemVisibility val = (Goo.CanvasItemVisibility)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_canvas_item_visibility (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = (Goo.CanvasItemVisibility)int.parse (val);
        }

        // methods
        /**
         * Create a new Aixplorer theme engine
         */
        public Engine ()
        {
            m_Root = get_root_item ();
        }

        public void
        append_child (EngineItem inChild)
        {
            if (inChild is Goo.CanvasItemSimple)
            {
                childs.insert (inChild.id, inChild);
                m_Root.add_child ((Goo.CanvasItemSimple)inChild, inChild.layer);
            }
        }

        public override void
        size_allocate (Gdk.Rectangle inAllocation)
        {
            Gtk.Allocation old = allocation;

            base.size_allocate (inAllocation);

            if (old.width != inAllocation.width || old.height != inAllocation.height)
            {
                set_bounds (0, 0, inAllocation.width, inAllocation.height);

                foreach (unowned EngineItem item in this)
                {
                    if (item is Item)
                    {
                        unowned ItemPackOptions? pack_options = (ItemPackOptions?)item;
                        if (pack_options.expand)
                        {
                            unowned Item? i = (Item?)item;
                            i.width = inAllocation.width;
                            i.height = inAllocation.height;
                        }
                    }
                    else if (item is Table)
                    {
                        unowned ItemPackOptions? pack_options = (ItemPackOptions?)item;
                        if (pack_options.expand)
                        {
                            unowned Table? i = (Table?)item;
                            i.width = inAllocation.width;
                            i.height = inAllocation.height;
                        }
                    }
                }
            }
        }
    }
}

public XSAA.Engine? plugin_init ()
{
    return new XSAA.Aixplorer.Engine ();
}
