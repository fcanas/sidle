import XCTest
import class Foundation.Bundle
@testable import sidle
import PrettyColors

final class sidleTests: XCTestCase {
    
    func testTurnFormatting() throws {
        let turn = Turn(guess: "tales",
                        feedback: [.miss, .miss, .misplaced, .hit, .miss])
        XCTAssertEqual(turn.display(), "\(ECMA48.controlSequenceIntroducer)1mt\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)1ma\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)43ml\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)42;1me\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)1ms\(ECMA48.controlSequenceIntroducer)0m")
    }
    
    func testPositionalRegexPlacementOverridesMisplaced() throws {
        
        let factsB: [Fact] =
        [
            .exclude("z"),
            .exclude("r"),
            .exclude("v"),
            .placedAt("p", 1),
            .misplacedAt("a", 0),
            .misplacedAt("b", 1),
            .misplacedAt("c", 2),
            .misplacedAt("d", 3),
        ]
        let regexB = factsB.positionalRegex(5)
        XCTAssertEqual(regexB,"[^a]p[^c][^d].")
    }
    
    func testPositionalRegexEmptyFacts() throws {
        let factsC: [Fact] = []
        let regexC = factsC.positionalRegex(5)
        XCTAssertEqual(regexC,".....")
    }
    
    func testPositionalRegexMultipleAtIndex() throws {
        let factsA: [Fact] =
        [
            .exclude("a"),
            .misplacedAt("b", 0),
            .misplacedAt("c", 0),
            .placedAt("p", 1),
            .misplacedAt("e", 3),
            .misplacedAt("f", 3),
        ]
        let regexA = factsA.positionalRegex(5)
        XCTAssertEqual(regexA,"[^bc]p.[^ef].")
        
        
        let factsB: [Fact] =
        [
            .exclude("b"),
            .exclude("c"),
            .placedAt("e", 1),
            .exclude("l"),
            .exclude("i"),
            .misplacedAt("e", 4),
            .minimumOccurrenceCount("e", 2)
        ]
        let regexB = factsB.positionalRegex(5)
        XCTAssertEqual(regexB,".e..[^e]")
    }

    func testFilterWithMinimumOccurrenceFacts() throws {
        let list = WordList(words: ["renet", "seedy", "teems", "weedy", "belie", "bells",  "zeeep"])
        let facts: [Fact] = [
                     .placedAt("e", 1),
                     .misplacedAt("e", 4),
                     .minimumOccurrenceCount("e", 2),
                     .exclude("z")
                    ]
        let newWords = try list.filter(with: facts, wordLength: 5, grepURL: URL(fileURLWithPath: "/usr/bin/grep"))
        XCTAssertEqual(newWords.words,
                       ["renet", "seedy", "teems", "weedy"])
        
    }
    
    func testTurnToFacts() throws {
        let turn = Turn(guess: "tales",
                        feedback: [.miss, .miss, .misplaced, .hit, .miss])
        let facts = turn.facts()
        XCTAssertEqual(Set(facts), Set([.exclude("t"),
                                        .exclude("a"),
                                        .misplacedAt("l", 2),
                                        .placedAt("e", 3),
                                        .exclude("s")]))
    }
     
    /// https://twitter.com/fcanas/status/1482162130191269890
    /// Today I discovered an additional source of information in wordle.
    /// Consider the following simulated/redacted game I observed:
    /// ```
    /// _ _ a _ _
    /// _ _ . _ _
    /// _ a _ a _
    /// _ = _ - _
    /// ```
    /// Once a letter is placed, a misplaced instance of the same letter will be
    /// reported as not appearing in the word, as long as the letter doesn't
    /// appear twice in the word.
    func testSameLetterExcludeInclude() throws {
        //
        
        let turn = Turn(guess: "falls",
                        feedback: [.miss, .miss, .hit, .miss, .miss])
        let facts = turn.facts()
        XCTAssertEqual(facts, [.exclude("f"),
                               .exclude("a"),
                               .placedAt("l", 2),
                               .excludeWhereNotPlaced("l"),
                               .exclude("s")
                              ])
    }
    
    func testSameLetterPlacedMisplaced() throws {
        // target: reset
        
        let turn = Turn(guess: "belie",
                        feedback: [.miss, .hit, .miss, .miss, .misplaced])
        let facts = turn.facts()
        XCTAssertEqual(facts, [.exclude("b"),
                               .placedAt("e", 1),
                               .exclude("l"),
                               .exclude("i"),
                               .misplacedAt("e", 4),
                               .minimumOccurrenceCount("e", 2)
                              ])
    }
    
