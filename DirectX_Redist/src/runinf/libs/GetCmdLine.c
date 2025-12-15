#include <windows.h>

/**
 * GetCmdLine was borrowed from the Microsoft MSVCR90's wincmdln.c, so this is
 * the "official" way to get the [w]WinMain lpCmdLine parameter.
 **/

PTSTR WINAPI GetCmdLine( )
{
	PTSTR pszCmdLine = GetCommandLine();

	if (pszCmdLine)
	{
		BOOLEAN fInQuotes = FALSE;

		/*
		 * Skip past program name (first token in command line).
		 * Check for and handle quoted program name.
		 */
		while (*pszCmdLine > TEXT(' ') || (*pszCmdLine && fInQuotes))
		{
			if (*pszCmdLine == TEXT('\"'))
				fInQuotes = ~fInQuotes;

			++pszCmdLine;
		}

		/*
		 * Skip past any white space preceeding the second token.
		 */
		while (*pszCmdLine && *pszCmdLine <= TEXT(' '))
			++pszCmdLine;
	}

	return(pszCmdLine);
}
