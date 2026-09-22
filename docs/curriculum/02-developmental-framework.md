# Chapter 02: Developmental framework

This chapter describes the shape of the curriculum: the twelve domains that tag every skill, the six
age stages that describe typical ranges without gating anything, the six core principles the whole
specification is built on, and the two design stances that follow from chapter 01 — guided play, and
play that leaves the screen.

Every factual claim about children or about what works cites an evidence id in square brackets, for
example [ev.math.nrc-2009], and the entry is in `data/evidence/`. Where Nova has no supporting entry,
the text says "Nova's design decision" and the claim is not presented as a research finding. Chapter
01 sets out the honesty rules and the evidence model; this chapter applies them.

---

## 1. The twelve domains

A domain is a **tag**, not a container (spec principle 1). A skill may carry more than one — the
working-memory skills are tagged both `executive_function` and `memory` — and nothing in the engine
routes a child through a domain. Domains exist so that a skill can be found, so that parent
reporting can group states into something readable, and so that coverage gaps are visible.

**The twelve-domain split is Nova's design decision.** No entry in `data/evidence` defines a domain
list, and none of the programme sources was used as one. HighScope organises its curriculum into
eight content areas — Approaches to Learning; Social and Emotional Development; Physical Development
and Health; Language, Literacy and Communication; Mathematics; Creative Arts; Science and Technology;
Social Studies — carrying 58 key developmental indicators [ev.programs.highscope-2024], but that is a
curriculum organisation published by the programme, not an empirical developmental sequence, and
Nova does not adopt it.

Four of the twelve domains below have **no supporting entry in `data/evidence` at all**: cognitive,
problem solving, attention, and science and exploration. Three more are supported only at their
edges. Those are stated in place rather than collected in a footnote.

The `age_range` values named in each paragraph are informational only and never gate content
(section 2). Two skills exist in `data/skills` today, both in the math domain; the rest of the skill
map is authored in later tasks, so the skills described below are the intended shape of each domain,
not a listing of records that already exist.

### 1.1 Cognitive (`cognitive`, id prefix `cog.`)

Covers the general thinking operations that are not specific to any subject: categorising, cause and
effect, sequencing events, matching and sorting, object permanence at the youngest ages, and
analogies and simple deduction at the oldest. Across 2-8 the skills move from matching identical
objects and sorting by one obvious feature, through putting a three-picture story in order and saying
why one thing caused another, to completing a simple analogy and drawing a conclusion from two stated
facts.

**Evidence: none.** Nova has no entry that establishes this grouping, this content or this ordering.
Every skill in this domain is **Nova's design decision** and every one of them carries
`evidence_basis: judgment` with an explicit design inference, per spec 3.6. It is also skill-map only
in this specification: no games, difficulty ladders or assessment rules are written for it.

### 1.2 Executive function (`executive_function`, id prefix `ef.`)

Covers three components, and the three-part split is taken from Harvard's Working Paper No. 11, which
states that "Among scientists who study these functions, three dimensions are frequently highlighted:
Working Memory, Inhibitory Control, and Cognitive or Mental Flexibility" and defines each on page 2:
working memory "is the capacity to hold and manipulate information in our heads over short periods of
time"; inhibitory control "is the skill we use to master and filter our thoughts and impulses so we
can resist temptations, distractions, and habits and to pause and think before we act"; cognitive or
mental flexibility "is the capacity to nimbly switch gears and adjust to changed demands, priorities,
or perspectives" [ev.transfer.harvard-cdc-2011].

Across 2-8 the skills run from holding two items in mind at 3-4 to holding four at 5-6 and reordering
a held sequence at 5-7; from stopping on a signal at 3-4 to acting against a conflicting rule at 4-6
and suppressing a dominant response at 6-8; and from sorting by colour or by shape at 3-4 to
switching the sorting rule at 4-5 and adapting to a rule that changes without warning at 6-8. **Those
ages and that ordering are Nova's design decision**; the Harvard paper supplies the vocabulary and
supports no ordering.

Three honest caveats sit on this domain, all of them load-bearing. First, the source itself says the
three are not separate things: "In most real-life situations, these three functions are not entirely
distinct, but, rather, they work together to produce competent executive functioning"
[ev.transfer.harvard-cdc-2011] — so Nova's three skill groups are a design convenience the source
does not underwrite. Second, they may be less separable still at these ages: the authors of
[ev.transfer.scionti-2020] attribute their preschool findings to executive functions being less
modular at 3-6. Third, training one component does not reliably build another — near transfer to the
trained component g+ = 0.44 (k = 43), against "no convincing evidence of far-transfer" to the
untrained ones (g+ = 0.11, k = 17, p = .11) [ev.transfer.kassai-2019], an `emerging`, abstract-only
entry whose included ages are not stated. A Nova game that trains inhibition is never credited with
building flexibility.

This is a deep-coverage domain at ages 3-6: its skills get games, difficulty ladders, assessment
rules and transfer probes.

### 1.3 Language and literacy (`language_literacy`, id prefixes `lang.`, `lit.ar.`, `lit.en.`)

Covers three things that behave differently. Universal oral language (`lang.oral.`) is
language-independent in structure and needs only translated strings: following one-, two- and
three-step instructions, answering and then asking questions, turn-taking, describing a picture,
telling a simple story, and explaining reasoning, running from 2-3 to 5-8. Arabic literacy
(`lit.ar.`) and English literacy (`lit.en.`) are **separate subgraphs with different progressions,
not translations of each other** (spec 3.8, chapter 05).

