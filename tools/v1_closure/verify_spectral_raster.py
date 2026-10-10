"""Color-independent raster distinctness on actual engine output, not clip/shape names."""
import json,itertools
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback/shape_gallery'
data=json.loads((OUT/'raster_fixture.json').read_text())
normal=np.asarray(Image.open(OUT/'nine_shape_normal.png').convert('RGB')).astype(float)
accessible=np.asarray(Image.open(OUT/'nine_shape_accessible.png').convert('RGB')).astype(float)
background=normal[350,1050]
masks={};brightness=[]
for r in data['rows']:
 x,y=map(round,r['center']);patch=normal[y-80:y+80,x-80:x+80];energy=np.max(np.abs(patch-background),axis=2);masks[r['fighter']]=energy>max(6,energy.max()*.16)
 core=normal[y-4:y+4,x-4:x+4].mean();dim=accessible[y-4:y+4,x-4:x+4].mean();brightness.append({'fighter':r['fighter'],'normal_core_mean':float(core),'reduced_core_mean':float(dim)})
pairs=[]
for a,b in itertools.combinations(masks,2):
 x,y=masks[a],masks[b];union=np.logical_or(x,y).sum();difference=np.logical_xor(x,y).sum();score=float(difference/max(1,union));pairs.append({'a':a,'b':b,'shape_difference_fraction':score,'pass':score>.06})
report={'ok':all(r['pass'] for r in pairs),'scope':'same-size actual gl_compatibility raster fixture; normalized luminance masks remove palette distinctions; no human taste score','pairs':pairs,'brightness':brightness,'normal':str((OUT/'nine_shape_normal.png').relative_to(ROOT)),'accessible':str((OUT/'nine_shape_accessible.png').relative_to(ROOT))}
(OUT/'raster_distinctness.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'ok':report['ok'],'pairs':len(pairs),'minimum_shape_difference':min(r['shape_difference_fraction'] for r in pairs)}))
assert report['ok']
