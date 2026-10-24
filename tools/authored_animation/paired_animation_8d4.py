"""Inspect an actual binary skeletal export; never accepts static reference snapshots."""
import json
import math
from pathlib import Path
import struct

CLIP = 'ANI08D4_REFERENCE_HOLD_PAIR'
FRAME_COUNT = 25
FPS = 60


def read_glb(path):
    raw=Path(path).read_bytes()
    if len(raw)<20 or raw[:4]!=b'glTF' or struct.unpack_from('<II',raw,4)!=(2,len(raw)):
        raise ValueError('Invalid GLB2 header/length')
    chunks=[];offset=12
    while offset<len(raw):
        if offset+8>len(raw):raise ValueError('Truncated GLB chunk')
        length,kind=struct.unpack_from('<II',raw,offset);offset+=8
        if length%4 or offset+length>len(raw):raise ValueError('Invalid GLB chunk extent')
        chunks.append((kind,raw[offset:offset+length]));offset+=length
    if len(chunks)!=2 or chunks[0][0]!=0x4E4F534A or chunks[1][0]!=0x004E4942:
        raise ValueError('Expected self-contained JSON and BIN chunks')
    doc=json.loads(chunks[0][1]);binary=chunks[1][1]
    if doc.get('asset',{}).get('version')!='2.0':raise ValueError('Expected glTF2')
    if len(doc.get('buffers',[]))!=1 or doc['buffers'][0].get('uri'):
        raise ValueError('External buffers are not part of the private paired export')
    if any(image.get('uri')for image in doc.get('images',[])):
        raise ValueError('External texture dependencies must be embedded before review')
    if not 0<=len(binary)-doc['buffers'][0]['byteLength']<=3:
        raise ValueError('Incorrect embedded buffer length')
    return doc,binary


def float_accessor(doc,binary,index):
    accessor=doc['accessors'][index]
    if accessor.get('componentType')!=5126 or accessor.get('sparse') or accessor.get('normalized'):
        raise ValueError('Expected explicit FLOAT animation data')
    count=accessor['count'];dimensions={'SCALAR':1,'VEC3':3,'VEC4':4}.get(accessor['type'])
    if not isinstance(count,int)or count<1 or dimensions is None:raise ValueError('Invalid animation accessor')
    view=doc['bufferViews'][accessor['bufferView']]
    stride=view.get('byteStride',dimensions*4);start=view.get('byteOffset',0)+accessor.get('byteOffset',0)
    if view.get('buffer',0)!=0 or stride<dimensions*4 or stride%4 or start<view.get('byteOffset',0):
        raise ValueError('Invalid animation stride/offset')
    end=start+(count-1)*stride+dimensions*4
    if end>view.get('byteOffset',0)+view['byteLength']or end>len(binary):raise ValueError('Animation accessor escapes buffer')
    values=[struct.unpack_from('<'+'f'*dimensions,binary,start+i*stride)for i in range(count)]
    if not all(math.isfinite(x)for v in values for x in v):raise ValueError('Non-finite animation data')
    return values


