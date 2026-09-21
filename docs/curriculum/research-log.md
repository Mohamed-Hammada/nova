# Research log: what happened when the brief's citations were checked

The original Nova brief cited eight sources. None of them had been verified. This file is the
record that each was opened and checked rather than trusted, and of what was found.

One row per citation from the original brief. "Confirmed" means the source exists, is the type
claimed, and says what the brief said it says. "Corrected" means it exists but the brief described
it inaccurately, and the evidence entry records the corrected version. "Dropped" means no entry was
recorded.

Part A of the verification work covered programme frameworks, guided play, game-based learning,
executive function and transfer, and digital/screens. Part B added the remaining three rows (the
2026 maths meta-analysis, the 2026 maths systematic review, and the phonological-awareness item),
and also researched early maths, Arabic and English early literacy, social-emotional learning and
spatial skills, which the original brief did not cite at all. All eight brief citations are now in
the table below.

## Classification rules used

- **Type is chosen by what the source is**, from the closed list in spec 3.6. Where a source is
  titled "a systematic review and meta-analysis" *and* pooled effect sizes were read, it is recorded
  as `meta_analysis`; where the title says systematic review and no pooled effect sizes were read in
  the primary source, it is recorded as `systematic_review`. A programme's own curriculum
  documentation is `program_evidence`; a model of development or of learning is
  `developmental_framework`. Both are framework class, so the choice does not change any
  `evidence_basis`.
- **Strength is separate from type.** No entry was rated `strong`. Every empirical entry recorded
  here is either indirect to Nova (teacher-led rather than digital, wider age band than 3-6,
  English-language samples) or carries a quality caveat, and several are both.

## The brief's citations

