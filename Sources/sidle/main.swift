import Darwin
import Foundation
import PrettyColors
import SidleCore

print("Welcome to sidle, the WORDLE assistant.")
print(Color.Wrap(foreground: .blue, style: .underlined).wrap("https://www.powerlanguage.co.uk/wordle/"))

let wordLength = 5
let wordListSpacing = 2

extension String: Error {}

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


func game(dictionary: WordList, wordLength: Int) throws {
    let wordList = try! dictionary.filterMatching("^[a-z]\\{5\\}$")

    var accumulatedFacts: Set<Fact> = []
    var turns: [Turn] = []
    while true {
        let turn = try Turn.get()
        turns.append(turn)
        accumulatedFacts.formUnion(turn.facts())
        
        let localList = try wordList.filter(with: accumulatedFacts, wordLength: wordLength)
        
        print(localList.display())
        
        try turns.forEach { t throws in
            print("\(t.display())")
        }
        if localList.words.count == 1 {
            break
        }
    }
}

try game(dictionary: DataWordList(), wordLength: wordLength)

// MARK: - User Input

extension Turn {
    static func get() throws -> Turn {
        while true {
            do {
                return Turn(guess: try getGuess(), feedback: try Turn.Feedback.get())
            } catch let error as String {
                print(error)
                continue
            }
        }
    }
}

func getGuess() throws -> String {
    print("Guess:")
    guard
        let input = readLine(),
        input.count == wordLength
    else {
        throw "Word must be \(wordLength) characters."
    }
    return input
}

extension Turn.Feedback {
    static func get() throws -> [Turn.Feedback] {
        print("Feedback: "
              + Turn.Feedback.hit.display()
              + Turn.Feedback.misplaced.display()
              + Turn.Feedback.miss.display()
        )
        guard
            let input = readLine(),
            input.count == wordLength
        else {
            throw "Feedback must be \(wordLength) characters."
        }
        let mapped = input.compactMap(Turn.Feedback.init)
        guard
            mapped.count == wordLength
        else {
            throw
            "Feedback should be in the form: "
            + Turn.Feedback.hit.display()
            + Turn.Feedback.misplaced.display()
            + Turn.Feedback.miss.display()
        }
        return mapped
    }
}

// MARK: - Display

extension WordList {
    /// Formats the words for display, wrapping lines to fit the available columns in the console
    /// - Returns: The word list as a single string, formatted for printing
    func display() -> String {
        // Fit remaining candidate words on the screen
        // https://stackoverflow.com/questions/47776658/determine-viewport-size-in-characters-from-command-line-app-in-swift
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return words.reduce(into: [[String]]()) { partialResult, nextWord in
                guard
                    var lastList = partialResult.last,
                    ((lastList.count + 1) * (wordLength + wordListSpacing)) < w.ws_col
                else {
                    partialResult.append([nextWord])
                    return
                }
                partialResult.removeLast()
                lastList.append(nextWord)
                partialResult.append(lastList)
            }.map { $0.joined(separator: String(Array(repeating: " ", count: wordListSpacing))) }
            .joined(separator: "\n")
        } else {
            return words.joined(separator: String(Array(repeating: " ", count: wordListSpacing)))
        }
    }
}

extension Turn.Feedback {
    func color() -> Color.Wrap {
        switch self {
        case .hit:
            return Color.Wrap(background: .green, style: .bold)
        case .misplaced:
            return Color.Wrap(background: .yellow)
        case .miss:
            return Color.Wrap(background: Color.Named.Color?.none, style: .bold)
        }
    }
    
    func display() -> String {
        color().wrap(String(rawValue))
    }
}

extension Turn {
    /// Formats a turn for output on a console.
    /// - Returns: The letters of the guess color-coded  by the feedback.
    func display() -> String {
        return zip(guess, feedback).reduce(into: "") { (partial, turnParts) in
            let (g, f) = turnParts
            partial += f.color().wrap(String(g))
        }
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
