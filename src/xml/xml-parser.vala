/* xml-parser.vala
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
    public class XmlParser : Parser
    {
        // Properties
        private string          m_Filename = null;
        private GLib.MappedFile m_File;
        private bool            m_EmptyElement = false;

        // Methods

        /**
         * Create a new xml parser from a filename
         *
         * @param inFilename xml filename
         */
        public XmlParser (string inFilename) throws ParseError
        {
            try
            {
                GLib.MappedFile file = new GLib.MappedFile (inFilename, false);
                this.from_buffer ((string)file.get_contents (), (long)file.get_length ());

                m_Filename = inFilename;
                m_File = (owned)file;
            }
            catch (FileError error)
            {
                throw new ParseError.OPEN("Error on open %s: %s", inFilename, error.message);
            }
        }

        /**
         * Create a new xml parser from a buffer
         *
         * @param inContent buffer content
         * @param inLength buffer length
         */
        public XmlParser.from_buffer (string inContent, long inLength) throws ParseError
        {
            char* begin = (char*)inContent;
            char* end = begin + inLength;

            base (begin, end);
        }

        private void
        skip_comment ()
        {
            m_pCurrent++;
            if (m_pCurrent < m_pEnd - 1 && m_pCurrent[0] == '-' && m_pCurrent[1] == '-')
            {
                m_pCurrent += 2;
                while (m_pCurrent < m_pEnd - 2)
                {
                    if (m_pCurrent[0] == '-' && m_pCurrent[1] == '-' && m_pCurrent[2] == '>')
                    {
                        m_pCurrent += 3;
                        break;
                    }
                    m_pCurrent++;
                }
            }
        }

        private void
        skip_processing_instruction ()
        {
            m_pCurrent++;
            while (m_pCurrent < m_pEnd - 1)
            {
                if (m_pCurrent[0] == '?' && m_pCurrent[1] == '>')
                {
                    m_pCurrent += 2;
                    break;
                }
                m_pCurrent++;
            }
        }

        private string
        read_name () throws ParseError
        {
            char* begin = m_pCurrent;

            while (m_pCurrent < m_pEnd)
            {
                if (m_pCurrent[0] == ' ' || m_pCurrent[0] == '\t' || m_pCurrent[0] == '>' ||
                    m_pCurrent[0] == '/' || m_pCurrent[0] == '=' || m_pCurrent[0] == '\n')
                    break;

                unichar u = ((string) m_pCurrent).get_char_validated ((long) (m_pEnd - m_pCurrent));
                if (u != (unichar) (-1))
                    m_pCurrent += u.to_utf8 (null);
                else
                    throw new ParseError.INVALID_UTF8 ("invalid UTF-8 character");
            }

            if (m_pCurrent == begin)
                throw new ParseError.INVALID_NAME ("invalid name");

            return ((string) begin).substring (0, (int) (m_pCurrent - begin));
        }

        private void
        read_attributes () throws ParseError
        {
            m_Attributes = new GLib.HashTable<string, string> (GLib.str_hash, GLib.str_equal);

            while (m_pCurrent < m_pEnd && m_pCurrent[0] != '>' && m_pCurrent[0] != '/')
            {
                string name = read_name ();
                if (m_pCurrent >= m_pEnd || m_pCurrent[0] != '=')
                    throw new ParseError.PARSE ("Unexpected end of element %s", m_Element);

                m_pCurrent++;
                if (m_pCurrent >= m_pEnd || m_pCurrent[0] != '"')
                    throw new ParseError.PARSE ("Unexpected end of element %s", m_Element);

                m_pCurrent++;
                string val = text ('"', false);

                if (m_pCurrent >= m_pEnd || m_pCurrent[0] != '"')
                    throw new ParseError.PARSE ("Unexpected end of element %s", m_Element);

                m_pCurrent++;

                m_Attributes.insert (name, val);
                skip_space ();
            }
        }

        private string
        text (char inEndChar, bool inRmTrailingWhitespace) throws ParseError
        {
            GLib.StringBuilder content = new GLib.StringBuilder ();
            char* text_begin = m_pCurrent;
            char* last_linebreak = m_pCurrent;

            while (m_pCurrent < m_pEnd && m_pCurrent[0] != inEndChar)
            {
                unichar u = ((string) m_pCurrent).get_char_validated ((long) (m_pEnd - m_pCurrent));
                if (u == (unichar) (-1))
                {
                    throw new ParseError.INVALID_UTF8 ("invalid UTF-8 character");
                }
                else if (u == '&')
                {
                    char* next_pos = m_pCurrent + u.to_utf8 (null);
                    if (((string) next_pos).has_prefix ("amp;"))
                    {
                        content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
                        content.append_c ('&');
                        m_pCurrent += 5;
                        text_begin = m_pCurrent;
                    }
                    else if (((string) next_pos).has_prefix ("quot;"))
                    {
                        content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
                        content.append_c ('"');
                        m_pCurrent += 6;
                        text_begin = m_pCurrent;
                    }
                    else if (((string) next_pos).has_prefix ("apos;"))
                    {
                        content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
                        content.append_c ('\'');
                        m_pCurrent += 6;
                        text_begin = m_pCurrent;
                    }
                    else if (((string) next_pos).has_prefix ("lt;"))
                    {
                        content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
                        content.append_c ('<');
                        m_pCurrent += 4;
                        text_begin = m_pCurrent;
                    }
                    else if (((string) next_pos).has_prefix ("gt;"))
                    {
                        content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
                        content.append_c ('>');
                        m_pCurrent += 4;
                        text_begin = m_pCurrent;
                    }
                    else
                    {
                        m_pCurrent += u.to_utf8 (null);
                    }
                }
                else
                {
                    if (u == '\n')
                    {
                        last_linebreak = m_pCurrent;
                    }

                    m_pCurrent += u.to_utf8 (null);
                }
            }

            if (text_begin != m_pCurrent)
            {
                content.append (((string) text_begin).substring (0, (int)(m_pCurrent - text_begin)));
            }

            if (inRmTrailingWhitespace)
            {
                char* str_pos = ((char*)content.str) + content.len;
                for (str_pos--; str_pos > ((char*)content.str) && str_pos[0].isspace(); str_pos--);
                content.erase ((ssize_t) (str_pos-((char*) content.str) + 1), -1);
            }

            return content.str;
        }

        internal override Parser.Token
        next_token () throws ParseError
        {
            Parser.Token token = Parser.Token.NONE;

            if (m_EmptyElement)
            {
                m_EmptyElement = false;
                return Parser.Token.END_ELEMENT;
            }

            skip_space ();

            if (m_pCurrent >= m_pEnd)
            {
                token = Parser.Token.EOF;
            }
            else if (m_pCurrent[0] == '<')
            {
                m_pCurrent++;
                if (m_pCurrent >= m_pEnd)
                {
                    throw new ParseError.PARSE ("Unexpected end of xml");
                }
                else if (m_pCurrent[0] == '?')
                {
                    skip_processing_instruction ();
                    token = next_token ();
                }
                else if (m_pCurrent[0] == '!')
                {
                    skip_comment ();
                    token = next_token ();
                }
                else if (m_pCurrent[0] == '/')
                {
                    token = Parser.Token.END_ELEMENT;
                    m_pCurrent++;
                    m_Element = read_name ();
                    if (m_pCurrent >= m_pEnd || m_pCurrent[0] != '>')
                        throw new ParseError.PARSE ("Unexpected end of element %s", m_Element);
                    m_pCurrent++;
                }
                else
                {
                    token = Parser.Token.START_ELEMENT;
                    m_Element = read_name ();
                    skip_space ();
                    read_attributes ();

                    if (m_pCurrent[0] == '/')
                    {
                        m_EmptyElement = true;
                        m_pCurrent++;
                        skip_space ();
                    }
                    else
                    {
                        m_EmptyElement = false;
                    }
                    if (m_pCurrent >= m_pEnd || m_pCurrent[0] != '>')
                    {
                        throw new ParseError.PARSE ("Unexpected end of element %s", m_Element);
                    }
                    m_pCurrent++;
                }
            }
            else
            {
                skip_space ();

                if (m_pCurrent[0] != '<')
                {
                    m_Characters = text ('<', true);
                }
                else
                {
                    return next_token ();
                }

                token = Parser.Token.CHARACTERS;
            }

            return token;
        }
    }
}
