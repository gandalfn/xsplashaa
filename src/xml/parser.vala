/* parser.vala
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
    public errordomain ParseError
    {
        OPEN,
        INVALID,
        PARSE,
        NOT_SUPPORTED,
        INVALID_UTF8,
        INVALID_NAME
    }

    public abstract class Parser : GLib.Object
    {
        // Types
        public enum Token
        {
            NONE,
            START_ELEMENT,
            END_ELEMENT,
            CHARACTERS,
            EOF
        }

        public class Iterator
        {
            private Parser       m_Parser;
            private Parser.Token m_Current;

            internal Iterator (Parser inParser)
            {
                m_Parser = inParser;
            }

            public bool
            next () throws ParseError
            {
                m_Current = m_Parser.next_token ();

                return m_Current != Parser.Token.EOF;
            }

            public unowned Token
            get ()
            {
                return m_Current;
            }
        }

        // Properties
        protected char*               m_pBegin;
        protected char*               m_pEnd;
        protected char*               m_pCurrent;

        protected string                         m_Element    = null;
        protected GLib.HashTable<string, string> m_Attributes = null;
        protected string                         m_Characters = null;

        // Accessors
        public string element {
            get {
                return m_Element;
            }
        }

        public GLib.HashTable<string, string> attributes {
            get {
                return m_Attributes;
            }
        }

        public string characters {
            get {
                return m_Characters;
            }
        }

        // Methods

        /**
         * Create a new parser
         */
        public Parser (char* inpBegin, char* inpEnd) throws ParseError
        {
            if (inpBegin >= inpEnd)
            {
                throw new ParseError.INVALID ("Invalid content");
            }

            m_pBegin = inpBegin;
            m_pEnd = inpEnd;
            m_pCurrent = m_pBegin;
        }

        protected void
        skip_space ()
        {
            while (m_pCurrent < m_pEnd &&
                   (m_pCurrent[0] == ' '  || m_pCurrent[0] == '\n' ||
                    m_pCurrent[0] == '\r' || m_pCurrent[0] == '\t'))
                m_pCurrent++;
        }

        protected abstract Token next_token () throws ParseError;

        public new Iterator
        iterator ()
        {
            return new Iterator (this);
        }
    }
}
