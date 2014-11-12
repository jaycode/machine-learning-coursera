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

typedef bool(__stdcall *f_Learn)(int size, double X[][10], double bid[], double ask[], time_t time[]);
typedef double(__stdcall *f_funcd)();
typedef void(__stdcall *f_GetLog)(std::wstring logStr);

int _tmain(int argc, _TCHAR* argv[])
{
	HINSTANCE hGetProcIDDLL = LoadLibrary(L"C:\\Users\\Jay\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Libraries\\FPDLL.dll");
	if (!hGetProcIDDLL) {
		std::cout << "Library not loaded: " << GetLastError() << std::endl;
		return EXIT_FAILURE;
	}

	if (!testAnswerOfLife(hGetProcIDDLL)) {
		std::cout << testAnswerOfLife(hGetProcIDDLL) << "failed!" << std::endl;
		return EXIT_FAILURE;
	}

	if (!testLearn(hGetProcIDDLL)) {
		std::cout << "failed!" << std::endl;
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}

bool testLearn(HINSTANCE const &hGetProcIDDLL)
{
	std::cout << "about to learn" << std::endl;
	f_Learn Learn = (f_Learn)GetProcAddress(hGetProcIDDLL, "Learn");
	if (!Learn) {
		std::cout << "could not locate the function" << std::endl;
		return false;
	}
	const int size = 1;
	double X[size][10];
	double bid[size];
	double ask[size];
	time_t time[size];
	bool status = Learn(size, X, bid, ask, time);
	std::cout << "status is " << status << std::endl;
	return status;
}

bool testAnswerOfLife(HINSTANCE const &hGetProcIDDLL)
{
	f_funci funci = (f_funci)GetProcAddress(hGetProcIDDLL, "GetAnswerOfLife");
	if (!funci) {
		std::cout << "could not locate the function" << std::endl;
		return false;
	}

	int ans = funci();
	std::cout << "Answer of life is " << ans << std::endl;

	f_GetLog GetLog = (f_GetLog)GetProcAddress(hGetProcIDDLL, "GetLog");
	std::wstring logStr = L"";
	GetLog(logStr);
	std::wcout << "log: " << logStr << std::endl;

	return true;
}
