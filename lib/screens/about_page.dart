import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- BAGIAN GAMBAR PEMBUAT ---
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.indigo,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- BAGIAN NAMA PEMBUAT ---
              Text(
                'Jejak Pena',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi Jurnal Perjalanan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // --- BAGIAN DESKRIPSI ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tentang Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jejak Pena adalah aplikasi untuk mencatat dan membagikan pengalaman perjalanan Anda. '
                      'Dengan fitur lokasi, foto, dan peta interaktif, Anda dapat menyimpan setiap momen berharga dari perjalanan Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),              // --- BAGIAN SARAN DAN KESAN ---
              Text(
                'Saran dan Kesan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Untuk Mata Kuliah: Pemrograman Aplikasi Mobile',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // --- TEXT STATIS DUMMY ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.2),
                  ),
                ),
                child: const Text(
                  'Aplikasi Jejak Pena telah memberikan pengalaman pembelajaran yang sangat berharga dalam mempelajari Flutter dan pengembangan aplikasi mobile. '
                  'Melalui proyek ini, saya dapat memahami konsep-konsep penting seperti state management, integrasi API, penggunaan database lokal, dan implementasi fitur-fitur modern dalam aplikasi mobile. '
                  'Fitur-fitur seperti pemetaan lokasi real-time, manajemen foto, dan keamanan aplikasi dengan PIN memperkaya portfolio pengembangan saya. '
                  'Terima kasih atas kesempatan untuk mengembangkan aplikasi yang praktis dan bermanfaat ini. '
                  'Saya berharap dapat terus meningkatkan keterampilan pemrograman mobile di masa depan.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 24),

              // --- INFO VERSI ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Versi 1.0.0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2025 Jejak Pena. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