| Claim in the original brief | What the source actually says | Outcome (confirmed / corrected / dropped) | Evidence id |
|---|---|---|---|
| HighScope organises its preschool curriculum around eight content areas and uses a Plan-Do-Review sequence. | Confirmed from HighScope's own curriculum page: eight content areas (Approaches to Learning; Social and Emotional Development; Physical Development and Health; Language, Literacy and Communication; Mathematics; Creative Arts; Science and Technology; Social Studies) carrying 58 key developmental indicators, with plan-do-review described as central to the daily routine — "children make decisions about what they will do, carry out their ideas, and reflect upon their activities with adults and other children". The page also asserts the curriculum "has been validated through a direct evaluation" but cites no study; that claim is **not** relied on and is recorded as an unverified assertion in the entry's limits. | confirmed | `ev.programs.highscope-2024` |
| Tools of the Mind focuses on executive function and make-believe play. | Confirmed from the programme's own site: it "pairs Vygotskian theory with neuroscience", states that "Vygotskian theory recognizes the tremendous developmental potential of a certain kind of play — make-believe play", and names self-regulation as its target. **But the effectiveness picture the brief implied is not supported.** The Campbell systematic review (Baron et al., 2017; six US studies, 14 records) found that Tools significantly improved maths with a small effect size, while "although the average effect sizes for self-regulation and literacy favoured tools compared to other approaches, the effect was not statistically significant" — i.e. the programme's headline outcome was the one that did not reach significance. The reviewers note "shortcomings in the quality of evidence" and "high risk of bias in some of the included studies". Recorded as mixed-to-null, not positive. | corrected | `ev.programs.tools-of-the-mind-2024`, `ev.programs.baron-2017` |
| The Harvard Center on the Developing Child's executive-function materials name working memory, inhibitory control and cognitive flexibility. | Confirmed. The Center's InBrief for Working Paper No. 11 ("Building the Brain's 'Air Traffic Control' System") names exactly those three and defines them: working memory as "the ability to hold and manipulate information in mind", inhibitory control as "the capacity to resist acting on impulse and to control behavior", and cognitive flexibility as "the ability to adjust to new demands, priorities, or perspectives". It is a synthesis by the National Scientific Council on the Developing Child, not a primary study, so it is recorded as `developmental_framework`. | confirmed | `ev.transfer.harvard-cdc-2011` |
| A 2024 systematic review and meta-analysis of game-based learning in early childhood in *Frontiers in Psychology* (10.3389/fpsyg.2024.1307881) found positive effects on cognitive, social and emotional development, motivation and engagement, larger cognitive effects for puzzle games, and a role for adult guidance. | The paper exists (Alotaibi, 2024) and says all of that: cognitive g = 0.46, social g = 0.38, emotional g = 0.35, motivation g = 0.40, engagement g = 0.44; "puzzle games having a larger effect than other game types (g = 0.63 vs. g = 0.31)"; "educator-guided game-play and scaffolding was important for maximizing learning gains". **However, reading the paper raised quality problems the brief did not mention:** it reports 136 included studies yet a total of only 1,426 participants with study sizes of 20–112 and a median of 40 (these cannot all be true); it reports 136 of 232 screened records as included, an implausible inclusion rate; it publishes no table of included studies against a 77-item reference list, so the included set cannot be checked; and no I² statistics appear in the text. Recorded as `meta_analysis` at `emerging` strength, with those inconsistencies written into its limits. Nova does not lean on it. | corrected | `ev.games.alotaibi-2024` |
| A 2022 systematic review and meta-analysis of guided play in *Child Development* (Skene et al.), 39 studies, benefits over direct instruction for some maths, shape-knowledge, task-switching and spatial-vocabulary outcomes. | Confirmed, with two precisions. 39 studies were **reviewed** (published 1977–2020); **17** were in the meta-analysis (N = 3893, ages 1–8). Guided play beat direct instruction on early maths (g = 0.24), shape knowledge (g = 0.63) and task switching (g = 0.40), and beat **free play** — not direct instruction — on spatial/maths vocabulary (g = 0.93). "Differences were not identified for other key outcomes": receptive vocabulary g = −0.06, behaviour regulation g = −0.03, inhibitory control g = −0.06. The authors report 38 of 39 studies at high risk of bias and half with samples under 50. Every included intervention was adult-led; **no digital intervention was included**. | confirmed | `ev.guided-play.skene-2022` |
| A 2026 three-level meta-analysis of pre-primary maths interventions in *Educational Research Review* (ScienceDirect S1747938X26000692), 74 studies, finding both intentional teaching and exploratory play associated with maths gains, varying by skill and design. | Confirmed from the publisher-deposited abstract. Sun, Xie, Li, Li & Mu (2026), *Educational Research Review*, **52**, 100830, doi:10.1016/j.edurev.2026.100830. 74 studies (2000–2025); intentional teaching k = 56, exploratory play k = 18; 566 effect sizes. Intentional teaching g = 0.32, exploratory play g = 0.21, and **the difference between the two approaches was not statistically significant** — the brief's "varying by design" is really "no significant difference between approaches, with variation inside them". Within intentional teaching, effects were **smaller for foundational number and counting (g = 0.21)** than for quantitative comparison (g = 0.42) and calculation (g = 0.45); effects faded (post-test g = 0.34 → follow-up g = 0.20). Within exploratory play, contextual scenarios mattered (g = 0.47 vs g = 0.13) and non-maths outcomes did not move at all (g = −0.01). **Access caveat:** ScienceDirect returned HTTP 403 to every request, including for the open-access PDF, so only the abstract was read; the entry records nothing beyond it. | confirmed (with precisions) | `ev.math.sun-2026` |
| A 2026 systematic review in *Educational Studies in Mathematics* (ERIC EJ1510312) of 101 maths interventions for ages 3–6 in 25 countries, over 90% reporting positive results but with weak transfer to broader maths. | Confirmed. Muñez, Cheung, Lim & Tang (2026), *Educational Studies in Mathematics*, **122**(3), 451–486, doi:10.1007/s10649-026-10490-9; the author-provided abstract was read in full on the ERIC record. 101 interventions, ages 3–6, 25 countries, past 25 years; over 90% reported positive outcomes; half targeted low-SES children. The transfer limitation is sharper than the brief said: "gains were predominantly characterized by near-transfer to trained skills… **only 7% of the studies demonstrated far-transfer effects, and these yielded small effect sizes**", and with only just over a third including long-term follow-up the "fade-out" effect is called a persistent concern. The review also reports partial or absent control for confounders, unreported fidelity (particularly participant responsiveness), nearly half the studies run under low ecological validity (researcher-led one-to-one sessions), and parent-focused interventions being both uncommon and less consistently effective. Note it pools no effect sizes, so "over 90% positive" is a vote count; it is recorded as `systematic_review`, not `meta_analysis`. **This is the key source behind Nova's Transfer state.** | confirmed (with precisions) | `ev.math.munez-2026` |
| For "a small overall effect on phonological awareness", an item titled "Combined Language and Code Emergent Literacy Intervention for At-Risk Preschool Children: A Systematic Meta-Analytic Review" (*Child Development*, 2025, doi:10.1111/cdev.14252). The title does not obviously match the claim. | The item exists and is what its title says: Cusiter, Short, Webb & Munro (2025), *Child Development*, **96**(4), 1519–1545 — a meta-analytic review of interventions that **combine** language work and code work for **at-risk** 4–6 year olds (29 RCTs, 43 interventions, 9,333 children; 25 of 29 studies in the USA). It is not a phonological-awareness meta-analysis. **But it does report a phonological-awareness effect**, read in full text on PubMed Central: "The overall mean intervention effect on phonological awareness was small (*g* = 0.32, 95% CI [0.18, 0.45], *p* < 0.01)", from 46 effect sizes in 21 studies, *I²* = 71%. So the brief's claim survives, with the size and the scope corrected: composite **code** effect *g* = 0.23, composite **language** effect *g* = 0.11, and within phonological awareness the composite measure barely moved (*g* = 0.08) while trained subskills did (blending/elision *g* = 0.26, first-sound identification *g* = 0.24). The authors detected publication bias. Only 2 of 43 interventions were computer-delivered. Recorded honestly as a caution about near transfer, not as support for a phonological-awareness game. | corrected | `ev.literacy.cusiter-2025` |

