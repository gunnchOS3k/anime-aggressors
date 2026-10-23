"""Reproduce the first8D2 source-cage fold from exact archived export dimensions.

Pinned to195194c7; do not apply the old cage reconstruction to corrected source.
Reads GLBs only, no Blender/import/render/install or binary mutation.
"""
import json,struct,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def minus(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def plus(*vs):return tuple(sum(v[k]for v in vs)for k in range(3))
def scale(v,s):return tuple(x*s for x in v)

def main():
    evidence=ROOT/'artifacts/v1_closure/production_8d/hands_remote_39882654215'
    m=json.loads((evidence/'PRODUCTION_MANIFEST.json').read_text());assert m['source_sha']=='195194c70cdd70f3930eb5d5082e1cfc159730e5'
    receipt=json.loads((evidence/'RECOVERY_RECEIPT.json').read_text());snapshot=Path(receipt['archive_root']);rows=[]
    for row in m['rows']:
        raw=(snapshot/'runtime'/row['resource']).read_bytes();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);blob=raw[28+length:]
        def read(i):
            a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];n={'VEC3':3,'SCALAR':1}[a['type']];fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']];step=v.get('byteStride',struct.calcsize('<'+fmt*n));offset=v.get('byteOffset',0)+a.get('byteOffset',0)
            return [struct.unpack_from('<'+fmt*n,blob,offset+j*step)for j in range(a['count'])]
        volumes={}
        for node in g['nodes']:
            if node.get('name')not in ['Palm L','Palm R']:continue
            volume=0.
            for prim in g['meshes'][node['mesh']]['primitives']:
                verts=read(prim['attributes']['POSITION']);idx=[x[0]for x in read(prim['indices'])]
                for i in range(0,len(idx),3):
                    a,b,c=[verts[n]for n in idx[i:i+3]];volume+=dot(a,cross(b,c))/6
            volumes[node['name']]=volume
        witnesses=[]
        for h in row['hands']:
            c=h['chains'][0];side=h['side'];w=h['width_m'];palm_end=h['distal_envelope_m']*.52;thick=h['depth_m'];forward=c['axis'];normal=c['normal'];across=(-1 if side=='R'else 1,0,0);wrist=h['wrist'];cell=3
            def grid(s,i):return plus(wrist,scale(across,(-.5+i*.25)*w*.96),scale(forward,palm_end),scale(normal,s*thick*.5*(.8+.2*(1-abs((-.5+i*.25)*w)/(w*.5)))))
            root=[grid(-1,cell),grid(-1,cell+1),grid(1,cell+1),grid(1,cell)];t=.025;taper=1-.2*t;ringcross=cross(normal,forward);width=w*.215;depth=thick*.76;origin=plus(c['start'],scale(forward,c['length']*t));ring=[plus(origin,scale(ringcross,a*width*.5*taper),scale(normal,b*depth*.5*taper))for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]]
            q=[root[0],root[1],ring[1],ring[0]];n1=cross(minus(q[1],q[0]),minus(q[2],q[0]));n2=cross(minus(q[2],q[0]),minus(q[3],q[0]));cos=dot(n1,n2)/math.sqrt(dot(n1,n1)*dot(n2,n2))
            witnesses.append({'side':side,'source_cage_first_bridge_triangle_normal_cosine':cos,'opposing_triangle_halves':cos<0})
        rows.append({'fighter':row['fighter'],'body':row['body'],'GLB_sha256':row['resource_sha256'],'exported_signed_hand_volume_m3':volumes,'source_cage_witnesses':witnesses})
    out={'scope':'Read-only actual exported triangle volumes plus original first source-cage quad reconstructed from retained exact dimensions; not engine images','producer_run':39882654215,'rows':rows,'finding':'Right fingers reverse the root cross-section; left thumb also uses an inconsistent root convention. Closed/manifold checks missed folded quads. Art approval false.','all_right_bridge_witnesses_opposed':all(next(x for x in r['source_cage_witnesses']if x['side']=='R')['opposing_triangle_halves']for r in rows),'human_approved':False}
    assert out['all_right_bridge_witnesses_opposed']
    (evidence/'HAND_CAGE_NEGATIVE_FINDING.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'rigs':len(rows),'all_right_bridges_folded':True,'first':rows[0]},indent=2))
if __name__=='__main__':main()
