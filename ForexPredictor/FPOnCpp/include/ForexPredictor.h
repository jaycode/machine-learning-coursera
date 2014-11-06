#ifndef ForexPredictorH
#define ForexPredictorH

#ifdef __cplusplus
extern "C"
{
#endif
    __declspec (dllexport) const int Init();
    __declspec (dllexport) const int Learn();
    __declspec (dllexport) const int Predict();
#ifdef __cplusplus
}
#endif

#endif