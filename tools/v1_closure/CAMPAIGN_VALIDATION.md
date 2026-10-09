# ANI-01 / ANI-02 validation

`python3 tools/v1_closure/validate_canon.py` checks the explicit October 9 approval,
seven unique loss identities, history/provenance and reproducible compilation.
`python3 tools/v1_closure/validate_campaign.py` checks all 145 node contracts,
handler bindings, route membership, Puppet sides and Essence tiers. CI runs these
scoped source checks; a green authority job grants no runtime/human/release gate.

From the repository root, import with Godot 4.7.1, then run serially:

```sh
godot --headless --path game-godot --log-file /tmp/ani-import.log --editor --import
godot --headless --path game-godot --log-file /tmp/ani-full.log --fixed-fps 60 --script res://tests/v1_closure/FullCampaign.gd
godot --headless --path game-godot --log-file /tmp/ani-restart.log --fixed-fps 60 --script res://tests/v1_closure/CampaignRestart.gd
AA_V1_ROUTE_REVIEW=1 godot --headless --path game-godot --log-file /tmp/ani-opening.log --fixed-fps 60 --script res://tests/v1_closure/CampaignCheckpoint.gd
AA_V1_ROUTE_REVIEW=1 godot --headless --path game-godot --log-file /tmp/ani-override.log --fixed-fps 60 --script res://tests/v1_closure/OwnerOverrideRuntime.gd
godot --headless --path game-godot --log-file /tmp/ani-combat.log --fixed-fps 60 --script res://tests/v1_closure/CombatActivation.gd
AA_V1_ROUTE_REVIEW=1 godot --headless --path game-godot --log-file /tmp/ani-roster.log --fixed-fps 60 --script res://tests/v1_closure/ShippingRosterPath.gd
```

The staged Mac tests use isolated `/private/tmp` save/key files. FullCampaign must
run before Restart/OwnerOverrideRuntime, which reuse its signed, actually exercised
fixture. An unsigned older checkpoint is retained as `.legacy`; replay authenticates
progress instead of trusting old completion arrays. Local signing prevents edited
save data from granting unlocks, not an attacker replacing code or obtaining its key.

FullCampaign uses ordinary Story mode, explicit invulnerable automated players,
positioned collision contacts and staged blast-zone KOs. Receipts come through the
bound BattleScene. Each trial identity exercises controls. Debug/eval/review runs
are nonqualifying; watch actors cannot issue receipts. These source-scene proofs
are distinct from packed builds, Web/Android runs and human playthroughs.

Final character art, authored movement/acting, VFX/SFX/mix, OVA screenplay/voice/music,
difficulty and human game feel remain under ANI-03/04. All owner/release gates stay
false. New exports require the existing disk guard and separate artifact hashes.
