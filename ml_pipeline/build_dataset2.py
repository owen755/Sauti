# Batch 2: ~185 new hand-written sentences, written BEFORE looking at any model output on them.
# Aimed at: new scam families, weak spots found earlier, genuine "I'm sending you money" lines, bank warnings, Sheng.
import csv
S={}; H={}
S["parcel_customs_fee"]=[
"Kifurushi chako kutoka Uchina kimekwama forodhani, lipa elfu nne ya ushuru kwa namba hii ndipo kitolewe",
"Your DHL parcel is held at customs, pay Ksh 3,500 clearance fee on this Mpesa number to release it today",
"Tuna mzigo wako wa zawadi kutoka Marekani, tuma elfu tano ya kusafirisha kabla ya saa kumi",
"Parcel yako haiwezi kuletwa mpaka ulipe ada ya kuhifadhi elfu mbili kwa namba hii ya rider",
"A gift from your friend abroad is waiting, send the delivery tax to this number so we can deliver it",
"Mzigo wako uko Nairobi, lipa elfu moja mia tano ya posta kwanza kwa mpesa binafsi nikuletee"]
S["investment_crypto"]=[
"Wekeza elfu kumi leo upate elfu hamsini baada ya siku saba, hakuna hasara, tuma kwa namba hii",
"Join our forex group, deposit Ksh 5,000 and we double it in 48 hours guaranteed",
"Chama chetu cha uwekezaji kinalipa asilimia hamsini kwa wiki, jiunge sasa kwa kutuma elfu mbili kwa mpesa",
"Bitcoin mining inakulipa kila siku, weka elfu tatu kuanza, pesa yako itarudi mara mbili",
"Limited slots: invest now with Ksh 2,000 and withdraw Ksh 10,000 tomorrow, send to this till number",
"Biashara yetu ya mtandaoni haina hasara, tuma elfu ishirini ya kuanzia, faida ni uhakika",
"Naweza kukuonyesha siri ya kutajirika haraka, tuma elfu moja ya kozi kwa namba hii leo",
"Pyramid mpya, ukileta watu watatu unapata elfu kumi, jiandikishe kwa kulipa elfu mbili sasa"]
S["romance_abroad"]=[
"Habari mpenzi, niko Uingereza, nimekutumia zawadi, lipa elfu sita ya forodha ili ipokelewe",
"Darling I am stuck at the airport, please send Ksh 15,000 to this number and I will repay you when I land",
"Nakupenda sana, nina shida ya hospitali hapa ng'ambo, tuma elfu ishirini kwa mpesa usimwambie yeyote",
"My love my wallet was stolen, send me money for the ticket to this Mpesa number, I will come see you",
"Mpenzi nimekwama uwanja wa ndege, tuma elfu kumi ya ada ya kuondoka kwa namba hii, nitakulipa kesho"]
S["fake_landlord_rent"]=[
"Nyumba ya vyumba viwili Kilimani ni elfu kumi tu, tuma deposit ya elfu ishirini kwa mpesa kushika nafasi leo",
"Bedsitter inapatikana Roysambu, lipa kodi ya mwezi mmoja mapema kwa namba hii, funguo utapewa kesho",
"I am the agent, the apartment is available, send the booking fee of Ksh 5,000 before someone else takes it",
"Mwenye nyumba yuko nje ya nchi, tuma deposit kwa namba ya wakili wake, utapata funguo ukituma risiti",
"House for rent in Kitengela, pay viewing fee Ksh 1,000 on Mpesa first and I will send the address"]
S["fake_charity_harambee"]=[
"Tunakusanya pesa kwa ajili ya mtoto mgonjwa, tuma mchango wowote kwa namba hii binafsi sasa hivi",
"Pastor amesema tuma sadaka ya shukrani elfu tano kwa namba hii ili upate baraka na kazi wiki hii",
"Harambee ya dharura ya mazishi, tuma elfu mbili kwa namba hii ya mtu wa familia, usipigie mtu kuthibitisha",
"Support the orphans, send your donation to this personal number today, God will bless you",
"Mganga wetu atakusaidia kupata pesa, tuma elfu tatu ya kuanza matambiko kwa mpesa"]
S["fake_insurance_sha"]=[
"SHA imekuchagua kupokea fidia ya elfu thelathini, tuma elfu mbili ya usajili ili upokee",
"Your NHIF refund is ready, confirm your ID number and PIN to receive Ksh 20,000",
"Bima yako ya gari imeisha, lipa elfu nane kwa namba hii leo la sivyo utakamatwa barabarani",
"Insurance claim approved, pay the release fee of Ksh 4,000 to this number to get your payout",
"Mamlaka ya bima inakupigia, una malipo ya kurudishiwa, tupe namba ya siri ya mpesa kuyaweka"]
S["fake_kplc_water"]=[
"KPLC hapa, umeme wako utakatwa saa moja, nunua token ya elfu mbili kwa namba hii ya afisa wetu",
"Your electricity will be disconnected today, pay the arrears Ksh 6,500 to this personal number immediately",
"Afisa wa maji anasema una deni, lipa elfu tatu kwa namba hii sasa hivi ama tukate maji",
"Kenya Power inakupa punguzo la bili, tuma PIN yako ya mpesa kuthibitisha akaunti yako ya umeme"]
S["fake_loan_betting_app"]=[
"Pakua app hii upate mkopo wa papo hapo, lipa ada ya elfu moja kwanza kuamilisha",
"Your betting account has a free bonus of Ksh 20,000, deposit Ksh 1,000 to unlock withdrawal",
"Ushindi wako wa betting umefika elfu hamsini, lipa ada ya kutoa pesa elfu mbili kwa namba hii",
"Instant loan without papers, send the verification fee to this number and the loan lands in 5 minutes"]
S["mpesa_reversal_v2"]=[
"Samahani kaka, ile pesa niliyokutumia si yako, ni ya mama yangu anaumwa, tafadhali irudishe sasa hivi",
"Hallo, nimetuma elfu nane kwa number isiyo sahihi, naomba unirudishie, nitakupa shukrani",
"Please help me, I sent Ksh 12,000 to your number by mistake, reverse it now before my boss finds out",
"Ulipokea elfu tano kutoka kwangu? Ni kosa la kidole, tuma tena kwa namba hii ya rafiki yangu",
"Sir, my Mpesa has sent money to you wrongly, kindly return it to this number, I am in a hurry",
"Nimeona nimekutumia pesa ya kulipia kodi kimakosa, rudisha kabla mwenye nyumba hajafika",
"UCM8K2L1PQ Confirmed. You have received Ksh 9,000 from PETER OMONDI. Please return it, it was sent wrongly",
"Ujumbe wa mpesa umeingia kwenye simu yako, ile pesa ni ya mtu mwingine, tafadhali irudishe leo hii"]
S["fake_agent_pin_otp_v2"]=[
"Habari, naitwa Mary kutoka Safaricom, tumeona matatizo na line yako, tafadhali tuambie PIN ya Mpesa tuirekebishe",
"Hello sir, I am calling from KCB fraud team, someone is trying to withdraw from your account, give me the code that just came by SMS",
"Mteja wetu mpendwa, akaunti yako ya Mpesa imefungwa, bonyeza nambari yako ya siri ili kuifungua sasa",
"This is Safaricom, we are upgrading Mpesa, kindly confirm your PIN so you do not lose your balance",
"Tuko benki ya Equity, kadi yako imezuiwa, soma namba ya uthibitisho tuliyotuma ili tuifungue",
"Please enter your Mpesa PIN on the prompt we are sending, it is only a verification, do not hang up",
"Nakupigia kutoka makao makuu ya Safaricom, umechaguliwa kwa uboreshaji wa bure, tupe nambari yako ya siri",
"Your Equity account is compromised, to secure it tell me the one time password sent to your number now",
"Afisa wa Airtel hapa, tunarudisha pesa ulizokosea, weka PIN yako kwenye ujumbe utakaokuja",
"I am from the bank, I need you to confirm your ATM PIN and the three digits behind your card",
"Sasisho la usajili wa Mpesa linahitaji PIN yako, usikate simu hadi tumalize",
"Mteja, tunahitaji nambari uliyoipokea kwa SMS, ni ya usalama wako, tafadhali isome sasa"]
S["sheng_coercion"]=[
"Msee mtoi wako ameshikwa na ma-cop, tuma ngovo kwa hii number fast ama atakaa ndani",
"Boss kuna issue kubwa, ukiskia hii simu usiseme na mtu, tuma doo kwa namba hii sasa hivi",
"Maze mamako yuko hosi anakufa, tuma elfu tano kwa hii nambari ya doc, fanya haraka",
"Bro nimekwama sana, tuma mia tano ya fare kwa hii number mpya, nitakurudishia kesho",
"Wasee wa KRA wamekuja kwa duka lako, tuma elfu kumi kwa mimi niwatulize, usipigie mtu",
"Rafiki yako yuko cell, tuma pesa ya bail kwa hii namba ama atafungwa leo usiku",
"Mzae, pesa ya fee ya kijana iko kwa hii namba, tuma sasa ama atafukuzwa shule kesho",
"Fanya haraka tuma doo, kijana wako yuko hosi hawataki kumtreat bila deposit kwa namba hii"]
S["spoofed_mpesa_sms"]=[
"UBC91K3M2N Confirmed. You have received Ksh25,000.00 from ANN WAMBUI. Kindly reverse the amount sent in error to this number",
"Umepokea Ksh12,000 kutoka kwa JOHN. Tuma kwa namba hii 0711000000 kwa makosa, asante",
"MPESA Confirmed Ksh8,500 received. Reversal needed urgently, call me back on this number and do not delay",
"Ujumbe: Umetumiwa Ksh4,200. Tafadhali rudisha kwa namba ya mtumaji kabla ya saa mbili usiku",
"Your Fuliza has been repaid by mistake, return Ksh 3,000 to this number to avoid penalty",
"Pesa ya mkopo imeingia kwa makosa kwa akaunti yako, rudisha kwa namba hii ndani ya saa mbili"]
S["fake_employer_id"]=[
"Kampuni yetu imekuchagua kwa kazi, tupe nambari ya ID na PIN ya mpesa kwa malipo ya mshahara wa kwanza",
"HR hapa, to process your salary send us your Mpesa PIN and ID photo today",
"Umepata kazi serikalini, lipa elfu nne ya fomu kwa namba hii ili jina lako liingie kwenye orodha",
"Job confirmed, pay uniform and training fee Ksh 3,500 before Monday or the slot goes to someone else"]
S["lawyer_bail"]=[
"Mimi ni wakili wa kijana wako, amekamatwa, tuma elfu kumi na tano ya bail sasa usimwambie mtu",
"This is the court registrar, your brother has a case, send Ksh 20,000 to this number to avoid jail tonight",
"Wakili anasema pesa ya dhamana lazima ipitie kwa namba yake binafsi sasa hivi, usikate simu",
"Your daughter is detained at the station, pay the cash bail to this Mpesa number immediately",
"Hakimu ameamuru malipo ya faini elfu kumi na tano kwa mpesa binafsi leo la sivyo atafungwa"]
H["direction_money_safe"]=[
"Mama nitakutumia mpesa sasa hivi ya matumizi, angalia simu yako baada ya dakika tano",
"Nimekutumia elfu mbili ya chakula, umepokea? Niambie ukipata",
"I will send you the rent right now, just confirm your till number first",
"Baba nimetuma pesa ya ada jana, risiti ya benki nitakuletea kesho",
"Hey I am sending the 3000 now, check your phone and tell me when it lands",
"Dada nitakulipa deni lako kesho asubuhi nikipokea pesa, usiwe na wasiwasi",
"Shosh nimekutumia pesa ya zawadi ya harusi, kumbuka kuniambia ukipata",
"Nitakutumia fare sasa hivi, usitoke, nakupigia nikimaliza",
"Nimeshatuma elfu tano ya chama, mweka hazina amethibitisha ameipata",
"I just paid your invoice by Mpesa, please confirm and send me the receipt",
"Mtoto wangu nakutumia pesa ya shule sasa hivi, nitumie picha ya risiti ukilipa",
"Wacha nikutumie hela ya mkate sasa hivi, uko wapi?"]
H["real_landlord_utilities"]=[
"Mwenye nyumba anasema kodi ni ya tarehe tano, lipa kwa paybill ya jengo kama kawaida",
"Reminder: your rent is due on the 5th, please pay via the building paybill and keep the receipt",
"Fundi wa maji atakuja kesho saa nne, tafadhali kuwa nyumbani",
"Bili ya umeme ya mwezi huu ni elfu moja na mia nane, unaweza kulipa kupitia app ya KPLC",
"Landlord here, the water will be off on Saturday morning for repairs, sorry for the inconvenience",
"Naomba risiti ya kodi ya mwezi uliopita, nilipa kwa paybill na ujumbe haujafika"]
H["chama_church_genuine"]=[
"Mchango wa harusi ya Jane unaendelea, lipa kwa paybill rasmi ya kanisa iliyo kwenye tangazo",
"Kikao cha chama kesho saa nane, kila mwanachama alete mchango wake wa mwezi",
"The church building fund account number is on the notice board, please pay at the bank or the official paybill",
"Asante kwa mchango wako, tumepokea na tutatoa risiti jumapili",
"Mazishi ni Jumamosi, tutakutana kwa nyumba ya marehemu saa tatu asubuhi",
"Treasurer here, please send the monthly contribution to the usual group number and post the message in the group"]
H["genuine_gov_info"]=[
"NTSA: renew your licence on eCitizen, we never ask for payments on personal numbers",
"KRA inakukumbusha tarehe ya mwisho ya kuwasilisha ripoti ya kodi ni tarehe thelathini, tumia iTax rasmi",
"Your Huduma Namba is ready for collection at the nearest Huduma Centre, bring your ID",
"Wizara ya elimu inatangaza matokeo yatatoka Ijumaa, angalia kwenye tovuti rasmi",
"The county office confirms your business permit is ready, you can pay at the revenue office or via the official paybill",
"Police: if anyone calls asking for money to release a relative, hang up and visit the station"]
H["genuine_courier"]=[
"Hello, this is G4S courier, your parcel is at the office, please come with your ID before 5pm",
"Dereva wa Sendy hapa, niko mlangoni na mzigo wako, tafadhali toka nje",
"Your Jumia order has been delivered, thank you for shopping with us",
"Mzigo wako umefika stage, malipo ya usafiri uliyokubaliana ni mia tatu, utanilipa ukichukua",
"DHL: your shipment is out for delivery today, no payment is required, please keep your phone on",
"Posta imekutumia ujumbe, kifurushi kiko ofisini, hakuna ada ya ziada"]
H["genuine_loan_reminder"]=[
"Salamu, hii ni M-Shwari, deni lako litaisha tarehe kumi, unaweza kulipa kupitia app rasmi",
"Your Fuliza balance is Ksh 500, repay through Mpesa when you receive your next income",
"Sacco yako inakukumbusha kikao cha wanachama kitakuwa Jumamosi, hakuna malipo ya ziada",
"Your loan statement is available in the app, no action needed, thank you for banking with us",
"Tunakupongeza kwa kulipa mkopo wako kwa wakati, kikomo chako kimeongezeka kupitia app",
"Hustler Fund: repay your loan via the official paybill, we will never ask you for your PIN"]
H["bank_telco_fraud_warning"]=[
"Sisi hatukuombi PIN wala OTP kwa simu, ukipigiwa na mtu anayeomba, kata simu na utuite kupitia namba rasmi",
"Beware of fraudsters, never share your PIN, OTP or card details with anyone on a call",
"Tafadhali usitume pesa kwa namba binafsi ukidai ni ya benki, tumia paybill rasmi pekee",
"KCB will never call you to ask for your PIN, if someone does, report it on our hotline",
"Ukipata ujumbe wa kuomba PIN yako, usijibu, na ripoti kwa Safaricom kupitia 333",
"Safaricom reminds customers that Mpesa reversals are only done through 456, never through personal calls",
"Equity yaonya wateja dhidi ya matapeli wanaojifanya wafanyakazi wa benki, usitoe taarifa zako",
"Do not respond to messages asking you to reverse money to a personal number, forward them to 333"]
H["hr_genuine"]=[
"HR hapa, mkataba wako uko tayari, uje ofisini kuusaini ukiwa na ID yako",
"Your payslip for this month is ready on the staff portal, no action needed",
"Mkutano wa wafanyakazi ni kesho saa tatu, tafadhali usichelewe",
"Congratulations on your interview, we will send an offer letter by email, there is no fee at any stage",
"Kampuni haitozi pesa yoyote kwa waombaji wa kazi, ripoti mtu yeyote anayeomba pesa"]
H["hospital_billing_insurance"]=[
"Bili yako ya hospitali ni elfu kumi na mbili, tafadhali ulipe kwa paybill rasmi kwenye ankara uliyopewa",
"SHA imekubali matibabu ya mama yako, hakuna malipo ya ziada, tafadhali leta kitambulisho",
"Your insurance has approved the claim, the hospital will bill them directly, you do not need to pay anything now",
"Daktari ameagiza apumzike nyumbani wiki mbili, tutakupa dawa na tarehe ya kurudi",
"The ambulance is on the way to the school, please meet us at the hospital reception",
"Mgonjwa amehamishwa wodi ya kawaida, unaweza kumtembelea saa nane hadi kumi",
"Mtoto wako yuko sawa, tulimpa dawa ya homa, uje umchukue ukiwa tayari",
"Please do not send money to anyone claiming to be a doctor, payments are only at the hospital cashier"]
H["casual_sheng"]=[
"Niaje msee, leo kuna game ya Gor, tutaenda kuangalia kwa mtaa saa nane",
"Mambo vipi, nimefika job, tutaongea nikitoka, niko na kazi nyingi",
"Maze nimechoka sana leo, foleni ya Mombasa Road ilikuwa mbaya",
"Bro tuonane wikendi, nitakuletea ile kitabu ulikuwa unataka",
"Wasee wa campus wanasema exam imesogezwa hadi Alhamisi",
"Kijana nimeamka late, nikufikie baada ya lunch tuongee",
"Rada ya bro, kuja kesho saa nne tuende kwa mechi",
"Nipigie usiku nikiwa free, leo niko busy na mambo ya ofisi",
"Shosh tutakutana kwa mall ama?, niko na sh elfu moja ya kununua zawadi",
"Hii wiki imekuwa ndefu, wikendi nitapumzika tu nyumbani"]
H["mpesa_chatter_genuine"]=[
"Umepokea pesa niliyotuma? Niliandika namba yako vizuri, hakikisha kwenye ujumbe wa mpesa",
"I got your Mpesa message, thanks, the balance is fine, no need to send anything else",
"Pesa ya mboga ni mia nane, nimeituma kwa till ya duka, risiti ipo",
"Nimepokea elfu mbili uliyonitumia, asante sana, nitakupigia jioni",
"Mpesa imekataa kutuma, mtandao ni mbaya, nitajaribu tena baadaye",
"I paid the school fees through the official paybill, the account number was the admission number",
"Asante kwa kulipia mboga, nimepata ujumbe wa mpesa, kila kitu sawa",
"Please check your Mpesa statement, I think I paid twice, if so I will ask the shop to refund me in cash"]
H["telco_genuine_v2"]=[
"Safaricom: Bundles za Tunukiwa zimeisha, nunua zaidi kupitia *544# au app ya My Safaricom",
"Hello, this is Airtel customer care, we are calling to confirm your network complaint was resolved, no action needed",
"Usajili wa line yako umekamilika, asante kwa kutumia Safaricom",
"Your Mpesa statement for the month has been sent to your email address",
"Safaricom inakuarifu kuwa huduma ya Mpesa itakuwa chini kwa matengenezo Jumapili usiku",
"Telkom: your data bundle will expire tomorrow, top up via the app"]
H["general_asks_safe"]=[
"Tafadhali tuma ripoti kabla ya saa kumi, ni haraka kidogo, mteja anasubiri",
"Send me the address of the venue now, we are leaving in ten minutes",
"Naomba unitumie namba ya mama, nimepoteza simu yangu ya zamani",
"Please confirm you have received the documents by email and call me back today",
"Kuja haraka nyumbani, kuna wageni wamefika na wanakungoja",
"Don't forget to call your mother today, she was asking about you",
"Usisahau kulipa ada ya shule kwa paybill rasmi kabla ya mwisho wa mwezi",
"Tafadhali nipigie, nahitaji kuongea nawe kuhusu mkutano wa kesho"]
new=[(t,1,c) for c,l in S.items() for t in l]+[(t,0,c) for c,l in H.items() for t in l]
old=list(csv.reader(open("out/dataset_v1.csv",encoding="utf-8")))[1:]
old=[(t,int(y),c) for t,y,c in old]
alltxt=[t for t,_,_ in old]
assert not any(t in alltxt for t,_,_ in new),"overlap with v1"
assert len({t for t,_,_ in new})==len(new),"dupes in new"
for t,_,_ in new: assert '"' not in t and '$' not in t and '\\' not in t, t
for name,rows in (("dataset_v2_new",new),("dataset",old+new)):
    with open(f"out/{name}.csv","w",newline="",encoding="utf-8") as f:
        w=csv.writer(f); w.writerow(["text","label","category"]); w.writerows(rows)
print("new:",len(new),"scam",sum(y for _,y,_ in new),"safe",sum(1-y for _,y,_ in new),"| merged total:",len(old)+len(new))
