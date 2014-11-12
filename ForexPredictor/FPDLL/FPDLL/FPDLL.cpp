// FPDLL.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"

ForexPredictor fp;
Logger logger;

const bool Predict(double x[], double ask, double positions[], double budget, bool& signal, double& take_profit, double& stop_loss, double& volume)
{
	fp.Init();
	Engine *ep;

	if (!(ep = engOpen("\0"))) {
		fprintf(stderr, "\nCan't start MATLAB engine\n");
		return false;
	}
	return true;
}

const bool Learn(int size, double X[][15], double bid[], double ask[], time_t times[])
// const bool Learn(int size, double X[][15])
{
	logger << L"Start Learning\n";
	logger << L"First bid: " << bid[0] << L"\n";
	logger << L"First ask: " << ask[0] << L"\n";
	logger << L"First time: " << times[0] << L"\n";
	fp.Init();
	return fp.Learn(size, X, bid, ask, times);
}

// Make sure to pass L"" otherwise weird things would happen (i.e. buffer not cleared).
const void GetLog(wchar_t *log_str = L"")
{
	//--- parameters check
	if (log_str == NULL) return;
	//--- replace it
	memcpy(log_str, logger.read().c_str(), wcslen(logger.read().c_str())*sizeof(wchar_t)+1);
	logger.clear();
}

const void GetLog(std::wstring log_str)
{
	log_str = logger.read();
}

// ==================================================
// Below functions are used just for testing the DLL:
// ==================================================
const int GetAnswerOfLife()
{
	fp.Init();
	logger << L"Just got an answer of life.";
	return 42;
}

const double RunMatlabFunction()
{
	fp.Init();
	Engine *ep;

	/*
	* Start the MATLAB engine locally by executing the string
	* "matlab".
	*
	* To start the session on a remote host, use the name of
	* the host as the string rather than \0.
	*
	* For more complicated cases, use any string with whitespace,
	* and that string will be executed literally to start MATLAB.
	*/
	if (!(ep = engOpen("\0"))) {
		fprintf(stderr, "\nCan't start MATLAB engine\n");
		return EXIT_FAILURE;
	}

	mxArray *T = NULL, *result = NULL;
	char s[100];
	sprintf_s(s, "cd('%s');", fp.MATLAB_PROJECT_DIR);
	engEvalString(ep, s);
	engEvalString(ep, "ans = HelloWorld(1);");
	mxArray *ans = engGetVariable(ep, "ans");
	return *mxGetPr(ans);
}


void StringTest(wchar_t *str)
{
	str = L"test";
}

void fnReplaceString(wchar_t *text, wchar_t *from, wchar_t *to)
{
	wchar_t *cp;
	//--- parameters check
	if (text == NULL || from == NULL || to == NULL) return;
	if (wcslen(from) != wcslen(to))             return;
	//--- search for substring
	if ((cp = wcsstr(text, from)) == NULL)         return;
	//--- replace it
	memcpy(cp, to, wcslen(to)*sizeof(wchar_t));
}
// ==================================================

//---------------------------------------------------------------------------