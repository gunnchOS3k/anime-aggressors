"""Playwright adapter — detect install; never require global Playwright MCP."""
from __future__ import annotations

from pathlib import Path

from ..process import run


def playwright_available(root: Path) -> bool:
    cfg = root / "playwright.config.ts"
    local = root / "node_modules" / "@playwright" / "test"
    return cfg.exists() and local.exists()


def run_playwright(root: Path, *, project: str | None = None, headed: bool = False):
    cmd = ["npx", "playwright", "test"]
    if project:
        cmd.extend(["--project", project])
    if headed:
        cmd.append("--headed")
    return run(cmd, cwd=root, timeout=600)
