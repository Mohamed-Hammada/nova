# Nova: Master Curriculum Specification (Design)

Date: 2026-09-21
Status: Approved, revision 2.1 (rev 2 plus the two clarifications below)
Sub-project: 1 of N (curriculum spec; no app code)

## 0. Revision 2 summary

Changes from revision 1 (the skill graph, mastery states, Arabic/English separation and full 2-8 skill map are unchanged):

1. Evidence **type** and evidence **strength** are now separate fields with closed vocabularies (section 3.6).
2. Every skill and game declares its **evidence basis**. Expert judgment and design inference are never treated as empirical evidence (3.6).
3. **Transfer** is a distinct assessment dimension with cross-game, cross-context and optional delayed checks (3.4).
4. The difficulty model is expanded into seven explicit dimensions (3.3).
5. All thresholds, weights and cutoffs are **provisional parameters** with calibration metadata, not validated values (3.5).
6. New core principle: engagement, completion and within-game performance are not evidence of learning or transfer (section 2).

Revision 2.1 clarifications:

7. The cross-game transfer requirement is now checkable: two distinct `mechanic_id`s per deep-scope skill; a reskin or same mechanic with different content never qualifies (3.4).
8. `evidence_basis` is deterministic by precedence empirical > framework > judgment and enforced by the validator (3.6).

## 1. Purpose

Nova is an evidence-informed child development platform for ages 2-8: a game library, a development map, adaptive progression and parent insights. Arabic and English launch first; the architecture must admit further languages (Chinese, Hindi, others) without reshaping the core.

The full product is several independent subsystems (curriculum, game engine, adaptive/assessment engine, parent dashboard, language packs). Each is its own sub-project with its own spec, plan and build. **This document covers only the first: the Master Curriculum Specification.** Every later subsystem consumes its output.

## 2. Core principles

1. **The skill graph is the source of truth.** Domains are tags; age is an expected range, never a gate.
2. **Evidence basis is always declared.** Empirical evidence, framework grounding, and judgment are different things and are never merged or presented as equivalent.
3. **Engagement, completion and within-game performance are not evidence of learning or transfer.** A child can finish every level, enjoy the game and improve at it without acquiring the underlying skill. Consequences:
   - Engagement signals (session time, completion, streaks, stars, return visits) never feed skill-state computation. The signal taxonomy tags every signal `learning` or `engagement`, and assessment rules may consume only `learning` signals.
   - Within-game performance is one input (the *performance* dimension). It alone can never establish Secure or Transfer (3.4).
   - Engagement metrics may be tracked for product health, but are never reported to parents as evidence of learning.
4. **Transfer is assessed as its own dimension** (3.4), not inferred from performance.
5. **Numbers are provisional until calibrated.** No threshold, weight or cutoff is presented as scientifically validated without a pilot calibration study (3.5).
6. **Claims are non-clinical.** Nova is "evidence-informed", never diagnostic, screening or clinical.

## 3. Decisions and core data model

### 3.0 Decisions

| Topic | Decision |
|---|---|
| Deliverable | Curriculum spec only. No app code, UI, engine, art/audio or backend. |
| Scope | Full skill map, ages 2-8, all domains, at skill level. Deep coverage (mastery rules, difficulty ladders, assessment rules, game specs) for Executive Function/Memory, Math/Numeracy, Arabic literacy and English literacy at ages 3-6. |
| Format | Markdown chapters plus structured YAML data validated by JSON Schemas. |
| Structure | Skill graph as the source of truth (principle 1). |
| Languages | Universal skills need only translated strings. Literacy is a separate subgraph per language. Arabic and English are complete; Chinese and Hindi get only the pack contract and extension notes. |

### 3.1 Skill node (YAML)
- `id`, domain tags, i18n keys for name and description
- `prerequisites: [skill ids]`; each edge may carry optional `evidence_refs`. An edge with none is a design inference and is labelled so.
- typical age range (informational only)
- observable indicators: what a child does when the skill is present
- `evidence_basis: empirical | framework | judgment` (required, see 3.6)
- `evidence_refs`: evidence ids about the skill itself (its importance and developmental ordering)
- `scope: universal | language-specific`; a language-specific skill also names its `language` and, where it fills one, its shared `slot` (3.8)
- `deep_scope: bool`: true for skills in the deep-coverage set (EF, memory and math, plus Arabic and English literacy, whose age range starts before 6 and ends after 3). The validator requires it for every skill that qualifies.

