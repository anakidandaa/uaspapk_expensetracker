import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AccountListScreen extends StatelessWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Rekening")),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users').doc(uid).collection('transactions')
                .snapshots(),
            builder: (context, snapshot) {
              double totalAll = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  double amt = (data['amount'] ?? 0).toDouble();
                  totalAll += (data['type'] == 'Income' ? amt : -amt);
                }
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Saldo Keseluruhan", style: TextStyle(color: Colors.white)),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalAll),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid).collection('accounts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final accounts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final accountName = accounts[index]['name'];

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users').doc(uid).collection('transactions')
                          .where('account', isEqualTo: accountName)
                          .snapshots(),
                      builder: (context, trxSnapshot) {
                        double balance = 0;
                        if (trxSnapshot.hasData) {
                          for (var doc in trxSnapshot.data!.docs) {
                            final trx = doc.data() as Map<String, dynamic>;
                            double amt = (trx['amount'] ?? 0).toDouble();
                            balance += (trx['type'] == 'Income' ? amt : -amt);
                          }
                        }

                        return ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: Text(accountName),
                          subtitle: Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balance),
                            style: TextStyle(color: balance < 0 ? Colors.red : Colors.black54),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('users').doc(uid).collection('accounts')
                                .doc(accounts[index].id).delete(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, String uid) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Rekening Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Rekening")),
            TextField(controller: balanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Saldo Awal")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users').doc(uid).collection('accounts')
                    .add({'name': nameCtrl.text, 'created_at': Timestamp.now()});
                
                double initial = double.tryParse(balanceCtrl.text) ?? 0;
                if (initial != 0) {
                  await FirebaseFirestore.instance
                      .collection('users').doc(uid).collection('transactions')
                      .add({
                    'amount': initial.abs(),
                    'type': initial >= 0 ? 'Income' : 'Expense',
                    'account': nameCtrl.text,
                    'category': 'Saldo Awal',
                    'date': Timestamp.now(),
                    'note': 'Setoran awal rekening'
                  });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}