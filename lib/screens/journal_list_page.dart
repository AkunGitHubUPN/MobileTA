import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'add_journal_page.dart';
import 'journal_detail_page.dart';

// Ganti nama class menjadi JournalListPage
class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => JournalListPageState();
}

class JournalListPageState extends State<JournalListPage> {
  List<Map<String, dynamic>> _journals = [];
  final dbHelper = DatabaseHelper.instance;

  void _loadJournals() async {
    final data = await dbHelper.getAllJournals();
    setState(() {
      _journals = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  // Fungsi untuk dipanggil dari luar (oleh HomePage)
  void refreshJournals() {
    _loadJournals();
  }

  @override
  Widget build(BuildContext context) {
    // Kita HAPUS Scaffold di sini, karena Scaffold-nya
    // akan disediakan oleh HomePage
    return _journals.isEmpty
        ? const Center(
            child: Text('Belum ada jurnal. Tekan + untuk menambah.'),
          )
        : ListView.builder(
            itemCount: _journals.length,
            itemBuilder: (context, index) {
              final journal = _journals[index];
              // Ubah subtitle untuk menampilkan lokasi (jika ada)
              String subtitle = journal[DatabaseHelper.columnTanggal];
              if (journal[DatabaseHelper.columnLatitude] != null) {
                subtitle += " (Lokasi tersimpan)";
              }

              return ListTile(
                title: Text(journal[DatabaseHelper.columnJudul]),
                subtitle: Text(subtitle),
                onTap: () {
                  // Navigasi ke halaman detail jurnal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalDetailPage(journalId: journal[DatabaseHelper.columnId]),
                    ),
                  );
                },
              );
            },
          );
  }
}