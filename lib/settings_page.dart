import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'category_list_screen.dart';
import 'account_list_screen.dart';
import 'excel_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text("Mode Gelap (Dark Mode)"),
          value: themeProvider.isDarkMode,
          onChanged: (v) => themeProvider.toggleTheme(),
        ),
        const Divider(),

        _menuItem(
          context,
          Icons.account_balance_wallet_outlined,
          "Manajemen Rekening",
          const AccountListScreen(),
        ),

        _menuItem(
          context,
          Icons.category_outlined,
          "Manajemen Kategori",
          const CategoryListScreen(),
        ),

        const Divider(),

        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text("Ekspor ke Excel (.xlsx)"),
          subtitle: const Text("Download seluruh riwayat transaksi"),
          onTap: () => ExcelService.exportTransactionsToExcel(),
        ),
      ],
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
