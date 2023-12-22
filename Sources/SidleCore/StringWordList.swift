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
