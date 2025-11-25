import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  String _conversionResult = "Hasil: -";
  Map<String, double> _rates = {};
  bool _isConverting = false;

  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY', 'GBP'];

  final Map<String, int> _allTimezones = {
    'San Francisco (UTC-8)': -8,
    'Chicago (UTC-6)': -6,
    'New York (UTC-5)': -5,
    'Buenos Aires (UTC-3)': -3,
    'Sao Paulo (UTC-3)': -3,
    'London (UTC+0)': 0,
    'Berlin (UTC+1)': 1,
    'Paris (UTC+1)': 1,
    'Kairo (UTC+2)': 2,
    'Moskow (UTC+3)': 3,
    'Istanbul (UTC+3)': 3,
    'Dubai (UTC+4)': 4,
    'Jakarta (WIB | UTC+7)': 7,
    'Makassar (WITA | UTC+8)': 8,
    'Jayapura (WIT | UTC+9)': 9,
    'Shanghai (UTC+8)': 8,
    'Singapura (UTC+8)': 8,
    'Tokyo (UTC+9)': 9,
    'Seoul (UTC+9)': 9,
    'Perth (UTC+8)': 8,
    'Sydney (UTC+10)': 10,
    'Auckland (UTC+12)': 12,
  };

  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  final _timeFormat = DateFormat('HH:mm');
  List<String> _selectedTimezones = [];

  @override
  void initState() {
    super.initState();
    _fetchRates();
    _loadSelectedTimezones();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B4A),
      ),
    );
  }

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                      activeColor: const Color(0xFFFF6B4A),
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
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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

  Widget _buildStaticTimeTile(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final utcTime = _currentTime.toUtc();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFF6B4A),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Utilitas',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Konversi Mata Uang",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: "Jumlah",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF6B4A), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _fromCurrency,
                                isExpanded: true,
                                underline: const SizedBox(),
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
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(Icons.arrow_forward, color: Color(0xFFFF6B4A)),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _toCurrency,
                                isExpanded: true,
                                underline: const SizedBox(),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _convertCurrency,
                            child: _isConverting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Konverter", style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _conversionResult,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6B4A),
                                  ),
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

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Jam Dunia",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFF6B4A)),
                            onPressed: _showManageTimezonesDialog,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildStaticTimeTile(
                        "Waktu Lokal",
                        _timeFormat.format(_currentTime),
                      ),
                      ..._selectedTimezones.map((key) {
                        final offset = _allTimezones[key] ?? 0;
                        final time = utcTime.add(Duration(hours: offset));
                        return _buildStaticTimeTile(key, _timeFormat.format(time));
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}