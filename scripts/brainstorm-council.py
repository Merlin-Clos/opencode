#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import random
import re
import sys
from typing import NoReturn, TypeVar, TypedDict


class Evidence(TypedDict):
    claim: str
    status: str
    source: str


class Candidate(TypedDict):
    solution: str
    benefits: list[str]
    costs: list[str]
    risks: list[str]
    evidence: list[Evidence]
    original: bool
    author: str
    model: str
    provider: str


class CandidateGroup(TypedDict):
    solution: str
    benefits: list[str]
    costs: list[str]
    risks: list[str]
    evidence: list[Evidence]
    source_indices: list[int]
    original: bool


class InputError(Exception):
    pass


class ArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> NoReturn:
        raise InputError("Usage: normalize [--seed N], where N is an integer.")


EVIDENCE_STATUSES = {
    "VERIFIED",
    "PARTIALLY SUPPORTED",
    "REFUTED",
    "UNVERIFIED",
    "NOT TESTABLE WITH AVAILABLE TOOLS",
}
SOURCE_REQUIRED = {"VERIFIED", "PARTIALLY SUPPORTED", "REFUTED"}
ORIGINAL_ATTRIBUTION = re.compile(
    r"\boriginal\s+(?:proposal|solution|candidate|idea|submission|approach|"
    r"suggestion|answer|option|plan)\b"
    r"|\b(?:proposal|solution|candidate|idea|submission|approach|suggestion|"
    r"answer|option|plan)\s+(?:is|was)\s+(?:the\s+)?original\b"
    r"|\b(?:this|that|it)\s+(?:is|was)\s+(?:the\s+)?original(?=\s*(?:[.,!?;:]|$))"
    r"|^(?:the\s+)?original(?:\s*:|$)",
    re.IGNORECASE,
)


def object_with_fields(value: object, fields: set[str], name: str) -> dict[str, object]:
    if not isinstance(value, dict) or value.keys() != fields:
        raise InputError(f"{name} must be an object with exactly the required fields.")
    return value


