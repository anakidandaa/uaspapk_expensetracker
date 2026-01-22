import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Kategori"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), 
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(uid).collection('categories')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada kategori."));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: Text(data['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, uid, docs[index].id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategoryDialog(context, uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCategoryDialog(BuildContext context, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Kategori"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Misal: Makan, Gaji, Listrik")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users').doc(uid).collection('categories')
                    .add({'name': controller.text, 'created_at': Timestamp.now()});
                if (context.mounted) Navigator.pop(context); }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kategori?"),
        content: const Text("Yakin ingin menghapus kategori ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).collection('categories').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}