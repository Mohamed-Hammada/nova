# Chapter 01: Research foundation

This chapter states what Nova means by "evidence-informed", how evidence is typed and weighed, how
each skill's and game's `evidence_basis` is computed, what Nova takes from the established
early-years programmes and what it refuses to take from them, and what the evidence does *not*
support.

It has two companion files that carry the detail:

- `docs/curriculum/research-log.md` — the record of opening each of the original brief's eight
  citations and checking it, including the three that were described inaccurately.
- `data/evidence/*.yaml` — the 35 evidence entries themselves, each with its source, type,
  strength, population, delivery mode, language, finding and limits. Section 5 below reproduces
  them in generated form.

Every factual claim in this chapter cites an evidence id in square brackets, for example
[ev.guided-play.skene-2022]. A statement with no bracketed id is either a claim about Nova's own
process (sourced to `research-log.md`) or is marked explicitly as Nova's design decision.

---

## 1. Purpose and honesty rules

### 1.1 What "evidence-informed" means here

Nova is an evidence-*informed* product, never a diagnostic, screening or clinical one (spec
principle 6). The phrase is not a softer synonym for "evidence-based". It means three specific
things, and excludes three others.

What Nova claims:

1. **Where a published source bears on a skill's importance or its developmental ordering, Nova
   cites that source and records what the source itself says its limits are.** The entry's `limits`
   field is not decoration; it is the part that governs how the finding may be used.
2. **Where no source exists, Nova writes the assumption down as an assumption.** A design inference
   is recorded in `data/evidence/design-inferences.yaml` with `verified: false`, capped at
   `emerging` strength, and the skill or game citing it carries `evidence_basis: judgment`.
3. **The difference is visible in the data, not only in the prose.** The validator recomputes
   `evidence_basis` from the cited entries and errors on any mismatch, so a claim cannot be
   upgraded by editing a chapter.

What Nova does not claim:

1. **That any Nova game has been shown to produce learning.** No such study exists. The closest
   thing Nova has to evidence that a playful, goal-carrying activity moves early maths is
   [ev.math.sun-2026], and that entry rests on a publisher-deposited abstract alone, is rated
   `emerging`, and reports its *smallest* effect (g = 0.21) on exactly the foundational number and
   counting skills Nova's worked example targets.
2. **That findings obtained with teachers, in classrooms, with physical materials, carry over to a
   tablet.** The meta-analysis behind Nova's guided-play stance included no digital intervention at
   all [ev.guided-play.skene-2022]. Where the question has been asked directly, computerised
   delivery was *not* superior: in preschool cognitive training, computerised g = 0.281 against
   non-computerised g = 0.373, with the difference not a significant moderator
   [ev.transfer.scionti-2020]; in spatial training, "paradigms that used concrete materials (e.g.,
   manipulatives) were more effective than those that did not (e.g., computerized training)"
   [ev.spatial.hawes-2022].
3. **That findings in English hold for Arabic.** This is not caution for its own sake. The National
   Reading Panel states that "Children learning to read in English showed larger effects than
   children learning to read in other alphabetic languages"
   [ev.literacy.nrp-phonemic-awareness-2000], and the National Early Literacy Panel searched only
   English-language journals [ev.literacy.nelp-2008]. Arabic is handled as its own track with its
   own, much thinner evidence base (section 6.6).

### 1.2 Expert judgment and design inference are not empirical evidence

