#ifndef STDAFXH
#define STDAFXH

#pragma once


#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>

#include <iostream>
#include <cstdlib>
#include <string>
#include <sstream> // needed in Logger.h for wstringstream
#include "engine.h"
#define  BUFSIZE 256

// #include "mql.h"
#include "Logger.h"
#include "ForexPredictor.h"
#include "FPDLL.h"

#endif