For English, the ordering Nova uses has a source. The National Early Literacy Panel found six
variables with "medium to large predictive relationships with later measures of literacy
development" that held after IQ and SES were accounted for, with pooled correlations to later
decoding of alphabet knowledge r = 0.50, writing or writing one's name r = 0.49, phonological
awareness r = 0.40, rapid naming of letters or digits r = 0.40, oral language r = 0.33 and concepts
about print r = 0.34 — and alphabet knowledge and writing were significantly stronger predictors than
phonological awareness was [ev.literacy.nelp-2008]. These are correlations among predictors, not
causes. The causal evidence is separate: phonemic-awareness instruction produced d = 0.86 on
phonological awareness, 0.53 on reading and 0.59 on spelling, with larger effects in preschool and
kindergarten than in grade 1 and above, and with focused instruction on one or two skills beating a
combination of three or more [ev.literacy.nrp-phonemic-awareness-2000]; systematic phonics produced
d = 0.44 overall, and "Phonics instruction taught early proved much more effective than phonics
instruction introduced after first grade" (kindergarten d = 0.56, first grade d = 0.54, grades 2-6
d = 0.27) [ev.literacy.nrp-phonics-2000]. The same panel states the ordering directly: systematic
phonics in kindergarten "must begin with foundational knowledge involving letters and phonemic
awareness" [ev.literacy.nrp-phonics-2000]. So the English track runs listening and vocabulary, then
rhyme and syllables, then letters and initial sounds, then phoneme blending, then CVC decoding.

For Arabic, the picture is thinner and the track is built differently because the script and the
diglossia demand it: "With 28 consonantal phonemes but over 100 allographic forms, children must
learn that multiple shapes correspond to the same sound", vowelization "is essential early on" with
its benefit declining with age, kindergarten and first-grade pupils "struggled with StA-specific
phonemes, a gap persisting through Grade 6", and "only 21% of Palestinian Arabic words are identical
across varieties" [ev.literacy.asadi-2026] — an `emerging` review that pools no effect sizes and
draws mostly on school-age children. The one Arabic intervention study sequences syllable-level
phonological awareness in weeks 1-3 and phoneme-level awareness only in week 8, and introduces
letters as shape-and-dot pairs [ev.literacy.haj-2026]; that entry is `emerging`, is a single
unreplicated trial whose control group also improved substantially, and reports no between-group
effect size. A second review's closing note is the honest state of the field: it highlights "the need
for research to develop and evaluate pedagogical approaches suited to diglossic contexts"
[ev.literacy.taha-thomure-2025], abstract-only.

One caution applies to both tracks. In combined language-and-code interventions for at-risk
preschoolers, the words actually taught moved (proximal vocabulary g = 0.53) while standardised
vocabulary barely did (g = 0.08), and specific phonological-awareness subskills moved (g = 0.24 to
0.26) while the phonological-awareness composite did not (g = 0.08) [ev.literacy.cusiter-2025].
Teaching a letter sound teaches that letter sound.

Both literacy tracks are deep-coverage at ages 3-6. Universal oral language is skill-map only.

### 1.4 Math (`math`, id prefix `math.`)

Covers counting, number recognition and the numeral-quantity link, comparison and ordering, early
addition and subtraction, patterns, geometry, measurement and simple data, running from 2-4 to 6-8.

The ordering at the base of the domain has a source. The National Research Council sets out four
aspects of the "number core" — cardinality, the number word list, one-to-one counting
correspondences, and written number symbols — states that they are initially separate and must be
connected, and describes the sequence Nova uses: children "first connect saying the number word list
with 1-to-1 correspondences to begin counting objects. Initially this counting is just an activity
without an understanding of the total amount (cardinality). If asked the question How many are there?
after counting, children may count again (repeatedly) or give a number word different from the last
counted word. Connecting counting and cardinality is a milestone in children's numerical learning
path" [ev.math.nrc-2009]. That is a `developmental_framework` at `moderate` strength: a consensus
committee synthesis that establishes the ordering by argument rather than experiment and pools no
effect size, and whose own teaching-learning paths are "approximate, age-indexed steps, not an
invariant sequence every child follows".

Everything else in this domain — subitizing to three before recognising numerals, comparison before
ordering, concrete combining before symbolic addition — is **Nova's design decision**.

Two findings bound what the domain may claim. Both intentional teaching (g = 0.32) and exploratory
play (g = 0.21) were associated with positive effects on pre-primary maths learning, with **no
statistically significant difference between the approaches**, and effects on foundational number
and counting were the *smallest* reported (g = 0.21, against quantitative comparison g = 0.42 and
calculation g = 0.45), fading from post-test g = 0.34 to follow-up g = 0.20
[ev.math.sun-2026] — `emerging`, abstract-only. And across 101 preschool maths interventions, "only
7% of the studies demonstrated far-transfer effects, and these yielded small effect sizes"
[ev.math.munez-2026] — also `emerging`, abstract-only, and a vote count rather than a pooled
estimate. Math is a deep-coverage domain at ages 3-6.

### 1.5 Problem solving (`problem_solving`, id prefix `ps.`)

Covers trial and error, choosing a tool for a job, planning a sequence of steps, means-end reasoning,
puzzles, and trying a second strategy when the first fails. Across 2-8 this runs from repeating an
action until something works, through fetching the right object to reach a goal, to planning three
steps before acting and abandoning a failed approach deliberately rather than repeating it.

**Evidence: none.** The nearest thing Nova has is [ev.games.alotaibi-2024], which reports game type
as a significant moderator of the cognitive effect "with puzzle games having a larger effect than
other game types (g = 0.63 vs. g = 0.31)" — but that entry is rated `emerging` because its
participant, sample-size and inclusion figures cannot all be true together and it publishes no table
of included studies, so Nova does not build a domain on it. This domain is **Nova's design decision**
and is skill-map only.

