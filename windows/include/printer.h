#ifndef PRINTER_H_
#define PRINTER_H_

#include <windows.h>
#include <map>
#include <memory>
#include <sstream>
#include <vector>
#include <string>

struct Printer
{
    const std::string name;
    const std::string model;
    const bool isDefault;
    const bool available;

    Printer(std::string name,
            std::string model,
            bool isDefault,
            bool available)
        : name(name),
          model(model),
          isDefault(isDefault),
          available(available) {}
};

class PrintManager
{
private:
    static HANDLE _hPrinter;

public:
    PrintManager(){};
    static std::vector<Printer> listPrinters();
    static BOOL pickPrinter(std::string pPrinterName);
    static BOOL printBytes(std::vector<uint8_t> data);
    static BOOL close();
    operator HANDLE() { return _hPrinter; }
};

#endif // PRINTER_H_
