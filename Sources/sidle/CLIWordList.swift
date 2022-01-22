import Foundation
import SidleCore

struct DataWordList: WordList {
    
    let grepURL: URL
    
    var data: Data
    
    var words: [String]  {
        guard
            let s = String(data: data, encoding: .utf8)
        else {
            return []
        }
        return s.split(separator: "\n").map(String.init)
    }
    
    internal init(words: [String], grepURL: URL = URL(fileURLWithPath: "/usr/bin/grep")) {
        data = (words.joined(separator: "\n") + "\n").data(using: .utf8)!
        self.grepURL = grepURL
    }
    
    private init(data: Data) {
        self.data = data
        self.grepURL = URL(fileURLWithPath: "/usr/bin/grep")
    }
    
    init(_ listPath: String = "/usr/share/dict/words", _ grepURL: URL = URL(fileURLWithPath: "/usr/bin/grep")) throws {
        guard
            let data = FileManager.default.contents(atPath: listPath)
        else {
            throw "Unable to initialize word list."
        }
        self.grepURL = grepURL
        self.data = data
    }
}

// MARK: - grep Filtering

extension DataWordList {
    func filterMatching(_ pattern: String, invert: Bool = false) throws -> WordList {
        let p = Process()
        p.executableURL = grepURL
        
        p.arguments = (invert ? ["-v"] : []) + ["\(pattern)"]
        let stdIn = Pipe()
        let stdOut = Pipe()
        p.standardInput = stdIn
        p.standardOutput = stdOut
        
        try p.run()
        try stdIn.fileHandleForWriting.write(contentsOf: self.data)
        try stdIn.fileHandleForWriting.write(contentsOf: "\n".data(using: .utf8)!)
        try stdIn.fileHandleForWriting.close()
        
        p.waitUntilExit()
        guard
            let dataOut = try? stdOut.fileHandleForReading.readToEnd()
        else {
            throw "No data from grep."
        }
        return DataWordList(data: dataOut)
    }
}
