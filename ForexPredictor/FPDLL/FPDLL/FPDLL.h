#ifndef FPDLLH
#define FPDLLH

// Be careful of the difference between ifndef and ifdef!
#ifdef __cplusplus
extern "C"
{
#endif
	__declspec (dllexport) const bool Predict(time_t time, double ask, double positions[], double budget, bool& signal, double& take_profit, double& stop_loss, double& volume);
	__declspec (dllexport) const bool Learn(int size, double X[][15], double bid[], double ask[], time_t times[]);
	// __declspec (dllexport) const bool Learn(int size, double X[][15]);
	__declspec (dllexport) const void GetLog(wchar_t *log);
	
	// Test functions //
	__declspec (dllexport) const int GetAnswerOfLife();
	__declspec (dllexport) const double RunMatlabFunction();
	__declspec (dllexport) void StringTest(wchar_t *str);
	__declspec (dllexport) void fnReplaceString(wchar_t *text, wchar_t *from, wchar_t *to);

#ifdef __cplusplus
}
#endif

#endif