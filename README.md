# pdf2txt

pdf2txt is a simple tool for extracting text from PDF files. Implemented in Swift.

The web backend and frontend are built with Vapor.
The OCR logic is implemented using [Apple's Vision framework](https://developer.apple.com/documentation/vision/).

## Requirements:
- [Swift](https://www.swift.org/)
- [Vapor](https://docs.vapor.codes/)

## Usage:
Clone this repo and then inside the pdf2txt folder, run `swift run`.
The server should be up and running :)

## Credits:

[Converting PDF to Images in Swift: A Step-by-Step Guide](https://medium.com/@swift3.0devlopment/converting-pdf-to-images-in-swift-a-step-by-step-guide-3d7129a14165)

[File upload using Vapor 4](https://theswiftdev.com/file-upload-using-vapor-4/)


### TODO:
    - Validate the input file. Now we are saving to our Public folder whatever the user gives us. The only validation in place
    is to check wheter is a PDF file or not. We should have a stronger validation.
    - Remove files from the Public folder after they are used.
    - Improve the OCR for PDF files containing images.
    - Avoid using deprecated methods from the Vapor framework. For example, fileio.openFile(...)