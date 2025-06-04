import Vapor
import Vision
import AppKit
import PDFKit
import UniformTypeIdentifiers


/*
The idea is that the route '/upload' will invoke `getFileContents` passing it:
    * The input file (given by `inputPath`, the file loaded by the user).
        This file is placed in the route handler under our Public directory.
    * The directory where to store the resulting output file (`destinationFolderPath``).

The conversion from PDF to TXT goes through a intermediate step: converting the PDF to PNG, and then the PNG to TXT.

The function `getFileContents` will:
1) Generate a png file for each page corresponding to the input PDF, and store them in the folder given by destinationFolderPath.
2) 
*/


// Given:   /Public/2025-0-3-16-06-72-test1.pdf
// Returns: /Public/2025-0-3-16-06-72-test1
func removeFileExtension(_ path: String) -> String? {
    if path.isEmpty || !path.hasSuffix(".pdf") {
        return nil
    }
    return String(path.dropLast(".pdf".count))
}


func getFileContents(inputPath: String, destinationFolderPath: String) -> String {
    var fileContents: String = ""
    //generateOnePngForEachPDFPage(pdfFileName: "/Users/juanignaciobianchi/Downloads/test1.pdf")

    // Generate a png file for each page corresponding to the input PDF, and store them in the folder given by destinationFolderPath.
    let numberOfPages = generateOnePngForEachPDFPage(pdfFileName: inputPath, destinationFolderPath: destinationFolderPath)
    //fromPngToString(fileName: "/Users/juanignaciobianchi/Downloads/UAT/test1-Page1.png")
    if let pathWithoutExtension = removeFileExtension(inputPath) {
        // For example if inputPath = "/Users/.../pdf2txt/Public/2025-54-4-15-06-77-test1.pdf"
        // We want to access the resulting png files, which will be given by the paths:
        // /Users/.../pdf2txt/Public/2025-54-4-15-06-77-test1-Page{i}.png FOR i = 0 .. < NUMBER_OF_PAGES
        // For example the first page: /Users/.../pdf2txt/Public/2025-54-4-15-06-77-test1-Page1.png

        // let pdfPagePngized = pathWithoutExtension + "-Page1.png"
        for pageNumber in 1...numberOfPages {
            let pdfPagePngized = pathWithoutExtension + "-Page\(pageNumber).png"
            print("pdfPagePngized QUEDO: \(pdfPagePngized)")
            fromPngToString(fileName: pdfPagePngized)
        }

        // Read result written by processResults (which is called indirectly by fromPngToString)
        let dirConfig = DirectoryConfiguration.detect()
        let pathToResultString = dirConfig.publicDirectory + "/STRING_RESULT.txt"
        let url = URL(fileURLWithPath: pathToResultString)
        do { 
            fileContents  = try String(contentsOf:url)
        } 
        catch { 
            print("Error thrown while reading file. \(error.localizedDescription)") 
        }
    } else {
        fileContents = "Could not read PDF file :("
    }

    return fileContents
}

func appendStringToFile(_ s: String, _ fileURL: URL) {
  if let data = s.data(using: .utf8) {
    do {
      let fileHandle = try FileHandle(forWritingTo: fileURL)
      fileHandle.seekToEndOfFile()
      fileHandle.write(data)
      fileHandle.closeFile()
    } catch {
      try? data.write(to: fileURL)
    }
  }
}

func processResults(_ recognizedStrings: [String]) {
    var stringResult = ""
    for str in recognizedStrings {
        //print(str)
        stringResult += str
    }
    stringResult += "\n\n" // To delimiter a new page

    print(">>>>>>>> \(stringResult)")

    // Write result:
    let dirConfig = DirectoryConfiguration.detect()
    let pathToResultString = dirConfig.publicDirectory + "/STRING_RESULT.txt"
    let url = URL(fileURLWithPath: pathToResultString)
    //do { 
        //try stringResult.write(to: url, atomically: true, encoding: .utf8) 

        appendStringToFile(stringResult, url)
    /*} catch { 
        print("Error writing: \(error.localizedDescription)") 
    }*/
}

func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations =
            request.results as? [VNRecognizedTextObservation] else {
        return
    }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    // Process the recognized strings.
    processResults(recognizedStrings)
}



func fromPngToString(fileName: String) {
    guard let nsImg = NSImage(byReferencingFile: fileName) else {
        fatalError("missing image!")
    }
    guard let cgImg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("can't convert image")
    }

    // creating request with cgImage
    let handler = VNImageRequestHandler(cgImage: cgImg, options: [:])


    // Vision provides its text-recognition capabilities through VNRecognizeTextRequest, 
    // an image-based request type that finds and extracts text in images.
    let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

    do {
        // Perform the text-recognition request.
        try handler.perform([request])
    } catch {
        print("Unable to perform the requests: \(error).")
    }
}


func convertPDF(at sourceURL: URL, to destinationURL: URL, dpi: CGFloat = 200) throws -> [URL] {
    //let pdfDocument = CGPDFDocument(sourceURL as CFURL)!
    guard let pdfDocument = CGPDFDocument(sourceURL as CFURL) else { print("FAK"); return [] }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

    var urls = [URL](repeating: URL(fileURLWithPath : "/"), count: pdfDocument.numberOfPages)
    DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { i in
        // Page number starts at 1, not 0
        let pdfPage = pdfDocument.page(at: i + 1)!

        let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
        let scale = dpi / 72.0
        let width = Int(mediaBoxRect.width * scale)
        let height = Int(mediaBoxRect.height * scale)

        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.interpolationQuality = .high
        context.setFillColor(.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)
        context.drawPDFPage(pdfPage)

        let image = context.makeImage()!
        let imageName = sourceURL.deletingPathExtension().lastPathComponent
        let imageURL = destinationURL.appendingPathComponent("\(imageName)-Page\(i+1).png")


        let imageDestination = CGImageDestinationCreateWithURL(imageURL as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)

        urls[i] = imageURL
    }
    return urls
}

func generateOnePngForEachPDFPage(pdfFileName: String, destinationFolderPath: String) -> Int {
    let sourceURL = URL(fileURLWithPath: pdfFileName)
    let destinationURL = URL(fileURLWithPath: destinationFolderPath)
    do {
        let urls = try convertPDF(at: sourceURL, to: destinationURL, dpi: 200)
        return urls.count
    } catch {
        //handle error
        print(error)
        return 0
    }
}