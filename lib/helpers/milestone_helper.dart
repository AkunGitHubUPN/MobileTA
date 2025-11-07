import '../helpers/database_helper.dart';
import '../helpers/user_session.dart';

class MilestoneHelper {
  final dbHelper = DatabaseHelper.instance;

  static const List<int> journalMilestones = [3, 5, 10, 20, 30, 50, 100];
  static const List<int> countryMilestones = [3, 5, 10, 20, 30, 50, 100];

  Future<Map<String, dynamic>?> checkJournalMilestone() async {
    try {
      final userId = UserSession.instance.currentUserId;
      if (userId == null) return null;

      final journals = await dbHelper.getJournalsForUser(userId);
      int totalJournals = journals.length;

      print("[MILESTONE] Total jurnal: $totalJournals");

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

  Future<Map<String, dynamic>?> checkCountryMilestone() async {
    try {
      final userId = UserSession.instance.currentUserId;
      if (userId == null) return null;

      final journals = await dbHelper.getJournalsForUser(userId);

      Set<String> uniqueCountries = {};
      for (var journal in journals) {
        String namaLokasi = journal[DatabaseHelper.columnNamaLokasi] ?? "";
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

  Future<List<Map<String, dynamic>>> checkAllMilestones() async {
    List<Map<String, dynamic>> activeMilestones = [];

    final journalMilestone = await checkJournalMilestone();
    if (journalMilestone != null) {
      activeMilestones.add(journalMilestone);
    }

    final countryMilestone = await checkCountryMilestone();
    if (countryMilestone != null) {
      activeMilestones.add(countryMilestone);
    }

    return activeMilestones;
  }

  String generateMilestoneText(String type, int milestone) {
    if (type == 'journal') {
      return 'Selamat! Anda telah membuat $milestone jurnal perjalanan! 🎉';
    } else if (type == 'country') {
      return 'Luar biasa! Anda telah mengunjungi $milestone negara berbeda! 🌍';
    }
    return 'Pencapaian baru! 🎊';
  }

  String generateMilestoneSubtitle(String type, int milestone) {
    if (type == 'journal') {
      return 'Perjalanan Anda semakin mengesankan';
    } else if (type == 'country') {
      return 'Pengalaman global Anda bertambah';
    }
    return 'Terus jelajahi dunia!';
  }
}
