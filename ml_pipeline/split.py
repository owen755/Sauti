from sklearn.model_selection import train_test_split
from scam_lib import load
def get_split(seed=7):
    d=load(); cats=[c for _,_,c in d]
    trainval,test=train_test_split(d,test_size=0.2,stratify=cats,random_state=seed)
    cats2=[c for _,_,c in trainval]
    train,val=train_test_split(trainval,test_size=0.25,stratify=cats2,random_state=seed)
    return train,val,test,trainval
if __name__=="__main__":
    tr,va,te,tv=get_split()
    for n,s in [("train",tr),("val",va),("test",te)]:
        print(n,len(s),"scam",sum(y for _,y,_ in s))
