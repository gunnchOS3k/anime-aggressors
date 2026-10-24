#!/usr/bin/env python3
"""Execute unchanged watch/dialogue source with synthetic actors in a tiny project.

No shipping BattleScene, model import, recording, voice asset or owner profile.
The fixture exercises real pause/navigation/cancel code; it is not visual proof.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import textwrap
import wave

ROOT=Path(__file__).resolve().parents[2]
WATCH='game-godot/scripts/story/ova_watch_scene.gd'
DIALOGUE='game-godot/scripts/story/story_dialogue_director.gd'

ACTOR='''
extends Node2D
var fighter_id := ""
var controls_enabled := true
var model_3d: Node
func _init() -> void:
    model_3d = load("res://model.gd").new()
    add_child(model_3d)
'''
MODEL='''
extends Node
var _viewport := Node.new()
func _init() -> void: add_child(_viewport)
func set_cinematic_expression(_expression: String) -> void: pass
func play_clip(_clip: String) -> void: pass
'''
BATTLE='''
extends Node2D
var fighters_root := Node2D.new()
var fighter1: Node2D
var fighter2: Node2D
var hud := Control.new()
func _ready() -> void:
    add_child(fighters_root)
    add_child(hud)
    fighter1 = load("res://actor.gd").new()
    fighter2 = load("res://actor.gd").new()
    fighter1.fighter_id = "SYNTHETIC_A"
    fighter2.fighter_id = "SYNTHETIC_B"
    fighters_root.add_child(fighter1)
    fighters_root.add_child(fighter2)
'''
CHECK='''
extends Node
var failures: Array = []
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failures.append(label)
func _ready() -> void:
    var saved := CampaignRuntime.progress.duplicate(true)
    var watch = load("res://scripts/story/ova_watch_scene.gd").new()
    add_child(watch)
    for i in range(4): await get_tree().process_frame
    check(not watch._swap_busy and StoryDialogue.node_id == "SYNTHETIC_0", "initial chapter begins")
    watch._toggle_pause()
    var line := StoryDialogue.current.duplicate(true)
    var before := StoryDialogue.remaining
    var clock: float = watch.elapsed
    await get_tree().create_timer(0.04).timeout
    check(StoryDialogue.remaining == before and watch.elapsed == clock, "manual pause freezes dialogue and watch clocks")
    StoryDialogue.advance()
    check(StoryDialogue.current == line, "advance cannot bypass pause")
    await watch.seek(1)
    check(StoryDialogue.node_id == "SYNTHETIC_1", "chapter navigation selects new narrative owner")
    check(not watch.playing and watch._pause.text == "Resume", "paused chapter navigation stays paused")
    check(StoryDialogue._manual_pause, "new chapter dialogue remains paused")
    check(StoryDialogue._voice.stream_paused, "new cue audio player is paused before the next process tick")
    check(watch._battle.process_mode == Node.PROCESS_MODE_DISABLED, "new synthetic battle remains paused")
    for actor in watch._battle.fighters_root.get_children():
        check(actor.model_3d._viewport.process_mode == Node.PROCESS_MODE_DISABLED, "new model viewport remains paused")
    before = StoryDialogue.remaining
    await get_tree().create_timer(0.04).timeout
    check(StoryDialogue.remaining == before, "new paused line does not elapse after navigation")
    if not watch.playing: watch._toggle_pause()
    before = StoryDialogue.remaining
    await get_tree().create_timer(0.04).timeout
    check(watch.playing and not StoryDialogue._manual_pause and StoryDialogue.remaining < before, "resume advances the new chapter")
    await watch.seek(0)
    check(watch.playing and StoryDialogue.node_id == "SYNTHETIC_0", "playing chapter navigation keeps playback enabled")
    watch.queue_free()
    await get_tree().process_frame
    check(not StoryDialogue.is_busy(), "exit cancels owned narrative queue")
    check(CampaignRuntime.progress == saved, "synthetic progress unchanged")
    var result := {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "scope":"Native headless watch/dialogue control flow with synthetic chapters/actors; no shipping BattleScene, body models, rendering, native audio, earned Story or device evidence", "human_approved":false}
    var file := FileAccess.open("res://RESULT.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(result,"\\t"))
    print(JSON.stringify(result))
    get_tree().quit(0 if failures.is_empty() else 1)
'''


def run(output, godot):
    output=output.resolve()
    if output.exists() or output.is_relative_to(ROOT):
        raise ValueError('Use a new isolated fixture output outside the public checkout')
    if shutil.disk_usage('/System/Volumes/Data').free < 18*1024**3+10*1024**2:
        raise ValueError('This fixture requires18GiB plus10MiB allowance; no cleanup or lower guard')
    output.mkdir(mode=0o700)
    def write(name,text):
        p=output/name;p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(textwrap.dedent(text).lstrip())
    for source,target in [(WATCH,'scripts/story/ova_watch_scene.gd'),(DIALOGUE,'dialogue.gd'),
                          ('game-godot/scripts/story/ova_private_camera_take.gd','scripts/story/ova_private_camera_take.gd')]:
        write(target,(ROOT/source).read_text())
    keys=json.loads(re.search(r'const SESSION_KEYS := (\[[^\n]+\])',(ROOT/WATCH).read_text()).group(1))
    write('state.gd','extends Node\n'+'\n'.join('var '+key+': Variant'for key in keys)+'\n')
    write('router.gd','extends Node\nfunc go(_where: String) -> void: pass\n')
    write('scripts/story/v1_story_encounter.gd','extends RefCounted\nvar battle: Node\nfunc set_form(_actor: Node, _form: String) -> void: pass\n')
    write('actor.gd',ACTOR);write('model.gd',MODEL);write('battle.gd',BATTLE);write('check.gd',CHECK)
    write('scenes/battle/BattleScene.tscn','[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://battle.gd" id="1"]\n[node name="SyntheticBattle" type="Node2D"]\nscript = ExtResource("1")\n')
    write('main.tscn','[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://check.gd" id="1"]\n[node name="WatchControlFixture" type="Node"]\nscript = ExtResource("1")\n')
    chapters=[{'id':'SYNTHETIC_'+str(i),'kind':'STORY_BATTLE','objective_contract':'STOCK_WIN','title':'Synthetic chapter','implemented':True,'opponent':'SYNTHETIC_B','watch_seconds':1000}for i in range(2)]
    route={'anchor':'SYNTHETIC_A','recruitment_pairs':[['SYNTHETIC_B']],'nodes':chapters}
    write('campaign.gd','extends Node\nvar watch_route_id := "SYNTHETIC"\nvar watch_presentation := "female"\nvar progress := {"SYNTHETIC_ONLY":true}\nfunc route_data(_id: String) -> Dictionary:\n    return JSON.parse_string('+json.dumps(json.dumps(route))+')\n')
    cues={};nodes={}
    for chapter in chapters:
        cue_id=chapter['id']+'_LINE'
        cues[cue_id]={'cue_id':cue_id,'node_id':chapter['id'],'event':'fixture_line','phase':'pre','performance':'calm','speaker':'Synthetic A','speaker_id':'SYNTHETIC_A','subtitle':'This is a synthetic pause and navigation fixture.','voice_asset':'res://synthetic_silence.wav'}
        nodes[chapter['id']]={'ordered_cues':[cue_id],'events':{'fixture_line':[cue_id]}}
    for name,data in [('cues',{'cues':cues}),('nodes',{'nodes':nodes}),('voice_assets',{'assets':{}})]:
        write('data/story/dialogue/v1/'+name+'.json',json.dumps(data))
    # Only digital silence for a real AudioStreamPlayer pause assertion.
    # No actor/TTS material, listening result or native game-audio claim.
    with wave.open(str(output/'synthetic_silence.wav'),'wb')as silent:
        silent.setnchannels(1);silent.setsampwidth(2);silent.setframerate(8000)
        silent.writeframes(bytes(16000))
    write('project.godot','''
        config_version=5
        [application]
        config/name="Private watch playback fixture"
        run/main_scene="res://main.tscn"
        config/use_custom_user_dir=true
        config/custom_user_dir_name="anime_watch_playback_fixture_20261023"
        [autoload]
        GameState="*res://state.gd"
        CampaignRuntime="*res://campaign.gd"
        StoryDialogue="*res://dialogue.gd"
        SceneRouter="*res://router.gd"
        [rendering]
        renderer/rendering_method="gl_compatibility"
    ''')
    write('SOURCE_BINDING.json',json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()for p in [WATCH,DIALOGUE]},indent=2))
    with (output/'godot.log').open('w')as log:
        result=subprocess.run([str(godot),'--headless','--path',str(output),'--audio-driver','Dummy','--quit-after','300'],stdout=log,stderr=subprocess.STDOUT,timeout=30)
    text=(output/'godot.log').read_text()
    if not (output/'RESULT.json').is_file() or 'SCRIPT ERROR:'in text or result.returncode:
        print(text);return 1
    report=json.loads((output/'RESULT.json').read_text());print(json.dumps(report))
    return 0 if report['PASS']else 1


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--godot',type=Path,default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    args=parser.parse_args()
    raise SystemExit(run(args.output,args.godot))
