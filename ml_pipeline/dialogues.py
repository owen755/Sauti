from scam_lib import *
from sklearn.model_selection import train_test_split
_d=load(); trainval,test=train_test_split(_d,test_size=0.2,stratify=[c for _,_,c in _d],random_state=7)
import json
ch=json.load(open("out/chosen.json")); THR=ch["thr"]; HP=ch["hp"]
m=Model(tokens_final).fit([(t,y) for t,y,_ in trainval],**HP)
D={
"DEMO scam (hospital coercion)":(1,["Hello, mzazi! Niko hapa hospitali, kwa emergency. Mtoto wako amepata ajali mbaya, na ameumia!","Mungu wangu! Wacha nimpigie mtoto wangu simu kwanza, nihakikishe.","Hapana, usikate simu na usipigie mtu! Daktari anasema, tuma elfu kumi na tano kwa hii namba binafsi, sasa hivi!"]),
"DEMO true hospital":(0,["Hello, Mama Njeri. Tunakupigia kutoka Aga Khan Clinic. Kijana wako amepata homa kidogo.","Je, ni kweli? Nilipe pesa kwa namba gani, ama nije hapo?","Usitume pesa kwa namba ya mtu binafsi. Unaweza kumpigia mtoto wako uhakikishe, kisha ulipe kwa Official Hospital Paybill ukifika reception."]),
"DEMO telco SIM-swap":(1,["Jambo, nakupigia kutoka Safaricom Customer Care. Kuna mwizi anajaribu kufanya, SIM swap, kwa line yako.","Sasa nifanye nini, ndio line yangu isifungwe?","Tafadhali, bonyeza PIN yako sasa hivi, na usomee ile OTP code imeingia kwa simu yako!"]),
"NEW scam: KRA tax":(1,["Habari, nakupigia kutoka KRA, tumegundua una deni la ushuru la elfu kumi na nane.","Lakini mimi nimelipa ushuru wangu mwaka huu, una uhakika?","Usibishane, lipa leo kwa namba hii ya afisa wetu ama tutakukamata kesho asubuhi."]),
"NEW scam: fake son new number":(1,["Mama hii ni mimi, nimebadilisha namba, simu yangu imeibiwa.","Ni nani wewe? Sauti si ya mwanangu.","Mama usinipigie, nimekwama, tuma elfu tano kwa namba hii sasa hivi tafadhali."]),
"NEW scam: English bank OTP":(1,["Hello, this is Equity Bank security department, we noticed suspicious activity.","What kind of activity? I haven't done anything.","To block it, please read me the OTP we just sent to your phone right now."]),
"NEW safe: school fall":(0,["Habari, naongea kutoka shule ya msingi, mtoto wako ameanguka kidogo uwanjani.","Mungu wangu, ameumia sana?","Hapana, ni mchubuko tu, tumempaka dawa, uje umchukue ukimaliza kazi, hakuna haraka."]),
"NEW safe: mum sends fare":(0,["Mama, niko stage, nimeishiwa na pesa ya matatu.","Sawa mwanangu, nitakutumia mpesa sasa hivi, ni namba yako ile ile?","Ndio ile ile, asante mama, nitakupigia nikifika."]),
"NEW safe: KCB card ready":(0,["Hello, this is KCB, we are calling about your new card which is ready at the branch.","Okay, do I need to pay anything?","No, there is nothing to pay, just carry your ID, and remember we never ask for your PIN."]),
}
def trace(turns,k):
    out=[];peak=0
    for i in range(len(turns)):
        txt=" ".join(turns[max(0,i-k+1):i+1]) if k else " ".join(turns[:i+1])
        p=m.p(txt); peak=max(peak,p); out.append(p)
    return out,peak
pol=[("all turns so far (current app)",0),("last 3 turns",3),("last 2 turns",2),("last 1 turn",1)]
for name,k in pol:
    ok=0
    print(f"\n--- policy: {name} ---")
    for d,(y,turns) in D.items():
        tr,peak=trace(turns,k); fired=peak>=THR; ok+= fired==(y==1)
        print(f"  {'OK ' if fired==(y==1) else 'XX '} {d:32s} per-turn risk%={[round(x*100) for x in tr]}  alert={'YES' if fired else 'no '} (truth: {'scam' if y else 'safe'})")
    print(f"  => {ok}/{len(D)} calls handled correctly")
