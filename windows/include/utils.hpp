#ifndef UTILS_H_
#define UTILS_H_

#include <windows.h>
#include <tchar.h>
#include <codecvt>
#include <fstream>
#include <objbase.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <string>

inline std::string toUtf8(std::wstring wstr)
{
    int cbMultiByte =
        WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, NULL, 0, NULL, NULL);
    LPSTR lpMultiByteStr = (LPSTR)malloc(cbMultiByte);
    cbMultiByte = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1,
                                      lpMultiByteStr, cbMultiByte, NULL, NULL);
    std::string ret = lpMultiByteStr;
    free(lpMultiByteStr);
    return ret;
}

inline std::string toUtf8(TCHAR *tstr)
{
#ifndef UNICODE
#error "Non unicode build not supported"
#endif

    if (!tstr)
    {
        return std::string{};
    }

    return toUtf8(std::wstring{tstr});
}

inline std::wstring fromUtf8(std::string str)
{
    auto len = MultiByteToWideChar(CP_UTF8, 0, str.c_str(),
                                   static_cast<int>(str.length()), nullptr, 0);
    if (len <= 0)
    {
        return std::wstring{};
    }

    auto wstr = std::wstring{};
    wstr.resize(len);
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), static_cast<int>(str.length()),
                        &wstr[0], len);

    return wstr;
}

#endif
