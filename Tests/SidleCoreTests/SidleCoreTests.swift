//
//  SidleCoreTests.swift
//
//
//  Created by Fabián Cañas on 1/16/22.
//

import XCTest

@testable import SidleCore

class SidleCoreTests: XCTestCase {

	func testFilterWithMinimumOccurrenceFacts() throws {
		let list = StringWordList(words: [
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

	func testHistogram() throws {
		let list = StringWordList(words: [
			"renet", "seedy", "teems", "weedy", "belie", "bells", "zeeep",
		])
		let histogram = list.wordWiseHistogram()
		XCTAssertEqual(
			histogram,
			[
				"d": 2, "i": 1, "l": 2, "z": 1, "y": 2, "r": 1, "s": 3, "m": 1,
				"e": 7, "b": 2, "p": 1, "w": 1, "n": 1, "t": 2,
			])
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

		let turn = Turn(
			guess: "falls",
			feedback: [.miss, .miss, .hit, .miss, .miss])
		let facts = turn.facts()
		XCTAssertEqual(
			facts,
			[
				.exclude("f"),
				.exclude("a"),
				.placedAt("l", 2),
				.excludeWhereNotPlaced("l"),
				.exclude("s"),
			])
	}

	func testSameLetterPlacedMisplaced() throws {
		// target: reset

		let turn = Turn(
			guess: "belie",
			feedback: [.miss, .hit, .miss, .miss, .misplaced])
		let facts = turn.facts()
		XCTAssertEqual(
			facts,
			[
				.exclude("b"),
				.placedAt("e", 1),
				.exclude("l"),
				.exclude("i"),
				.misplacedAt("e", 4),
				.minimumOccurrenceCount("e", 2),
			])
	}

	func testTurnToFacts() throws {
		let turn = Turn(
			guess: "tales",
			feedback: [.miss, .miss, .misplaced, .hit, .miss])
		let facts = turn.facts()
		XCTAssertEqual(
			Set(facts),
			Set([
				.exclude("t"),
				.exclude("a"),
				.misplacedAt("l", 2),
				.placedAt("e", 3),
				.exclude("s"),
			]))
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
		XCTAssertEqual(regexB, "[^a]p[^c][^d].")
	}

	func testPositionalRegexEmptyFacts() throws {
		let factsC: [Fact] = []
		let regexC = factsC.positionalRegex(5)
		XCTAssertEqual(regexC, ".....")
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
		XCTAssertEqual(regexA, "[^bc]p.[^ef].")

		let factsB: [Fact] =
			[
				.exclude("b"),
				.exclude("c"),
				.placedAt("e", 1),
				.exclude("l"),
				.exclude("i"),
				.misplacedAt("e", 4),
				.minimumOccurrenceCount("e", 2),
			]
		let regexB = factsB.positionalRegex(5)
		XCTAssertEqual(regexB, ".e..[^e]")
	}

}
