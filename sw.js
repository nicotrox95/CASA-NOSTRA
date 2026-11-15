const C='cn7',PRE=['./','index.html','manifest.webmanifest','icon-192.png','apple-touch-icon.png'],
 EXT=['https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js','https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js','https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js','https://cdnjs.cloudflare.com/ajax/libs/jsbarcode/3.11.6/JsBarcode.all.min.js','https://cdnjs.cloudflare.com/ajax/libs/qrcode-generator/1.4.4/qrcode.min.js'];
async function grab(c,u,seen){if(seen.has(u))return;seen.add(u);const r=await fetch(u,{mode:'cors'}).catch(()=>null);if(!r||!r.ok)return;await c.put(u,r.clone());if(!u.endsWith('.js'))return;const t=await r.text();
 for(const m of t.matchAll(/(?:from|import)\s*\(?\s*["']([^"']+)["']/g)){const n=m[1];if(n.startsWith('.')||n.startsWith('https://www.gstatic.com'))await grab(c,new URL(n,u).href,seen)}}
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(async c=>{await Promise.all(PRE.map(u=>c.add(u).catch(()=>{})));const seen=new Set();await Promise.all(EXT.map(u=>grab(c,u,seen)))}))});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))).then(()=>clients.claim())));
const put=(r,x)=>{if(x.ok){const y=x.clone();caches.open(C).then(c=>c.put(r,y))}return x};
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
 if(u.origin===location.origin){const cached=()=>caches.match(r,{ignoreSearch:true}).then(m=>m||caches.match('index.html'));
  e.respondWith(Promise.race([fetch(r).then(x=>put(r,x)),new Promise((_,j)=>setTimeout(j,4000))]).catch(cached))}
 else if(/(^|\.)gstatic\.com$|^cdnjs\.cloudflare\.com$/.test(u.hostname)&&/\.js$/.test(u.pathname)){e.respondWith(caches.match(r).then(m=>m||fetch(r).then(x=>put(r,x))))}});
