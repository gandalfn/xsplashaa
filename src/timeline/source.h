/* source.h
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

#ifndef __XSAA_SOURCE_H__
#define __XSAA_SOURCE_H__

#include <glib.h>

G_BEGIN_DECLS

typedef struct _XSAASource XSAASource;
typedef struct _XSAASourceFuncs XSAASourceFuncs;

struct _XSAASourceFuncs
{
    gboolean (*prepare)  (gpointer inData,
                          gint* inTimeout);
    gboolean (*check)    (gpointer inData);
    gboolean (*dispatch) (gpointer inData,
                          GSourceFunc inCallback,
                          gpointer inUserData);
    void     (*finalize) (gpointer inData);
};

XSAASource* xsaa_source_new              (XSAASourceFuncs inFunc,
                                          gpointer inData);
XSAASource* xsaa_source_new_from_pollfd  (XSAASourceFuncs inFunc,
                                          GPollFD* inpFd,
                                          gpointer inData);
XSAASource* xsaa_source_ref              (XSAASource* self);
void        xsaa_source_unref            (XSAASource* self);
void        xsaa_source_destroy          (XSAASource* self);

G_END_DECLS

#endif /* __XSAA_SOURCE_H__ */

