#include <windows.h>
#include <fusion.h>
#include <stdio.h>

typedef struct _DllFiles_{
	const WCHAR *Name;
}DllFiles;

typedef HRESULT (__stdcall *CreateAsmCache)(IAssemblyCache **ppAsmCache, DWORD dwReserved);
typedef HRESULT (__stdcall *LoadLibraryShim_PROC)(LPCWSTR szDllName, LPCWSTR szVersion, LPVOID pvReserved, HMODULE *phModDll);

typedef struct _INTERNAL_CONTEXT_{
	HMODULE					hFusionDll;
	HMODULE					hMsCorEE;
	CreateAsmCache			CreateAssemblyCache;
	LoadLibraryShim_PROC	LoadLibraryShim;
	IAssemblyCache* Cache;
}INTERNAL_CONTEXT, *LPINTERNAL_CONTEXT;

void __stdcall GacReleaseContext(LPINTERNAL_CONTEXT* RefContext){

	if(*RefContext == NULL)
		return;

	LPINTERNAL_CONTEXT Context = *RefContext;

	if(Context->hFusionDll != NULL)
		FreeLibrary(Context->hFusionDll);

	if(Context->hMsCorEE != NULL)
		FreeLibrary(Context->hMsCorEE);

	memset(Context, 0, sizeof(INTERNAL_CONTEXT));

	LocalFree(Context);

	*RefContext = NULL;
}

LPINTERNAL_CONTEXT __stdcall GacCreateContext(){
	LPINTERNAL_CONTEXT	Result = NULL;

	if((Result = (LPINTERNAL_CONTEXT)LocalAlloc(LPTR, sizeof(INTERNAL_CONTEXT))) == NULL)
		return NULL;

	memset(Result, 0, sizeof(INTERNAL_CONTEXT));

	if((Result->hMsCorEE = LoadLibrary(L"mscoree.dll")) == NULL)
		goto ERROR_ABORT;

	if((Result->LoadLibraryShim = (LoadLibraryShim_PROC)GetProcAddress(Result->hMsCorEE, "LoadLibraryShim")) == NULL)
		goto ERROR_ABORT;

	Result->LoadLibraryShim(L"fusion.dll", 0, 0, &Result->hFusionDll);

	if(Result->hFusionDll == NULL)
		goto ERROR_ABORT;

	if((Result->CreateAssemblyCache = (CreateAsmCache)GetProcAddress(Result->hFusionDll, "CreateAssemblyCache")) == NULL)
		goto ERROR_ABORT;

	if (!SUCCEEDED(Result->CreateAssemblyCache(&Result->Cache, 0)))
		goto ERROR_ABORT;

	return Result;

ERROR_ABORT:
	
	GacReleaseContext(&Result);

	return NULL;
}

extern "C" void __cdecl RunMain()
{
	LPINTERNAL_CONTEXT pContext = GacCreateContext();

	if (pContext == NULL)
		ExitProcess(1);

	const WCHAR DLL_SUFFIX[] = L", Culture=neutral, PublicKeyToken=31bf3856ad364e35";
	const WCHAR DLL_PREFIX[] = L"Microsoft.DirectX";
	const WCHAR DLL_2902MN[] = L", Version=1.0.2902.0";
	const WCHAR DLL_2902AV[] = L".AudioVideoPlayback, Version=1.0.2902.0";
	const WCHAR DLL_2902DG[] = L".Diagnostics, Version=1.0.2902.0";
	const WCHAR DLL_2902DD[] = L".Direct3D, Version=1.0.2902.0";
	const WCHAR DLL_2902DR[] = L".DirectDraw, Version=1.0.2902.0";
	const WCHAR DLL_2902DI[] = L".DirectInput, Version=1.0.2902.0";
	const WCHAR DLL_2902DP[] = L".DirectPlay, Version=1.0.2902.0";
	const WCHAR DLL_2902DS[] = L".DirectSound, Version=1.0.2902.0";
	const WCHAR DLL_2902DX[] = L".Direct3DX, Version=1.0.2902.0";
	const WCHAR DLL_2903DX[] = L".Direct3DX, Version=1.0.2903.0";
	const WCHAR DLL_2904DX[] = L".Direct3DX, Version=1.0.2904.0";
	const WCHAR DLL_2905DX[] = L".Direct3DX, Version=1.0.2905.0";
	const WCHAR DLL_2906DX[] = L".Direct3DX, Version=1.0.2906.0";
	const WCHAR DLL_2907DX[] = L".Direct3DX, Version=1.0.2907.0";
	const WCHAR DLL_2908DX[] = L".Direct3DX, Version=1.0.2908.0";
	const WCHAR DLL_2909DX[] = L".Direct3DX, Version=1.0.2909.0";
	const WCHAR DLL_2910DX[] = L".Direct3DX, Version=1.0.2910.0";
	const WCHAR DLL_2911DX[] = L".Direct3DX, Version=1.0.2911.0";

	DllFiles DllList[] =
	{
		{ DLL_2902MN },
		{ DLL_2902AV },
		{ DLL_2902DG },
		{ DLL_2902DD },
		{ DLL_2902DR },
		{ DLL_2902DI },
		{ DLL_2902DP },
		{ DLL_2902DS },
		{ DLL_2902DX },
		{ DLL_2903DX },
		{ DLL_2904DX },
		{ DLL_2905DX },
		{ DLL_2906DX },
		{ DLL_2907DX },
		{ DLL_2908DX },
		{ DLL_2909DX },
		{ DLL_2910DX },
		{ DLL_2911DX },
		{ NULL }
	};

	FUSION_INSTALL_REFERENCE InstallInfo;
	memset(&InstallInfo, 0, sizeof(InstallInfo));
	InstallInfo.cbSize = sizeof(InstallInfo);
	InstallInfo.dwFlags = 0;
	InstallInfo.guidScheme = FUSION_REFCOUNT_OPAQUE_STRING_GUID;
	InstallInfo.szIdentifier = L"{75339C8C-B4BA-463B-BAC7-975FCA2F89D9}";
	InstallInfo.szNonCannonicalData = L"DirectX for Managed Code";

	for (int i = 0; i < 18; i++)
	{
		WCHAR* pszAFP = (WCHAR*)LocalAlloc(LPTR, MAX_PATH);
		lstrcatW(pszAFP, DLL_PREFIX);
		lstrcatW(pszAFP, DllList[i].Name);
		lstrcatW(pszAFP, DLL_SUFFIX);
		pContext->Cache->UninstallAssembly(0, pszAFP, &InstallInfo, NULL);
		LocalFree(pszAFP);
	}

	GacReleaseContext(&pContext);
	ExitProcess(0);
}