### 1.6 Memory (`memory`, id prefix `mem.`)

Covers working memory, which it shares with executive function, plus recognition of familiar items,
visual memory for paired locations, episodic memory for retelling a sequence of events, and recall
after a delay. Across 2-8 this runs from recognising a familiar object at 2-4, through remembering
where a pair was hidden at 3-5 and retelling what happened at 4-6, to recalling something from a
previous session at 5-7.

Only the working-memory part has a source: the definition and the place of working memory in
executive function come from [ev.transfer.harvard-cdc-2011], and phonological memory appears among
the six predictors of later literacy in [ev.literacy.nelp-2008]. The recognition, visual-pair,
episodic and long-term skills, and the ordering among them, are **Nova's design decision**.

The domain also carries the sharpest warning in chapter 01. Working-memory training produced large
near transfer to the trained task (g = 0.80 against treated controls), small but reliable transfer to
other working-memory measures (g = 0.28 to 0.31) and no far transfer at all — nonverbal ability
g = 0.05, verbal ability g = 0.05, arithmetic g = 0.06 — leading its authors to describe the result
as "short-term, specific training effects that do not generalize to measures of 'real-world'
cognitive skills" [ev.transfer.melby-lervag-2016]. Nova builds memory games; it does not claim they
make a child cleverer. Memory is deep-coverage at ages 3-6.

### 1.7 Attention (`attention`, id prefix `att.`)

Covers focused attention (tracking a moving object, visual search in easy and crowded displays),
sustained attention over a short and then an extended task, selective attention (ignoring a
distractor), shifting attention when a cue changes, and divided attention across two cues. Across
2-8 this runs from following a moving object at 2-3 to holding two cues at once at 6-8.

**Evidence: none.** No entry in Nova's set is about attention as a domain. The closest adjacent
statement is that inhibitory control is what we use to "resist temptations, distractions, and
habits" [ev.transfer.harvard-cdc-2011], which is about inhibition, not about attention, and Nova does
not stretch it. This domain is **Nova's design decision** and is skill-map only, so it needs no games
or assessment rules in this specification. It does, however, appear in the difficulty model as the
Distractors and Cognitive-load dimensions (spec 3.3), which is where a game varies attentional demand
deliberately.

### 1.8 Visual-spatial (`visual_spatial`, id prefix `vs.`)

Covers shape matching, spatial vocabulary (in, on, under, behind), mental rotation, following a
simple map, reproducing block designs, and symmetry. Across 2-8 this runs from posting a shape into
a matching hole, through using spatial words correctly and copying a four-block design, to rotating a
shape mentally and completing a symmetrical pattern.

This domain has more evidence than most, and it is mixed. Spatial skill is trainable: g = 0.47 across
217 studies, stable across delays, transferring to other *spatial* tasks [ev.spatial.uttal-2013] —
`emerging`, abstract-only, spanning all ages including adults, with the age moderator unreadable.
Spatial and mathematical skill are moderately associated (r = .36), unmoderated by gender or grade
level, though fluid reasoning and verbal skill mediate part of the link [ev.spatial.atit-2022]. But
the causal version is small and its moderators run against Nova: spatial training moved maths at
g = .28, effects "increased in size" as participant age rose from 3 to 20, concrete manipulatives
beat computerised training, and transfer was largest where the maths outcome most resembled the
training [ev.spatial.hawes-2022] — `emerging`, abstract-only. Guided play is the one place spatial
content did well in Nova's evidence: it beat direct instruction on shape knowledge (g = 0.63) and
beat free play on spatial and maths vocabulary (g = 0.93) [ev.guided-play.skene-2022].

So Nova has a spatial domain because spatial skill is developed rather than fixed, and it does **not**
claim that a spatial game raises a child's mathematics. Skill-map only in this specification.

### 1.9 Fine motor (`fine_motor`, id prefix `fm.`)

Covers on-screen tapping and dragging accuracy, grasp, tracing lines and curves, drawing shapes,
scissors, and the precursors to forming letters. Across 2-8 this runs from a deliberate tap and a
short drag at 2-3, through tracing a curve and drawing a closed shape at 4-5, to forming letters at
5-7.

One thread has a source: the National Early Literacy Panel found writing, or writing one's own name,
among the six predictors of later literacy, correlating with later decoding at r = 0.49 — second only
to alphabet knowledge [ev.literacy.nelp-2008]. That is a correlation, not a cause, and it is about
writing rather than about fine motor control in general. Everything else in this domain, including
the ordering, is **Nova's design decision**.

This domain also makes the limits of a tablet obvious. Grasp and scissors cannot be practised or
observed on a screen at all; tapping and dragging accuracy is partly a property of the device. Where
the domain matters most it is off-screen, which is what section 5 is about. Skill-map only.

### 1.10 Social-emotional (`social_emotional`, id prefix `soc.`)

Covers naming emotions, calming strategies, empathy, sharing and turn-taking, cooperation, resolving
a disagreement, and self-awareness. Across 2-8 this runs from naming happy and sad in a picture at
2-3, through waiting for a turn and offering comfort at 3-5, to negotiating a shared rule at 6-8.

The vocabulary comes from CASEL's five competence areas — self-awareness, self-management, social
awareness, relationship skills and responsible decision-making [ev.sel.casel-2026] — and it is used
as a naming scheme and nothing more. That entry is rated `emerging`: it is an organisation's own
framework page, presents no research, and its two effectiveness claims carry no citations on the
page. The five competences are defined for all ages at once and are not operationalised into
observable behaviours for 3-6 year olds, so **every Nova social-emotional skill indicator is Nova's
own inference**, not CASEL's. The entry also notes that CASEL's emphasis on individual
self-management and autonomous decision-making is a cultural position as much as a developmental one,
and that nothing on the page establishes that these five categories carve up social-emotional
development the same way for Arabic-speaking children.

