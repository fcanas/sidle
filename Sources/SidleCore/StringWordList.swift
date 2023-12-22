//
//  StringWordList.swift
//
//
//  Created by Fabián Cañas on 1/16/22.
//

import Foundation

public class StringWordList: WordList {

	public var words: [String]

	public required init(words: [String]) {
		self.words = words
	}

	public func filterMatching(_ pattern: String, invert: Bool) throws -> WordList {
		let regex = try NSRegularExpression(pattern: pattern, options: [])
		return Self.init(
			words: words.filter { word in
				let nsWord = word as NSString
				let match = regex.matches(
					in: word, options: [],
					range: NSRange(location: 0, length: nsWord.length))
				return invert ? match.count == 0 : match.count > 0
			})
	}
}

extension WordList {
	public func wordWiseHistogram() -> [Character: Int] {
		var histogram: [Character: Int] = [:]
		for word in words {
			for letter in word.removeDuplicates() {
				if !letter.isLetter {
					continue
				}
				histogram[letter, default: 0] += 1
			}
		}
		return histogram
	}
}

extension String {
	func removeDuplicates() -> String {
		var used = Set<Character>()
		return filter { used.insert($0).inserted }
	}
}
