const fs=require('fs');
const dart=fs.readFileSync('out/scam_model.dart','utf8');
// pull the real regex literals + weights out of the generated Dart file
const rx=n=>{const m=dart.match(new RegExp('final RegExp '+n+' = RegExp\\(r([\'"])(.*?)\\1\\);'));if(!m)throw new Error('no '+n);return new RegExp(m[2],'g')};
const R={digitComma:rx('_digitComma'),digits:rx('_digits'),notLetters:rx('_notLetters'),spaces:rx('_spaces'),
 secret:rx('_secret'),ask:rx('_ask'),warn:rx('_warn'),isolate:rx('_isolate'),official:rx('_official'),payVerb:rx('_payVerb'),thisNum:rx('_thisNum'),urgent:rx('_urgent')};
const has=(r,t)=>{r.lastIndex=0;return r.test(t)};
const stop=new Set();
const wblock=dart.match(/const Map<String, double> kPretrainedWeights = \{([\s\S]*?)\n\};/)[1];
const W={};for(const m of wblock.matchAll(/'([^']+)': (-?[0-9.e+-]+),/g))W[m[1]]=parseFloat(m[2]);
const bias=parseFloat(dart.match(/const double kPretrainedBias = (-?[0-9.e+-]+);/)[1]);
const shift=parseFloat(dart.match(/static const double displayShift = (-?[0-9.e+-]+);/)[1]);
function flags(text){const t=text.toLowerCase(),f=[];const s=has(R.secret,t),w=has(R.warn,t);
 if(s&&has(R.ask,t)&&!w)f.push('SIG_SECRET_ASK'); if(s&&w)f.push('SIG_SECRET_WARN'); if(has(R.isolate,t))f.push('SIG_ISOLATE');
 if(has(R.official,t))f.push('SIG_OFFICIAL'); if(has(R.payVerb,t)&&has(R.thisNum,t))f.push('SIG_PAY_TO_NUMBER'); if(has(R.payVerb,t)&&has(R.urgent,t))f.push('SIG_PAY_URGENT');return f}
function feats(raw){let t=raw.toLowerCase();t=t.replace(R.digitComma,'$1$2');t=t.replace(R.digitComma,'$1$2');t=t.replace(R.digits,' num ');t=t.replace(R.notLetters,' ');
 const words=t.split(R.spaces).filter(w=>w.length>1&&!stop.has(w));const s=new Set(words);for(let i=0;i<words.length-1;i++)s.add(words[i]+'_'+words[i+1]);for(const f of flags(raw))s.add(f);return [...s]}
const sig=z=>z>20?0.9999:z<-20?0.0001:1/(1+Math.exp(-z));
const prob=t=>{let z=bias;for(const f of feats(t))z+=W[f]||0;return sig(z+shift)};
const py=JSON.parse(fs.readFileSync('out/py_features.json','utf8'));
const gold=JSON.parse(fs.readFileSync('out/golden.json','utf8'));
let featBad=0,n=0;for(const [t,pf] of Object.entries(py)){n++;const jf=feats(t).sort();if(JSON.stringify(jf)!==JSON.stringify(pf)){featBad++;if(featBad<=5)console.log('FEATURE MISMATCH:',JSON.stringify(t),'\n js:',jf.join(','),'\n py:',pf.join(','))}}
let pBad=0,maxd=0;for(const g of gold){const d=Math.abs(prob(g.text)-g.prob);maxd=Math.max(maxd,d);if(d>1e-6)pBad++}
console.log(`weights parsed from .dart: ${Object.keys(W).length}`);
console.log(`feature parity: ${n-featBad}/${n} sentences identical to Python`);
console.log(`probability parity on ${gold.length} golden cases: max abs diff = ${maxd.toExponential(2)}  (${pBad} beyond 1e-6)`);
for (const t of ["Usikate simu, tuma elfu kumi na tano kwa hii namba binafsi sasa hivi","Habari za asubuhi, tutaonana kesho kanisani","Hello this is Equity Bank security, read me the OTP right now","Equity Bank kamwe haitakuomba PIN au OTP kwa simu"])
  console.log(Math.round(prob(t)*100)+'%  '+t);
console.log('repeat check (tuma pesa x1 vs x6):',Math.round(prob('tuma pesa')*100),Math.round(prob(Array(6).fill('tuma pesa').join(' '))*100));