What such teaching achieves at this age is modest: in 79 studies of universal curriculum-based
programmes for 2-6 year olds, emotional competence d = 0.54 (95% CI 0.22-0.86), social competence
d = 0.30, behavioural self-regulation d = 0.28, reduced difficulties d = 0.19 and early learning
skills d = 0.18, with only 16.0% of studies rated high quality and **none of them a tablet
application** [ev.sel.blewitt-2018]. This supports the claim that these skills are teachable at this
age. It does not support the claim that Nova can teach them. Skill-map only.

### 1.11 Creativity (`creativity`, id prefix `cre.`)

Covers pretend play, free drawing, rhythm and music, storytelling, trying a new idea, and combining
materials in an unplanned way. Across 2-8 this runs from feeding a toy animal at 2-3, through a
drawing the child narrates and a story with a beginning and an end at 4-6, to inventing a variation
on a game's rules at 6-8.

Two entries touch it, neither strongly. The Montessori meta-analysis measured creativity as one of
its non-academic outcomes, at g = 0.26 [ev.programs.randolph-2023] — a small effect, from a
comparison of whole school environments rather than of any mechanic, and therefore not attributable
to anything Nova could reproduce. And Reggio Emilia contributes a design *value* rather than
evidence: the image of a child who "learns through the hundred languages belonging to all human
beings", with the atelier and the atelierista as constitutive elements [ev.programs.reggio-emilia-2024]
— an approach whose own organisation presents no effectiveness research at all. Tools of the Mind's
claim for make-believe play is a self-description [ev.programs.tools-of-the-mind-2024] whose
controlled evaluation did not reach significance on self-regulation [ev.programs.baron-2017], so it
is not used here either.

The sub-areas and their ordering are **Nova's design decision**. Skill-map only.

### 1.12 Science and exploration (`science_exploration`, id prefix `sci.`)

Covers observing and describing, predicting what will happen, distinguishing living from non-living,
weather and seasons, simple experiments, and measuring. Across 2-8 this runs from noticing and naming
a change at 2-3, through predicting whether something will sink or float at 4-5, to carrying out a
two-step comparison and reporting what happened at 6-8.

**Evidence: none.** HighScope includes "Science and Technology" among its eight content areas
[ev.programs.highscope-2024], which shows only that an early-years curriculum conventionally has
such an area — not that Nova's sub-areas or ordering are right. This domain is **Nova's design
decision** and is skill-map only.

---

## 2. Age stages

### 2.1 The six stages

| Stage | Ages | What it typically describes |
|---|---|---|
| **Discovery** | 2-3 | First deliberate actions on objects and people: matching, naming, one-step instructions, tracking, short bursts of attention, pretend play beginning |
| **Foundation** | 3-4 | One-to-one correspondence in counting, sorting by a single feature, rhyme and syllable play, holding two things in mind, stopping on a signal |
| **Early Learning** | 4-5 | Cardinality, initial sounds, letter recognition, switching a sorting rule, holding three things in mind, telling a short story |
| **School Readiness** | 5-6 | Blending phonemes, decoding first words, numerals to quantities, comparing and ordering, holding four things in mind, extended attention |
| **Early Academic** | 6-7 | Addition and subtraction within 10, reading short sentences, multi-rule switching, recall after a delay, resolving a disagreement with words |
| **Advanced Foundation** | 7-8 | Place value, adding and subtracting within 20, growing patterns, adapting to a changed rule, dividing attention across two cues, simple deduction |

### 2.2 Stages describe typical ranges and never gate content

**The six stage names are Nova's own labels.** No entry in `data/evidence` defines them, none is a
validated developmental period, and none carries a norm. They exist so that a parent can be told
roughly where a band of skills usually sits, and so that the skill map can be read at a glance.

The rules are enforced elsewhere in the specification and are repeated here because they are the
point of this section:

- A skill's `age_range` is **informational only** (spec 3.1). The only place the engine uses it is in
  deciding which skills fall in the deep-coverage set, and even there it is a scoping rule for
  authors, not a rule about children.
- **Age never gates a rung** (spec 3.3). Difficulty is child-relative. A 7-year-old who has not
  connected counting and cardinality gets rung r1 of the counting game; a 4-year-old who has gets r3.
- Nothing is locked, hidden or unlocked by a birthday. There is no "you must be 5 to play this".
- Per-domain "levels" shown to parents are derived from skill states, not stored (spec 3.2), so a
  stage label is never a stored property of a child.

The clearest evidence that these ages are approximations is a mismatch Nova records against itself.
The National Research Council places all four number-core components — including one-to-one counting
correspondences — and their coordination "to count n things and, later, say the number counted" inside
Step 1, "ages 2 and 3", with Step 2 at age 4 extending them to larger numbers [ev.math.nrc-2009].
Nova's `age_range` is [3, 4] for `math.count.one-to-one-5` and [4, 5] for `math.count.cardinality`:
later than the source on both. Those ages are **Nova's own judgment** and must not be attributed to
the NRC; the entry's `limits` field says so explicitly. The report also describes its
teaching-learning paths as approximate, age-indexed steps, "not an invariant sequence every child
follows".

### 2.3 A worked example: one child, four different levels

Layla is 5 years and 4 months old. The stage table calls that School Readiness (5-6). The stage label
describes none of the following, and changes none of it.

