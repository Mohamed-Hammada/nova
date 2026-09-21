"""Shared types and constants for the Nova spec validator."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

Record = dict[str, Any]

DOMAINS = (
    "cognitive",
    "executive_function",
    "language_literacy",
    "math",
    "problem_solving",
    "memory",
    "attention",
    "visual_spatial",
    "fine_motor",
    "social_emotional",
    "creativity",
    "science_exploration",
)

# The seven difficulty dimensions (spec 3.3).
DIFFICULTY_DIMENSIONS = (
    "item_complexity",
    "distractors",
    "working_memory_load",
    "rule_complexity",
    "abstraction",
    "cognitive_load",
    "independence",
)

# Shared literacy slots that every language pack fills (spec 3.8).
SLOTS = (
    "listening",
    "vocabulary",
    "phonological_awareness",
    "print_concepts",
    "letter_knowledge",
    "sound_mapping",
    "word_building",
    "early_reading",
)

MASTERY_STATES = ("emerging", "developing", "secure", "transfer")

# Assessment dimensions that a mastery state can require (spec 3.4).
ASSESSMENT_DIMENSIONS = ("performance", "independence", "transfer")

# Evidence type -> evidence class (spec 3.6).
EVIDENCE_TYPES = {
    "systematic_review": "empirical",
    "meta_analysis": "empirical",
    "rct": "empirical",
    "quasi_experimental": "empirical",
    "developmental_framework": "framework",
    "program_evidence": "framework",
    "expert_consensus": "judgment",
    "design_inference": "judgment",
}

EVIDENCE_STRENGTHS = ("emerging", "moderate", "strong")
STRENGTH_RANK = {name: rank for rank, name in enumerate(EVIDENCE_STRENGTHS, start=1)}

# Judgment-class evidence can never be rated above these caps.
STRENGTH_CAPS = {"expert_consensus": "moderate", "design_inference": "emerging"}

# Deep-coverage set (spec 3.1): these domains, plus Arabic and English literacy,
# for skills whose age range starts before DEEP_AGE_WINDOW[1] and ends after [0].
DEEP_DOMAINS = frozenset({"executive_function", "memory", "math"})
DEEP_LANGUAGES = frozenset({"ar", "en"})
DEEP_AGE_WINDOW = (3, 6)


@dataclass(frozen=True)
class Issue:
    level: str  # "error" | "warning"
    rule: str
    where: str
    message: str

    def __str__(self) -> str:
        return f"{self.level.upper()} [{self.rule}] {self.where}: {self.message}"


def error(rule: str, where: str, message: str) -> Issue:
    return Issue("error", rule, where, message)


def warning(rule: str, where: str, message: str) -> Issue:
    return Issue("warning", rule, where, message)


@dataclass
class Spec:
    skills: list[Record] = field(default_factory=list)
    games: list[Record] = field(default_factory=list)
    transfer_tasks: list[Record] = field(default_factory=list)
    evidence: list[Record] = field(default_factory=list)
    parameters: list[Record] = field(default_factory=list)
    assessment_rules: list[Record] = field(default_factory=list)
    langpacks: list[Record] = field(default_factory=list)
    mechanics: list[Record] = field(default_factory=list)
    signals: list[Record] = field(default_factory=list)
    i18n: dict[str, dict[str, str]] = field(default_factory=dict)


def index_by_id(records: list[Record]) -> dict[str, Record]:
    return {record["id"]: record for record in records}
