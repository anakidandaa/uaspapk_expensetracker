import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditTransactionScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditTransactionScreen({super.key, required this.docId, required this.currentData});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedType;
  String? _selectedAccount;
  String? _selectedCategory;
  late DateTime _selectedDate;

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.currentData['amount'].toString());
    _noteController = TextEditingController(text: widget.currentData['note'] ?? "");
    _selectedType = widget.currentData['type'];
    _selectedAccount = widget.currentData['account'];
    _selectedCategory = widget.currentData['category'];
    _selectedDate = (widget.currentData['date'] as Timestamp).toDate();
  }

  Future<void> _updateTransaction() async {
    if (_amountController.text.isEmpty || _selectedAccount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi data!")));
      return;
    }

    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('transactions').doc(widget.docId)
        .update({
      'amount': int.parse(_amountController.text),
      'type': _selectedType,
      'account': _selectedAccount,
      'category': _selectedCategory,
      'note': _noteController.text,
      'date': _selectedDate,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Perubahan Disimpan!"), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Transaksi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Income', label: Text("Pemasukan"), icon: Icon(Icons.download)),
                ButtonSegment(value: 'Expense', label: Text("Pengeluaran"), icon: Icon(Icons.upload)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newVal) => setState(() => _selectedType = newVal.first),
            ),
            const SizedBox(height: 20),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nominal", prefixText: "Rp ", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            _buildDropdown("accounts", "Pilih Rekening", (val) => setState(() => _selectedAccount = val), _selectedAccount),
            const SizedBox(height: 16),
            _buildDropdown("categories", "Pilih Kategori", (val) => setState(() => _selectedCategory = val), _selectedCategory),
            const SizedBox(height: 16),
            ListTile(
              title: Text("Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: "Catatan (Opsional)", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _updateTransaction, child: const Text("UPDATE TRANSAKSI"))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String collection, String hint, Function(String?) onChanged, String? currentVal) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final items = snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
        return DropdownButtonFormField<String>(
          value: items.contains(currentVal) ? currentVal : null,
          decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}