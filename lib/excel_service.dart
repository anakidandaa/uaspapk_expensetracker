import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExcelService {
  static Future<void> exportTransactionsToExcel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];

  
    sheet.appendRow([
      TextCellValue("Tanggal"),
      TextCellValue("Jenis"),
      TextCellValue("Kategori"),
      TextCellValue("Rekening"),
      TextCellValue("Nominal"),
      TextCellValue("Catatan"),
    ]);

   
    for (var doc in snapshot.docs) {
      final d = doc.data();
      final date = (d['date'] as Timestamp).toDate();

      sheet.appendRow([
        TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(date)),
        TextCellValue(d['type'] ?? ""),
        TextCellValue(d['category'] ?? ""),
        TextCellValue(d['account'] ?? ""),
        IntCellValue(d['amount'] ?? 0),
        TextCellValue(d['note'] ?? ""),
      ]);
    }

 
    final bytes = excel.encode();

    if (bytes == null) return;

    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
          "download",
          "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