### 3.2 Mastery
Each child has a state per skill: **Not yet -> Emerging -> Developing -> Secure -> Transfer**. Per-domain "levels" shown to parents are derived from skill states, not stored.

State entry requires evidence on the assessment dimensions in 3.4. In outline (all cutoffs provisional, see 3.5):
- **Emerging / Developing:** performance evidence, possibly with substantial support.
- **Secure:** performance sustained at low support (the *independence* dimension), not just in-game success under hints.
- **Transfer:** at least one passed cross-game or cross-context transfer check.

### 3.3 Difficulty model
A game's ladder is a sequence of rungs. Each rung is a **vector over seven dimensions**, not a single number. Each dimension is ordinal with named anchors. A composite "difficulty score" is not assumed; the dimensions interact and are not additive until calibrated.

| Dimension | What it varies | Example anchors |
|---|---|---|
| Item complexity | Intrinsic difficulty of single items | numbers 1-5 -> 1-10 -> 1-20; visually distinct letters -> similar shapes; short -> long words |
| Distractors | Number and similarity of irrelevant or competing options | none -> few dissimilar -> many similar |
| Working-memory load | Items to hold, delay, manipulation required | hold 2 -> hold 3 -> hold 4 -> reorder |
| Rule complexity | Number of rules, rule switches, conditionality | one rule -> two rules -> switch mid-task |
| Abstraction | Distance from concrete to symbolic | real objects -> pictures -> numerals or letters only |
| Cognitive load | Extraneous demand from interface and task: instruction length, concurrent demands, time pressure, interaction count | short single-step -> multi-step; untimed -> timed |
| Independence | Support given: modelling, hints, adult help | fully modelled -> guided -> hints on request -> independent |

Rules:
- Each game spec declares which dimensions it varies and holds the others fixed at stated values.
- Rungs change one dimension at a time where possible, so errors are diagnosable.
- Cognitive load is kept low unless it is the target. It must not confound a rise in another dimension.
- Each game spec names an anchor for every value a varied dimension takes (`anchors[dimension][value]`), so a rung value is never an unlabelled number. The validator enforces this. Consistency of anchors across games in the same skill cluster is a review item. Their psychometric validity is unverified until pilot data exists (3.5).
- Difficulty is child-relative. Age never gates a rung.

### 3.4 Assessment dimensions
Assessment evaluates each skill on separate dimensions and derives the mastery state from them. A single score is never the output.

| Dimension | Question it answers | Source |
|---|---|---|
| **Performance** | Does the child succeed at rungs of the target difficulty? | accuracy, error type, response time, retries |
| **Independence** | How much support was needed? | hints used, adult-assist flags, scaffold level |
| **Transfer** | Does it hold when the surface or setting changes? | transfer probes (below) |
| **Confidence** | How much evidence supports this estimate? | trial counts, consistency, recency |

**Transfer probes** are declared in game specs and skill assessment rules. Each probe states what changes and what stays the same:

- `cross_game`: a different game with a different mechanic that targets the same skill. Re-skinning the same game (new animals, colours, sounds) is *not* a transfer probe; it counts only as more performance evidence.
- `cross_context`: the same skill in a different representation, modality or setting: pictorial to symbolic, screen to physical objects, one language of instruction to another for language-independent skills, or an offline task the adult reports.
- `delayed` (optional, a modifier on either type): the probe is presented after a delay (provisionally days, not minutes), testing retention. A failed delayed probe does not demote the state. It lowers confidence and schedules review.

**Cross-game requirement.** Every deep-scope skill must be covered by **at least two distinct game mechanics**: either two games with different `mechanic_id`s, or one game plus a separately specified transfer task whose `mechanic_id` differs from that game's. A `cross_game` probe is valid only if its mechanic differs from the mechanic of the game that declares it (the practice the child just did), and the probed target actually uses the mechanic the probe names. It cannot be satisfied by a reskin, by the same mechanic with different content, theme or difficulty, or by the same mechanic under a new name. `mechanic_id` comes from a controlled mechanic vocabulary kept in data (e.g. sequence-recall, sort-by-rule, drag-to-count), so "distinct" is checkable, not a judgment call.

A **transfer task** is a short, separately specified task (own mechanic, own signals, own scoring) that exists to probe a skill. It need not be a full game.

Every deep-scope skill also has a `cross_context` probe where one is feasible. Delayed probes are optional per skill. The Transfer state requires a passed `cross_game` or `cross_context` probe. A passed delayed probe raises confidence.