| Skill | Nova's `age_range` | Layla's state | What that means |
|---|---|---|---|
| `math.count.one-to-one-5` | [3, 4] | **Secure** | Accuracy above the secure threshold with hints and adult help both rare — the independence dimension, not just in-game success. She is above the stated band |
| `math.count.one-to-one-5` | [3, 4] | *not* Transfer | Secure is not Transfer. `probe.one-to-one-at-home` has not been attempted, so the state stops at Secure |
| `math.count.cardinality` | [4, 5] | **Emerging** | Asked "how many?", she counts again rather than saying the last word — the exact behaviour the NRC describes for a child who has not yet connected counting and cardinality [ev.math.nrc-2009]. She is below the stated band |
| English letter knowledge | [3, 5] | **Developing** | Recognises most uppercase letters, still needs hints for several |
| Working memory, hold 3 | [4, 5] | **Developing** | Succeeds at three items when the sequence is short, not consistently |
| Switching a sorting rule | [4, 5] | **Not yet** | Sorts reliably by one rule; the switch defeats her |

Layla is invented, and so are her states; only the two counting skills, their age ranges, the game
rungs, the adult prompt and the probe ids in this example are real records today. The rest name skills
authored in later tasks.

Four different states across five skills, in a single child, in one month. Three of the six rows sit
outside the age band Nova prints next to the skill.

What follows in the product: she plays `game.math.bear-apples` at rung **r1** (requests of 1 to 3,
only apples in the pile) because the cardinality work needs the easiest item complexity, while the
one-to-one work could sit two rungs higher; the adult prompt on that game — "After the child
finishes, ask: how many apples does the bear have? Let them answer before you say it." — is aimed at
exactly the skill she is Emerging on; and `probe.one-to-one-at-home` is scheduled, because a Secure
state without a passed probe is the definition of an untested claim. Nothing about "School Readiness"
enters any of those decisions.

---

## 3. Core principles

The six principles are stated in spec section 2. They are restated here with the consequence each one
has for the curriculum.

### 3.1 The skill graph is the source of truth

Domains are tags. Age is an expected range, never a gate.

Consequences: every skill is a node with prerequisites, and the prerequisite edges — not the domain,
not the age, not a level number — determine what comes before what. A prerequisite edge may carry its
own `evidence_refs`; an edge with none is a design inference and is labelled as one (spec 3.1). The
graph is acyclic and every reference resolves, both checked by the validator. Parent-facing "levels"
are derived from skill states at read time, never stored (spec 3.2). Section 2 above is the age half
of this principle.

### 3.2 Evidence basis is always declared

Empirical evidence, framework grounding and judgment are different things, and are never merged or
presented as equivalent.

Consequences: every skill and every game declares `evidence_basis`, the validator recomputes it from
the cited entries by the precedence rule empirical > framework > judgment, and errors on any mismatch
(chapter 01, section 3). A record that cites nothing is an error, so a judgment basis must name at
least one `expert_consensus` or `design_inference` entry and is therefore visible. The reporting rule
follows from it: "evidence-based" only for `empirical` basis at `moderate` strength or better,
"informed by" everywhere else. As the data stands, everything in Nova is "informed by".

### 3.3 Engagement, completion and within-game performance are not evidence of learning or transfer

A child can finish every level, enjoy the game and improve at it without acquiring the underlying
skill.

Consequences, as the spec states them:

- Engagement signals — session time, completion, streaks, stars, return visits — never feed skill
  state computation. Every signal in `data/signals.yaml` is tagged `learning` or `engagement`, and
  assessment rules may consume only `learning` signals; the validator rejects any rule that names an
  engagement signal.
- Within-game performance is one input, the *performance* dimension. It alone can never establish
  Secure or Transfer. Secure additionally requires the *independence* dimension — accuracy sustained
  with hints and adult help both rare. Transfer additionally requires a passed probe.
- Engagement metrics may be tracked for product health, and are never reported to parents as evidence
  of learning.

Chapter 01, section 6.10 is the evidence behind this principle. Section 4.5 below is what it looks
like inside a single game.

### 3.4 Transfer is assessed as its own dimension

It is measured, not inferred from performance.

Consequences: `cross_game` and `cross_context` probes are declared in game specs and assessment
rules; a `cross_game` probe is valid only when its `mechanic_id` differs from the mechanic of the
game that declares it, and the probed target must actually use the mechanic named. A reskin — new
animals, colours or sounds — is not a transfer probe and counts only as more performance evidence.
Every deep-scope skill is covered by at least two distinct mechanics. Delayed probes are optional; a
failed one does not demote a state, it lowers confidence and schedules review. Chapter 01, sections
6.1 and 6.4 are the evidence; [ev.transfer.barnett-ceci-2002] supplies the dimensions along which a
probe must actually differ.

### 3.5 Numbers are provisional until calibrated

No threshold, weight or cutoff is presented as scientifically validated without a pilot calibration
study.

Consequences: every quantity the assessment or adaptive logic depends on is a parameter record with
an id, a value, a status, a basis, a rationale and a calibration plan (spec 3.5). All ten current
parameters ship `provisional`. Nothing may be marked `validated` without a linked calibration study.
Anything a parent sees that derives from a provisional parameter is labelled an estimate (chapter
06). The specification claims no psychometric validity — no reliability, no validity, no norms — and
the mastery thresholds in the assessment rules are starting points, not findings.

### 3.6 Claims are non-clinical

Nova is "evidence-informed", never diagnostic, screening or clinical.

