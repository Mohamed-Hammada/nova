# Skill profiles, skill-aware recommendations, and Nova's sound

What this adds on top of the Journey-first app (commit 51d2f7a), which it keeps as it was: the
child still follows the journey, age still only picks the starting point, and nothing the engine
learns can open a locked stage or activity.

```
Raw events (with explicit error types)
  -> Signals -> Assessment -> Adaptive rung            (unchanged: RuleBasedAdaptiveModel)
  -> SkillEvidence (one row per session and skill, appended)
  -> SkillProfileBuilder -> SkillProfile (per skill)  -> mastery state stored with the session
  -> SkillGraph + RecommendationEngine (scored candidates, inside curriculum eligibility)
  -> Home: "My next adventure is..."   Grown-ups: descriptive skill profile + why
```

Every weight and threshold below is **provisional** (as in the curriculum spec) until a pilot.

## 1. Skill evidence

`core/skills/skill_evidence.dart`. `GameRuntime.completeSession` turns each session into one
`SkillEvidence` per skill: game, mechanic, activity, context (game + picture skin), rung, scaffold,
first-try rounds and correct ones, all help (`hints`) and the part the child asked for
(`hintRequests`), adult assists, retries, self-corrections, and a count per error type. It is saved
in the same transaction as the rest of the session (`skill_evidence_rows`, schema v5; the v4 -> v5
migration only creates the table) and never updated or deleted.

### Error types (`core/skills/error_types.dart`)

Games report these explicitly from what happened in the round, never from accuracy:

| Type | Reported by |
|---|---|
| `over_count`, `under_count` | drag-to-count (plate), tap-to-count, join/separate, number line, clap |
| `wrong_object` | a distractor on the plate, a wrong letter tile, a pairs board with many wrong turns |
| `distractor_selected` | any wrong option of a choice round |
| `chose_smaller`, `chose_bigger` | More or Less (the trial factory tags each wrong group) |
| `sequence_break` | light sequences, reading order |
| `impulsive_response` | acting on a "don't" item (go/no-go); any wrong first answer under 0.7 s |
| `missed_target` | a target that went by (go/no-go) |
| `rule_perseveration` | sorting by the old rule after it changed |
| `repeated_error` | the same mistake again on the retry of the same round |
| `hint_requested`, `self_correction`, `adult_assist` | support and self-monitoring, not mistakes |

`self_correction` (provisional definition): in Bear's Apples the plate went wrong (one too many,
or a wrong item) and the child fixed it before pressing Done. Nothing in the app records
`adult_assist` yet; the field and signal are ready for a grown-up "I helped" control.

## 2. Skill profile

`SkillProfileBuilder` (`core/skills/skill_profile_builder.dart`) rebuilds a profile from the
whole history, deterministically:

- **State** (Not yet .. Transfer) is judged on a rolling window of the last 5 sessions, pooled into
  one performance and one independence estimate and handed to the existing `MasteryEngine`, so the
  thresholds stay the skill's own assessment rule. Moving up is immediate; moving down needs the
  last **two** sessions in a row below the current state's accuracy threshold, and goes one step at
  a time. One bad session never erases mastery.
- **Transfer** needs Secure plus a pass somewhere new: a session in a mechanic the skill was not
  yet secure in, at the rule's transfer pass mark (0.7) and within Secure's help limits -- or a
  grown-up's report that the probe task went well at home (Progress: "Try it at home"). A new
  picture skin in the same mechanic never counts; accuracy alone never counts.
- **Trend**: the last two sessions against the (up to three) before them (+/-0.1).
- **Consistency**: spread of session accuracies in the window (sd <= 0.1 strong, <= 0.2 moderate).
- **Independence**: help per round against Secure's limits (<= limit independent, <= 3x occasional).
- **Confidence**: `trials / (trials + 10)`, weighted by consistency.
- **Repeated errors**: a mistake type seen at least 3 times, in at least 2 sessions of the window,
  and still present in the last session (once the child stops, it stops pulling the journey).
- Also: recent and rolling accuracy, attempts, sessions, contexts/games/mechanics, last practised,
  how many recent sessions in a row used the skill (`recentRun`), current rung and scaffold.

A repeated error also brings back guidance: `planSession` starts the next session of that skill
with a guided first round (the Adaptive Engine's rung is untouched).

## 3. Skill graph

`SkillGraph.fromContent` builds the prerequisite graph from the skills' `prerequisites` in the
bundle. It answers: prerequisites and dependents, ancestors, missing prerequisite evidence, weak
prerequisites (played and still needing practice), readiness, next skills, reinforcement skills and
a dependency order. It is an internal layer: it only changes scores, never eligibility.

## 4. Recommendation engine

`core/journey/recommendation_engine.dart`, called by `CurriculumEngine.evaluate`.

**Hard rules** (a candidate must pass all): in the child's current adventure; startable (stage open,
prerequisites done, and the existing age rule); playable in the child's language.

**Scored factors** (points; each candidate keeps its list, `RecommendationCandidate.explain()`):