**Signals.** Each logged signal is tagged `learning` or `engagement` (principle 3). Assessment rules map `learning` signals to dimension values via evidence rules, e.g. "counting to 10 secure, quantity comparison developing", not "62%". Assessment is embedded in play; there are no exam screens.

### 3.5 Calibration and parameters
Every quantity that the assessment or adaptive logic depends on is a **parameter**: mastery cutoffs, trial counts, accuracy thresholds, weights, confidence rules, delayed-probe intervals, rung-advance and rung-retreat rules. Each parameter is a record:

- `id`, value or range, unit
- `status: provisional | pilot_calibrated | validated`
- `basis`: how the initial value was chosen (`design_inference`, `borrowed_from_literature` with an evidence ref, `prior_pilot`)
- `rationale`: one sentence
- `calibration_plan`: what data, sample size and method will set it
- `calibration_study`: required when status is `pilot_calibrated` or `validated`

Rules:
- Every parameter ships as `provisional`. The spec presents its initial values as starting points, not findings.
- Nothing labelled `validated` without a linked calibration study.
- Anything a parent sees that derives from a provisional parameter is labelled as an estimate (chapter 06).
- The spec claims no psychometric validity (reliability, validity, norms). The choice of adaptive model (rule-based, Bayesian knowledge tracing, IRT, or other) is deferred to the adaptive-engine sub-project.

### 3.6 Evidence model
Evidence **type** says what kind of source it is. Evidence **strength** says how much weight it deserves for Nova's use. They are independent fields. Type does not imply strength: a well-run meta-analysis outweighs a weak RCT, and an RCT on teacher-led classroom instruction only indirectly supports a tablet game.

**Type** (closed list; adding one is a spec change):

| Type | Class |
|---|---|
| `systematic_review`, `meta_analysis`, `rct`, `quasi_experimental` | empirical |
| `developmental_framework`, `program_evidence` | framework |
| `expert_consensus`, `design_inference` | judgment |

**Strength** (`strong | moderate | emerging`), assigned by a written rubric. It considers quality, consistency across studies, and *directness*: match to the age group, the outcome, the delivery mode (digital versus teacher-led) and the language. Caps: `expert_consensus` is at most `moderate`, and `design_inference` is at most `emerging`. Findings in English or from other populations are not assumed to hold for Arabic-speaking children.

**Evidence basis.** Each skill and each game declares `evidence_basis`. The value is fully determined by the cited evidence, with fixed precedence **empirical > framework > judgment**:
1. If any cited evidence is empirical-class, the basis is `empirical`.
2. Otherwise, if any cited evidence is framework-class, the basis is `framework`.
3. Otherwise the basis is `judgment`.

The validator recomputes the basis by this rule and errors on any mismatch with the declared value. A skill or game that cites no evidence is also an error: a `judgment` basis must cite at least one `expert_consensus` or `design_inference` entry, so it is explicit. Basis records the *class* of evidence only. How much weight it deserves is the separate strength field, and the reporting rule below still requires strength of at least `moderate`. Judgment is a legitimate basis, since much of the spec (skill ordering, game mechanics) is inference, but it is always visible and never counted as empirical.

**Two levels of claim.** Skill evidence is about the skill: its importance and developmental ordering. Game evidence is about the mechanic: whether this kind of game plausibly builds the skill. A game with no direct evidence for its mechanic declares `judgment`, which is the common case.

**Reporting consequence.** Parent-facing materials may say "evidence-based" only for a skill or game with `evidence_basis: empirical` at strength of at least `moderate`. Otherwise the wording is "informed by" (chapter 06).

### 3.7 Game spec (YAML)
- primary and secondary skills
- learning objective and mechanic, with a `mechanic_id` from the controlled vocabulary (3.4)
- `evidence_basis` and `evidence_refs` for the mechanic (3.6)
- difficulty ladder as vectors over the dimensions in 3.3, plus the dimensions held fixed
- scaffolding: hints and a short prompt for an adult
- logged signals, each tagged `learning` or `engagement`
- progression rules (referencing parameters, 3.5)
- transfer probes (3.4)
- optional offline (physical-world) extension
- language dependencies

### 3.8 Language packs
Shared slots (phonological awareness, vocabulary, print concepts, and others) are filled per language. A pack declares script properties (direction, letter joining, diacritics, tones, and similar) and its literacy subgraph. Adding Chinese or Hindi later means adding a pack, not changing the core. Math, EF, memory, spatial and social-emotional skills are universal. Arabic and English literacy are separate tracks with different progressions, not a translation of one another.

