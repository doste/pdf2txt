
#include "include/pdf2txt.hpp"
#include <pdf2txt/include/pdf2txt.hpp>

#include </opt/homebrew/Cellar/tesseract/5.5.1/include/tesseract/baseapi.h>
#include </opt/homebrew/Cellar/leptonica/1.85.0/include/leptonica/allheaders.h>
//#include <tesseract/baseapi.h>
//#include <leptonica/allheaders.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc.hpp>
#include <poppler-document.h>
#include <poppler-page.h>
#include <poppler-toc.h>

#include <iostream>
#include <fstream>
#include <filesystem>

/// HELPER FUNCTIONS

void cleanFolder(std::string pathToFolderToClean) {
    const std::filesystem::path dir_path{pathToFolderToClean};
    for (auto& path: std::filesystem::directory_iterator(dir_path)) {
        std::filesystem::remove_all(path);
    }
}

void saveOutputTextToFile(std::string outputPath, std::string outputText) {
    std::ofstream outputFile;
    outputFile.open(outputPath);
    outputFile << outputText << std::endl;
    outputFile.close();
    std::cout << "Saving extracted text in " << outputPath << std::endl;
}

std::string getFileNameFromFilePath(std::string filePath) {
    return std::filesystem::path(filePath).stem();
}

void createDirectoryNamed(std::string nameOfDirectory) {
    std::filesystem::create_directory(nameOfDirectory);
}


///////////////// OCR Tesseract

// Fallback, if applyPoppler didn't work.
void applyOcr(PdfFile* inputPdf, std::string pathToOutputFolder, bool showingOutput) {
    std::string outText;
    std::string imPath;
 
    // Create Tesseract object
    tesseract::TessBaseAPI *ocr = new tesseract::TessBaseAPI();
   
    // Initialize OCR engine to use English (eng) and The LSTM OCR engine.
    ocr->Init(NULL, "eng", tesseract::OEM_DEFAULT);  // PArece que con OEM_LSTM_ONLY funca tambien
   
    // Set Page segmentation mode to PSM_AUTO (3)
    ocr->SetPageSegMode(tesseract::PSM_AUTO);
 
    // Generate the PNGs from the PDF
    std::string pathToFolderContainingPngsFromPdf = "pngs_generated_from_pdf/";
    createDirectoryNamed(pathToFolderContainingPngsFromPdf);
    SwiftPNGGenerator::generatePngFolder(inputPdf->path, pathToFolderContainingPngsFromPdf);

    for (int i = 1; i <= inputPdf->numberOfPages; i++) {
        std::string imPathToPng_i = inputPdf->name + "-Page" + std::to_string(i) + ".png";
        imPath = pathToFolderContainingPngsFromPdf + imPathToPng_i;

        cv::Mat im = cv::imread(imPath, cv::IMREAD_COLOR);
    
        // Set image data
        ocr->SetImage(im.data, im.cols, im.rows, 3, im.step);
        
        // Run Tesseract OCR on image
        outText += std::string(ocr->GetUTF8Text());

        if (showingOutput) {
            std::cout << outText << std::endl;
        }
    }

    std::string outputPath = pathToOutputFolder + "/" + inputPdf->name + "_output_text.txt";
    saveOutputTextToFile(outputPath, outText);

    //std::cout << outText << std::endl;

    // Destroy used object and release memory
    ocr->End();

    cleanFolder(pathToFolderContainingPngsFromPdf);
}

///////////////// POPPLER

std::string to_utf8(poppler::ustring x) {
    if (x.length()) {
        poppler::byte_array buf = x.to_utf8();
        return std::string(buf.data(), buf.size());
    } else {
        return std::string("null");
    }
}

// Fast path.
// Independently if the text could be extracted or not, Poppler gives us the number of pages in the PDF file.
// So we modify the PdfFile object we receive as argument: we set its numberOfPages field accordingly.
// This functions returns a boolean indicating if the text extraction could be done or not.
bool applyPoppler(PdfFile* inputPdf, std::string pathToOutputFolder, bool showingOutput) {

    bool textCouldBeExtracted;

    poppler::document *doc = poppler::document::load_from_file(inputPdf->path, "", "");
    if (!doc) {
        throw std::runtime_error("Failed to read pdf file");
    }

    std::string outText = "";
    for(int i = 0; i < doc->pages(); i++) {
        poppler::page* Page_i(doc->create_page(i));
        if (!Page_i) {
            throw std::runtime_error("Failed to create page at index " + std::to_string(i));
        }
        outText += to_utf8(Page_i->text());
    }
    inputPdf->numberOfPages = doc->pages();

    // TODO: Improve this heuristic, to check if the text extraction succedeed.
    if(std::all_of(outText.begin(), outText.end(), isspace)) { // Could not extract text, return false.
        return false;
    } else {
        std::string outputPath = pathToOutputFolder + "/" + inputPdf->name + "_output_text.txt";
        saveOutputTextToFile(outputPath, outText);

        if (showingOutput) {
            std::cout << outText << std::endl;
        }

        return true;
    }
}


void pdf2txt(std::string inputPdfPath, bool showingOutput) {

    std::string fileName = getFileNameFromFilePath(inputPdfPath);

    PdfFile* inputPdf = new PdfFile;
    *inputPdf = {fileName, inputPdfPath, 0};

    std::string pathToFolderContainingOutputText = "OutputTexts";
    createDirectoryNamed(pathToFolderContainingOutputText);

    std::cout << "------- Extracting text from PDF file '" << fileName << "' -------" << std::endl;
    bool textCouldBeExtracted = applyPoppler(inputPdf, pathToFolderContainingOutputText, showingOutput);
    
    if (textCouldBeExtracted) {
        std::cout << "Text could be extracted the fast way!" << std::endl;
    } else {
        std::cout << "Text could not be extracted. Invoking slow path: Applying OCR on the file." << std::endl;
        applyOcr(inputPdf, pathToFolderContainingOutputText, showingOutput);
    }
    std::cout << std::endl;
}
