#include "stdafx.h"

void ForexPredictor::Init() {

}

bool ForexPredictor::Learn(int size, double X[][15], double bid[], double ask[], time_t times[]) {
	Engine *ep;

	if (!(ep = engOpen("\0"))) {
		fprintf(stderr, "\nCan't start MATLAB engine\n");
		return false;
	}
	char s[100];
	sprintf_s(s, "cd('%s');", MATLAB_PROJECT_DIR);
	std::cout << "s is " << s << std::endl;
	engEvalString(ep, s);

	// Write the variables
	mxArray *input_X = NULL, *input_bid = NULL, *input_ask = NULL, *input_time = NULL;
	input_X = mxCreateDoubleMatrix(1, 10, mxREAL);
	memcpy((char *)mxGetPr(input_X), (char *)X, 10 * sizeof(double));
	engPutVariable(ep, "X", input_X);

	// Call the learn function in Matlab
	engEvalString(ep, "ans = learn(X);");
	mxArray *ans = engGetVariable(ep, "ans");
	std::cout << "returned ans: " << ans << std::endl;
	std::cout << "returned val: " << *mxGetPr(ans) << std::endl;
	return *mxGetPr(ans);
}

std::string ForexPredictor::GetDLLDir() {
	char path[MAX_PATH];
	HMODULE hm = NULL;
	if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
		GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		(LPCSTR)"Learn",
		&hm))
	{
		int ret = GetLastError();
		fprintf(stderr, "GetModuleHandle returned %d\n", ret);
	}
	GetModuleFileNameA(hm, path, sizeof(path));

	std::string::size_type pos = std::string(path).find_last_of("\\/");
	return std::string(path).substr(0, pos);
}