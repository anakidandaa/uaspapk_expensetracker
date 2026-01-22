import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatefulWidget {
  final String searchQuery;

  const TransactionListScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTime _viewDate = DateTime.now();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime(_viewDate.year, _viewDate.month, 1);
    DateTime lastDay =
        DateTime(_viewDate.year, _viewDate.month + 1, 0, 23, 59, 59);

    return Column(
      children: [
        //filter perbulan
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_viewDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ),

       
        _buildHeaderSummary(firstDay, lastDay),

        const Divider(height: 1),

        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('transactions')
                .where('date', isGreaterThanOrEqualTo: firstDay)
                .where('date', isLessThanOrEqualTo: lastDay)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final category =
                    (data['category'] ?? "").toString().toLowerCase();
                final note = (data['note'] ?? "").toString().toLowerCase();

                return category.contains(widget.searchQuery) ||
                    note.contains(widget.searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("Tidak ada transaksi ditemukan."),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final isIncome = data['type'] == 'Income';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      data['category'] ?? "General",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "${data['account']} • ${DateFormat('dd/MM').format((data['date'] as Timestamp).toDate())}",
                    ),

                  
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(data['amount']),
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  
  Widget _buildHeaderSummary(DateTime start, DateTime end) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .snapshots(),
      builder: (context, snapshot) {
        double income = 0;
        double expense = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;

            if (d['type'] == 'Income') {
              income += d['amount'];
            } else {
              expense += d['amount'];
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pemasukan",
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: '',
                      decimalDigits: 0,
                    ).format(income),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pengeluaran",
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    "-${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(expense)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(income - expense),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
