"""Bounded public software verification in the existing hosted Ubuntu job.

Reuses its environment/storage/memory/time guards. No local production path,
art access, caches, uploads, game exports, sockets or device acceptance.
"""
import json
import os
from pathlib import Path
import subprocess

from run_training_story_ci import ROOT, execute, guard, sha


def run():
    guard()
    output = Path(os.environ["RUNNER_TEMP"]) / "netplay-session"
    output.mkdir(exist_ok=False)
    result = {"PASS": False, "scope": "Compiled public TypeScript combat/rollback sessions; not Godot LAN, native/device, human or online acceptance", "steps": {}}
    sources = [p for name in ["game-core", "rollback", "netplay"]
               for p in (ROOT / "packages" / name).rglob("*.ts") if "dist" not in p.parts]
    before = {str(p.relative_to(ROOT)): sha(p) for p in sources}
    try:
        result["source_head"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        if result["source_head"] != os.environ["GITHUB_SHA"]:
            raise RuntimeError("Source SHA mismatch")
        result["node_version"] = subprocess.check_output(["node", "--version"], text=True).strip()
        # Install only the existing lockfile's compiler/types and their one
        # dependency, retaining its registry URLs and integrity values. No full
        # app install, npm scripts, optional binaries or dependency upgrades.
        lock = json.loads((ROOT / "package-lock.json").read_text())
        names = ["typescript", "@types/node", "undici-types"]
        entries = {"node_modules/" + n: lock["packages"]["node_modules/" + n] for n in names}
        versions = {n: entries["node_modules/" + n]["version"] for n in names}
        tools = output / "compiler"
        tools.mkdir()
        package = {"name": "anime-existing-software-verifier", "version": "1.0.0", "private": True, "devDependencies": versions}
        (tools / "package.json").write_text(json.dumps(package))
        (tools / "package-lock.json").write_text(json.dumps({"name": package["name"], "version": "1.0.0", "lockfileVersion": 3,
            "requires": True, "packages": {"": package, **entries}}))
        result["locked_tools"] = {n: {"version": versions[n], "integrity": entries["node_modules/" + n]["integrity"]} for n in names}
        outcome = execute(["npm", "ci", "--prefix", str(tools), "--ignore-scripts", "--no-audit", "--no-fund"], output / "tools.log")
        result["steps"]["locked_compiler"] = outcome
        if not outcome["PASS"]: return result
        aliases = ROOT / "node_modules" / "@anime-aggressors"
        aliases.mkdir(parents=True, exist_ok=True)
        for name in ["game-core", "rollback", "netplay"]:
            (aliases / name).symlink_to(ROOT / "packages" / name, target_is_directory=True)
        compiler = tools / "node_modules" / "typescript" / "bin" / "tsc"
        for name in ["game-core", "rollback", "netplay"]:
            outcome = execute(["node", "--max-old-space-size=256", str(compiler), "--project", str(ROOT / "packages" / name),
                "--typeRoots", str(tools / "node_modules" / "@types")], output / (name + "-compile.log"))
            result["steps"][name + "_compile"] = outcome
            if not outcome["PASS"]: return result
        tests = [ROOT / "packages/game-core/dist/test/auraCharge.test.js",
                 ROOT / "packages/game-core/dist/test/determinism.test.js"]
        for name in ["rollback", "netplay"]:
            tests.extend(sorted((ROOT / "packages" / name / "dist/test").glob("*.test.js")))
        outcome = execute(["node", "--max-old-space-size=128", "--test", "--test-concurrency=1", *map(str, tests)], output / "tests.log")
        result["steps"]["compiled_tests"] = outcome
        print((output / "tests.log").read_text())
        after = {str(p.relative_to(ROOT)): sha(p) for p in sources}
        result["sources_unchanged"] = before == after
        result["source_sha256"] = before
        result["PASS"] = outcome["PASS"] and result["sources_unchanged"]
    except Exception as error:
        result["error"] = str(error)
    finally:
        for name, outcome in result["steps"].items():
            if not outcome["PASS"]:
                path = output / ("tools.log" if name == "locked_compiler" else name.replace("_compile", "-compile") + ".log")
                if path.exists(): print(path.read_text()[-12000:])
        (output / "RESULT.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    raise SystemExit(0 if run()["PASS"] else 1)