| Factor | Points |
|---|---|
| fresh / already done | +30 / -25 |
| role: required, practice, challenge, optional, review | +50, +20, +12, +10, +8 |
| made for the child's age | +5 |
| neediest skill: needs practice (evidence) / new / developing / slipping / secure / transfer | +20 / +15 / +8 / +18 / -10 / -20 |
| builds on a weak prerequisite / reinforces a prerequisite of a hard skill | -20 / +20 |
| after a hard session: practice in the same area (same skill) / the same activity again, easier | +130 (+140) / +85 |
| after strong, independent play: an open challenge | +90 |
| repeated error on a skill it trains | +70 (+55 if just played) |
| accurate but still needs help (build independence) | +25 |
| secure skill, new mechanic (transfer check) / same mechanic, new context | +40 / +6 |
| secure skill not practised for 7+ days, as review | +15 |
| just played / same game / same mechanic / same domain / same skill | -40 / -20 / -8 / -15 / -10 |
| (halved when a learning reason applies; +10 for the same skill in a different game) | |
| played in the last three sessions | -15 |
| skill in each of the last 3 sessions (4 with a learning reason) | -30 |
| area already done often | -1.5 per completion |

The pick's **internal reason** is its strongest reason-bearing factor: `next_required`,
`practice_missing_skill`, `address_repeated_error`, `build_independence`, `reinforce_secure_skill`,
`transfer_probe`, `stretch`, `try_again_easier`, `variety`, `review` (`SelectionReason`). Home only
shows the child-facing `RecommendationReason` (next, practice, try again, stretch, a new way, ...).
Grown-ups see the reason in words at the bottom of the journey report ("Nova's next pick: ...").

The existing `RecommendationReason` enum keeps its name and meaning (it is what Home and the tests
read); the spec's internal "RecommendationReason" is `SelectionReason` here.

## 5. Sound

Four layers, each on its own players, each switchable:

| Layer | Where | Switch |
|---|---|---|
| Background music | `BackgroundAudioService` (`ui/audio/background_audio.dart`) | Music |
| Ambience | same service, second layer | Music |
| Interaction sounds, companion voice | `SoundEffects` / `Sfx` (`ui/audio/sound_effects.dart`) | Sound effects |
| Voice / narration | TTS (`speechPortProvider`) and recorded narration (`narrationPortProvider`) | Voice and narration |

**Background audio.** One looping player per layer (plus, during a crossfade, the one fading out;
a new change finishes any old fade at once). Crossfades take 1.2 s. A missing or undecodable asset
leaves that layer silent. Music is ducked during play. Switching Music off releases every player;
on again restarts the current scene. The app going to the background pauses; coming back resumes if
Music is on. On the web, a browser may refuse sound until the first tap; every tap "nudges" the
players.

**Journey-aware.** Screens mark their sound with `AudioSceneMarker`; the newest marked screen still
on the navigation stack wins (`BackgroundAudioDirector`). Home -> `home`; a stage -> its place
(`numbers`, `language`, `sounds`, `feelings`, `memory`, `discovery`, `movement`); a game -> its
place, ducked; closing a screen restores the one below.

**Interaction sounds.** tap (every jelly/round button), select, pick and drop (dragging), pop,
success, retry (a warm "hmm?", never a buzzer), hint, show, celebrate, unlock, whoosh, transition
(setting off for an activity). **Companion voice** (wordless chirps): wave (tapping the companion on
Home), happy, encourage (after misses in a row), thinking (with a hint), surprise, celebrate (a run
of right answers, the end of a strong level). Not every animation makes a sound, and the companion
never chirps twice within 0.9 s.

**Assets.** All generated locally, original, no downloads or licences:

- `python tools/sfx/generate_sfx.py` -> `app/assets/sfx/*.wav` (19 sounds).
- `python tools/sfx/generate_music.py` -> `app/assets/audio/music/*.mp3` and
  `app/assets/audio/ambience/*.mp3` (8 + 8 seamless loops, about 2.4 MB). Needs numpy, scipy and
  ffmpeg.

## 6. Settings

The gear on Home opens Settings directly: **Sound** (Music, Sound effects, Voice and narration),
**Play** (Hint button, Reduced motion), **Child** (name, age, companion, world), **Language**
(Arabic / English), **Graphics** (Auto / Low / Medium / High). Every change applies at once and is
saved by `SettingsSync` (`music`, `soundEffects`, `speech`, `hints`, `reducedMotion`, ...) and
restored by `loadSettings` before the first frame. Reduced motion works like the device setting
(the app's `MediaQuery.disableAnimations`). Learning evidence stays in Progress.

## 7. Grown-ups' Progress

Each skill card keeps the state ladder and adds, when there is evidence: trend, independence,
confidence, practice history (sessions, rounds, settings), last practised, transfer status, any
mistake that keeps coming back, self-corrections, and -- for a secure skill with a home probe task --
"Try it at home: ..." with "We did it!" / "Not yet" (recorded on the transfer dimension; a pass is
never taken away). Descriptive only: no score, no rank.

## 8. Verification

- Unit: `test/core/skills/*`, `test/core/journey/recommendation_engine_test.dart`,
  `test/core/game/skill_evidence_runtime_test.dart`, the persistence contract (in-memory and
  SQLite) and the v4 -> v5 migration.
- Widgets: `test/ui/audio/background_audio_test.dart`, `test/ui/settings/home_settings_test.dart`,
  `test/ui/progress/skill_profile_view_test.dart`.
- Browser: `scripts/web_smoke_test.(sh|bat)` now also switches music and sound effects off from
  Home's Settings, checks they stay off across a reload and that nothing audible is even loaded
  while off, switches them back on (the orchard's music and the effects load), finishes the stage
  through several kinds of game, and checks settings, journey and skill evidence after a reload.

## Open decisions

- All weights, the 5-session window, the 0.7 s impulsive threshold and the self-correction
  definition are provisional.
- Delayed transfer probes (`delayed-probe-interval-days`) are not enforced yet.
- Volume sliders per layer are supported by the service but not exposed.
- The Arabic strings added here (settings, profile, error names) need the same native educator
  review as the rest.
