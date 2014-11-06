// FPDLLTest.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

/* Define a function pointer for our imported
* function.
* This reads as "introduce the new type f_funci as the type:
*                pointer to a function returning an int and
*                taking no arguments.
*
* Make sure to use matching calling convention (__cdecl, __stdcall, ...)
* with the exported function. __stdcall is the convention used by the WinAPI
*/
typedef int(__stdcall *f_funci)();
typedef bool(__stdcall *f_funcb)();
typedef double(__stdcall *f_funcd)();

int _tmain(int argc, _TCHAR* argv[])
{
	HINSTANCE hGetProcIDDLL = LoadLibrary(L"C:\\Users\\Jay\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Libraries\\FPDLL.dll");
	if (!hGetProcIDDLL) {
		std::cout << "Library not loaded: " << GetLastError() << std::endl;
		return EXIT_FAILURE;
	}

	if (!testAnswerOfLife(hGetProcIDDLL)) {
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}

int testAnswerOfLife(HINSTANCE hGetProcIDDLL)
{
	f_funci funci = (f_funci)GetProcAddress(hGetProcIDDLL, "GetAnswerOfLife");
	if (!funci) {
		std::cout << "could not locate the function" << std::endl;
		return EXIT_FAILURE;
	}

	int ans = funci();
	std::cout << "Answer of life is " << ans << std::endl;
	return EXIT_SUCCESS;
}
