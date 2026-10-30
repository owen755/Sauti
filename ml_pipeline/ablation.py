import itertools, statistics as st, collections, json
from sklearn.model_selection import RepeatedStratifiedKFold, train_test_split
from sklearn.metrics import roc_auc_score
from scam_lib import *
d=load(); cats=[c for _,_,c in d]
trainval,test=train_test_split(d,test_size=0.2,stratify=cats,random_state=7)
X=[t for t,_,_ in trainval]; Y=[y for _,y,_ in trainval]
print(f"split: trainval={len(trainval)} test={len(test)} (test locked until the end)")
HP=dict(epochs=60,lr=0.1,l2=0.03,seed=3)
rows=[]
for nn,ds,bi,sg in itertools.product([0,1],repeat=4):
    tok=make_tok(nn,ds,bi,sg); oof=collections.defaultdict(list)
    for tr,va in RepeatedStratifiedKFold(n_splits=5,n_repeats=3,random_state=31).split(X,Y):
        m=Model(tok).fit([(X[i],Y[i]) for i in tr],**HP)
        for i in va: oof[i].append(m.p(X[i]))
    p=[st.mean(oof[i]) for i in range(len(X))]
    rows.append((roc_auc_score(Y,p),prf(Y,[int(q>=.5) for q in p])["f1"],nn,ds,bi,sg))
rows.sort(reverse=True)
print("\n numbers->num | drop stopwords | binary | signals |  CV AUC | F1@.5")
for a,f,nn,ds,bi,sg in rows: print(f"      {nn}       |       {ds}        |   {bi}    |    {sg}    |  {a:.3f}  | {f:.3f}")
print("\nAverage AUC when a component is ON vs OFF (all other combos averaged):")
for i,n in enumerate(["numbers->num","drop stopwords","binary presence","signals"]):
    on=st.mean(r[0] for r in rows if r[2+i]==1); off=st.mean(r[0] for r in rows if r[2+i]==0)
    print(f"  {n:16s} ON {on:.4f}   OFF {off:.4f}   ({on-off:+.4f})")
json.dump({"best":rows[0][2:],"rows":rows},open("out/ablation.json","w"))