## Sources that need a spec change

- **Diamond & Lee (2011), *Science*, 333(6045), 959–964, "Interventions shown to aid executive
  function development in children 4 to 12 years old"** (opened at
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC3159917/>). This is a **narrative review**, not a
  systematic review and not a meta-analysis: the authors survey six families of intervention
  (computerised training, hybrid computer/non-computer games, aerobic exercise, martial arts and
  mindfulness, classroom curricula including Tools of the Mind and Montessori, and curriculum
  add-ons) without a systematic search protocol or pooled effect sizes. Its useful conclusions for
  Nova are that transfer tends to be narrow ("working memory training improves working memory but
  not inhibition or speed") and that "children with worse executive functions initially, benefit
  most". The closed type list in spec 3.6 has no `narrative_review`, and forcing this into
  `systematic_review` would misrepresent it. **No evidence entry was recorded.** Proposed spec
  change: add `narrative_review` (empirical class, but never above `moderate` strength) to the
  closed list, then record this source. Until then the narrow-transfer point is carried by
  `ev.transfer.melby-lervag-2016`, `ev.transfer.sala-2019` and `ev.transfer.kassai-2019`, which are
  meta-analyses and say the same thing more rigorously.
- **`developmental_framework` is the only framework-class type for a conceptual model, and its name
  does not fit every such model.** Barnett & Ceci (2002), a taxonomy of transfer, is recorded as
  `developmental_framework` because the framework *class* is right, but it is a framework of
  learning transfer, not of development. Proposed spec change: rename the type to `framework`, or
  add a sibling type, so the label stops implying a developmental claim. This is cosmetic: the class
  and therefore every computed `evidence_basis` is unaffected.

## Notes on access

Several publisher pages refused automated access (Wiley, SAGE, UC Press, AAP's *Pediatrics*, WHO
IRIS, and PubMed/NCBI Bookshelf all returned HTTP 403 or a bot check). Where that happened the same
primary content was obtained from another authoritative copy and that copy's URL is the one recorded
on the entry:

- Skene et al. (2022) — read in full on PubMed Central (PMC9545698).
- Baron et al. (2017) and Randolph et al. (2023) — read on the Campbell Collaboration's own review
  pages.
- Melby-Lervåg et al. (2016) — read on the Oxford University Research Archive record.
- Sala et al. (2019) — read on the authors' institutional repository record (Fujita Health
  University); the Collabra page itself returned 403.
