import AppKit
import PDFKit

public func sayHello() {
    print("Hello from Swift")
}

func convertPDF(at sourceURL: URL, to destinationURL: URL, dpi: CGFloat = 200) throws -> [URL] {
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


public func generatePngFolder(pathToInputPdf: String, pathToOutputPngsFolder: String) {
    //if CommandLine.arguments.count == 3 {
        //let pathToInputPdf = String(CommandLine.arguments[1])
        //let pathToOutputPngsFolder = String(CommandLine.arguments[2])
        do {
            /*
            let urls = try convertPDF(at: URL(fileURLWithPath: "/Users/juanignaciobianchi/Downloads/test2.pdf"),
                                    to: URL(fileURLWithPath: "/Users/juanignaciobianchi/devdev/pdf2txtToma2/PostaCpp/pngs_generated_from_pdf"),
                                    dpi: 200)*/
            let urls = try convertPDF(at: URL(fileURLWithPath: pathToInputPdf),
                                                    to: URL(fileURLWithPath: pathToOutputPngsFolder),
                                                    dpi: 200)
            //print(urls.count)
        } catch {
            print(error)
        }
    
}
