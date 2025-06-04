import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("hola") { req async throws -> View in
        return try await req.view.render("hello", ["name": "juani"])
    }

    app.get("upload") { req async throws -> View in
        return try await req.view.render("file_upload")
    }

    app.post("upload") { req -> EventLoopFuture<View> in
        struct Input: Content {
            var file: File
        }
        struct UploadContext: Encodable {
            var fileName: String
            var isValid: Bool
            var fileContents: [String]   // Each string of this array will corresponds to each page of the PDF
        }

        let input = try req.content.decode(Input.self)

        guard input.file.data.readableBytes > 0 else {
            throw Abort(.badRequest)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "y-m-d-HH-MM-SS-"
        let prefix = formatter.string(from: .init())
        let fileName = prefix + input.file.filename
        let path = app.directory.publicDirectory + fileName
        //let isFileValid = ["txt"].contains(input.file.extension?.lowercased())
        //let isPdf = ["pdf"].contains(input.file.extension?.lowercased())
        //let isFileValid = input.file.extension?.lowercased() == "txt"
        let isFileValid = ["txt", "pdf"].contains(input.file.extension?.lowercased())

        if isFileValid {
            return req.application.fileio.openFile(path: path,
                                                mode: .write,
                                                //flags: .allowFileCreation(posixMode: 0x744),
                                                flags: .allowFileCreation(posixMode: 0o600),
                                                eventLoop: req.eventLoop)
                .flatMap { handle in
                        req.application.fileio.write(fileHandle: handle,
                                                buffer: input.file.data,
                                                eventLoop: req.eventLoop)
                        .flatMapThrowing { _ in
                            try handle.close()
                        }
                        .flatMap {
                            //req.view.render("file_upload_result", UploadContext(fileName: fileName, isValid: isFileValid, fileContents: getFileContents(inputPath: path, destinationFolderPath: app.directory.publicDirectory)))
                            req.view.render("file_upload_result", UploadContext(fileName: fileName, isValid: isFileValid, fileContents: getFileContents(inputPath: path, destinationFolderPath: app.directory.publicDirectory)))
                        }
                }

        } else {
            return req.view.render("file_upload_result", UploadContext(fileName: fileName, isValid: isFileValid, fileContents: [""]))
        }
        
    }
}
