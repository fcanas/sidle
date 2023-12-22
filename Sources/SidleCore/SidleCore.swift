//
//  File.swift
//
//
//  Created by Fabián Cañas on 1/16/22.
//

import Foundation

public protocol WordList {
	var words: [String] { get }
	func filterMatching(_ pattern: String, invert: Bool) throws -> WordList
}

extension WordList {
	public func filterMatching(_ pattern: String) throws -> WordList {
		return try filterMatching(pattern, invert: false)
	}
}

public enum Fact: Hashable {
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

public struct Turn: Hashable {

	public init(guess: String, feedback: [Turn.Feedback]) {
		self.guess = guess
		self.feedback = feedback
	}

	public let guess: String
	public let feedback: [Feedback]

	public enum Feedback: Character, Hashable {
		case hit = "="
		case miss = "-"
		case misplaced = "."
	}

	public func facts() -> [Fact] {
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
					if case let .placedAt(placedChar, _) = fact,
						placedChar == misplacedChar
					{
						return true
					}
					return false
				})
				if placedCharacterMatches.count > 0 {
					accumulatedFacts.append(
						.minimumOccurrenceCount(
							misplacedChar,
							placedCharacterMatches.count + 1))
				}
			case let .exclude(misplacedChar):
				if nil
					!= factSet.first(where: { fact in
						if case let .placedAt(placedChar, _) = fact,
							placedChar == misplacedChar
						{
							return true
						}
						return false
					})
				{
					accumulatedFacts.append(
						.excludeWhereNotPlaced(misplacedChar))
				} else {
					accumulatedFacts.append(fact)
				}
			default:
				accumulatedFacts.append(fact)
			}
		}
	}
}

enum Positional: Hashable {
	case misplaced([Character])
	case placed(Character)
}

// MARK: - Filter by Fact

extension WordList {
	func filter(with fact: Fact) throws -> WordList {
		switch fact {
		case .exclude(let char):
			return try filterMatching(String(char), invert: true)
		case .misplacedAt(let char, _):
			return try filterMatching(String(char))
		case .minimumOccurrenceCount(let char, let count):
			return try filterMatching(
				Array(repeating: char, count: count).map(String.init).joined(
					separator: ".*"))
		default:
			return self
		}
	}

	public func filter<F: Collection>(with facts: F, wordLength: Int) throws -> WordList
	where F.Element == Fact {
		var localList = try self.filterMatching(facts.positionalRegex(wordLength))
		try facts.forEach { fact throws in
			localList = try localList.filter(with: fact)
		}
		return localList
	}
}

extension Collection where Element == Fact {
	func positionalRegex(_ wordLength: Int) -> String {
		return reduce(into: Array(repeating: Positional.misplaced([]), count: wordLength)) {
			partialResult, fact in
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
		}.reduce(
			into: String(),
			{ partialResult, positional in
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
