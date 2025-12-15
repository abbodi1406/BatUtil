#pragma comment(linker, "/version:1.2") // MUST be in the form of major.minor

#include <windows.h>
#include <setupapi.h>
#include "libs\GetCmdLine.h"

#ifdef USE_LAUNCHINFSECTIONEX
#include <advpub.h>
#undef InstallHinfSection
#define InstallHinfSection LaunchINFSectionEx
#endif

#pragma comment(linker, "/entry:runinf")
void runinf( )
{
	PTSTR pszCmdLine = GetCmdLine();

	if (pszCmdLine && *pszCmdLine)
	{
		InstallHinfSection(NULL, NULL, pszCmdLine, 0);
		ExitProcess(0);
	}

	ExitProcess(1);
}