## 4. Repository layout

```
docs/curriculum/
  01-research-foundation.md      programs matrix, evidence types/strength rubric, evidence table
  02-developmental-framework.md  domains, age stages, guided-play principles, core principles
  03-skill-model.md              schemas explained, mastery, difficulty dimensions
  04-assessment-adaptivity.md    assessment dimensions, transfer probes, signals, parameters/calibration
  05-language-packs.md           pack contract, Arabic + English, zh/hi notes
  06-parent-reporting.md         what the dashboard may / may not claim; estimate labelling
  07-safety-privacy-a11y.md      child data, content, accessibility rules
  08-validation-roadmap.md       educator review, pilot calibration plan, next sub-projects
data/
  schema/           JSON Schemas: skill, game, transfer_task, evidence, parameter,
                    assessment_rule, langpack, mechanic, signal
  skills/           universal and per-language skill graph
  games/            game specs
  transfer_tasks/   separately specified transfer tasks
  evidence/         evidence entries
  parameters/       provisional parameters
  assessment/       per-skill assessment rules
  langpacks/        one record per language (ar, en complete; zh, hi contract-only)
  mechanics.yaml    controlled mechanic vocabulary
  signals.yaml      signal vocabulary, each tagged learning or engagement
  i18n/             en.yaml, ar.yaml (flat key -> string)
tools/validate/     spec validator (Python; checks the spec, not app code)
```

The original 20-item outline maps onto these 8 chapters plus the YAML. The game catalog and difficulty system live in `data/games`, not prose.

## 5. Research method

- Every claim is recorded in `data/evidence/` with source, `evidence_type`, `evidence_strength`, population, delivery mode, language and finding. Skills and games cite evidence ids.
- Sources are verified against primary papers and program sites. The citations in the original brief are unverified and are not relied on. Claims that cannot be verified are dropped, or recorded as `design_inference` or `expert_consensus` at the correct cap.
- The programs matrix (Montessori, HighScope, Tools of the Mind, Reggio Emilia, Creative Curriculum, Harvard Center on the Developing Child EF materials) records what Nova adopts, what it leaves out, and why. Program materials are usually `developmental_framework` or `program_evidence`, not empirical effect evidence, and are recorded that way.
- Limits are recorded honestly: small effects for phonological awareness training, uneven transfer of math gains. These findings motivate the Transfer dimension (3.4) and principle 3.

## 6. Out of scope

App code, UI, game engine, art and audio, backend, dashboard implementation, pricing and monetization, diagnostic or screening claims, Chinese and Hindi skill content, and choice of the adaptive model.

## 7. Open questions

1. **Arabic instruction voice:** Modern Standard Arabic versus a dialect (e.g. Egyptian) for spoken instructions and prompts. Literacy content is MSA regardless. To be recorded in chapter 05 and decided later.
2. Target market and regulatory regimes for child data (COPPA, GDPR-K, regional equivalents). To be covered in chapter 07.
3. Pilot design for calibrating parameters (sample, sites, timing). Outlined in chapter 08; executed in a later sub-project.

## 8. Definition of done

The validator passes:
- no cycles in the skill graph; every reference resolves
- every skill and game cites evidence, declares `evidence_basis`, and the declaration equals the value computed by the precedence rule empirical > framework > judgment
- every evidence entry has a valid `evidence_type` and `evidence_strength`, and respects the caps
- every parameter has metadata and is `provisional` unless it links a calibration study
- no assessment rule consumes an `engagement` signal
- every deep-scope skill has at least one game spec and an assessment rule
- every deep-scope skill is covered by at least two distinct `mechanic_id`s (two games, or one game plus a transfer task on a different mechanic), has at least one valid `cross_game` probe, and every `cross_game` probe's `mechanic_id` differs from the mechanic of the game that declares it
- every language-specific skill belongs to a language pack that exists; a pack's declared slots match the slots its skills fill; a `complete` pack fills every shared slot
- every i18n key used by a skill, game or transfer task has a non-empty string in both `en` and `ar`

And:
- Every evidence entry traces to a source verified against the primary publication.
- An engineer can build the engine and adaptive logic from the YAML alone, without asking what a field means.
- Chapter 08 recommends early-childhood educator review before any child uses the product, and states that all parameters are provisional until a pilot.
