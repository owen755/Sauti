from scam_lib import *
from split import get_split
train,val,test,trainval=get_split()
old14=[
("hello mzazi niko hospitali kwa emergency mtoto wako amepata ajali mbaya ameumia",1),
("hapana usikate simu na usipigie mtu daktari anasema tuma elfu kumi na tano kwa hii namba binafsi sasa hivi",1),
("tuma pesa kwa namba yangu binafsi kabla mtoto aingie theatre sasa hivi",1),
("jambo nakupigia kutoka safaricom customer care kuna mwizi anajaribu kufanya sim swap kwa line yako",1),
("tafadhali bonyeza pin yako sasa hivi na usomee ile otp code imeingia kwa simu yako",1),
("nimetuma pesa kimakosa tafadhali rudisha reverse kwa hii namba sasa hivi",1),
("weka pin ya mpesa kwa hiyo prompt imeingia usikate simu",1),
("polisi wameshika kijana wako tuma elfu ishirini kwa namba binafsi",1),
("tunakupigia kutoka aga khan clinic kijana wako amepata homa kidogo kuja reception",0),
("usitume pesa kwa namba ya mtu binafsi mpigie mtoto uhakikishe kisha ulipe kwa official hospital paybill",0),
("unaweza kumpigia mtoto wako kwanza uhakikishe tuko ward four reception",0),
("niko hapa supermarket nanunua bidhaa wacha nilipe kwa merchant till",0),
("umefika nyumbani salama ndio niko darasani nitakupigia baadaye",0),
("tutakutana kesho asubuhi kwa mkutano wa familia asante sana",0)]
def evaluate(m,data,thr):
    y=[l for _,l,_ in data]; pred=[1 if m.p(t)*100>=thr else 0 for t,_,_ in data]
    return prf(y,pred)
def show(name,m):
    for thr in (50,75):
        r=evaluate(m,test,thr)
        print(f"{name:42s} thr={thr}: P={r['precision']:.2f} R={r['recall']:.2f} F1={r['f1']:.2f}  (missed scams={r['fn']}, false alarms={r['fp']})")
# A: your exact setup (bias -1.15, lr .25, 75 epochs, no shuffle, bias update x0.3)
A=Model(tokens_old,bias=-1.15).fit(old14,epochs=75,lr=0.25,shuffle=False,bias_scale=0.3)
B=Model(tokens_old,bias=-1.15).fit([(t,y) for t,y,_ in train],epochs=75,lr=0.25,shuffle=False,bias_scale=0.3)
print("TEST SET: 41 sentences never used for training. Scams in it:",sum(y for _,y,_ in test))
show("A  your model (14 samples)",A)
show("B  your algorithm + new 120-sample train",B)
