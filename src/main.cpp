//#include <Interop/Interop-swift.h>
//#include <pdf2txt/include/pdf2txt.hpp>
#include "include/pdf2txt.hpp"
#include <iostream>
#include <string>
#include <filesystem>


int main(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error("Use pdf folder path as parameter. Add --show-output if you would like to see the output as is generated.");
    }

    std::string pathToFolderContainingPdfs = argv[1];

    bool showingOutput = false;
    if (argc == 3) {
        std::string showOutputCmdOption = argv[2];
        if (showOutputCmdOption == "--show-output") {
            showingOutput = true;
        }
    }

    // Iterate over each file in the input folder:
    for (const auto& entry : std::filesystem::directory_iterator(pathToFolderContainingPdfs)) {
        if (entry.path().extension() == ".pdf") {

            std::string pathToInputPdf = entry.path();
            
            // Call the main function on each PDF file:
            pdf2txt(pathToInputPdf, showingOutput);

        } else {
            std::cout << entry.path().filename() << " is an invalid type." << std::endl;
            continue;
        }
    }

    return 0;
}