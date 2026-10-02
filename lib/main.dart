import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CasaNostraApp());
}

class CasaNostraApp extends StatelessWidget {
  const CasaNostraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa Nostra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  String? familyId;
  bool isLoading = true;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('family_id');
    if (savedId != null) {
      setState(() {
        familyId = savedId;
        isLoading = false;
      });
    } else {
      await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveFamilyId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_id', id.toUpperCase().trim());
    setState(() {
      familyId = id.toUpperCase().trim();
    });
  }

  String _generateCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    return List.generate(8, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Casa Nostra')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏠 Casa Nostra', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Organizer Familiare Cloud', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  String newCode = _generateCode();
                  _saveFamilyId(newCode);
                },
                child: const Text('Crea Nuova Famiglia'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Codice Famiglia (8 caratteri)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  if (_codeController.text.trim().length >= 6) {
                    _saveFamilyId(_codeController.text);
                  }
                },
                child: const Text('Entra con Codice'),
              ),
            ],
          ),
        ),
      );
    }

    return MainHomeScreen(familyId: familyId!);
  }
}

// --- SCHERMATA PRINCIPALE ---
class MainHomeScreen extends StatefulWidget {
  final String familyId;
  const MainHomeScreen({super.key, required this.familyId});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      LoyaltyCardsTab(familyId: widget.familyId),
      const PlaceholderTab(title: 'Liste Spesa'),
      const PlaceholderTab(title: 'Agenda Familiare'),
      SettingsTab(familyId: widget.familyId),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Fedeltà'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Liste'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Altro'),
        ],
      ),
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  final String title;
  const PlaceholderTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Sezione $title in arrivo...', style: const TextStyle(fontSize: 18))),
    );
  }
}

// --- SEZIONE CARTE FEDELTÀ ---
class LoyaltyCardsTab extends StatelessWidget {
  final String familyId;
  const LoyaltyCardsTab({super.key, required this.familyId});

  void _showAddCardDialog(BuildContext context) {
    final TextEditingController storeController = TextEditingController();
    final TextEditingController ownerController = TextEditingController();
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Carta Fedeltà'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: storeController,
                  decoration: const InputDecoration(labelText: 'Nome Negozio (es. Conad)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(labelText: 'Intestatario (es. Mario)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Codice a barre / Numero'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (storeController.text.isNotEmpty && codeController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('families')
                      .doc(familyId)
                      .collection('loyalty_cards')
                      .add({
                    'store': storeController.text.trim(),
                    'owner': ownerController.text.trim(),
                    'code': codeController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showCardBarcode(BuildContext context, String store, String code, String owner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(store),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (owner.isNotEmpty) Text('Titolare: $owner', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mostra questo codice in cassa', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte Fedeltà')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('loyalty_cards')
            .orderBy('store')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessuna carta salvata. Tocca "+" per aggiungere.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final cardId = docs[index].id;
              final store = data['store'] ?? '';
              final owner = data['owner'] ?? '';
              final code = data['code'] ?? '';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(store, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(owner.isNotEmpty ? '$owner • $code' : code),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('families')
                          .doc(familyId)
                          .collection('loyalty_cards')
                          .doc(cardId)
                          .delete();
                    },
                  ),
                  onTap: () => _showCardBarcode(context, store, code, owner),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- IMPOSTAZIONI ---
class SettingsTab extends StatelessWidget {
  final String familyId;
  const SettingsTab({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Codice Famiglia Attivo'),
              subtitle: Text(familyId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Esci dalla Famiglia'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('family_id');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}