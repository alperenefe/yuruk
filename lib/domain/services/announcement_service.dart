import '../entities/run_session.dart';

/// Service for generating voice announcements during runs
/// Only provides start and stop announcements (no interval announcements)
class AnnouncementService {
  /// Get start announcement
  String getStartAnnouncement() {
    return 'Koşu başladı';
  }

  /// Get stop announcement with run summary
  String getStopAnnouncement(RunSession session) {
    final km = (session.totalDistance / 1000).toStringAsFixed(2);
    final minutes = session.elapsedTime.inMinutes;
    final seconds = session.elapsedTime.inSeconds.remainder(60);
    final pace = session.averagePaceFormatted;
    
    if (session.totalDistance < 100) {
      return 'Koşu durduruldu';
    }
    
    return 'Koşu tamamlandı. $km kilometre. Süre $minutes dakika $seconds saniye. Ortalama tempo $pace';
  }
}
