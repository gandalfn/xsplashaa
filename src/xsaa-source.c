/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * xsaa-source.c
 * Copyright (C) Nicolas Bruguier 2010 <gandalfn@club-internet.fr>
 * 
 * cairo-compmgr is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * cairo-compmgr is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "xsaa-source.h"

struct _XSAASource
{
    GSource m_Source;
    XSAASourceFuncs m_Funcs;
    gpointer m_Data;
};

static gboolean
xsaa_source_prepare (GSource* inSource, gint* outTimeout)
{
    XSAASource* source = (XSAASource*) inSource;

    *outTimeout = -1;

    if (source->m_Funcs.prepare)
        return source->m_Funcs.prepare(source->m_Data, outTimeout);
    else
        return FALSE;
}

static gboolean
xsaa_source_check (GSource* inSource)
{
    XSAASource* source = (XSAASource*) inSource;

    if (source->m_Funcs.check)
        return source->m_Funcs.check(source->m_Data);
    else
        return FALSE;
}

static gboolean
xsaa_source_dispatch (GSource* inSource, GSourceFunc inCallback, gpointer inUserData)
{
    XSAASource* source = (XSAASource*) inSource;
    gboolean ret = FALSE;

    g_source_ref (inSource);
    if (source->m_Funcs.dispatch)
        ret = source->m_Funcs.dispatch(source->m_Data, inCallback, inUserData);
    g_source_unref (inSource);

    return ret;
}

static void
xsaa_source_finalize (GSource* inSource)
{
    XSAASource* source = (XSAASource*) inSource;

    if (source->m_Funcs.finalize)
        source->m_Funcs.finalize(source->m_Data);
}

static GSourceFuncs s_XSAASourceFuncs = {
    xsaa_source_prepare,
    xsaa_source_check,
    xsaa_source_dispatch,
    xsaa_source_finalize,
};

XSAASource* 
xsaa_source_new (XSAASourceFuncs inFuncs, gpointer inData) 
{
    g_return_val_if_fail(inData != NULL, NULL);

    XSAASource* self;

    self = (XSAASource*)g_source_new (&s_XSAASourceFuncs, sizeof (XSAASource));
    self->m_Funcs = inFuncs;
    self->m_Data = inData;

    return self;
}


XSAASource* 
xsaa_source_new_from_pollfd (XSAASourceFuncs inFuncs, GPollFD* inpFd,
                             gpointer inData) 
{
    g_return_val_if_fail(inpFd != NULL, NULL);
    g_return_val_if_fail(inData != NULL, NULL);

    XSAASource* self;

    self = (XSAASource*)g_source_new (&s_XSAASourceFuncs, sizeof (XSAASource));
    self->m_Funcs = inFuncs;
    self->m_Data = inData;
    g_source_add_poll ((GSource*) self, inpFd);
    g_source_set_can_recurse ((GSource*) self, TRUE);

    return self;
}

XSAASource*
xsaa_source_ref (XSAASource* self)
{
    g_return_val_if_fail(self != NULL, NULL);

    g_source_ref ((GSource*)self);

    return self;
}

void
xsaa_source_unref (XSAASource* self)
{
    g_return_if_fail(self != NULL);

    g_source_unref ((GSource*)self);
}

void
xsaa_source_destroy (XSAASource* self)
{
    g_return_if_fail(self != NULL);

    g_source_destroy ((GSource*)self);
}
