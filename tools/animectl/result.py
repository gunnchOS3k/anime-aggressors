"""Shared result envelope + exit codes for animectl."""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

EXIT_OK = 0
EXIT_INVALID_ARGS = 2
EXIT_ENV_MISSING = 3
EXIT_VALIDATION = 4
EXIT_BUILD = 5
EXIT_RUNTIME = 6
EXIT_NO_DEVICE = 7
EXIT_SIGNER = 8
EXIT_STALE = 9
EXIT_EXTERNAL = 10

HUMAN_GATES = {
    "G6_VISUAL_READABILITY": "REQUIRES_HUMAN",
    "G8_HUMAN_FEEL": "REQUIRES_HUMAN",
    "G9_FINAL_ART_APPROVED": "REQUIRES_HUMAN",
    "MERGE_AUTHORIZED": False,
}


@dataclass
class Check:
    id: str
    status: str
    detail: str = ""
    evidence: str = ""


@dataclass
class AnimectlResult:
    schema: str = "anime_aggressors_animectl_result_v1"
    schema_version: int = 1
    command: str = ""
    repo: str = "gunnchOS3k/anime-aggressors"
    branch: str = ""
    git_sha: str = ""
    git_dirty: bool = False
    generated_at: str = ""
    status: str = "PASS"
    exit_code: int = 0
    tool_versions: dict[str, Any] = field(default_factory=dict)
    checks: list[dict[str, Any]] = field(default_factory=list)
    artifacts: list[str] = field(default_factory=list)
    human_gates: dict[str, Any] = field(default_factory=lambda: dict(HUMAN_GATES))
    data: dict[str, Any] = field(default_factory=dict)

    def add_check(self, check_id: str, status: str, detail: str = "", evidence: str = "") -> None:
        self.checks.append({"id": check_id, "status": status, "detail": detail, "evidence": evidence})
        if status == "FAIL" and self.status not in ("FAIL",):
            self.status = "FAIL"
            self.exit_code = EXIT_VALIDATION
        elif status == "BLOCKED_EXTERNAL" and self.status == "PASS":
            self.status = "BLOCKED_EXTERNAL"
            self.exit_code = EXIT_EXTERNAL
        elif status == "REQUIRES_PHYSICAL" and self.status == "PASS":
            self.status = "REQUIRES_PHYSICAL"
            self.exit_code = EXIT_NO_DEVICE
        elif status == "REQUIRES_HUMAN" and self.status == "PASS":
            self.status = "PASS_WITH_NOTES"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def emit(self, *, as_json: bool, output: Path | None, no_color: bool = False) -> int:
        if not self.generated_at:
            self.generated_at = datetime.now(timezone.utc).isoformat()
        payload = self.to_dict()
        text = json.dumps(payload, indent=2) + "\n"
        if output:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(text, encoding="utf-8")
        if as_json:
            print(text, end="")
        else:
            print(f"[{self.status}] {self.command} @ {self.git_sha[:12] or 'unknown'} (dirty={self.git_dirty})")
            for c in self.checks:
                print(f"  - {c['id']}: {c['status']}" + (f" — {c['detail']}" if c.get("detail") else ""))
            if self.artifacts:
                print("artifacts:")
                for a in self.artifacts:
                    print(f"  - {a}")
        return int(self.exit_code)
