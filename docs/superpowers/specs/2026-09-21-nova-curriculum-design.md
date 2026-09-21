# Nova: Master Curriculum Specification (Design)

Date: 2026-09-21
Status: Draft for review
Sub-project: 1 of N (curriculum spec; no app code)

## 1. Purpose

Nova is an evidence-informed child development platform for ages 2-8: a game library, a development map, adaptive progression and parent insights. Arabic and English launch first; the architecture must admit further languages (Chinese, Hindi, others) without reshaping the core.

The full product is several independent subsystems (curriculum, game engine, adaptive/assessment engine, parent dashboard, language packs). Each is its own sub-project with its own spec, plan and build. **This document covers only the first: the Master Curriculum Specification.** Every later subsystem consumes its output.

## 2. Decisions

| Topic | Decision |
|---|---|
| Deliverable | Curriculum spec only. No app code, UI, engine, art/audio or backend. |
| Scope | Full skill map, ages 2-8, all domains, at skill level. Deep coverage (mastery rules, difficulty ladders, assessment rules, game specs) for Executive Function/Memory, Math/Numeracy, Arabic literacy and English literacy at ages 3-6. |
| Format | Markdown chapters plus structured YAML data validated by JSON Schemas. |
| Structure | The skill graph is the source of truth. Domains are tags. Age is an expected range, never a gate. |
| Languages | Universal skills need only translated strings. Literacy is a separate subgraph per language. Arabic and English are complete; Chinese and Hindi get only the pack contract and extension notes. |
| Claims | "Evidence-informed", never clinical, diagnostic or screening. |

## 3. Core data model

### 3.1 Skill node (YAML)
- `id`, domain tags, i18n keys for name and description
- `prerequisites: [skill ids]`
- typical age range (informational only)
- observable indicators: what a child does when the skill is present
- evidence references, each with a strength rating
- `scope: universal | language-specific`

### 3.2 Mastery
Each child has a state per skill: **Not yet -> Emerging -> Developing -> Secure -> Transfer**. *Transfer* means the child succeeded in a different game or context, guarding against learning only to beat one game. Per-domain "levels" shown to parents are derived from skill states, not stored.

### 3.3 Game spec (YAML)
- primary and secondary skills
- learning objective and mechanic
- difficulty ladder as parameters (items to remember, distractors, time limits), not fixed screens
- scaffolding: hints plus a short prompt for an adult
- logged assessment signals: accuracy, response time, retries, error type
- progression rules
- optional offline (physical-world) extension
- language dependencies
- a transfer variant

### 3.4 Assessment
Evidence rules map game signals to a skill's mastery state with a confidence value. Output is skill-specific ("counting to 10 secure, quantity comparison developing"), not a raw score. Assessment is embedded in play; there are no exam screens.

### 3.5 Language packs
Shared slots (phonological awareness, vocabulary, print concepts, and others) are filled per language. A pack declares script properties (direction, letter joining, diacritics, tones, and similar) and its literacy subgraph. Adding Chinese or Hindi later means adding a pack, not changing the core. Math, EF, memory, spatial and social-emotional skills are universal.

## 4. Repository layout

```
docs/curriculum/
  01-research-foundation.md      programs matrix + evidence table
  02-developmental-framework.md  domains, age stages, guided-play principles
  03-skill-model.md              schemas explained, mastery states
  04-assessment-adaptivity.md    evidence rules, progression, transfer checks
  05-language-packs.md           pack contract, Arabic + English, zh/hi notes
  06-parent-reporting.md         what the dashboard may / may not claim
  07-safety-privacy-a11y.md      child data, content, accessibility rules
  08-validation-roadmap.md       educator review, child testing, next sub-projects
data/
  schema/   skill, game, evidence, langpack JSON Schemas
  skills/   universal/  ar-literacy/  en-literacy/
  games/
  evidence/
  i18n/
tools/validate/   spec validator (checks the spec, not app code)
```

The original 20-item outline maps onto these 8 chapters plus the YAML. The game catalog and difficulty system live in `data/games`, not prose.

## 5. Research method

- Every claim is recorded in `data/evidence/` with source, study type, population, finding and strength (strong / moderate / emerging). Skill nodes cite evidence ids.
- Sources are verified against primary papers and program sites. The citations in the original brief are unverified and are not relied on. Claims that cannot be verified are dropped or marked *emerging*.
- The programs matrix (Montessori, HighScope, Tools of the Mind, Reggio Emilia, Creative Curriculum, Harvard Center on the Developing Child EF materials) records what Nova adopts, what it leaves out, and why.
- Limits are recorded honestly: small effects for phonological awareness training, uneven transfer of math gains. These findings motivate the Transfer state and the transfer variant on every game.

## 6. Out of scope

App code, UI, game engine, art and audio, backend, dashboard implementation, pricing and monetization, diagnostic or screening claims, Chinese and Hindi skill content.

## 7. Open questions

1. **Arabic instruction voice:** Modern Standard Arabic versus a dialect (e.g. Egyptian) for spoken instructions and prompts. Literacy content is MSA regardless. To be recorded in chapter 05 and decided later.
2. Target market and regulatory regimes for child data (COPPA, GDPR-K, regional equivalents). To be covered in chapter 07.

## 8. Definition of done

- The validator passes: no cycles, every reference resolves, every skill has indicators plus evidence or an explicit `expert-judgment` flag.
- Every deep-scope skill has at least one game spec and an assessment rule; every game spec has a transfer variant.
- Every evidence entry traces to a source verified against the primary publication.
- An engineer can build the engine and adaptive logic from the YAML alone, without asking what a field means.
- Chapter 08 recommends early-childhood educator review before any child uses the product.
