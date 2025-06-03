import Vapor


func getFileContents(path: String) -> String {
        print("PATHHHHHHH: \(path)")
        var fileContents = "!"
        var dataF: Data? = nil
        let fileURL = URL(filePath: path)
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)

            if let data = try fileHandle.readToEnd() {
                dataF = data
            }
            fileHandle.closeFile()
        } catch {
            print(">>!>> \(error)")
        }
        if let dataF = dataF {
            fileContents = String(decoding: dataF, as: UTF8.self)
        }
        print("FFFFFF: \(fileContents)")
        return fileContents
}