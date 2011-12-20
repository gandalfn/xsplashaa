/* timeout-interval.vala
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

[CCode (has_target = false)]
internal delegate bool XSAA.TimeoutFunc(void* inData);

internal struct XSAA.TimeoutInterval
{
    // properties
    public TimeVal m_StartTime;
    public uint    m_FrameCount;
    public uint    m_Fps;

    // methods
    public TimeoutInterval(uint inFps)
    {
        m_StartTime.get_current_time();
        m_Fps = inFps;
        m_FrameCount = 0;
    }

    private inline uint
    get_ticks (TimeVal inCurrentTime)
    {
        return (uint)((inCurrentTime.tv_sec - m_StartTime.tv_sec) * 1000 +
                      (inCurrentTime.tv_usec - m_StartTime.tv_usec) / 1000);
    }

    public bool
    prepare (TimeVal inCurrentTime, out int outDelay)
    {
        bool ret = false;
        uint elapsed_time = get_ticks (inCurrentTime);
        uint new_frame_num = elapsed_time * m_Fps / 1000;

        if (new_frame_num < m_FrameCount || new_frame_num - m_FrameCount > 2)
        {
            uint frame_time = (1000 + m_Fps - 1) / m_Fps;

            m_StartTime = inCurrentTime;
            m_StartTime.add(-(int)frame_time * 1000);

            m_FrameCount = 0;
            outDelay = 0;
            ret = true;
        }
        else if (new_frame_num > m_FrameCount)
        {
            outDelay = 0;
            ret = true;
        }
        else
        {
            outDelay = (int)((m_FrameCount + 1) * 1000 / m_Fps - elapsed_time);
        }

        return ret;
    }

    public bool
    dispatch (TimeoutFunc inCallback, void* inData)
    {
        bool ret = false;

        if (inCallback(inData))
        {
            m_FrameCount++;
            ret = true;
        }

        return ret;
    }

    public int
    compare (TimeoutInterval inTimeoutInterval)
    {
        uint a_delay = 1000 / m_Fps;
        uint b_delay = 1000 / inTimeoutInterval.m_Fps;
        long b_difference;
        int comparison;

        b_difference = ((m_StartTime.tv_sec - inTimeoutInterval.m_StartTime.tv_sec) * 1000
                        + (m_StartTime.tv_usec - inTimeoutInterval.m_StartTime.tv_usec) / 1000);

        comparison = ((int) ((m_FrameCount + 1) * a_delay) -
                      (int) ((inTimeoutInterval.m_FrameCount + 1) * b_delay + b_difference));

        return comparison < 0 ? -1 : comparison > 0 ? 1 : 0;
    }
}

