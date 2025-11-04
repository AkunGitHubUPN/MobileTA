import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk filter angka
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class UtilitiesPage extends StatefulWidget {
  const UtilitiesPage({super.key});

  @override
  State<UtilitiesPage> createState() => _UtilitiesPageState();
}

class _UtilitiesPageState extends State<UtilitiesPage> {
  // --- LOGIKA KONVERTER MATA UANG ---
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  String _conversionResult = "Hasil: -";
  Map<String, double> _rates = {}; // Menyimpan kurs
  bool _isConverting = false;

  // Daftar mata uang
  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY', 'GBP'];

  // --- LOGIKA JAM DUNIA (CUSTOM & OFFLINE) ---

  // 1. Database mini zona waktu
  final Map<String, int> _allTimezones = {
    // Benua Amerika
    'San Francisco (UTC-8)': -8,
    'Chicago (UTC-6)': -6,
    'New York (UTC-5)': -5,
    'Buenos Aires (UTC-3)': -3,
    'Sao Paulo (UTC-3)': -3,
    // Benua Eropa & Afrika
    'London (UTC+0)': 0,
    'Berlin (UTC+1)': 1,
    'Paris (UTC+1)': 1,
    'Kairo (UTC+2)': 2,
    'Moskow (UTC+3)': 3,
    'Istanbul (UTC+3)': 3,
    // Timur Tengah & Asia
    'Dubai (UTC+4)': 4,
    'Jakarta (WIB | UTC+7)': 7,
    'Makassar (WITA | UTC+8)': 8,
    'Jayapura (WIT | UTC+9)': 9,
    'Shanghai (UTC+8)': 8,
    'Singapura (UTC+8)': 8,
    'Tokyo (UTC+9)': 9,
    'Seoul (UTC+9)': 9,
    // Australia
    'Perth (UTC+8)': 8,
    'Sydney (UTC+10)': 10,
    'Auckland (UTC+12)': 12,
  };

  // 2. Variabel untuk timer
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  // 3. Format baru (tanpa detik)
  final _timeFormat = DateFormat('HH:mm');
  // 4. Daftar yang akan ditampilkan di UI
  List<String> _selectedTimezones = [];

  @override
  void initState() {
    super.initState();
    _fetchRates(); // Untuk konverter mata uang
    _loadSelectedTimezones(); // Muat daftar zona waktu

    // Atur timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel(); // Matikan timer
    _amountController.dispose(); // Matikan controller
    super.dispose();
  }

  // --- Fungsi Konverter Mata Uang ---
  Future<void> _fetchRates() async {
    try {
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/USD');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;
        _rates = ratesData.map((key, value) {
          return MapEntry(key, (value as num).toDouble());
        });
      } else {
        _showError("Gagal memuat kurs");
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _convertCurrency() {
    if (_amountController.text.isEmpty || _rates.isEmpty) return;
    setState(() {
      _isConverting = true;
    });

    double amount = double.parse(_amountController.text);
    double fromRate = _rates[_fromCurrency] ?? 1.0;
    double toRate = _rates[_toCurrency] ?? 1.0;
    double result = (amount / fromRate) * toRate;
    final format = NumberFormat.currency(
      symbol: '$_toCurrency ',
      decimalDigits: 2,
    );

    setState(() {
      _conversionResult = format.format(result);
      _isConverting = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Fungsi Jam Dunia ---
  Future<void> _loadSelectedTimezones() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTimezones = prefs.getStringList('selectedTimezones');
    if (savedTimezones == null || savedTimezones.isEmpty) {
      setState(() {
        _selectedTimezones = ['Jakarta (WIB | UTC+7)', 'London (UTC+0)'];
      });
    } else {
      setState(() {
        _selectedTimezones = savedTimezones;
      });
    }
  }

  Future<void> _showManageTimezonesDialog() async {
    List<String> tempSelected = List.from(_selectedTimezones);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Pilih Zona Waktu"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allTimezones.length,
                  itemBuilder: (context, index) {
                    final key = _allTimezones.keys.elementAt(index);
                    return CheckboxListTile(
                      title: Text(key),
                      value: tempSelected.contains(key),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(key);
                          } else {
                            tempSelected.remove(key);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    _saveSelectedTimezones(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveSelectedTimezones(List<String> newSelection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedTimezones', newSelection);
    setState(() {
      _selectedTimezones = newSelection;
    });
  }

  // --- Helper Widget Jam ---
  Widget _buildStaticTimeTile(String title, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(
        time,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deklarasikan utcTime di sini
    final utcTime = _currentTime.toUtc();

    // --- INI PERBAIKANNYA: Tambahkan Scaffold & AppBar ---
    return Scaffold(
      appBar: AppBar(title: const Text('Utilitas')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- KARTU 1: KONVERTER MATA UANG ---
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Konverter Mata Uang",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  // Input Jumlah (Dengan Filter Angka)
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Jumlah",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Dari / Ke
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _fromCurrency,
                          isExpanded: true,
                          items: _currencies
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _fromCurrency = val);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _toCurrency,
                          isExpanded: true,
                          items: _currencies
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _toCurrency = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol dan Hasil (Dengan Perbaikan Overflow)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _convertCurrency,
                        child: _isConverting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Konversi"),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _conversionResult,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- KARTU 2: JAM DUNIA (CUSTOM) ---
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan Tombol Edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Jam Dunia (Device)",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        onPressed: _showManageTimezonesDialog, // Panggil dialog
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  // Daftar Jam
                  _buildStaticTimeTile(
                    "Waktu Lokal (HP)",
                    _timeFormat.format(_currentTime), // Waktu HP
                  ),
                  // Tampilkan daftar pilihan
                  ..._selectedTimezones.map((key) {
                    final offset = _allTimezones[key] ?? 0;
                    final time = utcTime.add(Duration(hours: offset));
                    return _buildStaticTimeTile(key, _timeFormat.format(time));
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
