import '../helpers/database_helper.dart';

class MilestoneHelper {
  final dbHelper = DatabaseHelper.instance;

  // Milestone untuk jumlah jurnal
  static const List<int> journalMilestones = [3, 5, 10, 20, 30, 50, 100];
  
  // Milestone untuk jumlah negara
  static const List<int> countryMilestones = [3, 5, 10, 20, 30, 50, 100];

  /// Cek apakah user mencapai milestone jurnal
  /// Returns: [isMilestone, milestoneNumber] atau null jika tidak ada milestone
  Future<Map<String, dynamic>?> checkJournalMilestone() async {
    try {
      // Hitung total jurnal
      final journals = await dbHelper.getAllJournals();
      int totalJournals = journals.length;

      print("[MILESTONE] Total jurnal: $totalJournals");

      // Cek apakah mencapai milestone
      for (int milestone in journalMilestones) {
        if (totalJournals == milestone) {
          print("[MILESTONE] 🎉 Mencapai milestone jurnal: $milestone");
          return {
            'type': 'journal',
            'milestone': milestone,
          };
        }
      }

      return null;
    } catch (e) {
      print("[MILESTONE] Error checking journal milestone: $e");
      return null;
    }
  }

  /// Cek apakah user mencapai milestone negara
  /// Returns: [isMilestone, milestoneNumber] atau null jika tidak ada milestone
  Future<Map<String, dynamic>?> checkCountryMilestone() async {
    try {
      // Ambil semua jurnal dengan lokasi
      final journals = await dbHelper.getAllJournals();
      
      // Extract negara dari nama lokasi
      Set<String> uniqueCountries = {};
      for (var journal in journals) {
        String namaLokasi = journal[DatabaseHelper.columnNamaLokasi] ?? "";
        // Ambil kata terakhir (biasanya nama negara) dari lokasi
        List<String> parts = namaLokasi.split(',');
        if (parts.isNotEmpty) {
          String country = parts.last.trim();
          if (country.isNotEmpty) {
            uniqueCountries.add(country);
          }
        }
      }

      int totalCountries = uniqueCountries.length;
      print("[MILESTONE] Total negara unik: $totalCountries");

      // Cek apakah mencapai milestone
      for (int milestone in countryMilestones) {
        if (totalCountries == milestone) {
          print("[MILESTONE] 🌍 Mencapai milestone negara: $milestone");
          return {
            'type': 'country',
            'milestone': milestone,
          };
        }
      }

      return null;
    } catch (e) {
      print("[MILESTONE] Error checking country milestone: $e");
      return null;
    }
  }

  /// Cek semua milestone dan return yang aktif
  Future<List<Map<String, dynamic>>> checkAllMilestones() async {
    List<Map<String, dynamic>> activeMilestones = [];

    // Cek milestone jurnal
    final journalMilestone = await checkJournalMilestone();
    if (journalMilestone != null) {
      activeMilestones.add(journalMilestone);
    }

    // Cek milestone negara
    final countryMilestone = await checkCountryMilestone();
    if (countryMilestone != null) {
      activeMilestones.add(countryMilestone);
    }

    return activeMilestones;
  }

  /// Generate notifikasi text berdasarkan milestone
  String generateMilestoneText(String type, int milestone) {
    if (type == 'journal') {
      return 'Selamat! Anda telah membuat $milestone jurnal perjalanan! 🎉';
    } else if (type == 'country') {
      return 'Luar biasa! Anda telah mengunjungi $milestone negara berbeda! 🌍';
    }
    return 'Pencapaian baru! 🎊';
  }

  /// Generate subtitle notifikasi
  String generateMilestoneSubtitle(String type, int milestone) {
    if (type == 'journal') {
      return 'Perjalanan Anda semakin mengesankan';
    } else if (type == 'country') {
      return 'Pengalaman global Anda bertambah';
    }
    return 'Terus jelajahi dunia!';
  }
}
