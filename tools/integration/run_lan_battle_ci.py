"""Actual two-process localhost ENet/host BattleScene check, public CI only.

No private assets, exports or uploads. Reuses the existing hosted runner's
guards; never permits heavy local execution through this command.
"""
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import time

from run_training_story_ci import ROOT, execute, guard, sha


def pair(base, output, script):
    output.mkdir(exist_ok=False)
    record = {"suites": {}}
    processes = []
    streams = []
    try:
        # Reserve an unused loopback UDP port. No listening interface exposed
        # outside this runner; ENet host binds explicitly to127.0.0.1.
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as candidate:
            candidate.bind(("127.0.0.1", 0))
            port = candidate.getsockname()[1]
        record["port"] = port
        started = time.monotonic()
        peak = 0
        for role in ["host", "guest"]:
            guard()
            if role == "guest":
                deadline = time.monotonic() + 12
                while not (output / "HOST_READY").exists():
                    if processes[0].poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError("Host did not reach real ENet listen")
                    time.sleep(.05)
            stream = (output / (role + ".log")).open("x")
            streams.append(stream)
            environment = {**os.environ, "XDG_DATA_HOME": str(output / (role + "-profile"))}
            command = base + ["--max-fps", "60", "--script", "res://" + script, "--",
                              "--ordinary-output=" + str(output), "--lan-role=" + role, "--lan-port=" + str(port)]
            processes.append(subprocess.Popen(command, cwd=ROOT, env=environment, stdout=stream, stderr=subprocess.STDOUT))
        while any(child.poll() is None for child in processes):
            guard()
            rss = 0
            for child in processes:
                path = Path(f"/proc/{child.pid}/status")
                if path.exists():
                    match = re.search(r"^VmRSS:\s+(\d+)", path.read_text(), re.M)
                    if match: rss += int(match[1]) * 1024
            peak = max(peak, rss)
            if peak > 4 * 2**30: raise RuntimeError("Combined process memory guard")
            if time.monotonic() - started > 60: raise RuntimeError("Bounded two-process timeout")
            for role in ["host", "guest"]:
                path = output / (role + ".log")
                if path.stat().st_size > 8 * 2**20: raise RuntimeError("Log size guard")
                if "SCRIPT ERROR:" in path.read_text(errors="replace"): raise RuntimeError("Actual engine script error")
            time.sleep(.1)
        record["seconds"] = time.monotonic() - started
        record["combined_sampled_peak_rss_bytes"] = peak
        for role, child in zip(["host", "guest"], processes):
            path = output / ("LAN_" + role.upper() + ".json")
            data = json.loads(path.read_text()) if path.exists() else {}
            runtime_errors = [line for line in (output / (role + ".log")).read_text().splitlines() if "ERROR:" in line]
            record["suites"][role] = {"PASS": child.returncode == 0 and data.get("PASS", False) and not runtime_errors, "exit_code": child.returncode,
                "runtime_errors": runtime_errors, "checks": len(data.get("checks", [])), "failures": data.get("failures", ["Missing result"]), "result": data,
                "result_sha256": sha(path) if path.exists() else None, "log_sha256": sha(output / (role + ".log"))}
        return record
    finally:
        for child in processes:
            if child.poll() is None:
                child.terminate()
                try: child.wait(5)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
        for stream in streams: stream.close()



