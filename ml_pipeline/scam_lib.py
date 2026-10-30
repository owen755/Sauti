"""Tiny logistic-regression-by-SGD library. Pure Python so it can be mirrored 1:1 in Dart."""
import re, math, random, csv

STOP = set("""kwa na ya wa la za ni hii hiyo ile hio the a an to is are of and in on it i we be this that for with at
""".split())

def tokens_old(text):
    """EXACT copy of your Dart extractFeatures (unigrams + bigrams, with repeats)."""
    w=[x for x in re.split(r'\s+',re.sub(r'[^a-z0-9\s]',' ',text.lower())) if len(x)>1]
    return w+[w[i]+'_'+w[i+1] for i in range(len(w)-1)]

def tokens_new(text):
    """New pipeline: join digit commas, numbers->'num', drop punctuation, drop function words,
    unigrams + bigrams, each feature counted ONCE (presence, not count)."""
    t=text.lower()
    t=re.sub(r'(\d),(\d)',r'\1\2',t)
    t=re.sub(r'(\d),(\d)',r'\1\2',t)          # second pass handles 5,000,000
    t=re.sub(r'[0-9]+',' num ',t)
    t=re.sub(r'[^a-z\s]',' ',t)
    w=[x for x in t.split() if len(x)>1 and x not in STOP]
    feats=list(w)+[w[i]+'_'+w[i+1] for i in range(len(w)-1)]
    seen=set(); out=[]
    for f in feats:
        if f not in seen: seen.add(f); out.append(f)
    return out

def sig(z):
    if z>20: return 0.9999
    if z<-20: return 0.0001
    return 1/(1+math.exp(-z))

class Model:
    def __init__(self,tok,bias=0.0):
        self.tok=tok; self.w={}; self.b=bias
    def z(self,text):
        return self.b+sum(self.w.get(f,0.0) for f in self.tok(text))
    def p(self,text): return sig(self.z(text))
    def fit(self,data,epochs=40,lr=0.1,l2=0.0,shuffle=True,seed=0,bias_scale=1.0,warm=False):
        if not warm: self.w={}; 
        rng=random.Random(seed); data=list(data); feats=[(self.tok(t),y) for t,y in data]
        for ep in range(epochs):
            if shuffle: rng.shuffle(feats)
            for f,y in feats:
                z=self.b+sum(self.w.get(x,0.0) for x in f)
                e=sig(z)-y
                self.b-=lr*e*bias_scale
                for x in f:
                    wx=self.w.get(x,0.0)
                    self.w[x]=wx-lr*(e+l2*wx)
        return self

def load(path="out/dataset.csv"):
    with open(path,encoding="utf-8") as f:
        r=list(csv.DictReader(f))
    return [(x["text"],int(x["label"]),x["category"]) for x in r]

def prf(y,pred):
    tp=sum(1 for a,b in zip(y,pred) if a==1 and b==1); fp=sum(1 for a,b in zip(y,pred) if a==0 and b==1)
    fn=sum(1 for a,b in zip(y,pred) if a==1 and b==0); tn=sum(1 for a,b in zip(y,pred) if a==0 and b==0)
    P=tp/(tp+fp) if tp+fp else 0.0; R=tp/(tp+fn) if tp+fn else 0.0
    F=2*P*R/(P+R) if P+R else 0.0
    return dict(tp=tp,fp=fp,fn=fn,tn=tn,precision=P,recall=R,f1=F)

# ---------- hybrid: learned n-grams + a few hand-written "signal" features ----------
SECRET   = re.compile(r"\b(pin|otp|password|nambari ya siri|namba ya siri|siri ya|msimbo|code)\b")
ASK      = re.compile(r"\b(tupe|nipe|tusomee|usomee|soma|read|give|confirm|weka|bonyeza|press|enter|thibitisha|provide|tuma|send)\b")
WARN     = re.compile(r"\b(kamwe|never|usimpe|hatuombi|haitakuomba|haitaomba|hatutaki|do not share|don.?t share|ignore)\b")
ISOLATE  = re.compile(r"\b(usikate|usipigie|usimpigie|usipige|usiseme|usimwambie|don.?t hang up|don.?t call|don.?t tell|do not tell|do not call)\b")
OFFICIAL = re.compile(r"\b(rasmi|official|reception|cashier|branch|tawi|hakuna cha kulipa|no payment|no action|hakuna haja)\b")
PAYVERB  = re.compile(r"\b(tuma|send|lipa|pay|deposit|rudisha|return|nirudishie)\b")
THISNUM  = re.compile(r"\b(hii namba|hii number|hiyo namba|namba hii|nambari hii|this number|this mpesa number|namba binafsi|personal number|namba yangu|number yangu|my number)\b")
URGENT   = re.compile(r"\b(sasa hivi|haraka|immediately|right now|urgent|urgently|fasta|leo tu|today|before|kabla)\b")

def signal_flags(text):
    t=text.lower(); f=[]
    secret=bool(SECRET.search(t)); warn=bool(WARN.search(t))
    if secret and ASK.search(t) and not warn: f.append("SIG_SECRET_ASK")
    if secret and warn: f.append("SIG_SECRET_WARN")
    if ISOLATE.search(t): f.append("SIG_ISOLATE")
    if OFFICIAL.search(t): f.append("SIG_OFFICIAL")
    if PAYVERB.search(t) and THISNUM.search(t): f.append("SIG_PAY_TO_NUMBER")
    if PAYVERB.search(t) and URGENT.search(t): f.append("SIG_PAY_URGENT")
    return f

def tokens_hybrid(text):
    return tokens_new(text)+signal_flags(text)

# ---------- configurable tokenizer (used for the ablation; the winner is mirrored in Dart) ----------
def make_tok(norm_num,drop_stop,binary,signals):
    def tok(text):
        t=text.lower()
        if norm_num:
            t=re.sub(r'(\d),(\d)',r'\1\2',t); t=re.sub(r'(\d),(\d)',r'\1\2',t)
            t=re.sub(r'[0-9]+',' num ',t); t=re.sub(r'[^a-z\s]',' ',t)
        else:
            t=re.sub(r'[^a-z0-9\s]',' ',t)
        w=[x for x in t.split() if len(x)>1 and (not drop_stop or x not in STOP)]
        f=w+[w[i]+'_'+w[i+1] for i in range(len(w)-1)]
        if binary:
            seen=set(); f=[x for x in f if not (x in seen or seen.add(x))]
        if signals: f=f+signal_flags(text)
        return f
    return tok

# FINAL recipe, chosen by ablation on train+val of the 382-sentence set:
# numbers->'num' ON, drop stopwords OFF (it hurt), binary presence ON, 6 signal features ON.
tokens_final = make_tok(1,0,1,1)
