import PrettyColors
import SidleCore
import XCTest

import class Foundation.Bundle

@testable import sidle

final class sidleTests: XCTestCase {

	func testTurnFormatting() throws {
		let turn = Turn(
			guess: "tales",
			feedback: [.miss, .miss, .misplaced, .hit, .miss])
		XCTAssertEqual(
			turn.display(),
			"\(ECMA48.controlSequenceIntroducer)1mt\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)1ma\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)43ml\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)42;1me\(ECMA48.controlSequenceIntroducer)0m\(ECMA48.controlSequenceIntroducer)1ms\(ECMA48.controlSequenceIntroducer)0m"
		)
	}

	func testWordListInitialization() throws {
		XCTAssertThrowsError(try DataWordList("/\(UUID().uuidString)"))
		XCTAssertGreaterThan(try DataWordList("/usr/share/dict/words").words.count, 100)
	}

	func testBarChart() throws {
		let list = StringWordList(words: [
			"renet", "seedy", "teems", "weedy", "belie", "bells", "zeeep",
		])
		let histogram = list.wordWiseHistogram()
		let barChart = histogram.asDisplayBarChart()
		XCTAssertEqual(
			barChart,
			[
				"m":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"i":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"n":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"z":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"t":
					"████████████████████\u{1B}[7m2\u{1B}[0m█                                                       |",
				"e":
					"███████████████████████████████████████████████████████████████████████████\u{1B}[7m7\u{1B}[0m |",
				"r":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"b":
					"████████████████████\u{1B}[7m2\u{1B}[0m█                                                       |",
				"s":
					"███████████████████████████████\u{1B}[7m3\u{1B}[0m█                                            |",
				"p":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"w":
					"█████████\u{1B}[7m1\u{1B}[0m█                                                                  |",
				"y":
					"████████████████████\u{1B}[7m2\u{1B}[0m█                                                       |",
				"d":
					"████████████████████\u{1B}[7m2\u{1B}[0m█                                                       |",
				"l":
					"████████████████████\u{1B}[7m2\u{1B}[0m█                                                       |",
			])
	}

	func testWordListFiltering() throws {

		let list = DataWordList(words: [
			"renet", "seedy", "teems", "weedy", "belie", "bells", "zeeep",
		])
		let facts: [Fact] = [
			.placedAt("e", 1),
			.misplacedAt("e", 4),
			.minimumOccurrenceCount("e", 2),
			.exclude("z"),
		]
		let newWords = try list.filter(with: facts, wordLength: 5)
		XCTAssertEqual(
			newWords.words,
			["renet", "seedy", "teems", "weedy"])
	}

	func testGuessFeedback() throws {

		let (process, stdIn, out) = try startAGame()

		let introduction = [
			"Welcome to sidle, the WORDLE assistant.",
			"\(ECMA48.controlSequenceIntroducer)34;4mhttps://www.powerlanguage.co.uk/wordle/\(ECMA48.controlSequenceIntroducer)0m",
			"Guess:",
		]

		for line in introduction {
			let output = try out.fileHandleForReading.readLine()
			XCTAssertEqual(output, line)
		}

		try stdIn.fileHandleForWriting.write(contentsOf: "tale\n".data(using: .utf8)!)
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(), "Word must be 5 characters.")
		XCTAssertEqual(try out.fileHandleForReading.readLine(), "Guess:")
		process.terminate()
	}

	func testFeedbackFeedback() throws {

		let (process, stdIn, out) = try startAGame()

		let introduction = [
			"Welcome to sidle, the WORDLE assistant.",
			"\(ECMA48.controlSequenceIntroducer)34;4mhttps://www.powerlanguage.co.uk/wordle/\(ECMA48.controlSequenceIntroducer)0m",
			"Guess:",
		]

		for line in introduction {
			let output = try out.fileHandleForReading.readLine()
			XCTAssertEqual(output, line)
		}

		try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(),
			"Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
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
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(),
			"Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
		try stdIn.fileHandleForWriting.write(contentsOf: ".---\n".data(using: .utf8)!)

		let lengthFeedback = [
			"Feedback must be 5 characters.",
			"Guess:",
		]

		for line in lengthFeedback {
			let output = try out.fileHandleForReading.readLine()
			XCTAssertEqual(
				output, line,
				"Feedback shorter than 5 characters should prompt again.")
		}

		try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(),
			"Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
		try stdIn.fileHandleForWriting.write(
			contentsOf: ".--.........-\n".data(using: .utf8)!)

		for line in lengthFeedback {
			let output = try out.fileHandleForReading.readLine()
			XCTAssertEqual(
				output, line,
				"Feedback longer than 5 characters should prompt again.")
		}

		process.terminate()
	}

	func startAGame() throws -> (Process, Pipe, Pipe) {
		continueAfterFailure = false
		let env = ProcessInfo().environment
		guard
			env["XCTestBundlePath"] != nil
		else {
			throw XCTSkip(
				"Testing a game with input via stdin only seems to work in Xcode.")
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
			"Guess:",
		]

		for line in introduction {
			let output = try out.fileHandleForReading.readLine()
			XCTAssertEqual(output, line)
		}

		try stdIn.fileHandleForWriting.write(contentsOf: "tales\n".data(using: .utf8)!)
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(),
			"Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
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
		XCTAssertEqual(
			try out.fileHandleForReading.readLine(),
			"Feedback: \u{1B}[42;1m=\u{1B}[0m\u{1B}[43m.\u{1B}[0m\u{1B}[1m-\u{1B}[0m")
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
		while let d = try read(upToCount: 1),  // yes, really.
			let byte = d.first,
			byte != 10
		{
			dataOut.append(d)
		}
		return String(data: dataOut, encoding: .utf8)
	}
}
