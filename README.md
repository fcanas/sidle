# sidle

A [WORDLE](https://www.powerlanguage.co.uk/wordle/) assistant.

1. `sidle` is not a solver.
2. `sidle` uses `/usr/share/dict/words`, not the WORDLE dictionary.
3. Even if the dictionary were correct, the optimal move may not be in the presented list of words.

## Installing

The `sidle` CLI tool is available via a [Homebrew](https://brew.sh) [tap](https://docs.brew.sh/Taps#the-brew-tap-command):

`brew install fcanas/tap/sidle`

or

```
brew tap fcanas/tap
brew install sidle
```

## Instructions

On running `sidle`, you're prompted for a 5-letter guess.

Then you're prompted for 5-character feedback. Feedback is in the form:

| Character | Meaning |
| --------- | ------- |
| = | Correctly placed letter |
| . | Letter in the wrong spot |
| - | Letter does not appear in word |

After a guess, the possible remaining words are shown on the screen followed by a summary of your turns so far, which should match the game.

## Development notes

The word list is initially filtered to 5-letter words. After that, each turn will fully recompute the candidate words based on the facts provided so far. Starting from the complete the dictionary after each turn is, at this point, a deliberate choice to allow for the development of backtracking features in the future, or other interesting ways of exploring the game.

## QNA

> Why does `sidle` use `grep`?

Because my initial explorations into a "solver" that turned into this "assistant" looked like this:

```
cat /usr/share/dict/words | grep -x '.\{5\}$' | grep '.r.n[^n]' | grep -v t | grep -v l | grep -v e | grep -v s | grep -v b | grep -v u | grep -v w | grep -v o | grep -v g | grep -v a
```

> Is this cheating?

Yes.

> Have you been cheating?

No.

> This is over/poorly-engineered.

That's not a question.

> What does QNA mean?

Questions Nobody Asked
