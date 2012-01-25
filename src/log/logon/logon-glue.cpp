//
// logon-glue.c
//
// January 24, 2012
//
// Logon C wrapper
//
// Copyright (c) 2012 by SuperSonic Imagine
// Confidential - All Rights Reserved
//

#include <stdarg.h>
#include "logon.h"

#ifdef __cplusplus
extern "C"
{
#endif

void
logon_init ()
{
    logon::init ();
}

void
logon_release ()
{
    logon::release ();
}

void
logon_engine_create (const char* inConfFile, const char* inProcess, unsigned int inSession, unsigned int inPid, const char* inHost, unsigned int inPort, gboolean inResolveHost)
{
    logon::CLogEngine::create (inConfFile, inProcess, inSession, inPid, inHost, inPort, inResolveHost);
}

void
logon_error (const char* inModule, const char* inCategory, const char* inMessage, ...)
{
    va_list args;
    char *formatted;

    va_start (args, inMessage);
    formatted = g_strdup_vprintf (inMessage, args);
    va_end (args);

    logon::logon()->error (inModule, inCategory, formatted);
}

void
logon_warning (const char* inModule, const char* inCategory, const char* inMessage, ...)
{
    va_list args;
    char *formatted;

    va_start (args, inMessage);
    formatted = g_strdup_vprintf (inMessage, args);
    va_end (args);

    logon::logon()->warning (inModule, inCategory, formatted);
}

void
logon_info (const char* inModule, const char* inCategory, const char* inMessage, ...)
{
    va_list args;
    char *formatted;

    va_start (args, inMessage);
    formatted = g_strdup_vprintf (inMessage, args);
    va_end (args);

    logon::logon()->info (inModule, inCategory, formatted);
}

void
logon_notice (const char* inModule, const char* inCategory, const char* inMessage, ...)
{
    va_list args;
    char *formatted;

    va_start (args, inMessage);
    formatted = g_strdup_vprintf (inMessage, args);
    va_end (args);

    logon::logon()->notice (inModule, inCategory, formatted);
}

void
logon_debug (const char* inModule, const char* inCategory, const char* inMessage, ...)
{
    va_list args;
    char *formatted;

    va_start (args, inMessage);
    formatted = g_strdup_vprintf (inMessage, args);
    va_end (args);

    logon::logon()->debug (inModule, inCategory, formatted);
}

#ifdef __cplusplus
}
#endif