Consequences: no Nova output identifies, suggests or rules out a developmental condition, a delay or
a disorder. "Below the age band" is a statement about a skill state against an informational range,
not a finding about a child. Nova does not screen, and parent-facing material says so (chapter 06).
This is also why chapter 01 records the entries whose effects were larger for developmentally at-risk
children — ADHD g = 0.785, low socio-economic status g = 0.430, against smaller effects for typically
developing children [ev.transfer.scionti-2020] — as a fact about the literature and never as a reason
to categorise a user.

---

## 4. Guided play

### 4.1 The four parts

Nova's unit of design is a game that is simultaneously play and instruction. Four things must be
present, and the absence of any one of them turns it into something else:

1. **Play.** The child has real choices inside the activity — what to touch, in what order, how fast,
   which of several valid routes to take. Remove this and it is direct instruction.
2. **An objective.** The activity carries a stated learning goal that the adult (and the system)
   keeps in view, and that the child does not have to articulate. Remove this and it is free play.
3. **Scaffolding.** Support is available and is designed to fade: hints inside the game, and a short
   prompt for an adult alongside. Remove this and a child who gets stuck simply fails.
4. **Progression.** Difficulty moves along named dimensions, one at a time where possible, so that a
   failure is diagnosable. Remove this and the game is either always too easy or always too hard.

The evidence for this stance, and its limits, is [ev.guided-play.skene-2022] — a `meta_analysis` at
`moderate` strength, the highest rating anything in Nova's set carries. Guided play — play in which
an adult keeps a learning goal in view while the child keeps agency — was compared against direct
instruction and against free play. Against direct instruction it showed a greater positive effect on
early maths (g = 0.24), shape knowledge (g = 0.63) and task switching (g = 0.40); against free play,
on spatial and maths vocabulary (g = 0.93).

Four limits must travel with that result every time it is cited:

- **The benefit is specific, not general.** The authors state that "differences were not identified
  for other key outcomes": receptive vocabulary g = -0.06, behaviour regulation g = -0.03, inhibitory
  control g = -0.06. Guided play beat direct instruction on four outcomes and on none of the others,
  and the maths effect is small.
- **The study quality is weak.** 38 of the 39 studies were at high risk of bias, half used samples
  under 50, and heterogeneity was high where it mattered most (I-squared = 80.7% for spatial
  vocabulary against free play), while the clean maths estimate rests on few studies.
- **Every included intervention was human-guided** — a teacher, a parent or a researcher — and **no
  digital intervention was included at all.** This does not show that a tablet's scaffolding
  substitutes for an adult's.
- **The samples were predominantly US and English-speaking.** Nothing in it is specific to
  Arabic-speaking children.

A second entry points the same way and is not leaned on: [ev.games.alotaibi-2024] reports positive
pooled effects of game-based learning and states that "educator-guided game-play and scaffolding was
important for maximizing learning gains", but it is rated `emerging` because its own numbers are
internally inconsistent, so it corroborates rather than establishes. A third is closer to Nova's
content: both intentional teaching and exploratory play were associated with positive maths effects
with no significant difference between them, and within exploratory play, interventions using
contextual scenarios were much more effective (g = 0.47) than those without (g = 0.13)
[ev.math.sun-2026] — `emerging`, abstract-only. Nova reads that last contrast as support for putting
a mechanic inside a situation (a bear who wants apples) rather than presenting a bare task, while
noting that the entry cannot be checked beyond its abstract.

### 4.2 The four parts in a real game

`game.math.bear-apples`, in `data/games/math/counting.yaml`, is the worked example. It targets
`math.count.one-to-one-5` and `math.count.cardinality`.

**Play.** The bear asks for a number of apples; a pile with more apples than requested sits on the
table; the child drags apples onto the plate one at a time. Which apples, in which order, at what
speed, and whether to pause and recount are all the child's.

**Objective.** Stated in the spec as "Give the bear exactly the number of apples it asks for", and
tied to two named skills. The child is not asked to articulate it. The adult can read it in one line.

**Scaffolding.** Two in-game hints — "Each apple briefly lights up as its number is spoken" and "The
bear points at the plate and says the running count" — plus one adult prompt: "After the child
finishes, ask: how many apples does the bear have? Let them answer before you say it." Hints are
logged as the `hints_used` signal, which is how the independence dimension is computed; a child who
needs hints on most trials cannot reach Secure.

**Progression.** Three rungs. r1 varies nothing (requests of 1 to 3, only apples in the pile). r2
raises item complexity alone (requests of 1 to 5). r3 then raises distractors alone (apples mixed
with pears; only apples count). The other five difficulty dimensions — working-memory load, rule
complexity, abstraction, cognitive load, independence — are held fixed at their lowest anchor
throughout, so a failure at r3 points at distractors and not at anything else.

Against the four pillars for an educational app [ev.digital.hirsh-pasek-2015]: the mechanic is
*active* in the sense the authors mean — one drag per number word is "'minds-on' activity", not
decorative tapping; it is *engaged* because there is nothing else on the screen to attend to and no
reward interruption; it is *meaningful* because it sits in a situation (someone wants something) with
an obvious real-world twin; and it is *socially interactive* only through the adult prompt, which is
the weakest of the four for a single-player tablet game. That paper is a framework and not an
experiment: it does not show that an app built to the four pillars produces learning, and it offers
no validated rubric for scoring one, so this paragraph is an application of a design test, not a
result.

What the game's own evidence says is short. Its `evidence_basis` is `judgment`, its only citation is
[ev.design.drag-to-count-mechanic], and that entry's finding is written as the assumption it is:
"Moving one object per number word makes one-to-one correspondence visible and physical on a screen.
This is an assumption; Nova has not tested that it builds the skill." The closest empirical source
Nova has for guided play included no digital intervention [ev.guided-play.skene-2022], so there is
nothing better to cite.

