import copy
from scam_lib import *
from sklearn.model_selection import train_test_split
from baselines import A
_d=load(); trainval,test=train_test_split(_d,test_size=0.2,stratify=[c for _,_,c in _d],random_state=7)
import json
ch=json.load(open("out/chosen.json")); THR=ch["thr"]; HP=ch["hp"]
m=Model(tokens_final).fit([(t,y) for t,y,_ in trainval],**HP)
print("\nCHECK 1 - length drift (risk % when the same sentence is repeated 1x, 3x, 6x)")
for s in ["tuma pesa","umefika nyumbani salama ndio niko darasani nitakupigia baadaye"]:
    print(f"  '{s[:30]}': old model {[round(A.p(' '.join([s]*n))*100) for n in (1,3,6)]}   new model {[round(m.p(' '.join([s]*n))*100) for n in (1,3,6)]}")
print("\nCHECK 2 - live retraining on stage: add 4 new labelled phrases, warm-restart 15 epochs lr .05")
before=prf([y for _,y,_ in test],[1 if m.p(t)>=THR else 0 for t,_,_ in test])
new=[("Tuma pesa kwa wakili sasa hivi ama mwanao atafungwa, usimwambie mtu",1),
     ("Hongera umechaguliwa kupata mkopo, lipa ada ndogo ya elfu mbili kwanza",1),
     ("Nimeshafika nyumbani, nitakutumia pesa ya chakula jioni, usijali",0),
     ("Mwalimu anasema ada ya muhula ni elfu kumi, tutalipa kwa benki Ijumaa",0)]
m2=copy.deepcopy(m); data=[(t,y) for t,y,_ in trainval]+new
m2.fit(data,epochs=15,lr=0.05,l2=0.03,seed=5,warm=True)
after=prf([y for _,y,_ in test],[1 if m2.p(t)>=THR else 0 for t,_,_ in test])
print(f"  held-out test before: P={before['precision']:.2f} R={before['recall']:.2f} F1={before['f1']:.2f}")
print(f"  held-out test after : P={after['precision']:.2f} R={after['recall']:.2f} F1={after['f1']:.2f}")
for t,y in new: print(f"  new phrase p before={m.p(t):.2f} after={m2.p(t):.2f} (label {y})  {t[:50]}")
