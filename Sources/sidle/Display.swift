import Darwin
import PrettyColors
import SidleCore

private let wordListSpacing = 2

extension WordList {
	/// Formats the words for display, wrapping lines to fit the available columns in the console
	/// - Returns: The word list as a single string, formatted for printing
	func display(wordLength: Int) -> String {
		// Fit remaining candidate words on the screen
		// https://stackoverflow.com/questions/47776658/determine-viewport-size-in-characters-from-command-line-app-in-swift
		var w = winsize()
		if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
			return words.reduce(into: [[String]]()) { partialResult, nextWord in
				guard
					var lastList = partialResult.last,
					((lastList.count + 1) * (wordLength + wordListSpacing))
						< w.ws_col
				else {
					partialResult.append([nextWord])
					return
				}
				partialResult.removeLast()
				lastList.append(nextWord)
				partialResult.append(lastList)
			}.map {
				$0.joined(
					separator: String(
						Array(repeating: " ", count: wordListSpacing)))
			}
			.joined(separator: "\n")
		} else {
			return words.joined(
				separator: String(Array(repeating: " ", count: wordListSpacing)))
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