### 4.3 Plan-Do-Review as a design pattern

Two of the programmes in chapter 01's matrix use an explicit plan-act-reflect routine. HighScope
names plan-do-review as central to the daily routine, in which "children make decisions about what
they will do, carry out their ideas, and reflect upon their activities with adults and other
children" [ev.programs.highscope-2024]. Tools of the Mind describes children making play plans before
carrying them out [ev.programs.tools-of-the-mind-2024].

Both are `program_evidence` at `emerging` strength: they describe what the programmes do, not what
the routine achieves. Where Tools of the Mind's routine has been evaluated, the result did not
support the programme's headline claim — maths improved significantly with a small effect size, while
self-regulation and literacy "favoured tools compared to other approaches" but "the effect was not
statistically significant" [ev.programs.baron-2017], from six US studies with "high risk of bias in
some of the included studies". **Nova therefore adopts plan-do-review as a design pattern with a
published precedent, and makes no claim that it builds self-regulation.**

Nova's mapping of the pattern onto a game loop is **Nova's design decision**; no source evaluates
plan-do-review in a digital context:

- **Plan.** Before a round, the child makes a choice that commits them to something: picking which
  character to play for, saying or tapping how many they think will be needed, choosing which of two
  rungs to try. The plan must be short, visible and the child's own, or it is a loading screen.
- **Do.** The round itself, with hints available and the objective unchanged from what was planned.
- **Review.** A reflection prompt after the round, addressed to the adult where one is present and to
  the child where one is not. Bear-apples' adult prompt is the review step: the adult asks "how many
  apples does the bear have?" and, crucially, waits.

The pattern is not mandatory on every game. Where it is used, the game spec's `scaffolding` and
`objective` fields carry it; nothing new is added to the schema.

### 4.4 Adult scaffolding prompts

Every game spec carries a `scaffolding.adult_prompt` (spec 3.7). It is one sentence, written for the
adult, not the child.

The two authored examples:

- `game.math.bear-apples`: "After the child finishes, ask: how many apples does the bear have? Let
  them answer before you say it."
- `game.math.number-match`: "Ask the child to count the group they chose out loud before they
  confirm."

The rules for writing one are **Nova's design decisions**: one sentence; it names an action the adult
takes, at a stated moment, relative to play; it asks a question rather than supplying the answer; it
tells the adult to wait, because the failure mode is an adult who answers for the child; and it does
not require the adult to have watched the screen.

The reason prompts exist at all comes from the evidence, and it is a negative reason as much as a
positive one. Every intervention in the guided-play meta-analysis was human-guided, and the thing
that separated guided play from free play was an adult keeping the learning goal in view
[ev.guided-play.skene-2022] — Nova cannot assume a tablet supplies that, so it asks for the adult
explicitly. The socially-interactive pillar makes the same argument from the app side: "an app will
be more educationally effective when it allows children to socially interact with others around the
new material" [ev.digital.hirsh-pasek-2015], a framework claim rather than a measured effect. The AAP
policy statement's emphasis on high-quality content and on the family's role, rather than on a screen
number alone, is read by Nova as endorsing an explicit adult-alongside role [ev.screens.aap-2026] —
Nova's reading of a consensus document, not a finding in it. And the corroborating note that
"educator-guided game-play and scaffolding was important for maximizing learning gains" comes from an
entry Nova rates `emerging` and does not lean on [ev.games.alotaibi-2024].

### 4.5 In-game success is not learning: what that means inside one game

Principle 3 is abstract until it is applied to a mechanic. Here it is applied to bear-apples.

A child can reach rung r3 of bear-apples without holding one-to-one correspondence. Several routes
are available: dragging apples until the plate "looks right" for a familiar small quantity; memorising
that "three" means a particular visual arrangement; or leaning on the second hint, in which the bear
says the running count, so that the child stops when they hear the target word without ever pairing a
number word with an object themselves. **That analysis is Nova's own judgment about its own mechanic,
not a research finding** — but the general shape of the worry is exactly what the evidence reports:
near transfer to the trained task with far transfer rare [ev.math.munez-2026], the words actually
taught moving far more than the standardised measure [ev.literacy.cusiter-2025], and specific training
effects that "do not generalize" [ev.transfer.melby-lervag-2016].

So the data structures refuse to let in-game success stand alone:

- `completion` is logged by this game and is tagged `engagement` in `data/signals.yaml`. The validator
  rejects any assessment rule that consumes it. Finishing the game means nothing to the skill state.
- The assessment rule `rule.math.count.one-to-one-5` requires the *performance* dimension for Emerging
  and Developing, adds the *independence* dimension for Secure — accuracy above the secure threshold
  "with hints and adult help both rare" — and requires the *transfer* dimension for Transfer. The
  hint-leaning route above raises `hints_used`, which is precisely what blocks Secure.
- Transfer requires `probe.one-to-one-at-home`, which moves to the `physical-counting` mechanic and
  real objects counted with a person, or `probe.cardinality-later`, the same task about a week later.
  Neither can be satisfied by playing bear-apples better.

---

## 5. Physical and offline play

### 5.1 The digital-to-physical pattern

A Nova activity can send the child off the screen. The pattern is the same every time:

1. The app names a short task in the real world. *Find something round and bring it to a grown-up.*
   *Build a tower of five blocks.* *Count the spoons on the table.*
2. The child does it away from the device, with an adult present.
3. The adult marks the outcome in the app — what the app asks for is specific and observable, not an
   impression.

