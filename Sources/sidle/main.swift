import Foundation
import PrettyColors
import SidleCore

print("Welcome to sidle, the WORDLE assistant.")
print(Color.Wrap(foreground: .blue, style: .underlined).wrap("https://www.powerlanguage.co.uk/wordle/"))

fileprivate let wordLength = 5

extension String: Error {}

func game(dictionary: WordList, wordLength: Int) throws {
    let wordList = try! dictionary.filterMatching("^[a-z]\\{5\\}$")

    var accumulatedFacts: Set<Fact> = []
    var turns: [Turn] = []
    while true {
        let turn = try Turn.get(wordLength: wordLength)
        turns.append(turn)
        accumulatedFacts.formUnion(turn.facts())
        
        let localList = try wordList.filter(with: accumulatedFacts, wordLength: wordLength)
        
        print(localList.display(wordLength: wordLength))
        
        try turns.forEach { t throws in
            print("\(t.display())")
        }
        if localList.words.count == 1 {
            break
        }
    }
}

try game(dictionary: DataWordList(), wordLength: wordLength)
