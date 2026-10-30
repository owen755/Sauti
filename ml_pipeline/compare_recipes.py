"""All 382 sentences, repeated 5-fold CV (5 repeats = every sentence scored by 5 models that never saw it).
Threshold-free (ROC AUC) and best-case F1, so no recipe is helped by a threshold I picked."""
import statistics as st, collections
from sklearn.model_selection import RepeatedStratifiedKFold
from sklearn.metrics import roc_auc_score
from scam_lib import *
d=load(); X=[t for t,_,_ in d]; Y=[y for _,y,_ in d]
def run(name,tok,fit_kw,bias=0.0):
    oof=collections.defaultdict(list); foldf1=[]
    for tr,va in RepeatedStratifiedKFold(n_splits=5,n_repeats=5,random_state=21).split(X,Y):
        m=Model(tok,bias=bias).fit([(X[i],Y[i]) for i in tr],**fit_kw)
        ps=[m.p(X[i]) for i in va]
        for i,p in zip(va,ps): oof[i].append(p)
        foldf1.append(prf([Y[i] for i in va],[int(p>=.5) for p in ps])["f1"])
    p=[st.mean(oof[i]) for i in range(len(X))]
    best=max((prf(Y,[int(q>=t/100) for q in p])["f1"],t/100) for t in range(20,90,1))
    print(f"{name:46s} AUC={roc_auc_score(Y,p):.3f}  best-F1={best[0]:.3f} (at {best[1]:.2f})  fold F1@.5 = {st.mean(foldf1):.3f} ±{st.pstdev(foldf1):.3f}")
    return p
new=dict(epochs=60,lr=0.1,l2=0.03,seed=3)
run("old tokens + old SGD (your original recipe)",tokens_old,dict(epochs=75,lr=0.25,shuffle=False,bias_scale=0.3),bias=-1.15)
run("old tokens + new SGD (shuffle, L2)",tokens_old,new)
run("words only: binary, num, stopwords, new SGD",tokens_new,new)
run("HYBRID: words + 6 signals, new SGD",tokens_hybrid,new)
