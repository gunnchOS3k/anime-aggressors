"""animectl CLI."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__
from .acceptance import run_acceptance
from .audit import run_audit
from .doctor import run_doctor
from .inspect_runtime import run_inspect
from .result import EXIT_INVALID_ARGS
from .verify import run_verify
from .wrappers import run_android, run_art, run_build, run_capture, run_play, run_story


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _globals(p: argparse.ArgumentParser) -> None:
    """Global flags must work before or after the subcommand."""
    p.add_argument("--json", action="store_true", help="Emit structured JSON envelope")
    p.add_argument("--output", type=Path, help="Write JSON result to path")
    p.add_argument("--exact-head", action="store_true", help="Enforce exact-head evidence rules")
    p.add_argument("--no-color", action="store_true")
    p.add_argument("--verbose", action="store_true")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="animectl", description="Anime Aggressors control plane (V1.4)")
    _globals(p)
    p.add_argument("--version", action="version", version=f"animectl {__version__}")

    sub = p.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("doctor", help="Toolchain + disk")
    _globals(d)
    d.add_argument("--safe-clean", action="store_true")

    a = sub.add_parser("audit", help="Code-backed runtime map")
    _globals(a)

    insp = sub.add_parser("inspect", help="Inspect runtime contracts")
    _globals(insp)
    insp_sub = insp.add_subparsers(dest="inspect_cmd", required=True)
    ir = insp_sub.add_parser("runtime")
    _globals(ir)
    ir.add_argument("--fighter", required=True)
    ir.add_argument("--body", choices=["male", "female"], required=True)
    ir.add_argument("--story-form", default="NORMAL")
    ir.add_argument("--essence", type=int, default=0)

    ver = sub.add_parser("verify", help="Wrap validators")
    _globals(ver)
    ver.add_argument(
        "topic",
        nargs="?",
        default="all",
        choices=["animations", "moves", "models", "story", "determinism", "partylink", "all"],
    )
    ver.add_argument("--all", action="store_true", dest="verify_all")

    acc = sub.add_parser("acceptance", help="Exact-head acceptance")
    _globals(acc)
    acc.add_argument("--quick", action="store_true")
    acc.add_argument("--full", action="store_true")

    st = sub.add_parser("story", help="Story QA helpers")
    _globals(st)
    st.add_argument("action", choices=["status", "reset", "route", "state", "unlock-cosmic"])
    st.add_argument("route", nargs="?", default=None)
    st.add_argument("--test-profile", action="store_true")
    st.add_argument("--fighter")
    st.add_argument("--form")
    st.add_argument("--essence", type=int)

    b = sub.add_parser("build", help="Wrap builds")
    _globals(b)
    b.add_argument("target", choices=["web", "android", "all"])

    an = sub.add_parser("android", help="Android/ADB helpers")
    _globals(an)
    an.add_argument("action", choices=["doctor", "build", "install", "smoke", "evidence"])

    pl = sub.add_parser("play", help="Dev play hints")
    _globals(pl)
    pl.add_argument("--headed", action="store_true")
    pl.add_argument("--fighter")
    pl.add_argument("--body", choices=["male", "female"])
    pl.add_argument("--story", action="store_true")

    cap = sub.add_parser("capture", help="Capture evidence dirs")
    _globals(cap)
    cap.add_argument("topic", choices=["roster", "story", "fighter", "acceptance"])
    cap.add_argument("fighter_id", nargs="?", default=None)

    art = sub.add_parser("art", help="Art/Blender wrappers")
    _globals(art)
    art.add_argument("action", choices=["doctor", "validate", "build"])
    art.add_argument("--fighter")
    art.add_argument("--all", action="store_true", dest="art_all")

    return p


def _flag(ns: argparse.Namespace, name: str, default=None):
    return getattr(ns, name, default)


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    parser = build_parser()
    try:
        args = parser.parse_args(argv)
    except SystemExit as e:
        code = e.code if isinstance(e.code, int) else EXIT_INVALID_ARGS
        return code

    root = repo_root()
    as_json = bool(_flag(args, "json", False))
    output = _flag(args, "output", None)
    no_color = bool(_flag(args, "no_color", False))
    exact_head = bool(_flag(args, "exact_head", False))
    common = dict(as_json=as_json, output=output, no_color=no_color)

    if args.cmd == "doctor":
        return run_doctor(root, safe_clean_flag=bool(_flag(args, "safe_clean", False))).emit(**common)
    if args.cmd == "audit":
        return run_audit(root).emit(**common)
    if args.cmd == "inspect" and getattr(args, "inspect_cmd", None) == "runtime":
        return run_inspect(
            root,
            fighter=args.fighter,
            body=args.body,
            story_form=getattr(args, "story_form", "NORMAL") or "NORMAL",
            essence=int(getattr(args, "essence", 0) or 0),
        ).emit(**common)
    if args.cmd == "verify":
        topic = "all" if getattr(args, "verify_all", False) else (args.topic or "all")
        return run_verify(root, topic).emit(**common)
    if args.cmd == "acceptance":
        mode = "full" if getattr(args, "full", False) else "quick"
        # acceptance defaults to exact-head semantics
        return run_acceptance(root, exact_head=exact_head or True, mode=mode).emit(**common)
    if args.cmd == "story":
        return run_story(root, args.action, route=getattr(args, "route", None)).emit(**common)
    if args.cmd == "build":
        return run_build(root, args.target, exact_head=exact_head).emit(**common)
    if args.cmd == "android":
        return run_android(root, args.action).emit(**common)
    if args.cmd == "play":
        return run_play(root).emit(**common)
    if args.cmd == "capture":
        return run_capture(root, args.topic).emit(**common)
    if args.cmd == "art":
        return run_art(root, args.action).emit(**common)
    return EXIT_INVALID_ARGS
