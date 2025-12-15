#ifndef __GETCMDLINE_H__
#define __GETCMDLINE_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <windows.h>

/**
 * GetCmdLine returns a TCHAR string equivalent WinMain's lpCmdLine
 **/

PTSTR WINAPI GetCmdLine( );

#ifdef __cplusplus
}
#endif

#endif
