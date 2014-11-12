#ifndef MQLH
#define MQLH
struct MqlStr
{
public:
	int    len;
	wchar_t  *string;

	MqlStr() { init(); }
	~MqlStr() { dealloc(); }
	void assign(std::string& str) {
		dealloc();
		string = new wchar_t[str.length() + 1];
		//strncpy_s(string, str.length(), str.c_str(), str.length());
		string = L"test string";
		string[str.length()] = 0;
		len = str.length();
	}
	void dealloc() {
		// if (string != 0) delete[] string; init();
	}
private:
	void init() { string = 0; len = 0; }
	
	void operator= (const MqlStr &);
};
#endif