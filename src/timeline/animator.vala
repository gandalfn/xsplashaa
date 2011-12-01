/* animator.vala
 *
 * Copyright (C) 2009-2011  Supersonic Imagine
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
    public class Animator : GLib.Object
    {
        // delegates
        public delegate bool TransitionCallback (double inProgress);
        public delegate void TransitionFinished ();
        public delegate void PropertyCallback (Object inObject, string inName, GLib.Value inFrom, GLib.Value inTo, double inProgress, ref GLib.Value outValue);

        // types
        public enum ProgressType
        {
            LINEAR,
            SINUSOIDAL,
            EXPONENTIAL,
            EASE_IN_EASE_OUT;

            internal double
            calculate_progress (double inValue)
            {
                double progress = inValue;

                switch (this)
                {
                    case LINEAR:
                        break;

                    case SINUSOIDAL:
                        progress = GLib.Math.sin ((progress * GLib.Math.PI) / 2);
                        break;

                    case EXPONENTIAL:
                        progress *= progress;
                        break;

                    case EASE_IN_EASE_OUT:
                        progress *= 2;
                        if (progress < 1)
                            progress = GLib.Math.pow (progress, 3) / 2;
                        else
                            progress = (GLib.Math.pow (progress - 2, 3) + 2) / 2;
                        break;
                }

                return progress;
            }
        }

        private class PropertyRange : GLib.Object
        {
            // properties
            public unowned GLib.Object m_Object;
            public string              m_Name;
            public GLib.ParamSpec      m_ParamSpec;
            public GLib.Value          m_From;
            public GLib.Value          m_To;
            public PropertyCallback    m_Callback;

            // methods

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public PropertyRange (Object inObject, string inName, GLib.Value inFrom, GLib.Value inTo, PropertyCallback? inCallback = null)
            {
                m_Object = inObject;
                m_Name = inName;
                m_From = inFrom;
                m_To = inTo;
                m_ParamSpec = m_Object.get_class ().find_property (inName);
                m_Callback = inCallback;
            }

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public void
            progress (double inProgress)
            {
                if (m_ParamSpec != null)
                {
                    GLib.Type type = m_ParamSpec.value_type;
                    GLib.Value val = GLib.Value (type);

                    if (m_Callback == null)
                    {
                        if (type == typeof (int))
                        {
                            val = (int)((int)m_From + (((int)m_To - (int)m_From) * inProgress));
                        }
                        else if (type == typeof (float))
                        {
                            val = (float)((float)m_From + (((float)m_To - (float)m_From) * inProgress));
                        }
                        else if (type == typeof (double))
                        {
                            val = (double)((double)m_From + (((double)m_To - (double)m_From) * inProgress));
                        }
                    }
                    else
                    {
                        m_Callback (m_Object, m_Name, m_From, m_To, inProgress, ref val);
                    }

                    m_Object.set_property (m_Name, val);
                }
            }
        }

        private class Transition : GLib.Object
        {
            // properties
            private TransitionCallback m_Callback = null;
            private TransitionFinished m_Finished = null;
            private PropertyRange[]    m_Properties = {};

            // accessors
            public uint         id            { get; construct; default = 0; }
            public bool         is_playing    { get; set; default = false; }
            public double       from          { get; construct set; default = 0.0; }
            public double       to            { get; construct set; default = 1.0; }
            public ProgressType progress_type { get; construct set; default = ProgressType.LINEAR; }

            // methods

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public Transition (uint inId, double inFrom, double inTo, ProgressType inType,
                               TransitionCallback? inCallback = null, TransitionFinished? inFinished = null)
            {
                GLib.Object (id: inId, from: inFrom, to: inTo, progress_type: inType);
                m_Callback = inCallback;
                m_Finished = inFinished;
            }

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public void
            add_property (Object inObject, string inName, GLib.Value inFrom, GLib.Value inTo, PropertyCallback? inCallback = null)
            {
                // Create property
                PropertyRange property = new PropertyRange (inObject, inName, inFrom, inTo, inCallback);
                m_Properties += property;
            }

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public void
            progress (double inProgress, bool inLoop = false)
            {
                if (inProgress >= from && inProgress <= to)
                {
                    is_playing = true;

                    double  transition_progress = (inProgress - from) / (to - from);
                    transition_progress = transition_progress.clamp (0.0, 1.0);
                    transition_progress = progress_type.calculate_progress (transition_progress);

                    bool result = false;

                    // If we have callback launch it
                    if (m_Callback != null)
                    {
                        result = m_Callback (transition_progress);
                    }
                    if (!result)
                    {
                        foreach (unowned PropertyRange property in m_Properties)
                        {
                            property.progress (transition_progress);
                        }
                    }
                }

                if (inProgress >= to)
                {
                    if (!inLoop)
                    {
                        finish ();
                    }
                    else if (is_playing)
                    {
                        is_playing = false;
                    }
                }
            }

            ////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            public void
            finish ()
            {
                if (is_playing)
                {
                    is_playing = false;
                    if (m_Finished != null)
                    {
                        m_Finished ();
                    }
                }
            }
        }

        // properties
        private XSAA.Timeline m_Timeline = null;
        private uint m_Duration = 1000;
        private Transition[] m_Transitions = {};
        private uint m_TransitionLastId = 1;

        // accessors
        public uint speed {
            get {
                return m_Timeline.speed;
            }
            set {
                m_Timeline.speed = value;
                m_Timeline.duration = m_Duration;
            }
        }

        public uint duration {
            get {
                return m_Duration;
            }
            set {
                if (m_Duration != value)
                {
                    m_Duration = value;
                    m_Timeline.duration = m_Duration;
                }
            }
        }

        public XSAA.TimelineDirection direction {
            get {
                return m_Timeline.direction;
            }
            set {
                m_Timeline.direction = value;
            }
        }

        public bool loop {
            get {
                return m_Timeline.loop;
            }
            set {
                m_Timeline.loop = value;
            }
        }

        public bool is_playing {
            get {
                return m_Timeline.is_playing;
            }
        }

        // methods

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        construct
        {
            m_Timeline = new XSAA.Timeline (20, 20);
            m_Timeline.started.connect (on_started);
            m_Timeline.new_frame.connect (on_new_frame);
            m_Timeline.completed.connect (on_completed);
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public Animator (uint inSpeed, uint inDuration)
        {
            GLib.Object (speed: inSpeed, duration: inDuration);
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        private void
        on_started ()
        {
            foreach (unowned Transition transition in m_Transitions)
            {
                transition.is_playing = false;
            }
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        private void
        on_new_frame (int inNumFrame)
        {
            double progress = m_Timeline.progress;
            bool is_loop =  loop;

            foreach (unowned Transition transition in m_Transitions)
            {
                transition.progress (progress, is_loop);
            }
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        private void
        on_completed ()
        {
            foreach (unowned Transition transition in m_Transitions)
            {
                if (transition.is_playing)
                {
                    transition.finish ();
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public uint
        add_transition (double inFrom, double inTo, ProgressType inType,
                        TransitionCallback? inCallback = null, TransitionFinished? inFinished = null)
        {
            Transition transition = new Transition (m_TransitionLastId, inFrom, inTo, inType, inCallback, inFinished);
            m_Transitions += transition;
            m_TransitionLastId++;

            return transition.id;
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public void
        remove_transition (uint inTransition)
            requires (inTransition < m_TransitionLastId)
        {
            Transition[] new_transition = {};

            foreach (unowned Transition transition in m_Transitions)
            {
                if (inTransition != transition.id)
                {
                    new_transition += transition;
                }
            }

            m_Transitions = new_transition;
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public void
        add_transition_property (uint inTransition, Object inObject, string inName, GLib.Value inFrom, GLib.Value inTo,
                                 PropertyCallback? inCallback = null)
            requires (inTransition < m_TransitionLastId)
        {
            foreach (unowned Transition transition in m_Transitions)
            {
                if (inTransition == transition.id)
                {
                    transition.add_property (inObject, inName, inFrom, inTo, inCallback);
                    break;
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public void
        start ()
        {
            m_Timeline.rewind ();
            m_Timeline.start ();
        }

        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        public void
        stop ()
        {
            m_Timeline.stop ();
        }
    }
}
