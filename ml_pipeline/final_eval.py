import json, collections
from sklearn.model_selection import train_test_split
from scam_lib import *
from baselines import old14, A
ch=json.load(open("out/chosen.json")); THR=ch["thr"]; HP=ch["hp"]
d=load(); cats=[c for _,_,c in d]
trainval,test=train_test_split(d,test_size=0.2,stratify=cats,random_state=7)
tv=[(t,y) for t,y,_ in trainval]
def ev(m,thr,data=test): return prf([y for _,y,_ in data],[int(m.p(t)>=thr) for t,_,_ in data])
oldalg=Model(tokens_old,bias=-1.15).fit(tv,epochs=75,lr=0.25,shuffle=False,bias_scale=0.3)
v1=Model(tokens_hybrid).fit(tv,**HP)           # batch-1 recipe (function words dropped)
fin=Model(tokens_final).fit(tv,**HP)
print(f"\n=========== FINAL TEST: {len(test)} unseen sentences ({sum(y for _,y,_ in test)} scam / {sum(1-y for _,y,_ in test)} genuine) ===========")
rows=[("A  original 14-sample model, lock@0.75",A,.75),("B  original algorithm + all training data, lock@0.75",oldalg,.75),
      ("C  batch-1 recipe (stopwords dropped)",v1,THR),(f"D  FINAL model, thr {THR:.2f}",fin,THR)]
out={}
for n,m,t in rows:
    r=ev(m,t); out[n[0]]=r
    print(f"{n:54s} P={r['precision']:.2f} R={r['recall']:.2f} F1={r['f1']:.2f} | missed={r['fn']:2d} false alarms={r['fp']:2d}")
print("\nFinal-model mistakes on test:")
for t,y,c in test:
    p=fin.p(t)
    if (p>=THR)!=(y==1): print(f"  {'MISSED SCAM' if y else 'FALSE ALARM'} p={p:.2f} [{c}] {t[:88]}")
print("\n=========== Never-seen scam FAMILY test (whole family + its siblings removed from training) ===========")
GROUPS={"fake bank/telco agent (PIN/OTP)":["fake_agent_pin_otp","fake_agent_pin_otp_v2"],
 "wrong-transaction reversal (+ spoofed SMS)":["mpesa_reversal","mpesa_reversal_v2","spoofed_mpesa_sms"],
 "emergency / arrest / bail / lawyer":["emergency_coercion","sheng_coercion","lawyer_bail"],
 "SIM swap":["sim_swap"],"KRA / NTSA / police / fines":["govt_kra_ntsa","fake_kplc_water"],
 "job / loan / visa / employer fees":["job_visa_loan_fee","fake_employer_id","fake_loan_betting_app"],
 "prize / bonus":["prize_promo"],"relative / romance impersonation":["relative_impersonation","romance_abroad"],
 "investment / crypto":["investment_crypto"],"parcel / customs fee":["parcel_customs_fee"],
 "rent / charity / insurance":["fake_landlord_rent","fake_charity_harambee","fake_insurance_sha"]}
assert sorted(c for g in GROUPS.values() for c in g)==sorted({c for _,y,c in d if y==1}),"group mismatch"
test_set={t for t,_,_ in test}; loco={}
for g,cl in GROUPS.items():
    tr=[(t,y) for t,y,cc in d if cc not in cl and t not in test_set]
    held=[t for t,y,cc in d if cc in cl]
    m=Model(tokens_final).fit(tr,**HP); loco[g]=(sum(m.p(t)>=THR for t in held),len(held))
for g,(a,b) in sorted(loco.items(),key=lambda kv:kv[1][0]/kv[1][1]): print(f"  {g:44s} {a:2d}/{b:2d}")
tot=sum(a for a,_ in loco.values()); n=sum(b for _,b in loco.values())
print(f"  overall: {tot}/{n} = {tot/n:.0%} of scams from a family the model has never seen")
json.dump({"thr":THR,"hp":HP,"test_n":len(test),"test_final":out["D"],"test_old":out["A"],"test_oldalg":out["B"],"test_v1":out["C"],"loco":loco,"loco_overall":tot/n},open("out/results.json","w"),indent=1)
