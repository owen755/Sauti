"""Choose training settings + alert threshold using cross-validation on train+val ONLY (test untouched)."""
import itertools, statistics as st, collections, json
from sklearn.model_selection import RepeatedStratifiedKFold, StratifiedKFold, train_test_split
from sklearn.metrics import roc_auc_score
from scam_lib import *
d=load(); cats=[c for _,_,c in d]
trainval,test=train_test_split(d,test_size=0.2,stratify=cats,random_state=7)
X=[t for t,_,_ in trainval]; Y=[y for _,y,_ in trainval]
def oof_probs(hp,reps,seed):
    oof=collections.defaultdict(list)
    for tr,va in RepeatedStratifiedKFold(n_splits=5,n_repeats=reps,random_state=seed).split(X,Y):
        m=Model(tokens_final).fit([(X[i],Y[i]) for i in tr],**hp)
        for i in va: oof[i].append(m.p(X[i]))
    return [st.mean(oof[i]) for i in range(len(X))]
res=[]
for lr,l2,ep in itertools.product([0.05,0.1,0.2],[0.003,0.01,0.03,0.1],[30,60]):
    hp=dict(epochs=ep,lr=lr,l2=l2,seed=3); p=oof_probs(hp,3,41)
    res.append((roc_auc_score(Y,p),max(prf(Y,[int(q>=t/100) for q in p])["f1"] for t in range(30,80)),hp))
res.sort(key=lambda r:(-round(r[0],3),-r[1]))
print("Top settings by CV AUC (ties broken by best F1):")
for a,f,hp in res[:5]: print(f"  AUC={a:.3f} bestF1={f:.3f} {hp}")
hp=res[0][2]
p=oof_probs(hp,6,99)
print("\nThreshold sweep on out-of-fold predictions (train+val only):")
print(" thr   precision recall  F1   false-alarms missed  (of",sum(Y),"scams,",len(Y)-sum(Y),"genuine)")
chosen=None
for t in range(40,76,5):
    r=prf(Y,[int(q>=t/100) for q in p]); print(f" {t/100:.2f}   {r['precision']:.2f}      {r['recall']:.2f}   {r['f1']:.2f}    {r['fp']:3d}          {r['fn']:3d}")
# rule fixed in advance: smallest threshold whose out-of-fold precision is at least 0.93
for t in range(30,90):
    r=prf(Y,[int(q>=t/100) for q in p])
    if r["precision"]>=0.93: chosen=(t/100,r); break
thr,r=chosen
print(f"\nRULE: smallest threshold with out-of-fold precision >= 0.93  ->  thr={thr:.2f}  (P={r['precision']:.2f} R={r['recall']:.2f} F1={r['f1']:.2f})")
json.dump({"hp":hp,"thr":thr,"cv_precision":r["precision"],"cv_recall":r["recall"],"cv_f1":r["f1"],"cv_auc":res[0][0],"n_trainval":len(X)},open("out/chosen.json","w"),indent=1)
