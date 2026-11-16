process.env.TZ='Europe/Rome';
const mail=process.env.GMAIL_USER&&process.env.GMAIL_APP_PASSWORD?require('nodemailer').createTransport({service:'gmail',auth:{user:process.env.GMAIL_USER,pass:process.env.GMAIL_APP_PASSWORD}}):null;
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))});
const db=admin.firestore(),hr=new Date().getHours();
if((hr<7||hr>=22)&&!process.env.FORCE){console.log('Fuori orario: nessun invio');process.exit(0)}
const days=d=>Math.ceil((new Date(d.length>10?d:d+'T00:00')-Date.now())/864e5);
const fmt=d=>new Date(d.length>10?d:d+'T12:00').toLocaleDateString('it-IT',{day:'numeric',month:'short',year:'numeric'});
const STD={salute:'🩺',manut:'🛠️',giar:'🌿',gar:'🧰',bimbi:'🧒'};
(async()=>{
 for(const f of await db.collection('families').listDocuments()){
  const [is,ts,cs,ss]=await Promise.all([f.collection('items').get(),f.collection('tokens').get(),f.collection('cfg').doc('main').get(),f.collection('cfg').doc('sent').get()]);
  if(ts.empty&&!mail)continue;
  const items=is.docs.map(d=>({id:d.id,...d.data()})),hid=(cs.data()||{}).hidden||[],sent=ss.exists?ss.data():{},out=[];
  const veh=Object.fromEntries(items.filter(i=>i.m==='veic').map(v=>[v.id,v.t]));
  const add=(k,title,body)=>{if(!sent[k]){sent[k]=1;out.push({title,body,k})}};
  const dl=(i,t,w,per=7)=>{const n=days(i.d);if(n===null)return;
   const b=n<0?(w?'⚠️ Scaduto da '+(-n)+' giorni: aggiorna la scadenza':'⚠️ È scaduto!'):n===0?'⏰ Scade oggi!':'Scade tra '+n+' giorni ('+fmt(i.d)+')';
   if(w){if(n>w)return;add(i.id+':'+i.d+':'+(n===0?'z':Math.floor((w-n)/per)),t,b)}
   else{if(n>30)return;add(i.id+':'+i.d+':'+(n<=0?0:n<=5?5:n<=15?15:30),t,b)}};
  for(const i of items){
   if(i.done||!i.d||hid.includes(i.m==='vsc'?'veic':i.m))continue;
   if(i.m==='doc')dl(i,'🪪 '+i.k+(i.who?' · '+i.who:''),180,30);
   else if(i.m==='vsc')dl(i,'🚗 '+(veh[i.veh]?veh[i.veh]+' · ':'')+i.k,30);
   else if(STD[i.m])dl(i,STD[i.m]+' '+(i.t||i.k||i.who),0);
   else if(i.m==='turni'||i.m==='agenda'){const ev=new Date(i.d.length>10?i.d:i.d+'T00:00'),dd=Math.round((new Date(ev).setHours(0,0,0,0)-new Date().setHours(0,0,0,0))/864e5),ti=i.m==='turni'?'🕒 Turno'+(i.who?' · '+i.who:'')+(i.t?' '+i.t:''):'📅 '+i.t,k=i.id+':'+i.d+':p';
    if(dd===1&&hr>=10&&hr<20)add(k+'1',ti,'Domani — '+fmt(i.d));
    if(dd===1&&hr>=20)add(k+'2',ti,'Promemoria serale: domani — '+fmt(i.d));
    if(dd===0&&(i.m==='turni'||ev>Date.now())&&!sent[k+'1']&&!sent[k+'2'])add(k+'0',ti,'Oggi — '+fmt(i.d))}
  }
  const ids=new Set(items.map(i=>i.id));for(const k of Object.keys(sent))if(!ids.has(k.split(':')[0]))delete sent[k];
  if(out.length){
   let ok=false;
   if(mail){try{const ms=await f.collection('members').listDocuments(),us=await admin.auth().getUsers(ms.map(d=>({uid:d.id}))),bcc=us.users.map(u=>u.email).filter(Boolean);
     if(bcc.length){await mail.sendMail({from:'Casa Nostra <'+process.env.GMAIL_USER+'>',to:process.env.GMAIL_USER,bcc:bcc.join(','),subject:'🏠 Casa Nostra: '+out.length+(out.length===1?' promemoria':' promemoria'),text:out.map(o=>o.title+'\n   '+o.body).join('\n\n')+'\n\n— Casa Nostra'});ok=true;console.log('Email inviata a',bcc.length)}}catch(e){console.log('Errore email',e.message)}}
   const toks=ts.docs.map(d=>({ref:d.ref,token:d.data().token}));
   for(const o of out)for(const t of toks){try{await admin.messaging().send({token:t.token,data:{title:o.title,body:o.body,tag:o.k},webpush:{headers:{Urgency:'high',TTL:'86400'}}});ok=true;console.log('Inviata:',o.title)}catch(e){console.log('Errore invio',e.code);if(/not-registered|invalid-argument|invalid-registration/.test(e.code||''))await t.ref.delete().catch(()=>{})}}
   if(!ok)out.forEach(o=>delete sent[o.k]);
  }
  await f.collection('cfg').doc('sent').set(sent);
 }
})().catch(e=>{console.error(e);process.exit(1)});
