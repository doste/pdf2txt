# pdf2txt

pdf2txt is a simple command-line utility for extracting text from PDF files. Implemented in C++ and Swift.

## Build:
```sh
mkdir build
cd build
cmake -GNinja ..
ninja
```
## Usage:

Invoke `./src/pdf2txt` passing it as argument a path to a folder containing all the PDFs to analyze.
Add `--show-output` to the command if you would like to see the output as is generated.
The extracted output text will be put in a folder called OutputText.


## Implementation:

It iterates over each PDF file in the input folder, calling the function `pdf2txt` on each file.

The function `pdf2txt` is implemented using a "fast path" and "slow path".
It checks if the PDF can be parsed using the Poppler C++ library, which is really fast. This path will be taken only if the PDF is not image-based. If it can extract the text this way, done.
 If it can't, it will fall back to use OCR, relying on the Tesseract library. This way is slower.

For this slow path, we use the function `applyOcr` which works by first generating a PNG file for each page of the input PDF.
This convertion is done in Swift, by using the `SwiftPNGGenerator::generatePngFolder` function. Those generated PNGs are saved in the `pngs_generated_from_pdf` folder. 
 Then, in the `applyOcr` we use Tesseract to extract the text from the PNG files.

The output extracted text will be put in a folder called "OutputText", in a text called like the PDF input file with "_output_text.txt" at the end.

All the implementation is done in C++ and the converting from PDF to PNGs is done in Swift.