def inspect_paired_export(path,actors,*,clip_name=CLIP,frame_count=FRAME_COUNT):
    doc,binary=read_glb(path);nodes=doc.get('nodes',[]);skins=doc.get('skins',[])
    animations=doc.get('animations',[])
    if len(actors)!=2 or len(skins)!=2:raise ValueError('Paired playback requires two real skeletal skins')
    if len(animations)!=1 or animations[0].get('name')!=clip_name:
        raise ValueError('One synchronized, explicitly named paired action required')
    animation=animations[0];parents={}
    for i,node in enumerate(nodes):
        for child in node.get('children',[]):
            if child in parents or not 0<=child<len(nodes):raise ValueError('Invalid node hierarchy')
            parents[child]=i
    def below(child,parent):
        seen=set()
        while child!=parent:
            if child in seen or child not in parents:return False
            seen.add(child);child=parents[child]
        return True
    # Facial curves are permitted only on explicitly declared original morph
    # meshes under the owning actor. They cannot authorize object/root motion.
    morph_nodes={}
    for actor in actors:
        for declaration in actor.get('morph_nodes',[]):
            targets=declaration.get('targets',[])
            matches=[i for i,n in enumerate(nodes)if n.get('name')==declaration.get('node')]
            anchors=[i for i,n in enumerate(nodes)if n.get('name')==actor['anchor']]
            if len(matches)!=1 or len(anchors)!=1 or not below(matches[0],anchors[0]):
                raise ValueError('Original facial morph mesh ownership mismatch')
            index=matches[0];node=nodes[index]
            if index in morph_nodes or 'skin'not in node or 'mesh'not in node or not targets or len(set(targets))!=len(targets):
                raise ValueError('Explicit original skinned facial targets required')
            mesh=doc['meshes'][node['mesh']]
            if mesh.get('extras',{}).get('targetNames')!=targets or any(len(p.get('targets',[]))!=len(targets)for p in mesh['primitives']):
                raise ValueError('Original facial target names/count changed')
            morph_nodes[index]={'role':actor['role'],'targets':targets,'skin':node['skin']}
    driven={};duration=0.;facial_channels=[]
    for channel in animation.get('channels',[]):
        target=channel['target'];node=target['node'];path=target['path']
        if not 0<=node<len(nodes)or path not in ['translation','rotation','scale','weights']:
            raise ValueError('Only skeletal and explicitly declared facial channels are allowed')
        sampler=animation['samplers'][channel['sampler']]
        if sampler.get('interpolation','LINEAR')not in ['LINEAR','STEP']:
            raise ValueError('Expected sampled linear/step animation')
        times=float_accessor(doc,binary,sampler['input']);values=float_accessor(doc,binary,sampler['output'])
        if len(times)<2 or len(times[0])!=1:
            raise ValueError('Animation times/values mismatch')
        flat=[v[0]for v in times]
        if flat[0]<0 or any(a>=b for a,b in zip(flat,flat[1:])):raise ValueError('Non-monotonic animation clock')
        duration=max(duration,flat[-1])
        if path=='weights':
            if node not in morph_nodes:raise ValueError('Undeclared facial morph animation')
            count=len(morph_nodes[node]['targets'])
            if len(values)!=len(times)*count or any(len(v)!=1 or not 0<=v[0]<=1 for v in values):
                raise ValueError('Facial weights must preserve target count and unit range')
            facial_channels.append({'node':nodes[node]['name'],'targets':morph_nodes[node]['targets'],'frames':len(times)})
            continue
        if len(times)!=len(values):raise ValueError('Animation times/values mismatch')
        if len(values[0])!=(4 if path=='rotation'else 3):raise ValueError('Transform dimension mismatch')
        # A moving transform is evidence of data, not good acting or contact.
        if any(abs(a-b)>1e-7 for v in values[1:]for a,b in zip(values[0],v)):
            driven.setdefault(node,set()).add(path)
    if abs(duration-(frame_count-1)/FPS)>1e-6:raise ValueError('Paired clip must preserve its explicit60Hz source clock')
    if set(driven)-{j for skin in skins for j in skin.get('joints',[])}:
        raise ValueError('Animated object/actor roots cannot acquire movement authority')
    reports=[];used=set()
    for actor in actors:
        anchors=[i for i,n in enumerate(nodes)if n.get('name')==actor['anchor']]
        if len(anchors)!=1:raise ValueError('Missing or ambiguous original actor placement anchor')
        anchor=anchors[0]
        matching=[i for i,s in enumerate(skins)if s.get('joints')and all(below(j,anchor)for j in s['joints'])]
        if len(matching)!=1 or matching[0]in used:raise ValueError('Actor skin ownership is not distinct')
        skin_id=matching[0];used.add(skin_id);joints=skins[skin_id]['joints']
        if any(m['skin']!=skin_id for m in morph_nodes.values()if m['role']==actor['role']):
            raise ValueError('Facial morph mesh uses another actor skin')
        names=[nodes[j].get('name')for j in joints]
        if len(names)!=len(set(names))or set(names)!=set(actor['bone_names']):
            raise ValueError('Export dropped/renamed source bones')
        meshes=[n for i,n in enumerate(nodes)if n.get('skin')==skin_id and below(i,anchor)]
        if not meshes:raise ValueError('Skeleton has no owned skinned mesh')
        for mesh_node in meshes:
            for primitive in doc['meshes'][mesh_node['mesh']]['primitives']:
                if not {'JOINTS_0','WEIGHTS_0'}<=set(primitive.get('attributes',{})):
                    raise ValueError('Missing actual joint weights')
        moving=[nodes[j]['name']for j in joints if j in driven]
        if len(moving)<2:raise ValueError('Paired actor lacks nonconstant skeletal performance')
        reports.append({'role':actor['role'],'anchor':actor['anchor'],'source_bones':len(names),
                        'owned_skinned_meshes':len(meshes),'moving_joint_names':moving})
    return {'PASS':True,'clip':clip_name,'duration_seconds':duration,'actors':reports,'facial_channels':facial_channels,
            'scope':'Binary skeletal/action structure only; not Blender equivalence, native playback or art quality',
            'native_playback_verified':False,'release_acting_verified':False,'human_approved':False}
