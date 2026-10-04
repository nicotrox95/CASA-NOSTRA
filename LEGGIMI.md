# Casa Nostra – installazione gratuita (≈10 minuti)
1. console.firebase.google.com → Aggiungi progetto (piano Spark, gratis).
2. Build → Authentication → Inizia → abilita "Email/password" e "Google".
3. Build → Firestore Database → Crea (modalità produzione) → scheda Regole → incolla `firestore.rules` → Pubblica.
4. Impostazioni progetto → Le tue app → Web (</>) → copia `firebaseConfig` e incollalo in `index.html` al posto di CONFIG.
5. Hosting: `npm i -g firebase-tools && firebase login && firebase init hosting` (cartella pubblica = questa) → `firebase deploy`. In alternativa trascina la cartella su netlify.com/drop.
6. Authentication → Impostazioni → Domini autorizzati: aggiungi il tuo dominio.
7. Android: Chrome → Installa app. iOS: Safari → Condividi → Aggiungi a Home.
Sicurezza consigliata: attiva Firebase App Check e un budget alert; non salvare numeri di documento o PIN nelle note.
