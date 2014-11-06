#include <windows.h>
#include <iostream>
#include <cstdlib>

struct DllHandle
{
  DllHandle(const char * const filename)
    : h(LoadLibrary(filename)) {}
  ~DllHandle() { if (h) FreeLibrary(h); }
  const HINSTANCE Get() const { return h; }

  private:
  HINSTANCE h;
};

int main()
{
  //Obtain a handle to the DLL
  const DllHandle h("bin/functions.DLL");
  if (!h.Get())
  {
    MessageBox(0,"Could not load DLL","UnitCallDll",MB_OK);
    return 1;
  }

  //Obtain a handle to the Init function
  typedef const int (*InitFunction)();
  const InitFunction Init
    = reinterpret_cast<InitFunction>(
      GetProcAddress(h.Get(),"Init")); 

  typedef const int (*LearnFunction)();
  const LearnFunction Learn
    = reinterpret_cast<LearnFunction>(
      GetProcAddress(h.Get(),"Learn")); 

  typedef const int (*PredictFunction)();
  const PredictFunction Predict
    = reinterpret_cast<PredictFunction>(
      GetProcAddress(h.Get(),"Predict")); 

  if (!Init) //No handle obtained
  {
    std::cout << "Loading init failed";
    return 1;
  }

  if (Init() != 1)
  {
    std::cout << "Function init failed";
    return 1;
  }
  else
  {
    std::cout << "DLL loaded";
    // Put test code here
    std::cout << endl;
    
  }
}