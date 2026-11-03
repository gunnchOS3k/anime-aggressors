# Anime Aggressors — Story Mode Campaign Bible

> **Superseded on conflict by Creative Authority Pack V1.** This file is the prior doctrine pass at `e15a343`. Where it disagrees with [authority_pack_v1/](authority_pack_v1/README.md), the pack wins. The disagreement is recorded in [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md). This file is not runtime evidence and it is not art approval.
>
> `HUMAN_ART_APPROVAL=false`. `MERGE_AUTHORIZED=false`.


Status: **DOCTRINE for a campaign that is not in the shipping game.**

What the build actually has:

- Godot Android (`d94bc095`): no Story route. Versus and Training only. This is not a campaign.
- Web `#/story`: a director with seven spectrum routes, essence counts 0 / 1 / 2 / 4 / 6, a puppet selector, and a note that copy is `DRAFT_NARRATIVE_COPY`. QA completion sits behind `?dev=1`. Gray progress is the gate the screen uses before Yin and Yang. That is a scaffold. It is not a written campaign, not cutscenes, and not the Android game.

Nothing below is implemented except where a line says **in the web scaffold**.

`HUMAN_ART_APPROVAL=false`

## 1. Premise

Seven elemental souls share one sky. Each soul can be worn as a male or female form. The form changes the face and the costume. It does not change the soul or the fight.

Two principles stand outside the seven:

- Yin subtracts. Peace, to Yin, is a world with nothing left to conflict.
- Yang defines. Peace, to Yang, is a world with one perfect pattern and no remainder.

Both can rewrite a soul into a puppet. A Black Puppet still has one color left, pulled inward. A White Puppet still has a body, forced into a perfect loop. Neither puppet is the person.

Kaia Windrow is the green root, the only soul whose wind can carry the others without eating them. If she gathers the seven essences and stays herself, the sky can hold every color at once. That form is Prismatic Gray. Gray is not emptiness and not a uniform. It is all seven, none in charge.

## 2. World

The fights happen on stages that are already in the game (Training Grid is the current default and is not a story place). Story stages, when built, should be readable platform maps with one elemental idea:

- Ember: a living kiln
- Rook: a walking wall
- Juno: a rail in a storm
- Kaia: open sky
- Nix: a lattice over water
- Orion: a ringed dark
- Vesper: a street that does not agree with itself
- Yin: a quiet that gets smaller
- Yang: a white work that gets larger

The world rule the player must feel: losing a story fight can puppet you for the rematch. Winning returns your face. The moveset never changes. The mask does.

## 3. Roster narrative roles

| Fighter | Role in the campaign |
|---|---|
| Kaia | Protagonist. Collects essences. Refuses both puppets. |
| Ember | First ally. Teaches that forward fire is not the same as Yang’s order. |
| Rook | The promise that weight can protect without becoming a wall that never moves. |
| Juno | The warning that speed without a destination becomes Yang’s perfect circuit. |
| Nix | The builder. Closest to agreeing with Yang, and the one who must refuse the monument. |
| Orion | The judge of orbits. Shows that consequence is not the same as erasure. |
| Vesper | The doubt. Shows that a trick is not a self. Highest risk of enjoying the mask. |
| Yin | Antagonist-principle. Speaks softly. Offers rest. |
| Yang | Antagonist-principle. Speaks clearly. Offers a finished world. |

Male and female are how a chapter presents the soul. A chapter may specify one. Gameplay does not care.

## 4. Campaign structure

Eight chapters plus prologue and epilogue. Each chapter is a short set of fights and conversations. This outline is the writing target. The web scaffold’s seven routes are the early map of Act I only.

### Prologue — Two offers

Kaia is asked, in the sky, to stop the noise. Yin offers stillness. Yang offers a finished pattern. She refuses both and the wind tears. No fight. Establishes the two masks she will see later.

**In the build:** not present.

### Act I — The seven routes

One route per spectrum soul. Kaia is the root (**in the web scaffold**: she is marked ROOT). Each route is: meet, argue, fight, aftermath.

1. Ember — Kaia tries to bank a fire that only knows “forward.”
2. Rook — she asks a wall to take one step back.
3. Juno — she grounds a current that wants to skip the person it is saving.
4. Nix — she cracks a perfect lattice before it closes.
5. Orion — she steps into an orbit and chooses where to land.
6. Vesper — she is shown a second Kaia and has to say which one is late.
7. Return — the collected essences start to argue inside her ribbons.

Essence count (**in the web scaffold**: 0, 1, 2, 4, 6):

- After Ember: Essence 1. Ribbons lengthen.
- After Rook and Juno: Essence 2. Two colors in the wind. She is unsteady.
- After Nix and Orion: Essence 4. Sky and earth in the same cloth.
- After Vesper and the return: the count can reach 6 only if she is still Kaia. That is the end of Act II, not a menu toggle.

**In the build:** the web screen can set these counts from a dev control. That is not the story.

### Act II — The first puppet

Yin puppets Ember into a Black Puppet between rounds. The player fights the mask, then the person. Yang does the same to Nix with a White Puppet. The rule is taught here: the mask is a loss state you can win back inside the chapter. It is not a skin shop.

**In the build:** a puppet dropdown exists on the web story screen for QA. It is not this chapter.

### Act III — Yin and Yang enter

