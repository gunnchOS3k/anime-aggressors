"""Summarize measured stance-only slips; keep swings and facing flips separate.

No artistic passing threshold. Both pixel soles and ankle references are retained,
so ANI05's ankle measurements can be compared without changing the criterion.
"""
import argparse
import collections
import json
import math
from pathlib import Path
import statistics

def analyze(path):
    doc=json.loads(path.read_text());results=[]
    assert doc['PASS'] and len(doc['rows'])==72
    for row in doc['rows']:
        values={'ankles':[],'soles':[]};active={'ankles':[],'soles':[]}
        snaps=[];support_error=0.;kinds=set()
        for a,b in zip(row['trace'],row['trace'][1:]):
            assert a.get('soles') and b.get('transition'), 'incomplete trace'
            kinds.add(b['transition'].get('kind',''))
            support_error=max(support_error,b['transition'].get('support_error_m',0))
            if b['facing']!=a['facing']:
                snaps.append({'frame':b['frame'],'ankles_max_px':max(math.dist(a['ankles'][s],b['ankles'][s]) for s in ['L','R'])})
                continue
            if b['state'] not in ['idle','walk','run','dash'] or a['state'] not in ['idle','walk','run','dash']:continue
            if abs(b['phase']-a['phase'])>.3:continue
            for side in ['L','R']:
                old=(a['phase']+(0 if side=='L' else .5))%1
                cur=(b['phase']+(0 if side=='L' else .5))%1
                if .02<old<.48 and .02<cur<.48:
                    for metric in values:
                        slip=math.dist(a[metric][side],b[metric][side]);values[metric].append(slip)
                        if b['transition'].get('kind'):active[metric].append(slip)
        r={k:row[k] for k in ['fighter','body','initial_facing','kind']}
        for label,group in [('all_neutral_stance',values),('active_transition_stance',active)]:
            r[label]={metric:{'samples':len(v),'mean_px':statistics.mean(v) if v else None,'max_px':max(v) if v else None} for metric,v in group.items()}
        r.update(source_kinds=sorted(kinds),support_error_m=support_error,facing_flip_observations=snaps)
        results.append(r)
    return {'trace':str(path),'rows':results,'quality_threshold':None,'visual_acceptance':False,
            'criterion':'same facing and continuous gait phase in either travel direction; planted left phase0-.5/right.5-1; attacks/swing/side flip excluded and labeled separately'}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('trace',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    d=analyze(a.trace);a.output.write_text(json.dumps(d,indent=2)+'\n')
    groups=collections.defaultdict(list)
    for r in d['rows']:
        v=r['all_neutral_stance']['ankles'];groups[(r['fighter'],r['kind'])].append(v)
    for k,v in groups.items():
        n=sum(x['samples'] for x in v);mean=sum((x['mean_px'] or 0)*x['samples'] for x in v)/max(1,n)
        print(*k,'samples',n,'mean',round(mean,6),'peak',round(max(x['max_px'] or 0 for x in v),6))
