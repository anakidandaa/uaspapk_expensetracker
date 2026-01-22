import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'start_page.dart';
import 'transaction_list_screen.dart';
import 'add_transaction_screen.dart';
import 'summary_screen.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const StartPage(); 
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

 
  final List<String> _titles = [
    "Riwayat Transaksi",
    "Tambah Transaksi",
    "Statistik Keuangan",
    "Pengaturan",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       
        title: (_currentIndex == 0 && _isSearching)
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Cari kategori atau catatan...",
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              )
            : Text(_titles[_currentIndex]),
        elevation: 0,
        actions: [
        //icon cari di index 
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQuery = "";
                    _searchController.clear();
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
     
      body: _buildBody(), 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _isSearching = false; 
            _searchQuery = "";
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: "Transaksi"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Tambah"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: "Summary"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }

 
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return TransactionListScreen(searchQuery: _searchQuery); 
      case 1:
        return const AddTransactionScreen();
      case 2:
        return const SummaryScreen();
      case 3:
        return const SettingsPage();
      default:
        return TransactionListScreen(searchQuery: _searchQuery);
    }
  }
}