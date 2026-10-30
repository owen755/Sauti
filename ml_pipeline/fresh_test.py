"""Frozen-model exam: train on batch 1 only (exactly the shipped recipe), score batch 2 once."""
import csv, collections, json
from scam_lib import *
from baselines import old14, A
def rd(p): return [(t,int(y),c) for t,y,c in list(csv.reader(open(p,encoding="utf-8")))[1:]]
v1=rd("out/dataset_v1.csv"); v2=rd("out/dataset_v2_new.csv")
THR=0.55; HP=dict(epochs=60,lr=0.1,l2=0.03,seed=3)
hyb=Model(tokens_hybrid).fit([(t,y) for t,y,_ in v1],**HP)
words=Model(tokens_new).fit([(t,y) for t,y,_ in v1],**HP)
old_alg=Model(tokens_old,bias=-1.15).fit([(t,y) for t,y,_ in v1],epochs=75,lr=0.25,shuffle=False,bias_scale=0.3)
def ev(m,thr): return prf([y for _,y,_ in v2],[1 if m.p(t)>=thr else 0 for t,_,_ in v2])
print(f"\nFRESH EXAM: {len(v2)} brand-new sentences ({sum(y for _,y,_ in v2)} scam / {sum(1-y for _,y,_ in v2)} genuine)")
rows=[("Original 14-sample model, lock@0.75",A,.75),("Old algorithm on batch-1 data, lock@0.75",old_alg,.75),("Words-only new recipe, thr .55",words,THR),("SHIPPED model (hybrid), thr .55",hyb,THR)]
res={}
for n,m,t in rows:
    r=ev(m,t); res[n]=r
    print(f"  {n:44s} P={r['precision']:.2f} R={r['recall']:.2f} F1={r['f1']:.2f}  missed={r['fn']:2d} false alarms={r['fp']:2d}")
print("\nShipped model, per category (correct / total):")
d=collections.defaultdict(lambda:[0,0])
for t,y,c in v2:
    d[c][1]+=1; d[c][0]+= ((hyb.p(t)>=THR)==(y==1))
for c,(a,b) in sorted(d.items(),key=lambda kv:kv[1][0]/kv[1][1]): print(f"  {c:28s} {a}/{b}")
print("\nShipped model mistakes:")
for t,y,c in v2:
    p=hyb.p(t)
    if (p>=THR)!=(y==1): print(f"  {'MISSED SCAM' if y else 'FALSE ALARM'} p={p:.2f} [{c}] {t[:88]}")
json.dump(res,open("out/fresh_exam.json","w"),indent=1)