Two of the eight evidence types are judgment class: `expert_consensus` (an authoritative body's
recommendation) and `design_inference` (Nova's own working assumption). Neither is a measurement.

`expert_consensus` is capped at `moderate` strength and `design_inference` at `emerging`, and the
validator enforces both caps. The cap is not a comment on the authors. WHO's screen-time guideline
is a serious document produced by a serious process, and it says so of itself: the guidelines "were
developed using the best available evidence, expert consensus and consideration of values and
preferences, acceptability, feasibility, equity and resource implications" [ev.screens.who-2019].
Consensus is part of the basis, so the entry cannot be treated as a measurement of anything Nova
does.

Judgment is a legitimate basis. Most of Nova's game mechanics rest on it, and both of Nova's
authored games declare `evidence_basis: judgment` today. The requirement is that it is always
visible and never counted as empirical.

### 1.3 A programme's own documentation is never evidence that the programme works

Three entries are `program_evidence`: HighScope's curriculum page [ev.programs.highscope-2024],
Tools of the Mind's programme overview [ev.programs.tools-of-the-mind-2024] and Reggio Children's
description of the Reggio Emilia approach [ev.programs.reggio-emilia-2024]. Each describes what the
programme *does*. None is an evaluation of what it achieves.

Two of the three assert effectiveness without supporting it. HighScope's page states that the
curriculum "has been validated through a direct evaluation of the curriculum" but cites no study on
the page; Nova has not verified that claim and does not rely on it [ev.programs.highscope-2024].
Tools of the Mind's site claims that "neuroscience proves early childhood is critical for
self-regulation development" and makes an unreferenced claim about state test rankings; neither is
relied on [ev.programs.tools-of-the-mind-2024]. Reggio Children's site presents no effectiveness
research at all, and Nova found none on it [ev.programs.reggio-emilia-2024].

Where a controlled evaluation of a programme exists, it is recorded as a separate entry and it is
the entry that carries the effectiveness claim — see [ev.programs.baron-2017] for Tools of the Mind,
[ev.programs.randolph-2023] for Montessori and [ev.programs.wwc-creative-curriculum-2013] for the
Creative Curriculum. The results are in section 4, and two of the three are unflattering.

### 1.4 The original brief's citations were checked

The brief that started this project cited eight sources. None had been verified. Every one was
opened and read against what the brief said about it. `research-log.md` is the record, one row per
citation.

Of the eight: five were confirmed as described, three were described inaccurately and have been
corrected in the entry, and none was dropped as false. The three corrections were:

- **Tools of the Mind.** The brief's description of the programme is accurate, but the effectiveness
  picture it implied is not supported. The Campbell systematic review of six US studies found that
  Tools significantly improved maths, though "the effect size was small", and that "although the
  average effect sizes for self-regulation and literacy favoured tools compared to other approaches,
  the effect was not statistically significant" [ev.programs.baron-2017]. The programme's headline
  outcome is the one that did not reach significance.
- **Guided play (Skene et al.).** The brief treated all 39 reviewed studies as pooled, when 17 were,
  and attributed the spatial-vocabulary advantage to a comparison against direct instruction when it
  was against free play [ev.guided-play.skene-2022].
- **The phonological-awareness source.** The cited item is a meta-analytic review of *combined*
  language-and-code interventions for *at-risk* 4-6 year olds, not a phonological-awareness
  meta-analysis. It does report a phonological-awareness effect, and it is small (g = 0.32, 95% CI
  [0.18, 0.45], from 46 effect sizes across 21 studies, I-squared = 71%), with the composite
  phonological-awareness measure barely moving at all (g = 0.08) [ev.literacy.cusiter-2025].

One further correction was made in an independent review round, and it is worth naming because it
concerns a quotation Nova relies on: the three executive-function definitions Nova uses come from
Harvard's Working Paper No. 11, page 2, not from the InBrief summary that was previously cited. The
InBrief names the three functions differently ("working memory, mental flexibility, and
self-control") and contains neither the term "inhibitory control" nor "cognitive flexibility"
[ev.transfer.harvard-cdc-2011].

Three sources were read and deliberately **not** recorded, each for a stated reason, all logged in
`research-log.md`: Diamond & Lee (2011) is a narrative review and the spec's closed type list has no
slot for one; Yassin et al. (2020), the study that establishes the four script-specific features
Nova's Arabic track is built around, is a single observational study and there is no type for one;
and Abu Ahmad & Share (2024) and Saiegh-Haddad (2022) could not be opened in full, so their designs
could not be confirmed. Two spec changes are proposed in the log to close these gaps
(`narrative_review` and `observational_study`). Until then, the Arabic track looks thinner in the
data than it is in reality, and that is stated rather than papered over.

### 1.5 The honesty rules, as rules

1. Every claim about children, about development or about what works cites an evidence id. Claims
   about Nova's own process cite `research-log.md` or the data file.
2. A claim with no supporting entry is dropped, or labelled "Nova's design decision" and never
   presented as a research finding.
3. Strength is reported, not rounded up. Where an entry is `emerging`, or rests on an abstract
   alone, or comes from a single unreplicated trial, the sentence making the claim says so.
4. Null, mixed and non-transferring results are stated plainly, in the same register as the positive
   ones. Several of Nova's most important entries are unhelpful to Nova (section 6).
5. Nothing found in English or in Western samples is assumed to hold for Arabic-speaking children.
6. A programme's own documentation is never evidence that the programme works (1.3).
7. `verified: true` means someone opened the primary source at the recorded URL. Where only an
   abstract could be read, the entry's `limits` says "Abstract only; full text not read" and nothing
   beyond the abstract is recorded.

---

## 2. Evidence types and strength

### 2.1 The eight types and their three classes

Type says **what kind of source** an entry is. It is a closed list; adding a type is a spec change
(spec 3.6).

| Type | Class | What it is |
|---|---|---|
| `systematic_review` | empirical | A protocol-driven review of primary studies, with no pooled effect sizes read |
| `meta_analysis` | empirical | A review that pools effect sizes, and the pooled values were read |
| `rct` | empirical | A randomised controlled trial |
| `quasi_experimental` | empirical | A controlled comparison without randomisation |
| `developmental_framework` | framework | A model of how development or learning works |
| `program_evidence` | framework | A programme's own description of what it does |
| `expert_consensus` | judgment | An authoritative body's recommendation |
| `design_inference` | judgment | Nova's own working assumption |

Where a source is titled "a systematic review and meta-analysis", Nova records `meta_analysis` only
if the pooled effect sizes were actually read in the primary source; otherwise `systematic_review`.
This is why [ev.math.munez-2026] is a `systematic_review` despite reviewing 101 interventions: it
pools no effect sizes, so its "over 90% reported positive outcomes" is a vote count, not an estimate.

Both framework-class types exist because Nova needs to cite models it does not treat as
measurements. `developmental_framework` is currently the only framework type available for a
conceptual model, which is an imperfect fit for at least one entry: Barnett & Ceci's taxonomy of
transfer [ev.transfer.barnett-ceci-2002] is a framework of *learning transfer*, not of development.
The class is right and the computed basis is therefore unaffected; a rename is proposed in
`research-log.md`.

### 2.2 The strength scale and the caps

Strength says **how much weight the entry deserves for Nova's use**. The scale is
`emerging | moderate | strong`.

Two caps are enforced by the validator:

- `expert_consensus` is at most `moderate`.
- `design_inference` is at most `emerging`.

**No entry in Nova's evidence set is rated `strong`.** Of the 35 entries, 16 are `moderate` and 19
are `emerging`. That distribution is the honest summary of this chapter: nothing Nova rests on is
both high-quality and directly about a tablet game played by a 3-6 year old, in Arabic or in
English, with a measured learning outcome.

### 2.3 The rubric

Strength is assigned by considering three things. This is the written rubric the spec (3.6) refers
to.

**Quality — how well the work was done, and whether Nova could see enough to judge.** A study's
design, its risk of bias, its sample sizes, its heterogeneity, its treatment of publication bias,
and its internal consistency. This dimension includes an access test that does real work here: where
only a publisher-deposited abstract could be read, the methods, the included-study list, the
heterogeneity statistics and the authors' own limitations were not seen, so the conduct of the work
**cannot be judged** and the entry is capped at `emerging` for that reason alone. Seven entries are
in that position: [ev.math.sun-2026], [ev.math.munez-2026], [ev.literacy.taha-thomure-2025],
[ev.spatial.uttal-2013], [ev.spatial.hawes-2022], [ev.transfer.sala-2019] and
[ev.transfer.kassai-2019]. Each one's `limits` field opens with the words "Abstract only; full text
not read." Quality also covers internal coherence: [ev.games.alotaibi-2024] reports 136 included
studies yet a total of 1,426 participants with study sizes of 20-112 and a median of 40 — figures
that cannot all be true together — and publishes no table of its included studies, which is why a
meta-analysis of 136 studies is rated `emerging`.

**Consistency — whether independent work agrees.** The transfer finding is Nova's clearest case of
agreement: four independent meta-analyses reach the same conclusion by different routes
([ev.transfer.melby-lervag-2016], [ev.transfer.sala-2019], [ev.transfer.kassai-2019],
[ev.math.munez-2026]), which is why Nova treats it as settled enough to design around even though
two of the four rest on abstracts. Where work disagrees, the disagreement is recorded rather than
averaged: [ev.transfer.scionti-2020] found, in 3-6 year olds specifically, that transfer *within*
the executive domains was as large as near transfer (far g = 0.318 against near g = 0.352), which
partly contradicts [ev.transfer.kassai-2019] — and the Scionti authors attribute it to executive
functions being less modular at this age, while warning that "task impurity" may inflate it.

**Directness — how close the evidence is to Nova's actual case.** Four questions, each of which can
lower a strength rating on its own:

- *Age.* Does the sample cover 3-6 year olds, or does it average across children, adolescents and
  adults? [ev.transfer.melby-lervag-2016] and [ev.spatial.uttal-2013] both span far beyond Nova's
  ages.
- *Outcome.* Is the measured outcome the one Nova cares about, or a proxy?
- *Delivery.* Teacher-led and physical, or digital? Of the 35 entries, four carry
  `delivery: digital`: one is a framework paper about apps rather than a study of one
  [ev.digital.hirsh-pasek-2015], one is a professional body's policy statement [ev.screens.aap-2026],
  and two are Nova's own design inferences. **None of the 35 is a study of a digital learning
  intervention.**
- *Language.* English, Arabic, or unstated? Findings in English are not assumed to hold for Arabic
  (1.1).

### 2.4 Type never implies strength

The two fields are independent, and in this data set they frequently point in opposite directions.
Four entries make the point:

| Entry | Type | Strength | Why |
|---|---|---|---|
| [ev.games.alotaibi-2024] | `meta_analysis` | `emerging` | Internally inconsistent participant and inclusion figures; no table of included studies; no heterogeneity statistics reported |
| [ev.literacy.haj-2026] | `rct` | `emerging` | A single cluster-randomised trial with no independent replication, a published Correction that lowered two reported effect-size ranges, and no between-group effect size stated anywhere in the results |
| [ev.transfer.harvard-cdc-2011] | `developmental_framework` | `moderate` | A careful synthesis by a scientific council; it supports the vocabulary and the developmental picture, and nothing more |
| [ev.programs.randolph-2023] | `meta_analysis` | `moderate` | 32 studies across eight countries, full text read, pooled values recorded — and still only `moderate`, because it compares whole school environments and includes no tablet game |

An `rct` outranking a `meta_analysis` by type tells you nothing. A well-conducted meta-analysis of
teacher-led classroom instruction still only indirectly supports a tablet game, and that is what the
directness dimension is for.

---

## 3. How `evidence_basis` is computed

### 3.1 The precedence rule

Each skill and each game declares `evidence_basis`. The value is not an editorial choice. It is
fully determined by the classes of the evidence it cites, with fixed precedence
**empirical > framework > judgment**:

1. If any cited entry is empirical class (`systematic_review`, `meta_analysis`, `rct`,
   `quasi_experimental`), the basis is `empirical`.
2. Otherwise, if any cited entry is framework class (`developmental_framework`, `program_evidence`),
   the basis is `framework`.
3. Otherwise the basis is `judgment`.

The validator recomputes the basis by this rule and errors on any mismatch with the declared value.
A skill or game that cites nothing at all is also an error: a `judgment` basis must cite at least
one `expert_consensus` or `design_inference` entry, so the judgment is explicit rather than silent.

Basis records the **class** only. It says nothing about how much weight the evidence deserves; that
is the separate strength field, and the reporting rule in 3.3 requires both.

Skill evidence and game evidence answer different questions. Skill evidence is about the skill — its
importance and its developmental ordering. Game evidence is about the *mechanic* — whether this kind
of game plausibly builds the skill. A game with no direct evidence for its mechanic declares
`judgment`, and that is the common case.

### 3.2 Three worked examples

**Framework — `math.count.one-to-one-5`.** The skill cites one entry, [ev.math.nrc-2009], the
National Research Council's consensus synthesis on early mathematics. Its type is
`developmental_framework`, which is framework class. No empirical entry is cited, so rule 1 does not
fire; rule 2 does. The declared basis is `framework`, which is what the validator computes.

This is the honest answer for this skill. The NRC report states the ordering Nova uses — children
"first connect saying the number word list with 1-to-1 correspondences to begin counting objects.
Initially this counting is just an activity without an understanding of the total amount
(cardinality)... Connecting counting and cardinality is a milestone in children's numerical learning
path" — but it is a committee synthesis, it establishes no ordering experimentally, and it pools no
effect size [ev.math.nrc-2009]. The same entry is cited on the prerequisite edge
`math.count.one-to-one-5 -> math.count.cardinality`, so the edge is not a bare design inference
either. What the entry does *not* support is Nova's ages: the NRC places all four number-core
components inside Step 1, "ages 2 and 3", whereas Nova's `age_range` is [3, 4] for one-to-one
correspondence and [4, 5] for cardinality. Those ages are Nova's own judgment, set later than the
source, and the entry's `limits` says so.

**Judgment — `game.math.bear-apples`.** The game cites one entry,
[ev.design.drag-to-count-mechanic], type `design_inference`, judgment class. Rules 1 and 2 do not
fire, so the basis is `judgment`. The entry's own finding is written as an assumption: "Moving one
object per number word makes one-to-one correspondence visible and physical on a screen. This is an
assumption; Nova has not tested that it builds the skill."

Note what did *not* happen. The skill this game targets has framework-class evidence, so it would
have been easy to cite the skill's evidence on the game and inherit a better-looking basis. That
would have been wrong: the NRC report says nothing about dragging objects on a screen. Skill
evidence and game evidence are separate levels of claim (3.1), and the game's basis stays
`judgment`.

**Empirical — a constructed example.** No skill or game in the current data has an `empirical`
basis. The validator's report confirms it: 2 skills, both `framework`; 2 games, both `judgment`.
Constructing one shows how the rule would fire. Suppose the English-literacy skill
`lit.en.pa.blend-phonemes` (to be authored in a later task) cited
[ev.literacy.nrp-phonemic-awareness-2000] and [ev.literacy.nelp-2008]. Both are `meta_analysis`,
which is empirical class, so rule 1 fires on the first one found and the basis is `empirical` —
regardless of how many framework or judgment entries are cited alongside. Because both entries are
also `moderate` strength, that skill would be the first thing in Nova that the reporting rule in 3.3
permits to be called "evidence-based" to a parent.

**A citation Nova deliberately did not make.** [ev.math.sun-2026] is a `meta_analysis`, so citing it
on the two counting skills would have flipped their basis from `framework` to `empirical`, and at
`moderate` strength it would have licensed the words "evidence-based". It was not cited, for two
reasons recorded in `research-log.md`. First, it is evidence that pre-primary maths interventions
work, not evidence for Nova's ordering of one-to-one correspondence before cardinality — the wrong
source for the claim. Second, its effect on exactly those skills is the smallest number it reports:
within intentional teaching, foundational number and counting g = 0.21, against quantitative
comparison g = 0.42 and calculation g = 0.45 [ev.math.sun-2026]. Citing it there would have bought a
stronger label with the wrong source. (The entry is in any case `emerging`, because only the
publisher-deposited abstract could be read.)

### 3.3 The reporting consequence

The basis and strength fields are not internal bookkeeping. They decide what parent-facing material
is allowed to say (spec 3.6; detailed in chapter 06):

- **"Evidence-based"** may be used for a skill or a game only when its `evidence_basis` is
  `empirical` **and** the strength of the cited empirical evidence is at least `moderate`. Both
  conditions, not either.
- **"Informed by"** is the wording in every other case — including `framework` basis, including
  `judgment` basis, and including `empirical` basis at `emerging` strength.

As the data stands today, **nothing in Nova may be described as "evidence-based"**: both authored
skills are `framework` (each citing [ev.math.nrc-2009]) and both authored games are `judgment` (citing
[ev.design.drag-to-count-mechanic] and [ev.design.match-symbol-mechanic] respectively). Every parent-facing string about them
must read "informed by". This is the expected steady state for game mechanics, which are design
inferences almost by construction, and it is the reason the wording rule is enforced in the data
rather than left to whoever writes the marketing copy.

---

## 4. Programmes matrix

Six established programmes and materials, and what Nova does with each. The "evidence" column gives
the type and the honest strength, and where the evidence is thin, null or absent it says so rather
than summarising it away.

| Programme | What it is | What kind of evidence exists (type, honest strength) | What Nova adopts | What Nova leaves out | Why |
|---|---|---|---|---|---|
| **Montessori** | A whole-school approach: child-chosen work from a prepared set of self-correcting physical materials, mixed-age classrooms, teacher as observer | `meta_analysis`, **moderate**. 32 studies, 1970-2020, eight countries, full text read. Composite academic g = 0.24 and composite non-academic g = 0.33; executive function g = 0.36, creativity g = 0.26, social skills g = 0.23, social studies g = 0.06. Larger for randomised designs, for preschool and elementary, and for *private* Montessori settings. The authors report a possible publication bias and grade two of the larger non-academic domains as low-quality evidence [ev.programs.randolph-2023] | The general stance that a structured environment in which the child chooses within constraints has measurable effects on non-academic as well as academic outcomes, in the early years | Any claim that a *particular* Montessori mechanic causes the effect: child choice, self-correcting materials and mixed-age grouping are not separated in the evidence. Also the physical material set, the mixed-age classroom and the teacher-as-observer role | The review compares whole school environments, so it cannot attribute the effect to any single component; the effects are small (largest academic component g = 0.26); the larger effect in private settings and the 1970-2020 span raise selection and era confounds; and no included study is a tablet game [ev.programs.randolph-2023] |
| **HighScope** | A preschool curriculum organised into eight content areas carrying 58 key developmental indicators, with active learning at its centre and a plan-do-review daily routine | `program_evidence`, **emerging** — the publisher's own description of its product, not an evaluation. The page asserts the curriculum "has been validated through a direct evaluation" but cites no study, and Nova does not rely on that assertion [ev.programs.highscope-2024]. Nova recorded no evaluation of HighScope | Plan-do-review as a *design pattern* for games: the child says what they will do, does it, and reflects on it with an adult. HighScope describes it as children who "make decisions about what they will do, carry out their ideas, and reflect upon their activities with adults and other children" [ev.programs.highscope-2024] | The eight content areas as an organising scheme (Nova has its own twelve domains, chapter 02), the 58 indicators, and the unsupported validation claim | The content areas are a curriculum organisation, not an empirical developmental sequence. Plan-do-review is adopted as a published example of an explicit plan-act-reflect routine, which is a design pattern with a source — not a mechanism shown to work, and nothing here shows it transfers to a tablet game or to Arabic-speaking children [ev.programs.highscope-2024] |
| **Tools of the Mind** | A preschool and kindergarten curriculum pairing Vygotskian theory with neuroscience, targeting self-regulation through make-believe play, with children writing or stating play plans before playing | Two entries. `program_evidence`, **emerging**, for the self-description [ev.programs.tools-of-the-mind-2024]. `systematic_review`, **emerging**, for the effect: six US studies (14 records) found Tools significantly improved maths but "the effect size was small", while "although the average effect sizes for self-regulation and literacy favoured tools compared to other approaches, the effect was not statistically significant", with "shortcomings in the quality of evidence" and "high risk of bias in some of the included studies" [ev.programs.baron-2017] | The idea that a child states a plan before acting, as a design pattern only — the same pattern HighScope calls plan-do-review | The claim that make-believe play or planning routines build executive function or self-regulation. Also the programme's uncited assertions about neuroscience and test rankings | The programme's headline target, self-regulation, is precisely the outcome on which the controlled evidence did not reach significance, and the reviewers say their conclusion "should be read with caution" given the small number of studies and methodological shortcomings [ev.programs.baron-2017]. Adopting the routine while declining the mechanism claim is the only reading the evidence supports |
| **Reggio Emilia** | An educational philosophy built on the image of a capable child who "learns through the hundred languages", with the atelier and atelierista, the environment as educator, and documentation that makes learning processes visible | `program_evidence`, **emerging**. Explicitly a philosophy, not an intervention with an evidence base. Reggio Children's own site presents no effectiveness research, outcome evaluations or comparative data, and Nova found none [ev.programs.reggio-emilia-2024] | Two design *values*, cited as values and never as evidence: documentation (making a child's process visible to the adult, which is what chapter 06's parent reporting is for) and many media of expression (which shapes the creativity domain, chapter 02) | Everything requiring the physical setting: the atelier, the atelierista, the environment as educator, pedagogical coordination, the daily presence of more than one educator, and family participation as the programme structures it | There is no effectiveness research to adopt. Nova may cite it as a source of design values, never as evidence that a mechanic works, and it is a municipal, teacher-led, physical-environment approach, so nothing in it supports a claim about a digital product [ev.programs.reggio-emilia-2024] |
| **The Creative Curriculum for Preschool** | A widely used commercial US preschool curriculum (Fourth Edition as reviewed) | `systematic_review`, **emerging**. Of 14 studies identified, four were reviewed against group design standards and two met them, together covering 364 children in 11 preschools. The verdict: "The Creative Curriculum for Preschool, Fourth Edition, was found to have **no discernible effects** on oral language, print knowledge, phonological processing, or math for preschool children." Average improvement indices: oral language +2, print knowledge -2, phonological processing -2, math +2 percentile points [ev.programs.wwc-creative-curriculum-2013] | **Nothing.** It is recorded as a calibration of expectations, not as a source of design | The whole curriculum | A widely used commercial early-years curriculum, reviewed against a fixed standard, showed no measurable effect on the outcomes tested. That is the honest counterweight to programme marketing, including Nova's own. Two qualifying studies from a single research programme is a thin base; "no discernible effects" against other preschool provision is not the same as "no effect", the improvement-index ranges straddle zero in both directions, and the report reviews an edition the developer replaced in 2011, with no effectiveness studies of the replacement completed [ev.programs.wwc-creative-curriculum-2013] |
| **Harvard Center on the Developing Child, executive-function materials** | A research synthesis by the National Scientific Council on the Developing Child, using an air-traffic-control metaphor for how executive functions work together | `developmental_framework`, **moderate**. Working Paper No. 11 states that "Among scientists who study these functions, three dimensions are frequently highlighted: Working Memory, Inhibitory Control, and Cognitive or Mental Flexibility" and defines each on page 2 [ev.transfer.harvard-cdc-2011] | The three-part vocabulary — working memory, inhibitory control, cognitive flexibility — as the structure of Nova's executive-function domain, quoted from Working Paper No. 11 rather than the InBrief summary, which uses different terms | Any claim that a particular activity builds a particular component, and any assumption that the three are cleanly separable in a 3-year-old | It is a synthesis, not a study and not an evaluation: it supports the vocabulary and the broad developmental picture only. The paper itself says that "In most real-life situations, these three functions are not entirely distinct, but, rather, they work together to produce competent executive functioning", so Nova's three separate skill groups are a design convenience the source does not underwrite [ev.transfer.harvard-cdc-2011] — and [ev.transfer.scionti-2020] reports that executive functions are less modular at this age, which is a further reason not to treat the three as independent targets |

Two notes on the matrix.

**The matrix is asymmetric on purpose.** Montessori and Harvard's materials contribute structure;
HighScope and Tools of the Mind contribute one design pattern between them; Reggio Emilia
contributes two values; the Creative Curriculum contributes nothing but a warning. That asymmetry
follows the evidence rather than the programmes' reputations. The two programmes with the loudest
claims about executive function and self-regulation are the two whose controlled evidence is
weakest.

**None of the six was evaluated as software.** Every entry in the matrix is teacher-led and
physical. Nothing in the matrix supports a claim that a tablet game reproduces any of it, and no row
should be read as implying that Nova inherits the programme's results by adopting its pattern.

---

## 5. The evidence table

Generated from `data/evidence/*.yaml` by `python -m nova_validate --evidence-table`, so it cannot
drift from the data. The `limits` field is not reproduced here — it is often longer than the finding
and it governs how the finding may be used, so read the YAML entry before citing anything below.

| id | type | strength | verified | population | delivery | language | finding |
|---|---|---|---|---|---|---|---|
| ev.design.counting-progression | design_inference | emerging | False | children 3-6 years | not_applicable | multi | Nova orders counting as one-to-one correspondence, then cardinality (the last number counted is the total). This is a working assumption, to be checked against the early-counting literature. |
| ev.design.drag-to-count-mechanic | design_inference | emerging | False | children 3-5 years | digital | multi | Moving one object per number word makes one-to-one correspondence visible and physical on a screen. This is an assumption; Nova has not tested that it builds the skill. |
| ev.design.match-symbol-mechanic | design_inference | emerging | False | children 4-6 years | digital | multi | Pairing a numeral with a group of that size links the symbol to the amount. This is an assumption; Nova has not tested it. |
| ev.digital.hirsh-pasek-2015 | developmental_framework | moderate | True | young children using educational apps; the article is a synthesis of learning-science research rather than a study of a sample | digital | en | The authors propose four "pillars" for judging whether an app is educational. Active: learning requires "'minds-on' activity that requires intellectual thinking", not just tapping. Engaged: "children need to be able to stay on task, engage with the material, and be free of distractions", which argues against decorative animations and reward interruptions. Meaningful: "information is processed at a deeper level when it meaningfully relates to past knowledge or when it is personally relevant". Socially interactive: "an app will be more educationally effective when it allows children to socially interact with others around the new material". They add that learning should be guided by a specific learning goal. They note the market problem directly: "more than 80,000 App Store apps are described as being education- or learning-based, however, there are currently no science-based standards to guide this determination." These four pillars are the design test Nova applies to every mechanic. |
| ev.games.alotaibi-2024 | meta_analysis | emerging | True | children aged 3-8 years; the paper reports 136 studies (from 232 screened) published 2013-2023, spanning Africa, Latin America, the Middle East, North America, Australia and the UK | mixed | en | The paper reports positive pooled effects of game-based learning on cognitive development (g = 0.46), social development (g = 0.38), emotional development (g = 0.35), motivation (g = 0.40) and engagement (g = 0.44), and reports game type as a significant moderator of the cognitive effect, "with puzzle games having a larger effect than other game types (g = 0.63 vs. g = 0.31)". It states that "educator-guided game-play and scaffolding was important for maximizing learning gains". The original brief's description of this source is accurate as far as what the paper says. |
| ev.guided-play.skene-2022 | meta_analysis | moderate | True | children aged 1-8 years; 39 studies reviewed (published 1977-2020), 17 in the meta-analysis (N = 3893); 24 studies in the USA, the rest across Australia, Belgium, Canada, China, Denmark, Kenya, the Netherlands, Portugal, Slovakia, South Africa, Switzerland, Turkey and the UK | teacher_led | en | Guided play - play in which an adult keeps a learning goal in view while the child keeps agency - was compared with direct instruction and with free play. Against direct instruction, guided play showed a greater positive effect on early maths skills (g = 0.24), shape knowledge (g = 0.63) and task switching (g = 0.40). Against free play it showed a greater effect on spatial/maths vocabulary (g = 0.93). The authors state plainly that "differences were not identified for other key outcomes": receptive vocabulary (g = -0.06), behaviour regulation (g = -0.03) and inhibitory control (g = -0.06) all showed essentially no difference. This is the strongest evidence Nova has for its core stance that a game should carry a learning goal while leaving the child real choices. |
| ev.literacy.asadi-2026 | systematic_review | emerging | True | monolingual first-language Arabic speakers; a PRISMA-guided search of PubMed Central, PsycINFO, ERIC, LLBA, Web of Science, Frontiers and Google Scholar for empirical studies published January 2000 to July 2025, yielding 92 unique records, 38 full texts examined and 29 studies included; the included studies run from kindergarten to about Grade 6 | not_applicable | ar | The one synthesis Nova found that covers all four of the Arabic features its literacy track has to design around. On letter forms - "With 28 consonantal phonemes but over 100 allographic forms, children must learn that multiple shapes correspond to the same sound", many letters differ only by dots, and "Visual-orthographic errors - mainly letter-shape confusions and faulty ligaturing - made up over a quarter of mistakes in Grades 1-4, second only to phonological errors". On diacritics - vowelization "is essential early on" and its benefit declines with age, while "For skilled readers, diacritics hinder speed and accuracy"; the move from fully vowelized to unvowelized print is a developmental juncture, not a formatting choice. On phonological awareness - "Kindergarten and first-grade pupils struggled with StA-specific phonemes, a gap persisting through Grade 6". On diglossia - "Corpus studies show that only 21% of Palestinian Arabic words are identical across varieties", and the review's central claim is that diglossia and orthographic complexity interact multiplicatively rather than additively. Together these are the reasons Nova runs Arabic as a separate track with its own progression, teaches positional letter forms explicitly, treats diacritics as a staged support to be faded, and does not reuse the English phonological-awareness sequence. |
| ev.literacy.cusiter-2025 | meta_analysis | moderate | True | 29 randomised controlled trials published before March 2023, reporting 43 interventions with 9,333 children aged 4-6 years who were at risk - either identified with a speech and/or language disorder or at risk of literacy failure on socioeconomic or academic grounds (55% male; 45% African American, 30% Hispanic, 20% White, 5% other); 25 of the 29 studies were conducted in the USA, with one each from Israel, Australia, Canada and Costa Rica | teacher_led | en | This is the source the original brief cited for "a small overall effect on phonological awareness", and it does contain such an effect, though the paper is about something wider: interventions that combine language work (vocabulary, grammar, morphology, inferencing) with code work (phonological awareness, letter knowledge, print concepts) for at-risk preschoolers. The composite effects were small - language g = 0.11 [0.03, 0.18] and code g = 0.23 [0.15, 0.31] - and the phonological-awareness-specific pooled effect was "small (g = 0.32, 95% CI [0.18, 0.45], p < 0.01)" from 46 effect sizes across 21 studies, with substantial heterogeneity (I-squared = 71%). Within phonological awareness the subgroups split sharply: composite phonological-awareness measures moved almost not at all (g = 0.08), while the specific, trainable skills moved a little - blending and elision g = 0.26, first-sound identification and alliteration g = 0.24. Language subskills behaved the same way: proximal vocabulary, the words actually taught, g = 0.53, against distal (standardised) vocabulary g = 0.08. Interventions that gave code and language equal emphasis did at least as well on both as those weighted to one. For Nova this is a caution, not an endorsement: these programmes move the narrow skill that was trained, and barely move the broad measure. |
| ev.literacy.haj-2026 | rct | emerging | True | 403 monolingual Palestinian-Arabic-speaking kindergarten children in Israel (189 boys, 214 girls), aged 57-70 months (M = 64.4, SD = 3.1), from mid-to-low SES kindergartens, with no reported hearing or vision impairment and no diagnosed developmental disability; 250 in the experimental group across 50 classrooms and 153 controls across 13 classrooms | teacher_led | ar | A cluster-randomised trial of a diglossia-centred kindergarten programme, and the best intervention evidence Nova has for Arabic. Randomisation was at the kindergarten level. Kindergarten teachers, after a 30-hour training course and with weekly in-class modelling and fidelity checks, delivered 45 sessions of 20 minutes, three a week for 15 weeks, in small groups of five; controls got business-as-usual instruction from the standard preschool curriculum. The programme's ordering is the part Nova can use directly. It trains structures that are identical in Spoken and Standard Arabic first and moves to Standard-Arabic-specific structures later; it trains syllable-level phonological awareness in weeks 1-3 and only reaches phoneme-level awareness in week 8; and it introduces letters in a deliberate sequence - first four letters that represent spoken phonemes and share a basic shape while differing only in dots, then a diglossic letter with its spoken phonetic neighbour, each pair presented together, with auditory discrimination of confusable phonemes built in. Multilevel models for the nested data found significant time-by-group interactions favouring the experimental group on every Spoken-Arabic and Standard-Arabic language and metalinguistic measure (receptive and expressive vocabulary, lexico-phonological representations, phonological awareness, morphological awareness), on letter-name and letter-sound knowledge, and on all three executive-function components. |
| ev.literacy.nelp-2008 | meta_analysis | moderate | True | children from birth to age 5 and kindergarteners; about 500 research articles screened from more than 8,000, across correlational studies of predictors and experimental/quasi-experimental studies of instruction (code-focused n = 78, shared reading n = 19, parent and home n = 32, preschool/kindergarten programmes n = 33, language enhancement n = 28) | mixed | en | Two results matter to Nova. First, on what predicts later reading: six variables had "medium to large predictive relationships with later measures of literacy development" and kept their predictive power after IQ and SES were accounted for - alphabet knowledge, phonological awareness, rapid automatic naming of letters or digits, rapid automatic naming of objects or colours, writing or writing one's name, and phonological memory. The pooled correlations with later decoding were: alphabet knowledge r = 0.50 (52 studies, 7,570 children), writing/writing name r = 0.49 (10 studies, 1,650 children), phonological awareness r = 0.40 (69 studies, 8,443 children), rapid naming of letters/digits r = 0.40 (12 studies, 2,081), oral language r = 0.33 (63 studies, 9,358) and concepts about print r = 0.34 (12 studies, 2,604). Alphabet knowledge and writing were significantly stronger predictors of decoding than phonological awareness was, and phonological awareness was in turn stronger than concepts about print or oral language. Second, on what instruction does: code-focused interventions had "significant and moderate to large effects across a broad spectrum of early literacy outcomes", and "the largest impact of code-focused interventions was on PA, with an average ES of 0.82". This is the source behind Nova's choice of alphabet knowledge, phonological awareness and name-writing as English literacy skills, and behind the ordering that puts letter knowledge at least as early as phonological awareness. |
| ev.literacy.nrp-phonemic-awareness-2000 | meta_analysis | moderate | True | preschool through 6th grade, from 1,962 screened articles; 52 articles yielding 96 treatment-control comparisons of phonemic-awareness instruction against another form of instruction or regular classroom instruction | mixed | en | Teaching children to manipulate phonemes in spoken words works, and its benefit reaches reading. "The overall effect size on PA outcomes was large, 0.86. The overall effect size on reading outcomes was moderate, 0.53. The overall effect on spelling was also moderate, 0.59." Effects were still significant on follow-up tests several months after training ended, and on standardised as well as experimenter-devised tests. Several moderators bear directly on Nova's design: effect sizes "were larger when children received focused and explicit instruction on one or two PA skills than when they were taught a combination of three or more"; teaching phoneme manipulation with letters beat teaching it in speech alone; small groups beat individual or whole-class instruction; treatments of 5 to 18 hours beat both shorter and longer ones; "Classroom teachers were very effective in teaching PA to children. Also, computers were effective"; and "Students in the lower grades, preschool, and kindergarten, showed larger effect sizes in acquiring PA than children in 1st grade and above". The panel also reports a clean negative control that is worth keeping: "Effects of training did not generalize to performance on math tests, indicating that halo/Hawthorne effects did not account for the findings" - which is also a reminder that a literacy gain is a literacy gain and nothing more. |
| ev.literacy.nrp-phonics-2000 | meta_analysis | moderate | True | children from kindergarten to 6th grade; 38 studies yielding 66 treatment-control comparisons of systematic phonics instruction against unsystematic or no phonics instruction | teacher_led | en | "The mean overall effect size produced by phonics instruction was moderate in size and statistically greater than zero, d = 0.44." The age pattern is the part Nova needs: "Phonics instruction taught early proved much more effective than phonics instruction introduced after first grade. Mean effect sizes were kindergarten d = 0.56; first grade d = 0.54; 2nd through 6th grades d = 0.27." For children at risk the early effects were larger still - d = 0.58 for at-risk kindergarteners and d = 0.74 for at-risk first-graders. The panel also states that "To be effective, systematic phonics instruction introduced in kindergarten must be appropriately designed for learners and must begin with foundational knowledge involving letters and phonemic awareness", which is the ordering Nova's English track uses: letters and phonemic awareness first, then letter-sound decoding. |
| ev.literacy.taha-thomure-2025 | systematic_review | emerging | True | teaching and learning in Arabic diglossic contexts; a PRISMA search of eight education and social-science databases plus grey literature covering 1970-2021, screening 927 Arabic and English records and including 101 studies | teacher_led | ar | A PRISMA systematic review of the educational, rather than psycholinguistic, side of Arabic diglossia. Its descriptive synthesis identifies five recurring themes across the 101 included studies: diglossic distance, the achievement gap, prestige and attitudes, policy, and exposure to Standard Arabic including parental engagement. Its recommendations include "integrating simplified standard Arabic in early childhood education", applying evidence-based methods in teacher training, and "expanding home-based exposure to Standard Arabic through accessible, engaging resources", and it concludes by highlighting "the need for research to develop and evaluate pedagogical approaches suited to diglossic contexts". Nova records it for two reasons: it independently corroborates that diglossic distance is the organising problem of early Arabic literacy, and its closing sentence is the honest statement of where this field stands - the pedagogy has largely not been evaluated. |
| ev.math.munez-2026 | systematic_review | emerging | True | 101 mathematics interventions for preschool-aged children (3-6 years) conducted across 25 countries over the past 25 years; half of the studies targeted children from low-SES backgrounds | mixed | multi | Over 90% of the studies reported positive outcomes. But the review's central finding is about the shape of those gains: "gains were predominantly characterized by near-transfer to trained skills. Transfer to broader, more general mathematical abilities or untrained skills was not frequent. In fact, only 7% of the studies demonstrated far-transfer effects, and these yielded small effect sizes." Just over a third of studies included long-term follow-up, so "the sustainability of intervention effects remains largely unknown, making the documented 'fade-out' effect a persistent concern". The review also reports that a substantial proportion of studies had only partial or no control for confounders such as pre-existing cognitive ability and socioeconomic disparity, that fidelity of implementation - particularly participant responsiveness - was frequently unreported, that nearly half the studies ran under conditions of low ecological validity (researcher-led, isolated one-to-one sessions), and that parent-focused interventions were both uncommon and less consistently effective than school-based ones. This is the single most important source behind Nova's Transfer state: a child who gets better at a trained maths task usually does not, on this evidence, get better at maths. |
| ev.math.nrc-2009 | developmental_framework | moderate | True | children from about age 2 through kindergarten; a committee synthesis of the research literature, not a study of a sample | mixed | en | The committee sets out four aspects of the "number core" - cardinality, the number word list, 1-to-1 counting correspondences, and written number symbols - and states that they are initially separate and must be connected. On the ordering Nova had been assuming, the report is explicit: children "first connect saying the number word list with 1-to-1 correspondences to begin counting objects. Initially this counting is just an activity without an understanding of the total amount (cardinality). If asked the question How many are there? after counting, children may count again (repeatedly) or give a number word different from the last counted word. Connecting counting and cardinality is a milestone in children's numerical learning path". It also states that one-to-one counting correspondence means "each object is paired with exactly one number word", and it places both in Step 1 of the number core (ages 2-3), with later 2- and 3-year-olds coordinating the components "to count n things and, later, say the number counted". This is the source that replaces Nova's design inference for the counting ordering: one-to-one correspondence in counting precedes the understanding that the last word counted is the total. |
| ev.math.sun-2026 | meta_analysis | emerging | True | preschool and kindergarten children in 74 studies published 2000-2025, classified by dominant pedagogical emphasis as intentional teaching (k = 56) or exploratory play (k = 18), yielding 566 effect sizes; the abstract states no age band and names no countries | mixed | unstated | Both pedagogical approaches were associated with positive effects on children's learning, and the difference between them was not statistically significant: intentional teaching g = 0.32, exploratory play g = 0.21. Within intentional teaching, effects were larger for advanced numeracy outcomes (quantitative comparison g = 0.42; calculation g = 0.45) than for foundational number and counting skills (g = 0.21). Effects attenuated over time - post-test g = 0.34 versus follow-up g = 0.20 - which the authors call partial fadeout. Within exploratory play, interventions using contextual scenarios were much more effective (g = 0.47) than those without (g = 0.13), and effects were present for maths-specific outcomes (g = 0.26) but absent for non-maths outcomes (g = -0.01). For Nova this is the best available support for the claim that a playful, goal-carrying maths activity can produce learning, and it is also a warning: the effect on exactly the skills Nova's counting slice targets is the smallest one reported. |
| ev.programs.baron-2017 | systematic_review | emerging | True | children in six studies (14 records) of the Tools of the Mind curriculum, all conducted in the USA | teacher_led | en | The review pooled six studies (randomised controlled trials and quasi-experimental designs), all from the USA. Results were mixed rather than positive across the board: Tools significantly improved children's maths skills relative to comparison curricula, but "the effect size was small", and although "the average effect sizes for self-regulation and literacy favoured tools compared to other approaches, the effect was not statistically significant". The programme's headline target - self-regulation - is therefore the outcome on which the controlled evidence did not reach significance. |
| ev.programs.highscope-2024 | program_evidence | emerging | True | preschool children in HighScope classrooms (the page states no age band) | teacher_led | en | HighScope's own documentation states that the preschool curriculum covers eight content areas - Approaches to Learning; Social and Emotional Development; Physical Development and Health; Language, Literacy and Communication; Mathematics; Creative Arts; Science and Technology; Social Studies - carrying 58 key developmental indicators (KDIs). It describes active learning as the centre of the curriculum and names the plan-do-review sequence as central to the daily routine, in which "children make decisions about what they will do, carry out their ideas, and reflect upon their activities with adults and other children". Nova uses this as a published example of how one established programme organises early-years content and of an explicit plan-act-reflect routine. |
| ev.programs.randolph-2023 | meta_analysis | moderate | True | students from preschool to high school in 32 studies published 1970-2020, across eight countries (18 studies in the USA, 4 in Turkey, 3 in Switzerland, one each in England, France, Malaysia, Oman, Iran, the Philippines and Thailand) | teacher_led | multi | Across 32 studies comparing Montessori with traditional education, "Montessori students performed about 1/4 of a standard deviation better than students in traditional education" on academic outcomes and "about 1/3 of a standard deviation higher ... on non-academic outcomes, including self-regulation (executive function), well-being at school, social skills and creativity". Effects were "greater for randomized than non-randomized study designs, greater for preschool and elementary school than for middle and high school, and greater for private Montessori compared to public Montessori settings". The full text gives the pooled values behind those fractions: composite academic g = 0.24 (general academic ability g = 0.26, mathematics g = 0.22, language g = 0.17, social studies g = 0.06) and composite non-academic g = 0.33 (inner experience of school g = 0.41, executive function g = 0.36, creativity g = 0.26, social skills g = 0.23). Nova takes from this that a structured, child-chosen, self-correcting materials environment has measurable non-academic as well as academic effects in the early years. |
| ev.programs.reggio-emilia-2024 | program_evidence | emerging | True | children in Reggio Emilia's municipal infant-toddler centres and preschools (birth to 6) | teacher_led | en | Reggio Children describes the approach as "an educational philosophy based on the image of a child with strong potentialities for development and a subject with rights, who learns through the hundred languages belonging to all human beings, and grows in relations with others". The site names as constitutive elements the atelier and the atelierista, "the environment as educator", "documentation for making creative knowledge processes visible", pedagogical coordination, the daily presence of more than one educator, and family participation. |
| ev.programs.tools-of-the-mind-2024 | program_evidence | emerging | True | preschool and kindergarten children in Tools classrooms | teacher_led | en | Tools of the Mind's own documentation states that the programme "pairs Vygotskian theory with neuroscience", that "Vygotskian theory recognizes the tremendous developmental potential of a certain kind of play - make-believe play", and that its central target is self-regulation, which it calls "the biggest predictor of success in school and life". It describes children planning their play (play plans) before carrying it out. This confirms the original brief's description of the programme as focused on executive function/self-regulation through make-believe play. |
| ev.programs.wwc-creative-curriculum-2013 | systematic_review | emerging | True | preschool children; of 14 studies identified, two met WWC evidence standards (one randomised controlled trial without reservations, one with reservations, both from the Preschool Curriculum Evaluation Research Consortium, 2008), together covering 364 children in 11 full-day preschools in Georgia, North Carolina and Tennessee | teacher_led | en | The report states that "The WWC identified 14 studies that investigated the effects of The Creative Curriculum for Preschool, Fourth Edition, on the school readiness of preschool children", that four were reviewed against group design standards, that two met the standards (one without reservations, one with), that "Two studies do not meet WWC evidence standards" and that "The remaining ten studies do not meet WWC eligibility screens for review in this topic area". On the two that qualified, the verdict is blunt: "The Creative Curriculum for Preschool, Fourth Edition, was found to have no discernible effects on oral language, print knowledge, phonological processing, or math for preschool children." Table 1 gives the average improvement indices behind that rating - oral language +2 (range -6 to +9), print knowledge -2 (-7 to +8), phonological processing -2 (-4 to +1) and math +2 (-5 to +8) percentile points - with the extent of evidence rated "medium to large" in all four domains. This is the honest counterweight to programme marketing: a widely used commercial early-years curriculum, reviewed against a fixed standard, showed no measurable effect on the outcomes tested. |
| ev.screens.aap-2026 | expert_consensus | moderate | True | children and adolescents; the policy covers infancy through adolescence | digital | en | The American Academy of Pediatrics' current policy statement moves away from a single screen-time number without abandoning numbers altogether. Under "Set time boundaries" it states that "The amount of screen media time spent per child might vary based on each family, their needs, and school nights versus weekends", and that "Time limits might range from <1 hour/day for toddlers and preschoolers to 1 to 2 hours/day or more of entertainment (not school-related) media for school-aged children and teens" - so for Nova's 3-5 year olds AAP's own figure is under one hour a day, offered as guidance to be fitted to a family rather than as a cap. It adds that "The most important considerations are high-quality content and prioritizing healthy activities (eg, sleep, play, physical activity, reading)", that "Infants do not learn from digital media, but occasionally viewing brief, high-quality videos (e.g., Sesame Street) is not detrimental", and that families should "Avoid screen exposures an hour before bedtime and devices in the bedroom". The statement's abstract frames the wider argument: "when this digital ecosystem is designed with children's unique developmental needs in mind, it can support learning and well-being", while ecosystems "that prioritize engagement and commercialization often encourage prolonged use, which in turn can displace healthy behaviors (eg, movement behaviors, sleep)", and "'media and children' cannot be viewed solely through the lens of individual child behaviors or screen limits alone". For Nova this endorses three design commitments - an explicit adult-alongside role, content quality over minutes, and no engagement-maximising design - and one numeric one: a session budget that fits inside an hour a day for the 3-5 band. |
| ev.screens.who-2019 | expert_consensus | moderate | True | all healthy children under 5 years of age, irrespective of gender, cultural background or socio-economic status | not_applicable | multi | WHO's recommendations on sedentary screen time, quoted from the guideline: for infants (less than 1 year) "screen time is not recommended"; for children 1-2 years, "for 1-year-olds, sedentary screen time (such as watching TV or videos, playing computer games) is not recommended. For those aged 2 years, sedentary screen time should be no more than 1 hour; less is better"; for children 3-4 years, "sedentary screen time should be no more than 1 hour; less is better". In every band the guideline adds that "when sedentary, engaging in reading and storytelling with a caregiver is encouraged", and it states that "the quality of sedentary time matters and interactive non-screen-based activities, such as reading, storytelling, singing and puzzles are important for social and cognitive development". WHO also recommends at least 180 minutes of physical activity a day for 1-4 year olds and 10-13 hours of sleep for 3-4 year olds. This is a hard design constraint on Nova: a product for 3-6 year olds must fit inside an hour a day that WHO would rather were shorter, and must not displace play, sleep or adult reading. |
| ev.sel.blewitt-2018 | meta_analysis | moderate | True | children aged 2-6 years in centre-based early childhood education and care; 79 unique studies with 18,292 participants, 63 of them in the meta-analysis; 51 studies (64.6%) from North America and 21 (26.6%) from Europe, with a few from Australia, Africa, the Middle East and South America; teachers delivered 53 of the interventions (67.1%) and specialists 22 (27.8%) | teacher_led | multi | Universal, curriculum-based social-emotional programmes in early-years centres produce real but modest gains across five outcome families, compared with controls: emotional competence d = 0.54 (95% CI 0.22-0.86), social competence d = 0.30 (0.18-0.42), behavioural self-regulation d = 0.28 (0.11-0.46), reduced behavioural and emotional difficulties d = 0.19 (0.11-0.28) and early learning skills d = 0.18 (0.02-0.33). This is the age band Nova actually targets, which is why it is recorded rather than a larger K-12 meta-analysis, and it is the number Nova should have in mind when deciding how much a social-emotional feature can be claimed to do. |
| ev.sel.casel-2026 | developmental_framework | emerging | True | "all young people and adults"; the framework is not age-specific and the page states no age band | not_applicable | en | CASEL defines social and emotional learning as "the process through which all young people and adults acquire and apply the knowledge, skills, and attitudes to develop healthy identities, manage emotions and achieve personal and collective goals, feel and show empathy for others, establish and maintain supportive relationships, and make responsible and caring decisions", and organises it into five core competence areas, each defined on the page: self-awareness ("the abilities to understand one's own emotions, thoughts, and values and how they influence behavior across contexts"), self-management ("the abilities to manage one's emotions, thoughts, and behaviors effectively in different situations and to achieve goals and aspirations"), social awareness ("the abilities to understand the perspectives of and empathize with others, including those from diverse backgrounds, cultures, and contexts"), relationship skills ("the abilities to establish and maintain healthy and supportive relationships and to effectively navigate settings with diverse individuals and groups") and responsible decision-making ("the abilities to make caring and constructive choices about personal behavior and social interactions across diverse situations"). It places these inside four nested settings - classrooms, schools, families and caregivers, and communities. Nova uses this as the naming scheme for its social-emotional domain, nothing more. |
| ev.spatial.atit-2022 | meta_analysis | moderate | True | two meta-analyses synthesising 45 articles relating spatial skills to mathematical performance across grade levels; the included samples were "largely from the USA and other Western nations", with only seven studies from Eastern countries (China and Russia) | not_applicable | en | The correlational counterpart to ev.spatial.hawes-2022: how tightly are spatial and mathematical skill actually related? "Results revealed a positive moderate association between spatial and mathematical skills (r = .36, robust standard error = 0.035, tau-squared = 0.039)." Neither gender nor grade level significantly moderated the association, so the relation is not peculiar to one age band. A second, meta-analytic structural equation model found that domain-general fluid reasoning and verbal skills mediated the relation, "but a unique relation between the spatial and mathematical skills remained" - which is the honest version of the claim: spatial and mathematical skill share something beyond general reasoning, but general reasoning explains part of what looks like a specifically spatial link. The authors' own implication is that "bolstering spatial skills in conjunction with fluid reasoning and verbal skills may provide a greater boost to students' mathematical achievement than developing spatial skills alone". |
| ev.spatial.hawes-2022 | meta_analysis | emerging | True | 29 studies using controlled pre-post designs to test the effect of spatial training on mathematics, N = 3,765, k = 89 effect sizes; participants ranged from 3 to 20 years | mixed | unstated | This is the causal version of the spatial-mathematics question, and the answer is a qualified yes with three warnings Nova has to heed. "The average effect size (Hedges's g) of training relative to control conditions was .28 (SE = .07)", while the same training moved spatial thinking itself more (g = .49). Age, use of concrete manipulatives and type of transfer all moderated the effect. "As the age of participants increased from 3 to 20 years, the effects of spatial training also increased in size" - so the benefit is smallest at exactly Nova's ages. "Spatial training paradigms that used concrete materials (e.g., manipulatives) were more effective than those that did not (e.g., computerized training)" - so the delivery mode Nova uses is the less effective one. And "Larger transfer effects were observed for mathematics outcomes more closely aligned to the spatial training delivered compared to outcomes more distally related" - near transfer again. Analyses of publication bias and selective outcome reporting were non-significant, which is a mark in the meta-analysis's favour. The authors conclude that spatial training works but that the field has "a poor understanding of the mechanisms that support transfer". |
| ev.spatial.uttal-2013 | meta_analysis | emerging | True | 217 studies of spatial training; the abstract names sex, age and type of training among the moderators analysed but states no age band, no sample total, no literature window and no countries | mixed | unstated | Spatial skill is trainable, and this is the source for that claim. "After eliminating outliers, the average effect size (Hedges's g) for training relative to control was 0.47 (SE = 0.04). Training effects were stable and were not affected by delays between training and posttesting. Training also transferred to other spatial tasks that were not directly trained." The authors' conclusion is that "spatially enriched education could pay substantial dividends in increasing participation in mathematics, science, and engineering". Nova records it for one narrow purpose: it licenses treating spatial skill as something a child develops with practice rather than a fixed trait, which is a precondition for having a spatial domain at all. |
| ev.transfer.barnett-ceci-2002 | developmental_framework | moderate | True | not a study of a population - a conceptual taxonomy covering a century of human transfer-of-learning research | not_applicable | en | The authors argue that the long dispute over whether far transfer occurs is unresolved because studies fail to specify the dimensions along which transfer is being claimed, "resulting in comparisons of apples and oranges". They set out nine dimensions in two groups: content (what is transferred - the learned skill, its performance change and the memory demand at test) and context (when and where - knowledge domain, physical context, temporal context, functional context, social context and modality). They conclude that "estimation of a single effect size for far transfer is misguided in view of this complexity", and that "evidence for transfer under some conditions is substantial, but critical conditions for many key questions are untested". Nova uses these context dimensions to define what a cross-game transfer probe must actually vary - a different mechanic, a different surface, a later moment - rather than a reskin. |
| ev.transfer.harvard-cdc-2011 | developmental_framework | moderate | True | children from infancy through early childhood | not_applicable | en | Working Paper No. 11 states that "Among scientists who study these functions, three dimensions are frequently highlighted: Working Memory, Inhibitory Control, and Cognitive or Mental Flexibility", and defines each on page 2. "WORKING MEMORY is the capacity to hold and manipulate information in our heads over short periods of time." "INHIBITORY CONTROL is the skill we use to master and filter our thoughts and impulses so we can resist temptations, distractions, and habits and to pause and think before we act." "COGNITIVE OR MENTAL FLEXIBILITY is the capacity to nimbly switch gears and adjust to changed demands, priorities, or perspectives." It uses the air-traffic-control metaphor for how the three work together and describes them as built through practice and adult scaffolding. This three-part split is the structure Nova uses for its executive-function domain, and it confirms the original brief's description of the Harvard materials. |
| ev.transfer.kassai-2019 | meta_analysis | emerging | True | children in experimental studies training a component of executive function (the abstract does not state the age band; k = 43 comparisons for near transfer, k = 17 for far transfer) | mixed | en | Training one component of executive function (working memory, inhibitory control or cognitive flexibility) produced a significant near-transfer effect on the targeted component (g+ = 0.44, k = 43, p < .001), showing the interventions did what they set out to do. But there was "no convincing evidence of far-transfer" to the untrained components (g+ = 0.11, k = 17, p = .11). The authors "question the practical relevance of training specific executive function skills in isolation". For Nova this means a game that trains inhibition must not be credited with building cognitive flexibility. |
| ev.transfer.melby-lervag-2016 | meta_analysis | moderate | True | 87 publications with 145 experimental comparisons of working-memory training, spanning children, adults and older adults, both typically developing samples and samples with learning disorders | mixed | en | The effect shrinks as the outcome moves away from the trained task, and vanishes. Against treated control groups, near transfer to the trained task was large (g = 0.80 [0.62, 0.97]); intermediate transfer to other working-memory measures was small but reliable (verbal working memory g = 0.31 [0.19, 0.42]; visuospatial working memory g = 0.28 [0.16, 0.40]); and far transfer was absent - nonverbal ability g = 0.05 [-0.02, 0.13], verbal ability g = 0.05 [-0.07, 0.17], arithmetic g = 0.06 [-0.08, 0.19]. The authors state that for far-transfer measures "there was no convincing evidence of any reliable improvements when working memory training was compared with a treated control condition", and conclude that working-memory training produces "short-term, specific training effects that do not generalize to measures of 'real-world' cognitive skills". The gap between the untreated-control estimate for near transfer (g = 1.88 [1.33, 2.42]) and the treated-control estimate (g = 0.80) is itself a lesson for Nova's own evaluation design: more than half of the apparent effect disappears once the control group is given something to do. |
| ev.transfer.sala-2019 | meta_analysis | emerging | True | a meta-analysis of meta-analyses of cognitive-training programmes across children, adults and older adults (models of 99, 119 and 233 effect sizes) | mixed | en | Pooling across previous meta-analyses, working-memory and related cognitive training produced near transfer (to memory tasks), with the size of that effect varying by population. Far transfer to reasoning, processing speed and language was small or null, and once placebo effects and publication bias were accounted for "the overall effect size and true variance equaled zero". The authors conclude that "the lack of generalization of skills acquired by training is thus an invariant of human cognition". This is the single most important entry behind Nova's rule that in-game improvement is never treated as evidence of transfer. |
| ev.transfer.scionti-2020 | meta_analysis | moderate | True | preschool children aged 3-6 years; 32 studies from 27 papers, contributing 123 effect sizes | mixed | en | Cognitive training improved preschoolers' executive functions overall (g = 0.352, k = 123, p < 0.001), and - unlike the findings in older samples - there was no significant difference between near and far transfer *within* the executive domains (near g = 0.352, 95% CI [0.252, 0.451]; far g = 0.318, 95% CI [0.186, 0.449]). The authors attribute this to executive functions being less modular at this age. Crucially, transfer stopped at the edge of the executive domains: effects on behavioural and learning-related outcomes were not significant (g = 0.169, 95% CI [-0.047, 0.383], p = 0.122). Computerised training was effective (g = 0.281) but no more so than non-computerised (g = 0.373); the difference was not a significant moderator. Effects were larger for developmentally at-risk children (ADHD g = 0.785; low socio-economic status g = 0.430) than for typically developing children, and larger for group than individual sessions (0.443 vs 0.211). |


---

## 6. Honest limits

This section collects the findings that are small, mixed, null or that did not transfer, and states
what each one does to the design. It is the longest section for a reason: these results, not the
positive ones, are what force Nova's two most consequential structural decisions — Transfer as a
separate assessment dimension, and the rule that in-game success is not learning.

### 6.1 Trained skills improve; the improvement mostly stays where it was trained

This is the most consistent finding in Nova's evidence set, and it is unhelpful to Nova.

- **Working-memory training.** The effect shrinks as the outcome moves away from the trained task,
  and then vanishes. Against *treated* control groups, near transfer to the trained task was large
  (g = 0.80 [0.62, 0.97]), intermediate transfer to other working-memory measures was small but
  reliable (verbal g = 0.31, visuospatial g = 0.28), and far transfer was absent — nonverbal ability
  g = 0.05 [-0.02, 0.13], verbal ability g = 0.05 [-0.07, 0.17], arithmetic g = 0.06 [-0.08, 0.19].
  The authors conclude that such training produces "short-term, specific training effects that do
  not generalize to measures of 'real-world' cognitive skills" [ev.transfer.melby-lervag-2016].
- **Cognitive training generally.** A second-order meta-analysis found that once placebo effects and
  publication bias were accounted for, "the overall effect size and true variance equaled zero", and
  concluded that "the lack of generalization of skills acquired by training is thus an invariant of
  human cognition" [ev.transfer.sala-2019]. This entry is `emerging` and rests on an abstract alone
  — the models, the pooled meta-analyses and the authors' own limitations were not read — so it is
  quoted as agreement with the others, not as an independent foundation.
- **Executive function in children.** Training one component produced a significant near-transfer
  effect on that component (g+ = 0.44, k = 43), but "no convincing evidence of far-transfer" to the
  untrained components (g+ = 0.11, k = 17, p = .11) [ev.transfer.kassai-2019]. Also `emerging` and
  abstract-only: the age range of the included children is not stated in the abstract, so this entry
  must not be read as specific to 3-6 year olds, and only 17 comparisons contributed to the
  far-transfer estimate, so a small true effect cannot be ruled out.
- **Executive function in preschoolers specifically.** [ev.transfer.scionti-2020] partly disagrees,
  and the disagreement is recorded rather than smoothed. In 3-6 year olds, transfer *within* the
  executive domains was as large as near transfer (far g = 0.318 [0.186, 0.449] against near
  g = 0.352), which the authors attribute to executive functions being less modular at this age —
  while warning that "task impurity" may inflate the result. But transfer stopped at the edge of
  those domains: the effect on behavioural and learning-related outcomes was **not significant**
  (g = 0.169 [-0.047, 0.383], p = 0.122). Improvements on executive tasks did not show up in the
  classroom or in academic learning.
- **Early mathematics.** Over 90% of 101 preschool maths interventions reported positive outcomes,
  but "gains were predominantly characterized by near-transfer to trained skills. Transfer to
  broader, more general mathematical abilities or untrained skills was not frequent. In fact, only
  7% of the studies demonstrated far-transfer effects, and these yielded small effect sizes"
  [ev.math.munez-2026]. A child who gets better at a trained maths task usually does not, on this
  evidence, get better at maths. This entry is `emerging` and abstract-only, and it is a descriptive
  review that pools nothing, so "over 90% positive" is a vote count vulnerable to publication bias.
- **Early literacy.** The same shape appears in language. Proximal vocabulary — the words actually
  taught — moved at g = 0.53 while distal, standardised vocabulary moved at g = 0.08; specific
  trainable phonological-awareness skills moved (blending and elision g = 0.26, first-sound
  identification g = 0.24) while the phonological-awareness composite barely did (g = 0.08)
  [ev.literacy.cusiter-2025].

**What this does to the design.** Transfer is a separate assessment dimension (spec 3.4) and is
never inferred from performance. The Transfer mastery state requires a *passed probe*, and a probe
is only valid if it really changes something: a `cross_game` probe must use a different
`mechanic_id` from the game that declares it, and a reskin — new animals, new colours, new sounds —
never counts. [ev.transfer.barnett-ceci-2002] supplies the vocabulary for what "really changes"
means. Its authors argue that the long dispute over far transfer is unresolved because studies fail
to specify the dimensions along which transfer is claimed, "resulting in comparisons of apples and
oranges", and that "estimation of a single effect size for far transfer is misguided in view of this
complexity". Their nine dimensions — content, and the context dimensions of knowledge domain,
physical context, temporal context, functional context, social context and modality — are what a
Nova probe must vary. The worked example in `data/games/math/counting.yaml` does exactly that:
`probe.one-to-one-at-home` moves from screen apples on the `drag-to-count` mechanic to real objects
on the `physical-counting` mechanic, counted with a person; `probe.cardinality-later` adds a delay
of about a week. That entry is a framework and supplies no effects; its use here is organisational
only.

One boundary is worth stating, because it is easy to over-read this section.
[ev.transfer.sala-2019] concerns transfer of *trained cognitive capacity*. It does not say that
taught content — counting, letter sounds — fails to transfer, and Nova does not read it that way.

### 6.2 Guided play helps on some outcomes and not on others

Guided play is Nova's core stance, and [ev.guided-play.skene-2022] is the strongest evidence Nova
has for it. The benefit is real and it is specific. Against direct instruction, guided play showed a
greater positive effect on early maths (g = 0.24), shape knowledge (g = 0.63) and task switching
(g = 0.40); against free play it showed a greater effect on spatial and maths vocabulary (g = 0.93).

The authors then state plainly that "differences were not identified for other key outcomes".
Receptive vocabulary came out at g = -0.06, behaviour regulation at g = -0.03 and inhibitory control
at g = -0.06: essentially no difference. Guided play beat direct instruction on four of the outcomes
tested and on none of the others, and the maths effect is small. The quality caveats are substantial
— 38 of the 39 studies were at high risk of bias, half used samples under 50, and heterogeneity was
high where it mattered most (spatial vocabulary against free play, I-squared = 80.7%), while the
clean maths estimate rests on few studies.

**The caveat that matters most to Nova is the delivery one.** Every included intervention was
human-guided — a teacher, a parent or a researcher. **No digital intervention was included.** This
meta-analysis does not show that a tablet's scaffolding substitutes for an adult's, and Nova does
not claim it does.

The other game-based-learning entry, [ev.games.alotaibi-2024], reports positive pooled effects on
cognitive development (g = 0.46), social development (g = 0.38), emotional development (g = 0.35),
motivation (g = 0.40) and engagement (g = 0.44), and states that "educator-guided game-play and
scaffolding was important for maximizing learning gains". Nova does not lean on it. Its participant,
sample-size and inclusion figures cannot all be true together, it publishes no table of included
studies, and it reports no heterogeneity statistics, which is why it is rated `emerging` despite its
headline size. Its own caveats point the same way as the rest of this section: mixed cognitive
results across studies, and skills acquired through games having limited real-world applicability.
"Games help" is a working hypothesis here, not a finding, and this entry never licenses calling a
Nova game "evidence-based".

### 6.3 Two of the three programme evaluations are unflattering

- The Creative Curriculum for Preschool, Fourth Edition, "was found to have no discernible effects
  on oral language, print knowledge, phonological processing, or math for preschool children"
  [ev.programs.wwc-creative-curriculum-2013]. A widely used commercial curriculum, reviewed against
  a fixed standard, moved none of the four outcomes tested.
- Tools of the Mind improved maths significantly but with a small effect size, while the average
  effect sizes for self-regulation and literacy "favoured tools compared to other approaches" but
  "the effect was not statistically significant" — the programme's headline target is the one that
  did not reach significance [ev.programs.baron-2017].
- Montessori's effects are real and small: composite academic g = 0.24, composite non-academic
  g = 0.33, with social studies at g = 0.06, and the authors report a possible publication bias and
  grade two of the larger non-academic domains as low-quality evidence [ev.programs.randolph-2023].

**What this does to the design.** It sets the expectation for what a good early-years intervention
achieves: a fraction of a standard deviation, on the outcomes closest to what was taught, with a
real chance of nothing measurable at all. Any Nova claim larger than that is wrong before it is
tested.

### 6.4 Effects fade

[ev.math.sun-2026] reports partial fadeout directly: post-test g = 0.34 against follow-up g = 0.20.
[ev.math.munez-2026] reports that just over a third of the 101 interventions included any long-term
follow-up, so "the sustainability of intervention effects remains largely unknown, making the
documented 'fade-out' effect a persistent concern". Both entries are `emerging` and abstract-only.

**What this does to the design.** Delayed probes exist (spec 3.4) and are optional per skill. A
*failed* delayed probe does not demote a mastery state; it lowers confidence and schedules review.
Retention is treated as a measurement problem, not as something a curriculum can assert.

### 6.5 Digital delivery is not the better medium, and may be the worse one

Where the comparison has been made directly, the screen does not win:

- In preschool cognitive training, computerised training was effective (g = 0.281) but no more so
  than non-computerised (g = 0.373), and the difference was not a significant moderator
  [ev.transfer.scionti-2020].
- In spatial training, "paradigms that used concrete materials (e.g., manipulatives) were more
  effective than those that did not (e.g., computerized training)" [ev.spatial.hawes-2022] —
  `emerging`, abstract-only.
- In phonemic-awareness instruction, "Classroom teachers were very effective in teaching PA to
  children. Also, computers were effective" — but in classroom-teacher and computer studies "the
  degree of transfer was less than that achieved in experimentally controlled studies". Real
  settings produced smaller effects than research settings, and Nova is a real setting with even
  less adult supervision than either [ev.literacy.nrp-phonemic-awareness-2000].
- Almost all effective phonics instruction was delivered by a person — tutoring d = 0.57, small
  group d = 0.43, whole class d = 0.39 — and none of it establishes that a tablet can substitute
  [ev.literacy.nrp-phonics-2000].
- Of 43 combined language-and-code interventions for at-risk preschoolers, only 2 were delivered by
  a computer [ev.literacy.cusiter-2025]. Of the early-years social-emotional programmes that
  produced the effects in [ev.sel.blewitt-2018], none was a tablet application.

The one entry written specifically about apps is a framework, not an experiment
[ev.digital.hirsh-pasek-2015]. Its four pillars — active ("'minds-on' activity that requires
intellectual thinking", not just tapping), engaged (free of distractions, which argues against
decorative animations and reward interruptions), meaningful (connected to what the child already
knows) and socially interactive — are the design test Nova applies to every mechanic. But the paper
synthesises learning-science findings obtained mostly outside apps and applies them to apps by
argument. It does not show that an app built to the four pillars produces learning, quantifies no
effect, and offers no validated rubric for scoring an app against the pillars. It also names the
market problem Nova is part of: "more than 80,000 App Store apps are described as being education-
or learning-based, however, there are currently no science-based standards to guide this
determination."

**What this does to the design.** Every deep-scope skill's transfer probe reaches off the screen
where it can, using the `physical-counting`, `physical-build`, `physical-hunt`, `physical-sort`,
`physical-freeze`, `oral-sound-game`, `retell` and `print-hunt` mechanics; every game carries an
`offline_extension`; and the adult is given an explicit role rather than being treated as absent
(chapter 02, section 5).

### 6.6 Spatial skill: trainable, but the moderators point the wrong way

Spatial skill is trainable — g = 0.47 across 217 studies, stable over delays, transferring to other
*spatial* tasks [ev.spatial.uttal-2013]. That is `emerging` and abstract-only, the 217 studies span
all ages including adults, and the age moderator — the one Nova most needs — was not readable. Nova
uses it for one narrow purpose: to license treating spatial skill as something a child develops with
practice rather than a fixed trait, which is the precondition for having a spatial domain at all.

Whether spatial training reaches mathematics is a separate question with a smaller answer: g = .28
against control, with the same training moving spatial thinking itself more (g = .49). All three
significant moderators point against Nova's case. "As the age of participants increased from 3 to 20
years, the effects of spatial training also increased in size" — the benefit is smallest at exactly
Nova's ages; concrete materials beat computerised training; and transfer was largest where the maths
outcome most resembled the training [ev.spatial.hawes-2022]. `emerging`, abstract-only.

The correlational version is stronger and says less: r = .36 between spatial and mathematical
skills, unmoderated by gender or grade level, with fluid reasoning and verbal skill mediating part
of it though "a unique relation between the spatial and mathematical skills remained"
[ev.spatial.atit-2022]. An association is not an effect.

**What this does to the design.** Nova records spatial work as plausibly useful for mathematics and
explicitly does not claim that a spatial game raises a child's mathematics.

### 6.7 The Arabic evidence base is much thinner than the English one, and the spec says so

Nova runs Arabic and English as separate tracks, and their evidence is not comparable.

The English track rests on large, well-known meta-analyses: six predictors of later literacy with
their pooled correlations to decoding (alphabet knowledge r = 0.50, writing one's name r = 0.49,
phonological awareness r = 0.40) and code-focused interventions with "the largest impact... on PA,
with an average ES of 0.82" [ev.literacy.nelp-2008]; phonemic-awareness instruction at d = 0.86 on
phonological awareness, 0.53 on reading and 0.59 on spelling
[ev.literacy.nrp-phonemic-awareness-2000]; systematic phonics at d = 0.44 overall and d = 0.56 in
kindergarten [ev.literacy.nrp-phonics-2000]. All three are `moderate`, all three are about English,
and all three carry the same caveats: the predictor correlations are correlations and not causes,
the databases closed in 2000 and 2008, and the delivery was human.

The Arabic track has one intervention study. [ev.literacy.haj-2026] is a cluster-randomised trial of
a diglossia-centred kindergarten programme with 403 Palestinian-Arabic-speaking children, and it is
rated `emerging`, not `moderate`, for reasons that should be read before it is cited: it is a single
trial with no independent replication; a published Correction lowered two of its reported
control-group effect-size ranges; the control group improved substantially too (d = 0.20 to 0.65 on
Spoken Arabic tasks, d = 0.78 to 0.86 on letter knowledge), so the value added is the interaction
term and **no standardised between-group effect size appears anywhere in the results**; allocation
was 50 experimental classrooms of five children against 13 control classrooms of 5 to 16; the
within-cluster selection of the five children per classroom is unexplained; outcomes are immediate
post-intervention only; and the authors themselves state that "generalization to other
Arabic-speaking contexts requires consideration of cultural, regional, and sociolinguistic
variability that may moderate intervention effects". What Nova takes from it is its *ordering* —
shared Spoken/Standard structures before Standard-specific ones, syllable-level phonological
awareness in weeks 1-3 before phoneme-level in week 8, and letters introduced in shape-and-dot pairs
— not an effect size.

The other two Arabic entries are reviews, both `emerging`. [ev.literacy.asadi-2026] is the one
synthesis covering all four Arabic features Nova must design around: "With 28 consonantal phonemes
but over 100 allographic forms, children must learn that multiple shapes correspond to the same
sound"; vowelization "is essential early on" with its benefit declining with age; "Kindergarten and
first-grade pupils struggled with StA-specific phonemes, a gap persisting through Grade 6"; and
"only 21% of Palestinian Arabic words are identical across varieties". It pools no effect sizes,
includes only 29 studies, draws mostly on school-age rather than 3-6 year old children, and its
vowelization findings come from Grades 5-9 — so "vowelize early, fade later" is a direction, not a
calibrated rule. [ev.literacy.taha-thomure-2025], abstract-only, independently corroborates that
diglossic distance is the organising problem, and its honest closing note is the state of the field:
it highlights "the need for research to develop and evaluate pedagogical approaches suited to
diglossic contexts". The pedagogy has largely not been evaluated.

As `research-log.md` records, this is worse than it has to be. The single most directly relevant
Arabic source found — Yassin et al. (2020), the naturalistic spelling-error analysis that
establishes the four script-specific features, reporting visual-orthographic errors at "over one
quarter (27.2%)" of all spelling errors — could not be recorded at all, because the spec's closed
type list has no slot for a single observational study.

**What this does to the design.** Arabic is a separate track with its own progression, not a
translation of the English one; it teaches positional letter forms explicitly and treats diacritics
as a staged support to be faded; and chapter 05 states plainly where the track rests on judgment
rather than evidence.

### 6.8 Social-emotional effects are modest, and the framework is a naming scheme

[ev.sel.casel-2026] gives Nova the vocabulary for its social-emotional domain — self-awareness,
self-management, social awareness, relationship skills, responsible decision-making — and nothing
more. It is an organisation's own framework page, presents no research, and its two effectiveness
claims carry no citations on the page, so they are not relied on. The five competences are defined
for all ages at once and are not operationalised into observable behaviours for 3-6 year olds, so
**every Nova social-emotional skill indicator is Nova's own inference**, not CASEL's.

The effect estimate comes from [ev.sel.blewitt-2018], chosen because it is the right age band:
emotional competence d = 0.54 (95% CI 0.22-0.86), social competence d = 0.30, behavioural
self-regulation d = 0.28, reduced behavioural and emotional difficulties d = 0.19, early learning
skills d = 0.18. Small to moderate, with the widest interval wide enough that the true value could
be trivial or substantial, heterogeneity from I-squared 20.5 to 78.4, and only 12 of 79 studies
(16.0%) rated high quality. Every included intervention was a curriculum delivered in a centre by a
teacher or specialist; none was a tablet application. It supports the claim that social-emotional
skills in this age band are teachable. It does not support the claim that Nova can teach them.

### 6.9 Screen guidance is a hard design constraint, and it is a recommendation, not a measurement

Both screen entries are `expert_consensus`, capped at `moderate`, and neither measures anything
about Nova.

WHO recommends that for children aged 2 and for children aged 3-4, "sedentary screen time should be
no more than 1 hour; less is better", adds in every band that "when sedentary, engaging in reading
and storytelling with a caregiver is encouraged", and states that "the quality of sedentary time
matters and interactive non-screen-based activities, such as reading, storytelling, singing and
puzzles are important for social and cognitive development" [ev.screens.who-2019]. The guideline
concerns sedentary behaviour and physical health; it sets no threshold for learning and makes no
distinction between passive video and interactive educational use, so it neither endorses nor
condemns an hour spent on a guided-play game. It covers under-5s only, so it does not directly cover
Nova's 5-8 year old users.

AAP's current policy statement moves away from a single number without abandoning numbers: "Time
limits might range from <1 hour/day for toddlers and preschoolers to 1 to 2 hours/day or more of
entertainment (not school-related) media for school-aged children and teens", with "the most
important considerations" being "high-quality content and prioritizing healthy activities (eg,
sleep, play, physical activity, reading)" [ev.screens.aap-2026]. That figure is explicitly a range
offered for discussion — "might range from" — and clinicians are told to "discuss limits that fit a
family's routine", so **Nova must not present "<1 hour/day" as an AAP rule**. The statement also
frames the design argument Nova sits inside: ecosystems "that prioritize engagement and
commercialization often encourage prolonged use, which in turn can displace healthy behaviors (eg,
movement behaviors, sleep)".

The two bodies agree rather than conflict at Nova's youngest ages, and differ in kind rather than in
number: WHO issues a bounded recommendation, AAP an explicitly family-negotiated range.

**What this does to the design.** Nova designs its session budget to fit inside an hour a day for
the 3-5 band, commits to an explicit adult-alongside role, puts content quality ahead of minutes,
and builds no engagement-maximising mechanics. Chapter 02, section 5 covers the offline half.

### 6.10 The rule that follows from all of it: in-game success is not learning

Spec principle 3 states that engagement, completion and within-game performance are not evidence of
learning or transfer. Sections 6.1 to 6.9 are why.

A child can finish every level, enjoy the game and improve at it without acquiring the underlying
skill. The evidence says the improvement will mostly be improvement *at the game*: large near
transfer, absent far transfer [ev.transfer.melby-lervag-2016]; near transfer to trained skills with
far transfer in 7% of studies [ev.math.munez-2026]; proximal vocabulary g = 0.53 against distal
g = 0.08 [ev.literacy.cusiter-2025]; executive-task gains that did not reach behavioural or learning
outcomes [ev.transfer.scionti-2020].

The consequences are enforced in data, not in prose:

- Every signal in `data/signals.yaml` is tagged `learning` or `engagement`. Session time,
  completion, streaks, stars and return visits are `engagement`; the validator rejects any
  assessment rule that consumes one. A game may still *log* them — `game.math.bear-apples` logs
  `completion` — but no mastery state can be built from them.
- Within-game performance is one dimension of four (performance, independence, transfer,
  confidence). It alone can never establish Secure or Transfer. Secure additionally requires the
  independence dimension: accuracy sustained with hints and adult help both rare. Transfer
  additionally requires a passed probe.
- Engagement metrics may be tracked for product health, and are never reported to parents as
  evidence of learning (chapter 06).

There is one reassuring result worth keeping alongside the warnings, because it shows the test can
come out the other way. The National Reading Panel reports a clean negative control: "Effects of
training did not generalize to performance on math tests, indicating that halo/Hawthorne effects did
not account for the findings" [ev.literacy.nrp-phonemic-awareness-2000]. A gain that stays inside
its own domain is evidence that something real was taught — and equally, a reminder that a literacy
gain is a literacy gain and nothing more.
