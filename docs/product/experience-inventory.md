# Nova experience inventory (audit of `main`, before the product-experience pass)

Scope: what a child actually meets when playing, not the architecture (journey, curriculum,
assessment and adaptation are done and out of scope here).

## Playable end to end

All 40 games in the content bundle are playable: each has a trial builder (`core/play/trial_factory.dart`)
whose mechanic matches the spec, and a view (`ui/play/trial_views.dart`), except Bear's Apples,
which has its own dedicated screen (`ui/game/game_screen.dart`). None is a content-only definition.

## Mechanics and the views they share

| View (interaction) | Games | Journey levels |
|---|---|---|
| **ChoiceTrialView** (tap one card in a grid) | number-match, more-or-less, pattern-train, pattern-builder, feelings-friends, how-would-they-feel, listen-and-find (en/ar), word-hunt (en/ar), rhyme-time (en/ar), first-sound (en/ar), sound-blender (en/ar), word-pictures (en/ar), letter-pairs (en), letter-forms (ar) | ~65 of 150 |
| DragCountTrialView | bear-apples (free play), bunny-carrots | 10 |
| TapCountTrialView | star-count | 4 |
| JoinSeparateTrialView | add-take-away, space-shop | 11 |
| NumberLineTrialView | number-line-hop | 5 |
| SortTrialView | color-sort, sort-switch | 11 |
| PairsTrialView | peekaboo-pairs | 8 |
| SequenceTrialView | simon-lights | 11 |
| StreamItemTrialView | feed-the-fish, number-catch, letter-catch (en/ar) | 15 |
| ClapTrialView | clap-syllables (en/ar) | 10 |
| PrintTrialView | book-explorer (en/ar) | 8 |
| BuildWordTrialView | word-builder (en/ar) | 12 |

## Gaps found

1. **Quiz feel.** Almost half the journey runs through one view: white rounded cards in a grid,
   inside a white panel. Numbers, feelings, words, rhymes and letters all look like the same
   multiple-choice question. This is the biggest "form, not adventure" problem.
2. **No second try.** In choice rounds a wrong tap immediately reveals the answer and moves on;
   there is no "try again" moment and no demonstration. (Accuracy already counts only the first
   try, and the signal mapper already records retries, so a retry flow needs no pipeline change.)
3. **Adaptation is invisible.** The modelled/guided scaffold only pulses a card; the companion never
   shows anything. Moving up a rung changes the task but not the world.
4. **Same game, same look.** A game replayed across stages looks identical: the scene comes from the
   game's category, not from the stage the child is in (e.g. simon-lights appears in 11 levels).
5. **The activity sits on a white panel** rather than in the place, so the storybook world stops at
   the edge of the game.
6. **Companion is beside the game, not in it:** it reacts to right/wrong but never points, looks at
   the answer, or demonstrates.
7. **No sound effects.** Audio is narration only (text-to-speech plus content audio keys whose files
   are not produced yet); taps, successes, retries and celebrations are silent.
8. **Environmental storytelling** exists on Home, place and journey screens (StoryScene), but game
   objects (options) have no relationship to the place (baskets in the orchard, bubbles by the
   cove, balloons on the hill...).

## Plan (this pass)

- A reusable **scene choice stage** replacing the card grid for every choice game: options become
  objects that belong to the place (baskets, balloons, bubbles, lily pads, carriages, signposts,
  islands), arrive with movement, bob, pop, and celebrate. The look is data (game x place), the
  mechanic is unchanged.
- A **try-again flow** for choice rounds: a first miss eliminates that option with a gentle wobble,
  the companion encourages and, if needed, demonstrates; the child tries again.
- **Visible scaffolding:** a pointing hand from the companion demonstrates (modelled), shows the
  first step (guided) or appears on request (hint); independent play gets encouragement only.
- **Visible adaptation:** the world gets richer as the child moves up a rung (more props, sky life);
  an eased round keeps the goal with fewer options.
- **Stage-themed play:** journey activities play in their stage's place, so the same game differs
  from stage to stage.
- **Games in the world:** activities sit on a ground stage in the scene, not a white form panel.
- **Sound effects:** small local, generated sound files (tap, success, gentle retry, celebration,
  pop, demonstration, unlock) through the existing AudioPort, always optional.
