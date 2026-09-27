# Communication and social skills (ENDCORE, adapted for ages 2-8)

## Sources (both read in full on J-STAGE, 2026-09-27)

1. **Fujimoto, M., & Daibo, I. (2007).** ENDCORE: A hierarchical structure theory of communication
   skills (コミュニケーション・スキルに関する諸因子の階層構造への統合の試み). *The Japanese Journal of
   Personality*, 15(3), 347-361. <https://www.jstage.jst.go.jp/article/personality/15/3/15_3_347/_article/-char/en>
   - Six main skills, each with four sub-skills (24-item scale ENDCOREs; one-item short form ENDCORE,
     which the authors note suits ratings of others).
   - **Basic skills:** self-control 自己統制 (holding back impulses, controlling emotions, moral
     judgement, meeting expectations), expressivity 表現力 (verbal, gestural, facial expression,
     conveying emotion), decoding 解読力 (the same four channels, read in others).
   - **Interpersonal skills:** assertion 自己主張 (leading, independence, flexibility, logic),
     other-acceptance 他者受容 (empathy, friendliness, yielding, respect), relationship regulation
     関係調整 (valuing and maintaining relationships, handling opinion and emotional conflict).
   - Three systems: expressive (expressivity -> assertion), responsive (decoding ->
     other-acceptance), management (self-control -> relationship regulation). The hierarchical model
     fitted (GFI .980, CFI .981, RMSEA .090).
   - **Limits:** 233 Japanese university students, self-report. Self-control reliability was modest
     (alpha .68). Not a measure for young children.
2. **Takahashi, Y., Okada, K., Hoshino, T., & Anme, T. (2008).** Social skills of preschoolers
   (就学前児の社会的スキル). *Japanese Journal of Educational Psychology*, 56(1), 81-92.
   <https://www.jstage.jst.go.jp/article/jjep1953/56/1/56_81/_article/-char/ja/>
   - 10,981 children aged 4-6 in 98 licensed nurseries across 21 prefectures, rated by childcare
     staff (2000-2006). Three stable factors: **cooperation** 協調 (helping, sharing, empathy),
     **self-restraint** 自己抑制 (handling conflict, taking turns, yielding), **self-expression** 自己表現
     (introducing oneself, leading a conversation, stating requests clearly). Scores predicted later
     problem behaviour.
   - **Limits:** a measurement study, not an intervention; nurseries were night-care affiliated.

Neither paper shows that a game improves these skills. Nova uses them to decide *which* skills to
practise and *what they look like* at this age; the claim stays at that level.

## How Nova uses the model

|                  | Expressing | Understanding | Managing |
|---|---|---|---|
| **With others** (interpersonal) | Asking clearly and kindly `sel.comm.assertion` (4-8) | Caring about others `sel.comm.other-acceptance` (3-8) | Keeping friendships good `sel.comm.relationships` (5-8) |
| **Basic** | Showing feelings `sel.comm.expressivity` (2-6) | Reading feelings `sel.emotion.faces`, `sel.emotion.situations` (existing) | Calming down `sel.comm.self-control` (3-8) |

- **Hierarchy as prerequisites.** Each interpersonal skill lists its basic skill as a prerequisite
  (relationships also builds on other-acceptance), so the skill graph and the recommendation
  engine favour the foundation first, as the model describes.
- **Games** (all `story-choice` except Show My Feeling, `emotion-match`), each with two ways to
  choose on the first rung and three on the second, everything read aloud:

  | Game | Skill | What the child does | Wrong choices report |
  |---|---|---|---|
  | Show My Feeling | expressivity | Picks the face that shows how they feel in a moment ("your tower fell down") | `distractor_selected` |
  | Kind, Clear Words | assertion | Picks what to say: a clear, kind request vs saying nothing vs grabbing/shouting | `passive_response`, `aggressive_response` |
  | Help a Friend | other-acceptance | Picks what helps or respects a friend | `self_focused`, `unkind_response` |
  | Calm Corner | self-control | Picks a calm way through a big feeling or a hard wait | `impulsive_response`, `aggressive_response` |
  | Fair Play | relationships | Picks what keeps it fair: take turns, share, make up | `passive_response`, `aggressive_response`, `self_focused` |

  The situations come from the preschool factors (e.g. taking turns and yielding from
  self-restraint; stating requests clearly from self-expression; helping and sharing from
  cooperation). Content: `app/lib/core/play/social_stories.dart` (English and Arabic, interim, for
  specialist and native-educator review).
- **Real life.** Each game has a `cross_context` transfer probe to a grown-up task (e.g. "Taking
  turns in real play"); Progress offers "Try it at home" once the skill is secure, and a reported
  success counts as transfer evidence -- the closest Nova gets to the other-rating the ENDCORE
  short form allows.
- **Journey.** Show My Feeling in Friendly Garden (age 2); Calm Corner and Help a Friend in Rainbow
  Hill (3); Kind, Clear Words in Story Bridge (4); Help a Friend, Calm Corner (required), Fair Play
  and Kind, Clear Words in Kindness Garden (5); Fair Play and Kind, Clear Words in the age 6-8
  journey.
- **Grown-ups.** Progress shows the 2x3 grid, basic skills under the interpersonal ones, each cell
  naming the state its games have shown ("Not played yet" until then). Descriptive, never a score.
- **Answer cards.** Sentences sit on flat cards with one text size for every option, so the length
  or shape of an answer never hints at it. (The kind option is often the longest sentence; content
  review should even out lengths.)

## Rule: every new game is based on published research

Added 2026-09-27 at the product owner's request. `tools/validate` (and the content compiler) reject a
game that is not on the frozen list `data/research_grandfathered.json` unless it cites at least one
**verified empirical or framework** source; a design inference alone is not enough. Japanese research
is preferred: the validator warns when none of a new game's evidence has `research_origin: [JP]`.
The frozen list is never updated by tooling, so re-baselining ids cannot bypass the rule.

## Open decisions

- All lines need review by an early-years specialist and a native Arabic educator; the Arabic uses
  the generic second person.
- The assessment rules use Nova's default, provisional thresholds (three-choice rounds have a
  one-in-three chance level; two-choice rounds one-in-two).
- Recorded narration for the new names is declared (`data/audio`) but not produced yet.
