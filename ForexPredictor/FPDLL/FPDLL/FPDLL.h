#ifndef FPDLLH
#define FPDLLH

// Be careful of the difference between ifndef and ifdef!
#ifdef __cplusplus
extern "C"
{
#endif
	__declspec (dllexport) const int GetAnswerOfLife();
	__declspec (dllexport) const double RunMatlabFunction();
	__declspec (dllexport) const bool Predict(time_t time, double ask, double positions[], double budget, bool& signal, double& take_profit, double& stop_loss, double& volume);
	__declspec (dllexport) const bool Learn(int size, double X[][10], double bid[], double ask[], time_t time[]);
#ifdef __cplusplus
}
#endif

#endif