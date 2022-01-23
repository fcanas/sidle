import SidleCore

extension Turn {
    static func get(wordLength: Int) throws -> Turn {
        while true {
            do {
                return Turn(guess: try getGuess(wordLength: wordLength), feedback: try Turn.Feedback.get(wordLength: wordLength))
            } catch let error as String {
                print(error)
                continue
            }
        }
    }
}

func getGuess(wordLength: Int) throws -> String {
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
    static func get(wordLength: Int) throws -> [Turn.Feedback] {
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
