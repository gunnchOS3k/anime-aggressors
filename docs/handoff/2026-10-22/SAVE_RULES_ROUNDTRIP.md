# Save rules round-trip

Base `7c25c2996f8adcee97ec2187a14bfc578d8681bf`. Official V1 and RC2 remain NOT READY.

`GameState._persist_save` writes `rules.stocks`, `rules.cpu_level`, and `rules.timer` (`match_timer_seconds`) to `user://aa_save.cfg`. Before this change, `ensure_save_loaded` restored career, progress, accessibility, volume, `rules.damage_ratio`, `rules.team_attack`, and `rules.preset`, and did not read the three rule fields. `load_ruleset_preset` still reads a named preset from `user://aa_rulesets.cfg` and was not changed.

Isolated probe, no asset import, user dir `aa-save-rules-probe` (not `Anime Aggressors`):

```sh
./tools/save_rules/run_isolated_probe.sh
```

Before, exit 1:

```
DISK load_err=0 rules.stocks=7 rules.cpu_level=4 rules.timer=60
FRESH_DEFAULTS stocks=3 cpu_level=2 match_timer_seconds=180
RELOADED stocks=3 cpu_level=2 match_timer_seconds=180
ROUNDTRIP false
FAIL reloaded stocks=3 cpu_level=2 match_timer_seconds=180 !== expected stocks=7 cpu_level=4 match_timer_seconds=60
FAIL false !== true
```

After, exit 0:

```
DISK load_err=0 rules.stocks=7 rules.cpu_level=4 rules.timer=60
RELOADED stocks=7 cpu_level=4 match_timer_seconds=60
ROUNDTRIP true
ABSENT_KEYS stocks=3 cpu_level=2 match_timer_seconds=180
PASS save rules roundtrip
```

Absent keys use the writer defaults 3, 2, and 180. Owner `aa_save.cfg` stayed mtime 1790883337 size 626. Owner `aa_rulesets.cfg` stayed mtime 1789773945 size 99. `df` stayed 15 GiB available. No `.godot` import cache. Full Godot project import was not run.