    func testWordListInitialization() throws {
        XCTAssertThrowsError(try WordList("/\(UUID().uuidString)"))
        XCTAssertGreaterThan(try WordList().words.count, 100)
    }
    
    func testGuessFeedback() throws {
        
        let (process, stdIn, out) = try startAGame()
        
        let introduction = [
            "Welcome to sidle, the WORDLE assistant.",
            "\(ECMA48.controlSequenceIntroducer)34;4mhttps://www.powerlanguage.co.uk/wordle/\(ECMA48.controlSequenceIntroducer)0m",
            "Guess:"
        ]
        
        for line in introduction {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "tale\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Word must be 5 characters.")
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Guess:")
        process.terminate()
    }
    
    func testFeedbackFeedback() throws {
        
        let (process, stdIn, out) = try startAGame()
        
        let introduction = [
            "Welcome to sidle, the WORDLE assistant.",
            "\(ECMA48.controlSequenceIntroducer)34;4mhttps://www.powerlanguage.co.uk/wordle/\(ECMA48.controlSequenceIntroducer)0m",
            "Guess:"
        ]
        
        for line in introduction {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
        try stdIn.fileHandleForWriting.write(contentsOf: "+++-.\n".data(using: .utf8)!)
        
        let formatFeedback = [
            "Feedback should be in the form: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m",
            "Guess:",
        ]
        
        for line in formatFeedback {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
        try stdIn.fileHandleForWriting.write(contentsOf: ".---\n".data(using: .utf8)!)
        
        let lengthFeedback = [
            "Feedback must be 5 characters.",
            "Guess:",
        ]
        
        for line in lengthFeedback {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line, "Feedback shorter than 5 characters should prompt again.")
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
        try stdIn.fileHandleForWriting.write(contentsOf: ".--.........-\n".data(using: .utf8)!)
        
        for line in lengthFeedback {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line, "Feedback longer than 5 characters should prompt again.")
        }
        
        process.terminate()
    }
    
    func startAGame() throws -> (Process, Pipe, Pipe) {
        continueAfterFailure = false
        let env = ProcessInfo().environment
        guard
            env["XCTestBundlePath"] != nil
        else {
            throw XCTSkip("Testing a game with input via stdin only seems to work in Xcode.")
        }
        
        let sidleBinary = productsDirectory.appendingPathComponent("sidle")
        
        let process = Process()
        process.executableURL = sidleBinary
        
        let stdIn = Pipe()
        process.standardInput = stdIn
        let out = Pipe()
        process.standardOutput = out
        
        try process.run()
        
        return (process, stdIn, out)
    }
    
    func testGame() throws {
        
        let (process, stdIn, out) = try startAGame()
        
        let introduction = [
            "Welcome to sidle, the WORDLE assistant.",
            "\(ECMA48.controlSequenceIntroducer)34;4mhttps://www.powerlanguage.co.uk/wordle/\(ECMA48.controlSequenceIntroducer)0m",
            "Guess:"
        ]
        
        for line in introduction {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
        try stdIn.fileHandleForWriting.write(contentsOf: ".=--=\n".data(using: .utf8)!)
        
        let response = [
            "darts  pants  patas",
            "\u{1B}[43mt\u{1B}[0m\u{1B}[42;1ma\u{1B}[0m\u{1B}[1ml\u{1B}[0m\u{1B}[1me\u{1B}[0m\u{1B}[42;1ms\u{1B}[0m",
            "Guess:",
        ]
        
        for line in response {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        
        try stdIn.fileHandleForWriting.write(contentsOf: "darts\n".data(using: .utf8)!)
        XCTAssertEqual(try out.fileHandleForReading.readLine(), "Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
        try stdIn.fileHandleForWriting.write(contentsOf: "=====\n".data(using: .utf8)!)
        
        let endGame = [
            "darts",
            "\u{1B}[43mt\u{1B}[0m\u{1B}[42;1ma\u{1B}[0m\u{1B}[1ml\u{1B}[0m\u{1B}[1me\u{1B}[0m\u{1B}[42;1ms\u{1B}[0m",
        ]
        
        for line in endGame {
            let output = try out.fileHandleForReading.readLine()
            XCTAssertEqual(output, line)
        }
        process.waitUntilExit()
    }
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
    }
}

extension FileHandle {
    func readLine() throws -> String? {
        var dataOut = Data()
        while
            let d = try read(upToCount: 1), // yes, really.
            let byte = d.first,
            byte != 10
        {
            dataOut.append(d)
        }
        return String(data: dataOut, encoding: .utf8)
    }
}