These tasks are first-class records, not prose. A transfer task has its own id, its own skills, its
own `mechanic_id`, its own signals and its own scoring, and it need not be a full game (spec 3.4).
The mechanic vocabulary in `data/mechanics.yaml` carries the off-screen mechanics that make the
pattern checkable: `physical-counting`, `physical-build`, `physical-hunt`, `physical-sort`,
`physical-freeze`, `oral-sound-game`, `retell` and `print-hunt`.

The one authored example, `task.math.count-objects-at-home`, shows what "specific and observable"
means. Its description: "An adult names a set of real objects (for example, spoons on the table); the
child counts them aloud, then the adult asks how many there are." Its scoring: "The adult marks, in
the app, whether each object got one number word and whether the child stated the total without
recounting." Two binary observations, each mapped to one of the two skills the task targets. Its
signals are `accuracy`, `adult_assist` and `error_type`, all three tagged `learning`.

Games also carry a lighter version in their `offline_extension` field, which is a suggestion rather
than a scored task. Bear-apples': "Ask the child to set the table with exactly the right number of
spoons for the people eating."

### 5.2 Why an off-screen task counts as transfer and a reskin does not

`probe.one-to-one-at-home` changes the mechanic (`drag-to-count` to `physical-counting`), the
modality (screen to objects), the physical context (the app to the kitchen table) and the social
context (alone to with a person). A reskin — the bear becomes a rabbit, the apples become carrots —
changes none of them.

[ev.transfer.barnett-ceci-2002] is what makes that distinction principled rather than a matter of
taste. Its authors argue that the dispute over far transfer is unresolved because studies fail to
specify the dimensions along which transfer is claimed, "resulting in comparisons of apples and
oranges", and set out nine dimensions in two groups: content (the learned skill, its performance
change, the memory demand at test) and context (knowledge domain, physical context, temporal context,
functional context, social context, modality). A Nova probe names what it changes and what it
preserves, in exactly those terms — `probe.one-to-one-at-home` records `changes: From screen apples to
real objects at home, counted with a person` and `preserved: One number word for each object, in
groups of up to 5`. That entry is a framework and supplies no effects; it tells Nova how to describe
and design a transfer claim, nothing more, and it draws mostly on school-age, adolescent and adult
research rather than on 3-6 year olds.

### 5.3 Why the product is not screen-only

Four separate lines of evidence converge, and none of them is about Nova.

**Public-health guidance bounds the screen half.** WHO recommends that for 2-year-olds and for 3-4
year-olds "sedentary screen time should be no more than 1 hour; less is better", adds that "when
sedentary, engaging in reading and storytelling with a caregiver is encouraged", and states that "the
quality of sedentary time matters and interactive non-screen-based activities, such as reading,
storytelling, singing and puzzles are important for social and cognitive development"
[ev.screens.who-2019]. AAP's figure for the same ages is "<1 hour/day for toddlers and preschoolers",
explicitly offered as a range to be fitted to a family rather than as a cap, alongside "prioritizing
healthy activities (eg, sleep, play, physical activity, reading)" [ev.screens.aap-2026]. Both are
`expert_consensus`, capped at `moderate`, and neither measures a learning outcome or distinguishes
passive video from interactive use, so neither endorses or condemns an hour on a guided-play game.
What they do establish is that a product for this age cannot be designed to occupy more of the day,
and must not displace play, sleep or an adult reading aloud. **Nova's design decision** follows: a
session budget that fits inside an hour a day for the 3-5 band, with no engagement-maximising
mechanics.

**The screen is not the better medium for the learning itself.** In preschool cognitive training,
computerised training was effective (g = 0.281) but no more so than non-computerised (g = 0.373), and
the difference was not a significant moderator [ev.transfer.scionti-2020]. In spatial training,
"paradigms that used concrete materials (e.g., manipulatives) were more effective than those that did
not (e.g., computerized training)" [ev.spatial.hawes-2022] — `emerging`, abstract-only. In
phonemic-awareness instruction, computers were effective, but in classroom-teacher and computer
studies "the degree of transfer was less than that achieved in experimentally controlled studies"
[ev.literacy.nrp-phonemic-awareness-2000].

**Almost everything that works was delivered by a person.** Effective phonics came at tutoring
d = 0.57, small group d = 0.43 and whole class d = 0.39, none of it establishing that a tablet can
substitute [ev.literacy.nrp-phonics-2000]. Only 2 of 43 combined literacy interventions for at-risk
preschoolers were computer-delivered [ev.literacy.cusiter-2025]. None of the social-emotional
programmes behind the effects in [ev.sel.blewitt-2018] was a tablet application. And every study in
the guided-play meta-analysis was human-guided [ev.guided-play.skene-2022].

**The app framework says the same from the other side.** The fourth pillar of an educational app is
that it "allows children to socially interact with others around the new material"
[ev.digital.hirsh-pasek-2015] — a framework claim, not a measured effect, but one that points at the
adult rather than at the device.

### 5.4 What the offline half is not

It is not a claim that Nova teaches off-screen. In the offline half the adult teaches, or nobody
does; Nova names the task, records the outcome and uses it as the probe that the screen cannot
supply. Where a domain is largely physical — grasp and scissors in fine motor (1.9), cooperation and
resolving a disagreement in social-emotional (1.10) — Nova's honest position is that it has no
mechanic at all and does not pretend otherwise.

It is also not free evidence. An adult report is a `learning` signal, and like every other input it
feeds the confidence dimension, which reflects trial counts, consistency and recency (spec 3.4). How
much weight an adult's report should carry relative to an in-app trial is a calibration question, and
every parameter in this specification ships `provisional` (spec 3.5). What the offline half buys is
the only kind of evidence the evidence base says matters: a skill shown somewhere other than where it
was practised.
