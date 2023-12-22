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

extension Dictionary where Value == Int {
	/// Formats a histogram for display on a console.
	/// - Parameter maxIn: Range of display. If nil, the maximum value in the histogram is used.
	/// - Returns: A dictionary with the receiver's keys and a horizontal bar fill string as the value.
	func asDisplayBarChart(_ maxIn: Int? = nil) -> [Key: String] {

		let max = maxIn ?? values.max() ?? 1

		let screenWidth: Int
		var w = winsize()
		if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
			screenWidth = Int(Swift.min(w.ws_col - 4, 80 - 4))
		} else {
			screenWidth = 80 - 4
		}

		let unitPerCharacter = Double(max) / Double(screenWidth)

		return [Key: String](
			uniqueKeysWithValues: map { (key, count) in
				let unitCharacters = Int(floor(Double(count) / unitPerCharacter))
				let countString = "\(count)"
				let remainder = Double(count).remainder(
					dividingBy: unitPerCharacter)
				let bar =
					{
						if unitCharacters >= countString.count {
							String(
								Array(
									repeating: "█",
									count: unitCharacters
										- countString.count)
							)
								+ Color.Wrap(styles: .negative)
								.wrap(
									countString)
						} else {
							String(
								Array(
									repeating: "█",
									count: unitCharacters))
						}
					}()
					+ fractionalHorizontalFill(
						for: remainder / unitPerCharacter)
				let countWidth = unitCharacters
				let space =
					screenWidth - countWidth > 0
					? String(
						Array(
							repeating: " ",
							count: screenWidth - countWidth)) : ""
				return (key, "\(bar)\(space)|")
			})
	}
}

/// Returns a single character representing the fraction of a horizontal unit for a bar fill.
/// - Parameter fraction: percentage of a horizontal character to fill (0.0 to 1.0) from left to right.
/// - Returns: A single-character string proportionally filled from the left.
func fractionalHorizontalFill(for fraction: Double) -> String {
	let increments = "  ▏▎▍▌▋▊▉█"
	let bucketRanges: [Range<Double>] =
		(0..<(increments.count)).map({ (i: Int) -> Range<Double> in
			Double(i) / Double(increments.count)..<Double(i + 1)
				/ Double(increments.count)
		})
	guard
		let index = bucketRanges.firstIndex(where: { $0.contains(fraction) })
	else { return "█" }
	return String(increments[increments.index(increments.startIndex, offsetBy: index)])
}
