//
// logon-glue.h
//
// January 24, 2012
//
// Logon C wrapper
//
// Copyright (c) 2012 by SuperSonic Imagine
// Confidential - All Rights Reserved
//

#include <glib.h>

#ifndef __LOGON_GLUE_H__
#define __LOGON_GLUE_H__

#ifdef __cplusplus
extern "C"
{
#endif

void logon_init ();
void logon_release ();
void logon_engine_create (const char* inConfFile, const char* inProcess, unsigned int inSession, unsigned int inPid, const char* inHost, unsigned int inPort, gboolean inResolveHost);
void logon_error (const char* inModule, const char* inCategory, const char* inMessage, ...);
void logon_warning (const char* inModule, const char* inCategory, const char* inMessage, ...);
void logon_info (const char* inModule, const char* inCategory, const char* inMessage, ...);
void logon_notice (const char* inModule, const char* inCategory, const char* inMessage, ...);
void logon_debug (const char* inModule, const char* inCategory, const char* inMessage, ...);

#ifdef __cplusplus
}
#endif

#endif

