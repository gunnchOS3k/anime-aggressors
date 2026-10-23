"""Tiny explicitly synthetic skeletal fixtures. No character art or producer execution."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest
from paired_animation_8d4 import CLIP, inspect_paired_export

ROOT=Path(__file__).resolve().parents[2]


def fixture():
    binary=bytearray();doc={'asset':{'version':'2.0','generator':'SYNTHETIC_8D4_TEST_ONLY'},
                           'bufferViews':[],'accessors':[],'buffers':[]}
    def accessor(values,kind,component=5126,bounds=False):
        binary.extend(bytes((-len(binary))%4));start=len(binary)
        fmt='f'if component==5126 else 'H'
        for row in values:binary.extend(struct.pack('<'+fmt*len(row),*row))
        view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':len(binary)-start})
        result={'bufferView':view,'componentType':component,'count':len(values),'type':kind}
        if bounds:result.update(min=[min(row[i]for row in values)for i in range(len(values[0]))],max=[max(row[i]for row in values)for i in range(len(values[0]))])
        doc['accessors'].append(result);return len(doc['accessors'])-1
    pos=accessor([[0,0,0],[.1,0,0],[0,.1,0]],'VEC3',bounds=True)
    joints=accessor([[0,1,0,0]]*3,'VEC4',5123)
    weights=accessor([[.5,.5,0,0]]*3,'VEC4')
    ibm=accessor([[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],
                  [1,0,0,0,0,1,0,0,0,0,1,0,0,-1,0,1]],'MAT4')
    times=accessor([[f/60]for f in range(25)],'SCALAR',bounds=True)
    doc.update(meshes=[{'primitives':[{'attributes':{'POSITION':pos,'JOINTS_0':joints,'WEIGHTS_0':weights}}]}],
               nodes=[{'name':'A_STAGE','children':[1,3]}, {'name':'Root','children':[2]},
                      {'name':'Tip','translation':[0,1,0]}, {'name':'A_Mesh','mesh':0,'skin':0},
                      {'name':'B_STAGE','translation':[1,0,0],'children':[5,7]}, {'name':'Root','children':[6]},
                      {'name':'Tip','translation':[0,1,0]}, {'name':'B_Mesh','mesh':0,'skin':1}],
               skins=[{'joints':[1,2],'skeleton':1,'inverseBindMatrices':ibm},
                      {'joints':[5,6],'skeleton':5,'inverseBindMatrices':ibm}],
               scenes=[{'nodes':[0,4]}],scene=0)
    animation={'name':CLIP,'samplers':[],'channels':[]}
    values={1:[[.02*f/24,0,0]for f in range(25)],2:[[0,1+.03*f/24,0]for f in range(25)],
            5:[[0,0,.03*f/24]for f in range(25)],6:[[.01*f/24,1,0]for f in range(25)]}
    for node,rows in values.items():
        output=accessor(rows,'VEC3');index=len(animation['samplers'])
        animation['samplers'].append({'input':times,'output':output,'interpolation':'LINEAR'})
        animation['channels'].append({'sampler':index,'target':{'node':node,'path':'translation'}})
    doc['animations']=[animation];doc['buffers']=[{'byteLength':len(binary)}]
    definitions=[{'role':r,'anchor':r+'_STAGE','bone_names':['Root','Tip']}for r in ['A','B']]
    frames=[]
    for f in range(25):
        t=f/24;identity=[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
        other=copy.deepcopy(identity);other[0][3]=1
        frames.append({'frame':f,'actors':[
            {'role':'A','anchor_transform_stage_m':identity,'bones_stage_m':{'Root':[.02*t,0,0],'Tip':[.02*t,1+.03*t,0]}},
            {'role':'B','anchor_transform_stage_m':other,'bones_stage_m':{'Root':[1,0,.03*t],'Tip':[1+.01*t,1,.03*t]}}]})
    entry={'resource':'fixture.glb','clip':CLIP,'FPS':60,'source_frame_count':25,
           'actors':definitions,'pose_frames':frames,'scope':'SYNTHETIC_ONLY_NOT_CHARACTER_ART'}
    return doc,binary,entry


def write_glb(path,doc,binary):
    text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4)
    binary=bytes(binary)+bytes((-len(binary))%4)
    raw=struct.pack('<4sII',b'glTF',2,12+8+len(text)+8+len(binary))
    raw+=struct.pack('<I4s',len(text),b'JSON')+text+struct.pack('<I4s',len(binary),b'BIN\0')+binary
    path.write_bytes(raw);return hashlib.sha256(raw).hexdigest()


class BinaryPairedAnimation(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Retain diagnostics. Never clean owner/art/evidence directories.
        cls.folder=Path(tempfile.mkdtemp(prefix='anime_synthetic_pair_8d4_'))

    def probe(self,change=None):
        doc,binary,entry=fixture()
        if change:change(doc,binary,entry)
        path=self.folder/(self.id().split('.')[-1]+'_'+str(len(list(self.folder.glob('*.glb'))))+'.glb')
        write_glb(path,doc,binary)
        return inspect_paired_export(path,entry['actors'])

    def test_real_binary_has_two_weighted_skeletons_and_one_moving_clip(self):
        report=self.probe();self.assertTrue(report['PASS']);self.assertEqual(len(report['actors']),2)
        self.assertFalse(report['native_playback_verified']);self.assertFalse(report['human_approved'])

    def test_static_snapshot_is_not_animated_acceptance(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d.update(animations=[]))

    def test_one_rig_is_not_a_paired_export(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d.update(skins=d['skins'][:1]))

    def test_missing_original_joint_is_not_retargeting_success(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:e['actors'][0].update(bone_names=['INVENTED']))

    def test_unweighted_mesh_is_rejected(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d['meshes'][0]['primitives'][0]['attributes'].pop('WEIGHTS_0'))

    def test_one_actors_animation_cannot_stand_in_for_two(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d['animations'][0].update(channels=d['animations'][0]['channels'][:2]))

    def test_actor_root_motion_cannot_gain_gameplay_authority(self):
        with self.assertRaisesRegex(ValueError,'movement authority'):
            self.probe(lambda d,b,e:d['animations'][0]['channels'][0]['target'].update(node=0))

    def test_external_buffers_are_rejected(self):
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d['buffers'][0].update(uri='unbound.bin'))

    def test_nonmonotonic_clock_and_buffer_overrun_fail_closed(self):
        def backwards(d,b,e):
            a=d['accessors'][d['animations'][0]['samplers'][0]['input']];v=d['bufferViews'][a['bufferView']]
            struct.pack_into('<f',b,v['byteOffset']+4,-1.)
        with self.assertRaises(ValueError):self.probe(backwards)
        with self.assertRaises(ValueError):self.probe(lambda d,b,e:d['accessors'][d['animations'][0]['samplers'][0]['output']].update(byteOffset=1000000))


def native_check(output,godot):
    if output.exists()or output.resolve().is_relative_to(ROOT):raise ValueError('New private fixture folder required')
    if shutil.disk_usage('/System/Volumes/Data').free<18*1024**3+10*1024**2:
        raise ValueError('Native fixture needs18GiB plus10MiB; no guard lowering')
    output.mkdir(mode=0o700);project=output/'project';project.mkdir()
    (project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Synthetic paired animation API checks"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="anime_paired_8d4_native_fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    source=ROOT/'game-godot/tests/v1_closure/PairedAnimationPlayback8D4.gd'
    shutil.copyfile(source,project/'review.gd')
    reports=[]
    for label,corrupt in [('valid',False),('source_pose_drift',True)]:
        case=output/label;case.mkdir();doc,binary,entry=fixture()
        entry['sha256']=write_glb(case/'fixture.glb',doc,binary)
        inspect_paired_export(case/'fixture.glb',entry['actors'])
        if corrupt:entry['pose_frames'][12]['actors'][0]['bones_stage_m']['Tip'][0]+=.01
        (case/'manifest.json').write_text(json.dumps({'rows':[{'animated_reference':entry}]}))
        with (case/'godot.log').open('w')as log:
            result=subprocess.run([str(godot),'--headless','--path',str(project),'--audio-driver','Dummy',
                                   '--script','res://review.gd','--','--animation-manifest='+str(case/'manifest.json'),
                                   '--test-output='+str(case),'--synthetic-fixture'],stdout=log,stderr=subprocess.STDOUT,timeout=30)
        if not (case/'paired_animation_playback.json').is_file()or 'SCRIPT ERROR:'in(case/'godot.log').read_text():
            print((case/'godot.log').read_text());return 1
        report=json.loads((case/'paired_animation_playback.json').read_text())
        expected=(report['PASS']is not corrupt)and result.returncode==int(corrupt)
        reports.append({'case':label,'observed_PASS':report['PASS'],'expected_result':expected,'joint_samples':report['joint_samples']})
    summary={'PASS':all(r['expected_result']for r in reports),'cases':reports,
             'observer_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
             'scope':'SYNTHETIC fixture only. Zero original source rigs or8D4art outputs verified.'}
    (output/'NATIVE_FIXTURE_RESULTS.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary))
    return 0 if summary['PASS']else 1


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-output',type=Path)
    parser.add_argument('--godot',type=Path,default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    args,remaining=parser.parse_known_args()
    if args.native_output:raise SystemExit(native_check(args.native_output.resolve(),args.godot))
    unittest.main(argv=[__file__,*remaining])