def nonempty_text(value: object, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise InputError(f"{name} must be a non-empty string.")
    return value


def text_list(value: object, name: str, *, nonempty: bool = False) -> list[str]:
    if not isinstance(value, list) or (nonempty and not value):
        raise InputError(f"{name} must be a list of non-empty strings.")
    return [nonempty_text(item, name) for item in value]


def evidence_item(value: object) -> Evidence:
    item = object_with_fields(value, {"claim", "status", "source"}, "Evidence")
    claim = nonempty_text(item["claim"], "Evidence claim")
    status = nonempty_text(item["status"], "Evidence status")
    if status not in EVIDENCE_STATUSES:
        raise InputError("Evidence status is not recognized.")
    source = item["source"]
    if not isinstance(source, str) or (status in SOURCE_REQUIRED and not source.strip()):
        raise InputError("Evidence source must be a string and is required for this status.")
    return {"claim": claim, "status": status, "source": source}


def candidate_item(value: object) -> Candidate:
    item = object_with_fields(
        value,
        {
            "solution", "benefits", "costs", "risks", "evidence", "original",
            "author", "model", "provider",
        },
        "Candidate",
    )
    evidence = item["evidence"]
    if not isinstance(evidence, list):
        raise InputError("Candidate evidence must be a list.")
    original = item["original"]
    if type(original) is not bool:
        raise InputError("Candidate original must be a boolean.")
    return {
        "solution": nonempty_text(item["solution"], "Candidate solution"),
        "benefits": text_list(item["benefits"], "Candidate benefits"),
        "costs": text_list(item["costs"], "Candidate costs"),
        "risks": text_list(item["risks"], "Candidate risks"),
        "evidence": [evidence_item(entry) for entry in evidence],
        "original": original,
        "author": nonempty_text(item["author"], "Candidate author"),
        "model": nonempty_text(item["model"], "Candidate model"),
        "provider": nonempty_text(item["provider"], "Candidate provider"),
    }


def normalized_text(value: str) -> str:
    return " ".join(value.casefold().split())


def reject_attribution(task: str, criteria: list[str], candidates: list[Candidate]) -> None:
    identities = {
        normalized_text(identity)
        for candidate in candidates
        for identity in (candidate["author"], candidate["model"], candidate["provider"])
    }
    public_text = [task, *criteria]
    for candidate in candidates:
        public_text.append(candidate["solution"])
        public_text.extend(candidate["benefits"])
        public_text.extend(candidate["costs"])
        public_text.extend(candidate["risks"])
        for evidence in candidate["evidence"]:
            public_text.extend((evidence["claim"], evidence["status"], evidence["source"]))
    for text in public_text:
        normalized = normalized_text(text)
        if ORIGINAL_ATTRIBUTION.search(normalized) or any(
            identity in normalized for identity in identities
        ):
            raise InputError(
                "Public content contains candidate attribution metadata; "
                "provide neutral content or corrected metadata."
            )


T = TypeVar("T")


def extend_unique(target: list[T], items: list[T]) -> None:
    for item in items:
        if item not in target:
            target.append(item)


def normalize(value: object, seed: int | None) -> dict[str, object]:
    item = object_with_fields(value, {"task", "criteria", "candidates"}, "Input")
    task = nonempty_text(item["task"], "Task")
    criteria = text_list(item["criteria"], "Criteria", nonempty=True)
    raw_candidates = item["candidates"]
    if not isinstance(raw_candidates, list) or len(raw_candidates) < 2:
        raise InputError("At least two candidates are required.")
    candidates = [candidate_item(candidate) for candidate in raw_candidates]
    if not any(candidate["original"] for candidate in candidates):
        raise InputError("At least one candidate must be original.")
    reject_attribution(task, criteria, candidates)

    groups: dict[str, CandidateGroup] = {}
    for index, candidate in enumerate(candidates):
        key = normalized_text(candidate["solution"])
        if key not in groups:
            groups[key] = {
                "solution": candidate["solution"],
                "benefits": [],
                "costs": [],
                "risks": [],
                "evidence": [],
                "source_indices": [],
                "original": False,
            }
        group = groups[key]
        extend_unique(group["benefits"], candidate["benefits"])
        extend_unique(group["costs"], candidate["costs"])
        extend_unique(group["risks"], candidate["risks"])
        extend_unique(group["evidence"], candidate["evidence"])
        group["source_indices"].append(index)
        group["original"] = group["original"] or candidate["original"]
    if len(groups) < 2:
        raise InputError("At least two distinct solutions are required.")

    ordered = list(groups.values())
    rng = random.SystemRandom() if seed is None else random.Random(seed)
    rng.shuffle(ordered)
    packet_candidates = []
    mapping = {}
    for identifier, group in enumerate(ordered, start=1):
        packet_candidates.append({
            "id": identifier,
            "solution": group["solution"],
            "benefits": group["benefits"],
            "costs": group["costs"],
            "risks": group["risks"],
            "evidence": group["evidence"],
        })
        mapping[str(identifier)] = {
            "source_indices": group["source_indices"],
            "original": group["original"],
        }
    return {
        "packet": {"task": task, "criteria": criteria, "candidates": packet_candidates},
        "mapping": mapping,
    }


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = {}
    for key, value in pairs:
        if key in result:
            raise InputError("JSON objects must not contain duplicate fields.")
        result[key] = value
    return result


def invalid_constant(_value: str) -> NoReturn:
    raise InputError("Input must be valid JSON.")


def main() -> int:
    parser = ArgumentParser(add_help=False)
    commands = parser.add_subparsers(required=True)
    normalize_parser = commands.add_parser("normalize", add_help=False)
    normalize_parser.add_argument("--seed", type=int)
    try:
        args = parser.parse_args()
        try:
            value = json.load(
                sys.stdin, object_pairs_hook=unique_object, parse_constant=invalid_constant
            )
        except (ValueError, UnicodeDecodeError, RecursionError):
            raise InputError("Input must be valid JSON.") from None
        output = json.dumps(normalize(value, args.seed))
    except InputError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 1
    print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
