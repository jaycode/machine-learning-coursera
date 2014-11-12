#ifndef ForexPredictorH
#define ForexPredictorH

#ifdef __cplusplus
extern "C"
{
#endif	
	class ForexPredictor {
	public:
		const char * MATLAB_PROJECT_DIR = "D:\\Projects\\machine_learning\\ForexPredictor\\FPWithMatlab\\App";
		bool loggerConfigured = false;
		void Init();
		bool Learn(int size, double X[][15], double bid[], double ask[], time_t times[]);
		std::string GetDLLDir();
	};

#ifdef __cplusplus
}
#endif

#endif