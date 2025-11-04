import 'package:flutter/material.dart';
import 'journal_list_page.dart';
import 'map_page.dart';
import 'add_journal_page.dart';
import 'utilities_page.dart';
import 'settings_page.dart';
import 'home_tab_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Indeks tab yang aktif

  final GlobalKey<HomeTabPageState> _homeKey = GlobalKey();

  // Daftar halaman/tab kita
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTabPage(key: _homeKey),
      const UtilitiesPage(),
      const SettingsPage(),
    ];
  }

  // Fungsi untuk pindah tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_selectedIndex == 0 ? 'Daftar Jejak' : 'Peta Jejak'),
      // ),
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // Tombol + (FAB)
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.add),
      //   onPressed: () async {
      //     await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const AddJournalPage()),
      //     );

      //     _listKey.currentState?.refreshJournals();
      //     _mapKey.currentState?.refreshMarkers();
      //   },
      // ),

      // Navigasi Tab di Bawah
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Wajib untuk 3+ item
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Utilitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
