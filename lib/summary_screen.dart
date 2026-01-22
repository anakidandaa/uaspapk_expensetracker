import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _viewDate = DateTime.now();
  String _selectedType = 'Expense'; // Default: Pengeluaran
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime(_viewDate.year, _viewDate.month, 1);
    DateTime lastDay = DateTime(_viewDate.year, _viewDate.month + 1, 0, 23, 59, 59);

    return Scaffold(
      body: Column(
        children: [
     
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(DateFormat('MMMM yyyy').format(_viewDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Income', label: Text("Pendapatan"), icon: Icon(Icons.trending_up)),
                ButtonSegment(value: 'Expense', label: Text("Pengeluaran"), icon: Icon(Icons.trending_down)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newVal) => setState(() => _selectedType = newVal.first),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid).collection('transactions')
                  .where('date', isGreaterThanOrEqualTo: firstDay)
                  .where('date', isLessThanOrEqualTo: lastDay)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data?.docs ?? [];
                
             
                Map<String, double> categoryData = {};
                double totalAmount = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                
                  if (data['type'] == _selectedType) {
                    String cat = data['category'] ?? "Lainnya";
                    double amt = (data['amount'] ?? 0).toDouble();
                    categoryData[cat] = (categoryData[cat] ?? 0) + amt;
                    totalAmount += amt;
                  }
                }

                if (totalAmount == 0) {
                  return Center(child: Text("Tidak ada data ${_selectedType == 'Income' ? 'Pendapatan' : 'Pengeluaran'} untuk bulan ini."));
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                     
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _generateSections(categoryData, totalAmount),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Text(
                        _selectedType == 'Income' ? "Detail Pendapatan" : "Detail Pengeluaran", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      const Divider(),

                     
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryData.length,
                        itemBuilder: (context, index) {
                          String key = categoryData.keys.elementAt(index);
                          double val = categoryData[key]!;
                          double percentage = (val / totalAmount) * 100;

                          return ListTile(
                            leading: Icon(Icons.circle, color: _getColor(index)),
                            title: Text(key),
                            subtitle: Text("${percentage.toStringAsFixed(1)}%"),
                            trailing: Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, double> data, double total) {
    int index = 0;
    return data.entries.map((entry) {
      return PieChartSectionData(
        color: _getColor(index++),
        value: entry.value,
        title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
        radius: 50.0,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getColor(int index) {
    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber];
    return colors[index % colors.length];
  }
}