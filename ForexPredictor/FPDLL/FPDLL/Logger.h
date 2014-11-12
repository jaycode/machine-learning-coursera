class Logger
{
private:
	std::wstringstream buffer;
public:
	template <class T>
	Logger &operator<<(const T &x) {
		buffer << x;
		return *this;
	}
	// Logger operator<<(Logger &logger, std::wstring text) { buffer += text + L"\n"; return logger; };
	std::wstring read() { return buffer.str(); };
	void clear() { buffer.str(std::wstring()); };
};