"""Small pure-math cage regression on all18 retained original source dimensions.

No Blender/export/render. Checks the corrected root-derived frame before remote
source production; this does NOT verify newly saved meshes or visual quality.
"""
import json,math
from pathlib import Path
from audit_hand_bridge_8d2 import minus,cross,dot,plus,scale,ROOT

def norm(v):return scale(v,1/math.sqrt(dot(v,v)))
def cosine(q):
    a,b,c,d=q;n1=cross(minus(b,a),minus(c,a));n2=cross(minus(c,a),minus(d,a))
    return dot(n1,n2)/math.sqrt(dot(n1,n1)*dot(n2,n2))

def main():
    root=ROOT/'artifacts/v1_closure/production_8d/hands_remote_39882654215';m=json.loads((root/'PRODUCTION_MANIFEST.json').read_text());rows=[];total=0
    for record in m['rows']:
        for h in record['hands']:
            w=h['width_m'];end=h['distal_envelope_m'];depth=h['depth_m'];palm_end=end*.52;forward=h['chains'][0]['axis'];normal=h['chains'][0]['normal'];across=(-1 if h['side']=='R'else 1,0,0);wrist=h['wrist'];frows=[-.014,palm_end*.22,palm_end*.62,palm_end]
            def grid(s,row,i):
                u=(-.5+i*.25)*w;thick=depth*.5*(.8+.2*(1-abs(u)/(w*.5)));thenar=.004*(i/4)**2 if row in [1,2]and s==1 else 0
                return plus(wrist,scale(across,u*[.72,.90,1,.96][row]),scale(forward,frows[row]),scale(normal,s*thick+thenar))
            minimum=1.;count=0
            for chain in h['chains']:
                thumb=chain['digit']==4;direction=chain['axis'];origin=chain['start'];length=chain['length'];stops=chain['stops']
                if thumb:root_loop=[grid(1,1,4),grid(1,2,4),grid(-1,2,4),grid(-1,1,4)];width=depth*.9;thickness=depth*.9;rings=[.025,.10,.46,.50,.54,.90,.97,1.]
                else:
                    cell=3-chain['digit'];root_loop=[grid(-1,3,cell),grid(-1,3,cell+1),grid(1,3,cell+1),grid(1,3,cell)];width=w*.215;thickness=depth*.76;rings=[.025,.08,stops[1]-.035,stops[1],stops[1]+.035,stops[-2]-.035,stops[-2],stops[-2]+.035,.94,.985,1.]
                edge=minus(root_loop[1],root_loop[0]);x=norm(minus(edge,scale(direction,dot(edge,direction))))
                edge=minus(root_loop[3],root_loop[0]);z=norm(minus(minus(edge,scale(direction,dot(edge,direction))),scale(x,dot(edge,x))))
                last=root_loop
                for t in sorted(set(rings)):
                    taper=(1-.20*t)*max(.18,1-max(0,t-.93)/.07*.65);knuckle=1.10 if min(abs(t-s)for s in stops[1:-1])<.01 else 1.;center=plus(origin,scale(direction,length*t))
                    blend=min(1.,t/stops[1]);blend=blend*blend*(3-2*blend);current=[]
                    for corner,(a,b) in enumerate([(-1,-1),(1,-1),(1,1),(-1,1)]):
                        wanted=plus(center,scale(x,a*width*.5*taper*knuckle),scale(z,b*thickness*.5*taper*knuckle));neck=plus(root_loop[corner],scale(direction,length*t))
                        current.append(plus(scale(neck,1-blend),scale(wanted,blend)))
                    for i in range(4):
                        c=cosine([last[i],last[(i+1)%4],current[(i+1)%4],current[i]]);minimum=min(minimum,c);count+=1
                        assert c>0,(record['fighter'],record['body'],h['side'],chain['digit'],t,i,c)
                    last=current
            rows.append({'fighter':record['fighter'],'body':record['body'],'side':h['side'],'minimum_bridge_half_normal_cosine':minimum,'bridge_quads':count});total+=count
    result={'PASS':True,'rigs':18,'hands':36,'bridge_quads':total,'rows':rows,'scope':'Pure-math corrected cage from exact prior source dimensions only; no new Blender source/export/native verification','human_approved':False}
    (root/'BRIDGE_FRAME_MATH_CHECK.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items()if k!='rows'}))
if __name__=='__main__':main()