- Kassai et al. (2019) — read on the Edinburgh Research Explorer record; cross-checked against the
  Europe PMC record for the same DOI.
- Barnett & Ceci (2002) — the PDF was downloaded and its text extracted; the abstract, the two
  taxonomy categories and the *Psychological Bulletin* 128(4), 612–637 citation line were read
  directly from it.
- WHO (2019) — the recommendation text was read from the WHO IRIS PDF of the guideline summary
  (WHO/NMH/PND/2019.4); the publication record (date 2 April 2019, ISBN 9789241550536) was read on
  the who.int publication page, which is the URL recorded on the entry. The GRADE strength and
  quality ratings for individual recommendations were **not** obtained and are therefore not
  recorded.
- AAP (2026) — the abstract was read from the Europe PMC record for doi:10.1542/peds.2025-075320 and
  the family-facing recommendations from AAP's own HealthyChildren.org explainer, which is the URL
  recorded. The full *Pediatrics* text returned 403 and its recommendation tables were not read, so
  no numeric limit for ages 2–5 is attributed to AAP.

## Other sources recorded in Part A (not from the brief)

| Source | Why it is here | Type / strength |
|---|---|---|
| Randolph et al. (2023), Campbell systematic review of Montessori, 32 studies, 8 countries | The brief asked for Montessori to be recorded honestly. Academic outcomes ≈ 0.25 SD, non-academic ≈ 0.33 SD over traditional education; larger for randomised designs, for preschool/elementary, and for *private* Montessori. | `systematic_review` / `moderate` |
| Reggio Children, the Reggio Emilia Approach | Documented philosophy. Reggio Children's own site presents **no** effectiveness research at all; recorded as such. | `program_evidence` / `emerging` |
| What Works Clearinghouse (2013), The Creative Curriculum for Preschool, 4th ed. | The honest counterweight to programme marketing: of 14 studies only 2 met WWC standards, and the rating was "no discernible effects" on general mathematics achievement, oral language, phonological processing and print knowledge. The 4th edition has since been superseded. | `systematic_review` / `emerging` |
| Scionti et al. (2020), *Frontiers in Psychology*, meta-analysis of cognitive training in 3–6 year olds | The only transfer meta-analysis in Part A that is specific to Nova's age band, and it partly disagrees with Kassai: transfer **within** executive domains was as large as near transfer (g = 0.318 vs 0.352), but transfer **out** to behavioural and learning outcomes was not significant (g = 0.169, p = 0.122). Computerised training was no more effective than non-computerised. | `meta_analysis` / `moderate` |
| Hirsh-Pasek et al. (2015), *Psychological Science in the Public Interest* | The four pillars (active, engaged, meaningful, socially interactive) plus a learning goal, and the observation that "more than 80,000 App Store apps are described as being education- or learning-based, however, there are currently no science-based standards to guide this determination". | `developmental_framework` / `moderate` |

## Nothing was dropped in Part A

Every source examined for these rows was either recorded or, in the single case of Diamond & Lee
(2011), held back pending a spec change and logged above. No claim was recorded that its source did
not support.
