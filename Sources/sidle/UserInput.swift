import SidleCore

extension Turn {
	static func get(wordLength: Int) throws -> Input<Turn> {
		while true {
			do {

				let input = try getGuess(wordLength: wordLength)
				switch input {
				case .guess(let guess):
					return .guess(
						Turn(
							guess: guess,
							feedback: try Turn.Feedback.get(
								wordLength: wordLength)))
				case .query(let query):
					return .query(query)
				}
			} catch let error as String {
				print(error)
				continue
			}
		}
	}
}

enum Input<T> {
	case guess(T)
	case query(String)
}

func getGuess(wordLength: Int) throws -> Input<String> {
	print("Guess:")
	guard
		let input = readLine()
	else {
		throw "Guess must be \(wordLength) characters, or command starting with ?"
	}

	if input.starts(with: "?") {
		return .query(String(input.dropFirst()))
	} else if input.count == wordLength {
		return .guess(input)
	} else {
		throw "Guess must be \(wordLength) characters, or command starting with ?"
	}
}

extension Turn.Feedback {
	static func get(wordLength: Int) throws -> [Turn.Feedback] {
		print(
			"Feedback: "
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