def run():
    guard()
    output = Path(os.environ["RUNNER_TEMP"]) / "lan-battle"
    output.mkdir(exist_ok=False)
    record = {"PASS": False, "scope": "Actual two-process localhost ENet guest input into host BattleScene; host-state guest BattleScene presentation; not physical LAN, native visual, rollback, art or human approval", "suites": {}}
    processes = []
    streams = []
    try:
        record["available_start_bytes"] = guard()
        head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        if head != os.environ["GITHUB_SHA"]: raise RuntimeError("Exact source SHA mismatch")
        record["source_head"] = head
        record["source_sha256"] = {str(p.relative_to(ROOT)): sha(p) for p in (ROOT / "game-godot/scripts").rglob("*.gd")}
        godot = os.environ["GODOT_BIN"]
        record["godot_version"] = subprocess.check_output([godot, "--version"], text=True).strip()
        if not record["godot_version"].startswith("4.7.1.stable"): raise RuntimeError("Unexpected engine")
        project = ROOT / "game-godot/project.godot"
        config = re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n', '', project.read_text(), flags=re.M)
        project.write_text(config.replace('[application]', '[application]\nconfig/name="aa-native-ci-lan"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="aa-native-ci-lan"', 1))
        base = [godot, "--headless", "--path", str(ROOT / "game-godot"), "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility"]
        record["import"] = execute(base + ["--editor", "--import", "--quit"], output / "import.log", 180)
        if not record["import"]["PASS"]: return record
        first = pair(base, output / "input", "tests/integration/LanActualBattle.gd")
        record.update({k:first[k] for k in ["seconds", "combined_sampled_peak_rss_bytes"]})
        record["suites"].update(first["suites"])
        if not all(s["PASS"] for s in first["suites"].values()): return record
        # Preserve actionable retained-resource identity, rather than filtering
        # shutdown errors when the Results/rematch/menu sequence frees actors.
        terminal = pair(base + ["--verbose"], output / "terminal", "tests/integration/LanTerminalMatch.gd")
        record["terminal_seconds"] = terminal["seconds"]
        record["terminal_combined_sampled_peak_rss_bytes"] = terminal["combined_sampled_peak_rss_bytes"]
        record["suites"].update({"terminal-"+k:v for k,v in terminal["suites"].items()})
        if not all(s["PASS"] for s in terminal["suites"].values()): return record
        lobby = pair(base, output / "lobby-reconnect", "tests/integration/LanLobbyReconnect.gd")
        record["lobby_seconds"] = lobby["seconds"]
        record["suites"].update({"lobby-"+k:v for k,v in lobby["suites"].items()})
        if not all(s["PASS"] for s in lobby["suites"].values()): return record
        respawn = pair(base, output / "respawn-clock", "tests/integration/LanRespawnClock.gd")
        record["respawn_seconds"] = respawn["seconds"]
        record["suites"].update({"respawn-"+k:v for k,v in respawn["suites"].items()})
        if not all(s["PASS"] for s in respawn["suites"].values()): return record
        # Changed shared input readers and scene lifecycle warrant these two
        # existing affected regressions, not another full Story playthrough.
        for name, script, filename in [
            ("combat-components", "tests/integration/NativeCombatComponents.gd", "NATIVE_COMBAT_COMPONENTS.json"),
            ("party-components", "tests/integration/PartyCombatComponents.gd", "PARTY_COMBAT_COMPONENTS.json"),
            ("stage-audio", "tests/integration/StageAudioOwnership.gd", "STAGE_AUDIO_OWNERSHIP.json"),
            ("authored-special-links", "tests/integration/AuthoredSpecialLinks.gd", "AUTHORED_SPECIAL_LINKS.json"),
            ("throw-ownership", "tests/v1_closure/ThrowOwnership.gd", "throw_ownership.json"),
            ("training-lifecycle", "tests/integration/TrainingLifecycle.gd", "TRAINING_LIFECYCLE.json"),
        ]:
            outcome = execute(base + ["--fixed-fps", "60", "--script", "res://" + script, "--", "--ordinary-output=" + str(output)], output / (name + ".log"))
            path = output / filename
            data = json.loads(path.read_text()) if path.exists() else {}
            outcome.update({"PASS": outcome["PASS"] and bool(data.get("PASS", False)), "failures": data.get("failures", []),
                            "checks": len(data.get("checks", [])), "rows": len(data.get("rows", [])), "result": data})
            record["suites"][name] = outcome
        record["PASS"] = all(s["PASS"] for s in record["suites"].values())
        record["remaining_diagnostics"] = {str(p.relative_to(output)):[line for line in p.read_text(errors="replace").splitlines() if "ERROR:" in line or "WARNING:" in line] for p in output.rglob("*.log")}
    except Exception as error:
        record["error"] = str(error)
    finally:
        for child in processes:
            if child.poll() is None:
                child.terminate()
                try: child.wait(5)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
        for stream in streams: stream.close()
        for path in output.rglob("*.log"):
            print("DIAGNOSTIC", str(path.relative_to(output)), path.read_text(errors="replace")[-14000:])
        (output / "LAN_ENGINE_RESULT.json").write_text(json.dumps(record, indent=2) + "\n")
        print(json.dumps(record, indent=2))
    return record


if __name__ == "__main__":
    raise SystemExit(0 if run()["PASS"] else 1)
