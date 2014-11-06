// FPDLL.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
const char * MATLAB_PROJECT_DIR = "D:\\Projects\\machine_learning\\ForexPredictor\\FPWithMatlab\\App";

const bool Predict(double x[], double ask, double positions[], double budget, bool& signal, double& take_profit, double& stop_loss, double& volume)
{
	Engine *ep;

	if (!(ep = engOpen("\0"))) {
		fprintf(stderr, "\nCan't start MATLAB engine\n");
		return false;
	}
	return true;
}

const bool Learn(int size, double X[][10], double bid[], double ask[], time_t time[])
{
	Engine *ep;

	if (!(ep = engOpen("\0"))) {
		fprintf(stderr, "\nCan't start MATLAB engine\n");
		return false;
	}
	char s[100];
	sprintf_s(s, "cd('%s');", MATLAB_PROJECT_DIR);
	engEvalString(ep, s);

	// Write the variables
	mxArray *input_X = NULL, *input_bid = NULL, *input_ask = NULL, *input_time = NULL;
	input_X = mxCreateDoubleMatrix(1, 10, mxREAL);
	// memcpy((char *)mxGetPr(T), (char *)time, 10 * sizeof(double));
	engPutVariable(ep, "X", input_X);

	// Call the learn function in Matlab
	engEvalString(ep, "learn(X, bid, ask, time);");

	return true;
}

// ==================================================
// Below functions are used just for testing the DLL:
// ==================================================
const int GetAnswerOfLife()
{
	return 42;
}

const double RunMatlabFunction()
{
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
	sprintf_s(s, "cd('%s');", MATLAB_PROJECT_DIR);
	engEvalString(ep, s);
	engEvalString(ep, "ans = HelloWorld(1);");
	mxArray *ans = engGetVariable(ep, "ans");
	return *mxGetPr(ans);
}
// ==================================================

//---------------------------------------------------------------------------
