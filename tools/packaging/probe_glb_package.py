#!/usr/bin/env python3
"""Export a tiny Godot pack using the shipping game-godot filters.

The pack contains real authored bytes copied from this repository.
It does not regenerate art and it does not edit export_presets.cfg.

Cases:
  form_unimported  — form-acting GLB with no .import, matching the commit
  form_keep        — same GLB plus importer="keep" (candidate packaging fix)
  pipeline_scene   — pipeline_proof.glb plus its committed scene .import
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import textwrap
from pathlib import Path


FORM_REL = (
    "game-godot/assets/characters/form_acting_8c/ember-vale/female/EMBER_ASCENDED.glb"
)
FORM_RES = "res://assets/characters/form_acting_8c/ember-vale/female/EMBER_ASCENDED.glb"
PIPELINE_REL = "game-godot/assets/characters/authored/ember-vale/pipeline_proof.glb"
PIPELINE_RES = "res://assets/characters/authored/ember-vale/pipeline_proof.glb"
PRESET_CFG = "game-godot/export_presets.cfg"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def preset_filters(cfg_text: str) -> dict[str, dict[str, str]]:
    current = None
    found: dict[str, dict[str, str]] = {}
    meta: dict[str, str] = {}
    for raw in cfg_text.splitlines():
        line = raw.strip()
        if line.startswith("[") and line.endswith("]"):
            if current and "name" in meta:
                found[meta["name"]] = {
                    "platform": meta.get("platform", ""),
                    "export_filter": meta.get("export_filter", ""),
                    "include_filter": meta.get("include_filter", ""),
                    "exclude_filter": meta.get("exclude_filter", ""),
                }
            current = line
            meta = {}
            continue
        if current and current.endswith(".options]"):
            continue
        if "=" not in line or line.startswith(";"):
            continue
        key, value = line.split("=", 1)
        if key in {"name", "platform", "export_filter", "include_filter", "exclude_filter"}:
            meta[key] = value.strip().strip('"')
    if current and "name" in meta:
        found[meta["name"]] = {
            "platform": meta.get("platform", ""),
            "export_filter": meta.get("export_filter", ""),
            "include_filter": meta.get("include_filter", ""),
            "exclude_filter": meta.get("exclude_filter", ""),
        }
    return found


def write_probe_project(root: Path, case: str, godot_feature: str, filters: dict[str, dict[str, str]], repo: Path) -> None:
    if root.exists():
        shutil.rmtree(root)
    (root / "assets/characters/form_acting_8c/ember-vale/female").mkdir(parents=True)
    (root / "assets/characters/authored/ember-vale").mkdir(parents=True)
    (root / "extra").mkdir()
    form_src = repo / FORM_REL
    pipe_src = repo / PIPELINE_REL
    shutil.copy2(form_src, root / "assets/characters/form_acting_8c/ember-vale/female/EMBER_ASCENDED.glb")
    shutil.copy2(pipe_src, root / "assets/characters/authored/ember-vale/pipeline_proof.glb")
    (root / "extra/keep.json").write_text('{"probe":true}\n', encoding="utf-8")
    (root / "extra/skip.txt").write_text("not a resource and not in include_filter\n", encoding="utf-8")

    if case == "form_keep":
        keep = root / "assets/characters/form_acting_8c/ember-vale/female/EMBER_ASCENDED.glb.import"
        keep.write_text(
            textwrap.dedent(
                f"""\
                [remap]

                importer="keep"

                [deps]

                source_file="{FORM_RES}"
                """
            ),
            encoding="utf-8",
        )
    elif case == "pipeline_scene":
        shutil.copy2(repo / (PIPELINE_REL + ".import"), root / "assets/characters/authored/ember-vale/pipeline_proof.glb.import")

    (root / "project.godot").write_text(
        textwrap.dedent(
            f"""\
            ; Engine configuration file.
            config_version=5

            [application]

            config/name="GLBPackageProbe"
            config/features=PackedStringArray("{godot_feature}", "GL Compatibility")
            run/main_scene="res://Probe.tscn"

            [rendering]

            renderer/rendering_method="gl_compatibility"
            """
        ),
        encoding="utf-8",
    )
    (root / "probe.gd").write_text(
        textwrap.dedent(
            """\
            extends Node

            func _ready() -> void:
            	var lines: PackedStringArray = []
            	_file(lines, "form", "res://assets/characters/form_acting_8c/ember-vale/female/EMBER_ASCENDED.glb")
            	_file(lines, "pipeline", "res://assets/characters/authored/ember-vale/pipeline_proof.glb")
            	_exists(lines, "json", "res://extra/keep.json")
            	_exists(lines, "txt", "res://extra/skip.txt")
            	print("PROBE_RESULT_BEGIN")
            	for line in lines:
            		print(line)
            	print("PROBE_RESULT_END")
            	get_tree().quit(0)

            func _file(lines: PackedStringArray, label: String, path: String) -> void:
            	var exists := FileAccess.file_exists(path)
            	var bytes := PackedByteArray()
            	if exists:
            		bytes = FileAccess.get_file_as_bytes(path)
            	var magic := ""
            	if bytes.size() >= 4:
            		magic = bytes.slice(0, 4).get_string_from_ascii()
            	var gltf_err := -1
            	var gltf_scene := false
            	if exists and magic == "glTF":
            		var document := GLTFDocument.new()
            		var state := GLTFState.new()
            		gltf_err = document.append_from_file(path, state)
            		if gltf_err == OK:
            			gltf_scene = document.generate_scene(state) != null
            	var loaded: Variant = null
            	if ResourceLoader.exists(path):
            		loaded = load(path)
            	lines.append("%s exists=%s size=%d magic=%s gltf_err=%d gltf_scene=%s load=%s resource_exists=%s" % [label, exists, bytes.size(), magic, gltf_err, gltf_scene, loaded, ResourceLoader.exists(path)])

            func _exists(lines: PackedStringArray, label: String, path: String) -> void:
            	var exists := FileAccess.file_exists(path)
            	var size := FileAccess.get_file_as_bytes(path).size() if exists else -1
            	lines.append("%s exists=%s size=%d" % [label, exists, size])
            """
        ),
        encoding="utf-8",
    )
    (root / "Probe.tscn").write_text(
        textwrap.dedent(
            """\
            [gd_scene load_steps=2 format=3]

            [ext_resource type="Script" path="res://probe.gd" id="1"]

            [node name="Probe" type="Node"]
            script = ExtResource("1")
            """
        ),
        encoding="utf-8",
    )
    preset_lines = ["[preset.0]", "", 'name="Web"', 'platform="Web"', "runnable=true", 'export_filter="all_resources"']
    web = filters.get("Web", {})
    android = filters.get("Android", {})
    preset_lines.append(f'include_filter="{web.get("include_filter", "")}"')
    preset_lines.append(f'exclude_filter="{web.get("exclude_filter", "")}"')
    preset_lines.append('export_path="build/web/index.html"')
    preset_lines.append("")
    preset_lines.append("[preset.0.options]")
    preset_lines.append("")
    preset_lines.append('custom_template/debug=""')
    preset_lines.append('custom_template/release=""')
    preset_lines.append("variant/thread_support=false")
    preset_lines.append("")
    preset_lines.append("[preset.1]")
    preset_lines.append("")
    preset_lines.append('name="Android"')
    preset_lines.append('platform="Android"')
    preset_lines.append("runnable=true")
    preset_lines.append(f'export_filter="{android.get("export_filter", "all_resources")}"')
    preset_lines.append(f'include_filter="{android.get("include_filter", "")}"')
    preset_lines.append(f'exclude_filter="{android.get("exclude_filter", "")}"')
    preset_lines.append('export_path="build/android/probe.apk"')
    preset_lines.append("")
    preset_lines.append("[preset.1.options]")
    preset_lines.append("")
    preset_lines.append("gradle_build/use_gradle_build=false")
    preset_lines.append("package/signed=false")
    preset_lines.append('package/unique_name="com.gunnchos.glbprobe"')
    preset_lines.append('package/name="GLB Probe"')
    (root / "export_presets.cfg").write_text("\n".join(preset_lines) + "\n", encoding="utf-8")


def run(cmd: list[str], cwd: Path, timeout: int) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, timeout=timeout, check=False)


def parse_probe(log: str) -> list[str]:
    lines = log.splitlines()
    if "PROBE_RESULT_BEGIN" not in lines or "PROBE_RESULT_END" not in lines:
        return []
    start = lines.index("PROBE_RESULT_BEGIN") + 1
    end = lines.index("PROBE_RESULT_END")
    return lines[start:end]


def pck_paths(pck: Path) -> list[str]:
    data = pck.read_bytes()
    if data[:4] != b"GDPC":
        return [f"bad_magic:{data[:4]!r}"]
    # Godot 4 directory entries store res:// paths as length-prefixed strings.
    paths: list[str] = []
    needle = b"res://"
    start = 0
    while True:
        at = data.find(needle, start)
        if at < 0 or at < 4:
            break
        length = int.from_bytes(data[at - 4 : at], "little")
        if 6 <= length <= 512 and at + length <= len(data):
            raw = data[at : at + length]
            if raw.startswith(b"res://") and b"\x00" not in raw:
                try:
                    paths.append(raw.decode("utf-8"))
                except UnicodeDecodeError:
                    pass
        start = at + 6
    # Preserve order, drop duplicates.
    seen: set[str] = set()
    unique: list[str] = []
    for path in paths:
        if path not in seen:
            seen.add(path)
            unique.append(path)
    return unique


def export_case(godot: str, root: Path, out_dir: Path, case: str, preset: str) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    pck = out_dir / f"{case}-{preset.lower()}.pck"
    log_path = out_dir / f"{case}-{preset.lower()}.export.log"
    export = run([godot, "--headless", "--path", str(root), "--export-pack", preset, str(pck)], root, 180)
    log_path.write_text(export.stdout + "\n" + export.stderr, encoding="utf-8")
    record: dict = {
        "case": case,
        "preset": preset,
        "export_code": export.returncode,
        "pck_exists": pck.exists(),
        "pck_bytes": pck.stat().st_size if pck.exists() else 0,
        "paths": [],
        "runtime": [],
        "runtime_code": None,
    }
    if not pck.exists():
        record["export_tail"] = (export.stdout + export.stderr)[-2000:]
        return record
    record["paths"] = pck_paths(pck)
    runtime = run([godot, "--headless", "--main-pack", str(pck)], root, 90)
    (out_dir / f"{case}-{preset.lower()}.runtime.log").write_text(runtime.stdout + "\n" + runtime.stderr, encoding="utf-8")
    record["runtime_code"] = runtime.returncode
    record["runtime"] = parse_probe(runtime.stdout + "\n" + runtime.stderr)
    if not record["runtime"]:
        record["runtime_tail"] = (runtime.stdout + runtime.stderr)[-2000:]
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    repo = Path(args.repo)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    filters = preset_filters((repo / PRESET_CFG).read_text(encoding="utf-8"))
    form = repo / FORM_REL
    pipe = repo / PIPELINE_REL
    summary: dict = {
        "godot_version_requested": args.version,
        "godot_bin": args.godot,
        "shipping_filters": filters,
        "sources": {
            "form": {"path": FORM_REL, "bytes": form.stat().st_size, "sha256": sha256(form)},
            "pipeline": {"path": PIPELINE_REL, "bytes": pipe.stat().st_size, "sha256": sha256(pipe)},
        },
        "cases": [],
    }
    version = run([args.godot, "--version"], repo, 30)
    summary["godot_version_output"] = (version.stdout or version.stderr).strip()
    feature = args.version
    work = out / "work"
    for case in ("form_unimported", "form_keep", "pipeline_scene"):
        project = work / case
        write_probe_project(project, case, feature, filters, repo)
        for preset in ("Web", "Android"):
            summary["cases"].append(export_case(args.godot, project, out / "packs", case, preset))
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    web_ok = any(case["preset"] == "Web" and case["pck_exists"] and case["runtime"] for case in summary["cases"])
    return 0 if web_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
