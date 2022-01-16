import Darwin
import Foundation
import PrettyColors

print("Welcome to sidle, the WORDLE assistant.")
print(Color.Wrap(foreground: .blue, style: .underlined).wrap("https://www.powerlanguage.co.uk/wordle/"))

let wordLength = 5
let wordListSpacing = 2

extension String: Error {}

enum Fact: Hashable {
    // The letter _ is in the word and in the correct spot.
    case placedAt(Character, Int)
    // The letter _ is not in the word in any spot.
    case exclude(Character)
    // The letter _ is in the word but in the wrong spot.
    case misplacedAt(Character, Int)
    // This is an undocumented Fact:
    // There is an existing fact placing the letter somewhere. Some additional placement has excluded it
    case excludeWhereNotPlaced(Character)
    // This is an undocumented Fact:
    // There is an existing fact placing the letter somewhere. A second placement has indicated it is misplaced at this index, meaning
    // it must be placed somewhere else. Such an observation should
    // generate two facts: `misplacedAt` and a
    case minimumOccurrenceCount(Character, Int)
}

struct Turn {
    let guess: String
    let feedback: [Feedback]
    
    enum Feedback: Character {
        case hit = "="
        case miss = "-"
        case misplaced = "."
    }
    
    func facts() -> [Fact] {
        let factSet = zip(guess, feedback)
            .enumerated()
            .map { (index, pair) -> Fact in
                let (guess, feedback) = pair
                switch feedback {
                case .miss:
                    return .exclude(guess)
                case .hit:
                    return .placedAt(guess, index)
                case .misplaced:
                    return .misplacedAt(guess, index)
                }
            }
        return factSet.reduce(into: [Fact]()) { (accumulatedFacts, fact) in
            
            switch fact {
            case let .misplacedAt(misplacedChar, _):
                accumulatedFacts.append(fact)
                let placedCharacterMatches = factSet.filter({ fact in
                        if
                            case let .placedAt(placedChar, _) = fact,
                            placedChar == misplacedChar
                        {
                            return true
                        }
                        return false
                    })
                if placedCharacterMatches.count > 0 {
                    accumulatedFacts.append(.minimumOccurrenceCount(misplacedChar, placedCharacterMatches.count + 1))
                }
            case let .exclude(misplacedChar):
                if nil != factSet.first(where: { fact in
                        if
                            case let .placedAt(placedChar, _) = fact,
                            placedChar == misplacedChar
                        {
                            return true
                        }
                        return false
                    })
                {
                    accumulatedFacts.append(.excludeWhereNotPlaced(misplacedChar))
                } else {
                    accumulatedFacts.append(fact)
                }
            default:
                accumulatedFacts.append(fact)
            }
        }
    }
}

struct WordList {
    var data: Data
    
    var words: [String]  {
        guard
            let s = String(data: data, encoding: .utf8)
        else {
            return []
        }
        return s.split(separator: "\n").map(String.init)
    }
    
    internal init(words: [String]) {
        data = (words.joined(separator: "\n") + "\n").data(using: .utf8)!
    }
    
    private init(data: Data) {
        self.data = data
    }
    
    init(_ listPath: String = "/usr/share/dict/words") throws {
        guard
            let data = FileManager.default.contents(atPath: listPath)
        else {
            throw "Unable to initialize word list."
        }
        self.data = data
    }
}

enum Positional {
    case misplaced([Character])
    case placed(Character)
}

let grepURL: URL = {
    let url = URL(fileURLWithPath: "/usr/bin/grep")
    guard
        FileManager.default.isExecutableFile(atPath: url.path)
    else {
        fatalError("File at \(url.path) does not appear to be executable")
    }
    return url
}()


func game(wordLength: Int, grepURL: URL) throws {
    let wordList = try! WordList().filterMatching("^[a-z]\\{5\\}$", grepURL: grepURL)

    var accumulatedFacts: Set<Fact> = []
    var turns: [Turn] = []
    while true {
        let turn = try Turn.get()
        turns.append(turn)
        accumulatedFacts.formUnion(turn.facts())
        
        let localList = try wordList.filter(with: accumulatedFacts, wordLength: wordLength, grepURL: grepURL)
        
        print(localList.display())
        
        try turns.forEach { t throws in
            print("\(t.display())")
        }
        if localList.words.count == 1 {
            break
        }
    }
}

try game(wordLength: wordLength, grepURL: grepURL)


// MARK: - Fact to Regex

extension WordList {
    func filter(with fact: Fact, grepURL: URL) throws -> WordList{
        switch fact {
        case .exclude(let char):
            return try filterMatching(String(char), grepURL: grepURL, invert: true)
        case .misplacedAt(let char, _):
            return try filterMatching(String(char), grepURL: grepURL)
        case .minimumOccurrenceCount(let char, let count):
            return try filterMatching(Array(repeating: char, count: count).map(String.init).joined(separator: ".*"), grepURL: grepURL)
        default:
            return self
        }
    }
    
    func filter<F: Collection>(with facts: F, wordLength: Int, grepURL: URL) throws -> WordList where F.Element == Fact {
        var localList = try self.filterMatching(facts.positionalRegex(wordLength), grepURL: grepURL)
        try facts.forEach { fact throws in
            localList = try localList.filter(with: fact, grepURL: grepURL)
        }
        return localList
    }
}

extension Collection where Element == Fact {
    func positionalRegex(_ wordLength: Int) -> String {
        return reduce(into: Array(repeating: Positional.misplaced([]), count: wordLength)) { partialResult, fact in
            switch fact {
            case let .placedAt(char, loc):
                partialResult[loc] = .placed(char)
            case .exclude(_):
                break
            case let .misplacedAt(char, loc):
                if case let .misplaced(excluded) = partialResult[loc] {
                    partialResult[loc] = .misplaced(excluded + [char])
                }
            case let .excludeWhereNotPlaced(char):
                
                partialResult.enumerated().forEach { (index, value) in
                    if case .placed = value {
                        return
                    }
                    if case let .misplaced(excluded) = partialResult[index] {
                        partialResult[index] = .misplaced(excluded + [char])
                    }
                }
            case .minimumOccurrenceCount(_, _):
                break
            }
        }.reduce(into: String(), { partialResult, positional in
            switch positional {
            case .placed(let c):
                partialResult.append(c)
            case .misplaced(let chars):
                if chars.count == 0 {
                    partialResult.append(".")
                } else {
                    partialResult.append("[^\(String(chars))]")
                }
            }
        })
    }
    
    func consolidateFacts() -> Self {
        return self
    }
    
}

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

extension WordList {
    func filterMatching(_ pattern: String, grepURL: URL, invert: Bool = false) throws -> WordList {
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
        return WordList(data: dataOut)
    }
}