**In the web scaffold:** finishing gray routes is what the UI uses before Yin and Yang are relevant. Doctrine uses that gate, then adds the fights the screen does not have.

- Yin’s fight is quiet. The stage shrinks. Kaia’s win condition is to keep moving her own way, not to erase Yin.
- Yang’s fight is bright. The stage gains lines. Kaia’s win condition is to leave a remainder, not to match the pattern.

Neither fight unlocks a balance change.

### Act IV — Gray

Essence 6. Kaia’s Prismatic form. All seven colors in one wind. She fights a Black Puppet Kaia and a White Puppet Kaia. Winning is refusing to become either. The form returns to her own face with every color still in the ribbons.

**In the build:** a “GRAY COMPLETE” badge can be set from QA. There is no prismatic mesh and no puppet Kaia.

### Epilogue — The sky that stays mixed

The seven are themselves. Yin and Yang remain in the world as principles, not as deleted bosses. Versus play is the epilogue’s joke and its truth: the souls keep disagreeing, on purpose. No secret fighter. No stat reward.

**In the build:** not present.

## 5. Gameplay loop

When this is implemented, a chapter step is one of:

- Conversation (portraits, the modeled face, short lines)
- Fight (existing versus rules, story form applied to the meshes)
- Aftermath (essence step or mask removed)

Loss on a story fight offers retry without deleting earlier essences (**the web scaffold already preserves progress on a recorded loss**). Retry may start you in the puppet form for that bout. Win clears the mask.

No chapter may change weight, damage, or frame data. `gameplay_delta` stays false for every form.

## 6. Kaia’s arc

She begins as the person who makes room. Each essence tempts her to solve the others by becoming them. Gray is the refusal. The ribbon progression on the boards is the visual arc:

1. Base — one green.
2. Essence 1 — longer ribbons, still green.
3. Essence 2 — a second color she cannot quite steer.
4. Essence 4 — sky and earth, almost a costume.
5. Essence 6 — prismatic, face still Kaia’s.

If a build shows Gray as a gray mannequin, the arc has failed.

## 7. Yin and Yang

They are not secret palette swaps of the roster. They are the two endings Kaia will not pick.

Yin believes difference is the wound. Yang believes difference is unfinished work. Both love the world. That is why they are dangerous. They do not monologue as conquerors. They offer rest and completion.

Their fights are late. They are not unlocked by a debug checkbox in the player build.

## 8. Puppet logic

| | Black Puppet | White Puppet |
|---|---|---|
| Author | Yin | Yang |
| Who | Any of the seven, including Kaia in Act IV | Same |
| Look | Mask, inward motion, one color left | Mask, perfect loops, white and gold |
| Fight | Same moves, different performance | Same |
| Clear | Win the bout as yourself | Same |
| Versus mode | Absent | Absent |

A puppet never speaks in the soul’s normal voice. See the voice guide.

## 9. Dialogue bible

Full lines are in [dialogue_voice_guide.md](dialogue_voice_guide.md). Law:

- Short. A fight line fits in one breath.
- No one explains the element like a wiki.
- Male and female use the same diction. The actor may change. The soul does not.
- Puppet lines are the principle speaking through a mask, with one word of the soul left in.

## 10. Character story packets

Each packet is a page a writer can draft from. None of these scenes are in the game.

- Ember: admits she starts fires to see who runs toward them.
- Rook: admits the wall is fear of being moved.
- Juno: admits she arrives before she has decided to help.
- Kaia: admits she would rather carry everyone than choose.
- Nix: admits a perfect plan felt kinder than a person.
- Orion: admits he trusted the orbit more than the landing.
- Vesper: admits the late copy is sometimes the honest one.
- Yin: offers to end the argument by ending the noise.
- Yang: offers to end the argument by ending the exception.

## 11. Cutscenes and later adaptation

Not in the build. When they are made, each is four beats, reusable for an animatic:

1. The offer (Yin or Yang, or the soul’s habit)
2. The refusal or the slip
3. The fight’s first contact, using a move-sheet pose
4. The face, unmasked or still masked

No finished cinematic exists. Do not ship a title card in place of one and call it a cutscene.

## 12. Ending and later seasons

The campaign ends on mixed sky, not on a killed god. A later season may follow one soul who liked the mask. That is not this bible and not this build.

## 13. Doctrine versus build

| Item | Label |
|---|---|
| Premise, chapters, voices, packets | DOCUMENTED_ONLY (this file) |
| Web seven-route screen, essence numbers, QA complete | PARTIAL_RUNTIME, web only, draft copy |
| Godot Android story route | Absent |
| Prismatic mesh, puppet meshes, cutscenes | Absent |
| Dialogue audio | Absent |

`HUMAN_ART_APPROVAL=false`


## October 9, 2026 — ANI-02 owner canon amendment

The historical OPEN First Loss statements above are superseded only for the seven identities by `first_loss_owner_decision_2026-10-09.json`. Working V1 selection: Kaia → Rook; Ember → Nix; Rook → Juno; Juno → Orion; Nix → Vesper; Orion → Kaia; Vesper → Ember. There are seven unique lost identities. Juno → Rook is superseded. The Last Vector follows the owner scene contract in `CODEX_ANIME_CANON_CAMPAIGN_2026-10-09.md`; Orion’s ultimate fate remains unresolved. All losses are route-specific. New dialogue is DRAFT_OWNER_REVIEW; final Story/presentation gates remain false.
