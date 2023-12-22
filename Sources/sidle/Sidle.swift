import ArgumentParser
import PrettyColors
import SidleCore

@main
struct Sidle: ParsableCommand {

	@Option(name: .shortAndLong, help: "The number of letters in the word. Defaults to 5.")
	var letterCount: Int = 5

	@Option(
		name: .shortAndLong,
		help: "Path to a newline-delimited word file. Defaults to /usr/share/dict/words")
	var wordsListPath: String = "/usr/share/dict/words"

	mutating func run() throws {
		print("Welcome to sidle, the WORDLE assistant.")
		print(
			Color.Wrap(foreground: .blue, style: .underlined).wrap(
				"https://www.powerlanguage.co.uk/wordle/"))
		try game(dictionary: DataWordList(wordsListPath), wordLength: letterCount)
	}

	mutating func game(dictionary: WordList, wordLength: Int) throws {
		let wordList = try! dictionary.filterMatching("^[a-z]\\{\(wordLength)\\}$")

		var accumulatedFacts: Set<Fact> = []
		var turns: [Turn] = []
		while true {
			let turn = try Turn.get(wordLength: wordLength)
			turns.append(turn)
			accumulatedFacts.formUnion(turn.facts())

			let localList = try wordList.filter(
				with: accumulatedFacts, wordLength: wordLength)

			print(localList.display(wordLength: wordLength))

			try turns.forEach { t throws in
				print("\(t.display())")
			}
			if localList.words.count == 1 {
				break
			}
		}
	}
}

extension String: Error {}
