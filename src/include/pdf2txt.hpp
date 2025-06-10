#ifndef pdf2txt_hpp
#define pdf2txt_hpp

#include <string>


struct PdfFile {
    std::string name;
    std::string path;
    int numberOfPages;
};

void applyOcr(PdfFile* inputPdf, std::string pathToOutputFolder, bool showingOutput);

bool applyPoppler(PdfFile* inputPdf, std::string pathToOutputFolder, bool showingOutput);

void pdf2txt(std::string inputPdf, bool showingOutput);

#endif