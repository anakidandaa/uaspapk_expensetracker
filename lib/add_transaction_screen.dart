import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'Income';
  String? _selectedAccount;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // FUNGSI UTAMA: Simpan Transaksi ke Database
  Future<void> _saveTransaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null ||
        _amountCtrl.text.isEmpty ||
        _selectedAccount == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi data!")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add({
            'amount': double.parse(_amountCtrl.text),
            'type': _type,
            'account': _selectedAccount,
            'category': _selectedCategory,
            'note': _noteCtrl.text,
            'date': Timestamp.fromDate(_selectedDate),
            'created_at': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Berhasil Masuk Database!")),
        );
        _amountCtrl.clear();
        _noteCtrl.clear();
      }
    } catch (e) {
      print("Error simpan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Income', label: Text("Pendapatan")),
                ButtonSegment(value: 'Expense', label: Text("Pengeluaran")),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nominal",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              "accounts",
              "Pilih Rekening",
              (v) => setState(() => _selectedAccount = v),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              "categories",
              "Pilih Kategori",
              (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (p != null) setState(() => _selectedDate = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Tanggal",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: "Catatan (Opsional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text("SIMPAN TRANSAKSI"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String col, String hint, Function(String?) fn) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(col)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var items = snapshot.data!.docs
            .map((d) => d['name'].toString())
            .toList();
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: fn,
        );
      },
    );
  }
}
