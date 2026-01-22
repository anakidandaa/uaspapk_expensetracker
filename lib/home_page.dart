import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_list_screen.dart'; 
import 'add_transaction_screen.dart'; 
import 'summary_screen.dart';
import 'settings_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;


  final List<Widget> _pages = [
    const TransactionListScreen(),
    const AddTransactionScreen(),
    const SummaryScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ExpenseTracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        iconSize: 28, 
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), 
            label: "Transaksi"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), 
            label: "Tambah"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline), 
            label: "Summary"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: "Settings"
          ),
        ],
      ),
    );
  }
}