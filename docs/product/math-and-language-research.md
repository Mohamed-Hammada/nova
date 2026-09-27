# How young children learn number operations and language: research behind Nova's games

Checked 2026-09-27. Each source was verified against its publisher record, abstract or full text
(J-STAGE, Crossref, OpenAlex). Japanese research is preferred (the research rule), and each entry
says where the research was done and on whom. Nothing here is a Nova finding: Nova's games borrow
methods from these studies and have not themselves been tested.

## Number operations

| Source | Where / who | What it shows | Used in Nova |
|---|---|---|---|
| **Murata (2004)**, Cognition and Instruction 22(2), 185-218 | Japan, Grade 1, one school year | Children move gradually to the **break-apart-to-make-ten** method for teen sums; counting and visual grouping support it | **Make Ten** (いくつといくつ); the skill graph now puts *parts of ten* before *adding within 20* |
| **Kullberg, Björklund, Brkovic & Runesson Kempe (2020)**, Educational Studies in Mathematics 103(2), 157-172 | Sweden, 103 five-year-olds, quasi-experiment (65 vs 38) | Making the **part-part-whole relations of numbers to ten** visible raised arithmetic above controls, lasting a year | **Make Ten** (five-frame, then ten-frame, then numbers only) |
| **Siegler & Ramani (2008)**, Developmental Science 11(5), 655-661 | USA, preschoolers, randomised | Four 15-minute sessions of a **linear numbered board game** closed the estimation gap between low- and higher-income children; a colour version did not | **Frog Hops** |
| **Ramani & Siegler (2008)**, Child Development 79(2), 375-394 | USA, low-income preschoolers (mean 5.4), randomised | About an hour of the linear board game improved comparison, number-line estimation, counting and numeral identification; gains held 9 weeks | **Frog Hops**; home task "a number board game at home" |
| **Urakami & Sugimura (2017)**, 科学教育研究 41(3), 295-302 | Japan (Hiroshima), 59 children aged 5-6 | Preschoolers' placements on a 0-20 line reflect a developing **mental number line** | **Frog Hops** (why a linear path suits this age) |

| **Murata (2008)**, Mathematical Thinking and Learning 10(4), 374-406 | Japan, elementary curriculum and classrooms | The **tape diagram** (テープ図) is a central representation used consistently across the grades to connect quantities in story problems | **Tape Stories** (ages 6-8): join stories (whole missing), then take-away (part missing) |

Also built from Murata (2004): **Cherry Sums** (さくらんぼ計算, ages 6-8): add past ten by making ten first
(8 + 5 -> 8 + 2 = 10, 10 + 3 = 13), in three steps. A parents' guide to all four Japanese methods, in
Arabic: [japanese-math-methods-ar.md](japanese-math-methods-ar.md); the same guide appears in Progress.

## Language and early literacy

| Source | Where / who | What it shows | Used in Nova |
|---|---|---|---|
| **Kakihana, Ando, Koyama, Iitaka & Sugawara (2009)**, 教育心理学研究 57(3), 295-308 | Japan, 55 children aged 3-4 | Of five cognitive factors, only **mora awareness** (the spoken units kana spell) independently predicted letter-sound knowledge | Cited on the **syllable-clapping** games (en/ar): spoken units practised early, alongside letters |
| **Shimamura & Mikami (1994)**, 教育心理学研究 42, 70-76 | Japan, 1,202 preschoolers (Tokyo, Aichi) | Most children read most hiragana before school | Context only |
| **Mol, Bus, de Jong & Smeets (2008)**, Early Education and Development 19(1), 7-26 | Meta-analysis of 16 studies | **Dialogic reading** (asking the child questions while reading) adds to expressive vocabulary, d = .59; smaller at 4-5 and for children at risk | **Story Time** (en/ar): a question after each page -- who, what happened, finish the sentence -- with pictures that do not give the answer away; home task: read and ask |
| **Ehri et al. (2001)**, Reading Research Quarterly 36(3), 250-287 | NRP meta-analysis, 52 studies | **Phonemic awareness** instruction helps reading (d = .53) and spelling (d = .59); more effective **with letters**, on one or two skills at a time, in short total time | Next step: pair sound games with letters (Nova's first-sound games already do) |
| **Marulis & Neuman (2010)**, Review of Educational Research 80(3), 300-335 | Meta-analysis, 67 studies, pre-K and K | Vocabulary interventions average d = .88; strongest when **explicit and implicit** teaching are combined | Next step: Word Hunt says a child-friendly meaning of each word after it is found |

No peer-reviewed Japanese study of dialogic reading was found in this search, so Story Time carries a
"research-japanese" warning from the validator -- the rule working as intended.

## What changed in Nova

- New skills: `math.number.parts-of-ten` (4-7), `math.number.path-to-10` (3-6); teen sums
  (`math.add-sub.within-20`) now build on parts of ten.
- New games: **Make Ten** (`make-number` mechanic), **Frog Hops** (`board-game-move`), **Story Time**
  (English and Arabic). Each reports explicit errors (over/under count, picture distractor) and has a
  real-life transfer task.
- Journey: Frog Hops in Rainbow Hill (3) and Echo Valley (4), Make Ten in Lily Pond (5) and Pattern
  Peaks (6, required), Story Time in Bubble Cove (3) and Story Bridge (4, required).
- The syllable games now cite Kakihana et al. (2009).

## Open decisions

- Story Time stories, Make Ten and Frog Hops wording need specialist and native Arabic review.
- Paths and frames always run left to right, as a number line does, in Arabic too; Arabic-medium
  classrooms should confirm this matches how children meet number lines at school.
- Recorded narration for new names is declared but not produced.
