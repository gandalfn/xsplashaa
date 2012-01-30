/* state-machine.vala
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
     * State machine class
     */
    public abstract class StateMachine : GLib.Object
    {
        // constants
        const int DELAY = 100;
        const int ERROR_DELAY = 20;

        // properties
        private unowned StateMachine? m_Current;
        private StateMachine[]        m_States;
        private GLib.Type             m_NextState = GLib.Type.INVALID;
        private GLib.Type             m_ErrorState = GLib.Type.INVALID;

        // acessors
        public GLib.Type current {
            get {
                return m_Current != null ? m_Current.get_type () : GLib.Type.INVALID;
            }
        }

        public GLib.Type next_state {
            get {
                return m_NextState;
            }
            set {
                m_NextState = value;
            }
        }

        public GLib.Type error_state {
            get {
                return m_ErrorState;
            }
            set {
                m_ErrorState = value;
            }
        }

        public int length {
            get {
                return m_States.length;
            }
        }

        // signals
        public signal void step ();
        public signal void progress (int inProgress);
        public signal void message (string inMessage);
        public signal bool error (string inMessage);
        public signal bool question (string inMessage);
        public signal void finished ();

        // methods
        construct
        {
            m_States = {};
        }

        private void
        on_child_finished ()
        {
            if (m_Current != null && m_Current.next_state != GLib.Type.INVALID)
            {
                foreach (unowned StateMachine? state in m_States)
                {
                    if (state.get_type () == m_Current.next_state)
                    {
                        Log.info ("%s finished, switch to state %s", current.name (), m_Current.next_state.name ());
                        m_Current = state;
                        step ();
                        m_Current.run ();
                        return;
                    }
                }

                m_Current = null;
                error ("State %s not found".printf (m_Current.next_state.name ()));
            }
            else
            {
                m_Current = null;
                Log.info ("%s finished", current.name ());
                finished ();
            }
        }

        private void
        next_step_after_error ()
        {
            if (m_Current != null && m_Current.error_state != GLib.Type.INVALID)
            {
                foreach (unowned StateMachine? state in m_States)
                {
                    if (state.get_type () == m_Current.error_state)
                    {
                        Log.warning ("%s finished with error, switch to state %s", current.name (), m_Current.error_state.name ());
                        m_Current = state;
                        step ();
                        m_Current.run ();
                        return;
                    }
                }

                m_Current = null;
                error ("State %s not found".printf (m_Current.next_state.name ()));
            }
            else
            {
                Log.warning ("%s finished with error", current.name ());
                m_Current = null;
                finished ();
            }
        }

        private bool
        on_child_error (string inMessage)
        {
            bool ret = error (inMessage);

            if (!ret)
            {
                GLib.Timeout.add_seconds (ERROR_DELAY, () => {
                    next_step_after_error ();
                    return false;
                });
            }

            return ret;
        }

        private void
        on_child_message (string inMessage)
        {
            message (inMessage);
        }

        private bool
        on_child_question (string inMessage)
        {
            return question (inMessage);
        }

        private void
        on_child_progress (int inProgress)
        {
            progress (inProgress);
        }

        protected virtual void
        on_run ()
        {
            m_Current = null;
            finished ();
        }

        protected void
        start (GLib.Type inState)
        {
            m_Current = null;

            foreach (unowned StateMachine? state in m_States)
            {
                if (state.get_type () == inState)
                {
                    m_Current = state;
                    m_Current.run ();
                    return;
                }
            }
        }

        public void
        resume_after_error ()
        {
            next_step_after_error ();
        }

        public virtual void
        question_response (bool inResponse)
        {
            if (m_Current != null)
            {
                m_Current.question_response (inResponse);
            }
        }

        public void
        add_state (StateMachine inMachine)
        {
            m_States += inMachine;
            inMachine.finished.connect (on_child_finished);
            inMachine.error.connect (on_child_error);
            inMachine.message.connect (on_child_message);
            inMachine.progress.connect (on_child_progress);
            inMachine.question.connect (on_child_question);
        }

        public void
        run ()
        {
            GLib.Timeout.add (DELAY, () => {
                on_run ();
                return false;
            });
        }
    }
}

