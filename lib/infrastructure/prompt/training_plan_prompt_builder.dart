import '../../domain/entities/training_goal.dart';

/// LLM'e verilecek prompt şablonu.
class TrainingPlanPromptBuilder {
  static String build({
    required TrainingGoal goal,
    required int daysPerWeek,
    String? currentFitness,
    String? userNotes,
  }) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final raceStr =
        '${goal.raceDate.year}-${goal.raceDate.month.toString().padLeft(2, '0')}-${goal.raceDate.day.toString().padLeft(2, '0')}';
    final weeksUntil = goal.daysUntilRace ~/ 7;
    final pace = goal.targetPacePerKm ?? _estimatePace(goal);

    return '''
Sen deneyimli bir koşu antrenörüsün. Aşağıdaki hedef için Yürük mobil uygulamasına özel JSON formatında antrenman planı üret.

═══════════════════════════════
SPORCU HEDEFİ
═══════════════════════════════
- Hedef tarihi    : $raceStr
- Hedef mesafe    : ${goal.distanceMeters.toInt()} m (${goal.distanceLabel})
- Hedef süre      : ${goal.targetTime}  →  ~$pace /km
- Bugün           : $todayStr  (kalan: ${goal.daysUntilRace} gün / $weeksUntil hafta)
- Haftada koşu    : $daysPerWeek gün
- Mevcut seviye   : ${currentFitness?.isNotEmpty == true ? currentFitness : 'bilinmiyor'}
- Notlar          : ${userNotes?.isNotEmpty == true ? userNotes : 'yok'}

═══════════════════════════════
UYGULAMA YETENEKLERİ (buna göre üret)
═══════════════════════════════
Yürük uygulaması şu adım tiplerini çalıştırabilir:
  • type="distance"  → meters (zorunlu), targetPace ("M:SS"), name, isRest
  • type="time"      → durationSeconds (zorunlu), targetPace, name, isRest=true (dinlenme için)

Her gün tipi için ZORUNLU format:

┌─────────────────────────────────────────────────────────────┐
│ type="rest"    → workout YAZMA. Sadece title+description.   │
├─────────────────────────────────────────────────────────────┤
│ type="easy"    → workout YAZMA.                             │
│   targetDistanceMeters + targetPacePerKm yeterli.           │
│   Uygulama tek adımlı sabit tempo koşusu oluşturur.         │
├─────────────────────────────────────────────────────────────┤
│ type="long"    → workout YAZMA.                             │
│   targetDistanceMeters + targetPacePerKm yeterli.           │
│   Uygulama tek adımlı uzun koşu oluşturur.                  │
├─────────────────────────────────────────────────────────────┤
│ type="tempo"   → workout.steps ZORUNLU.                     │
│   3 adım: ısınma(distance) + tempo bloğu(distance)          │
│            + soğuma(distance)                               │
│   Her adımda targetPace belirt.                             │
├─────────────────────────────────────────────────────────────┤
│ type="interval"→ workout.steps ZORUNLU.                     │
│   Yapı: ısınma → [hızlı + dinlenme] × tekrar → soğuma      │
│   Dinlenme adımlarında isRest=true, type="time" kullan.     │
│   Her koşu adımında targetPace belirt.                      │
├─────────────────────────────────────────────────────────────┤
│ type="test"    → workout.steps ZORUNLU.                     │
│   3 adım: ısınma(1000m, kolay pace) +                       │
│            test mesafesi(targetPace YOK, max efor) +        │
│            soğuma(500m, çok kolay)                          │
├─────────────────────────────────────────────────────────────┤
│ type="race"    → workout YAZMA.                             │
│   targetDistanceMeters + targetPacePerKm yeterli.           │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════
JSON ŞEMASI
═══════════════════════════════
{
  "version": 1,
  "goal": {
    "name": "...", "raceDate": "YYYY-MM-DD",
    "distanceMeters": ..., "targetTime": "M:SS",
    "targetPacePerKm": "M:SS"
  },
  "meta": { "weeksTotal": ..., "daysPerWeek": ..., "generatedBy": "llm", "generatedAt": "..." },
  "weeks": [
    { "days": [ /* gün nesneleri */ ] }
  ]
}

═══════════════════════════════
ÖRNEKLER
═══════════════════════════════

── easy günü ──────────────────
{"date":"2026-06-16","type":"easy","title":"Kolay koşu","description":"Rahat tempo, nefes kontrolü",
 "targetDistanceMeters":5000,"targetPacePerKm":"6:00"}

── tempo günü ─────────────────
{"date":"2026-06-18","type":"tempo","title":"Tempo koşu",
 "workout":{"name":"Tempo 6km",
   "steps":[
     {"type":"distance","meters":1500,"targetPace":"6:30","name":"Isınma"},
     {"type":"distance","meters":4000,"targetPace":"5:00","name":"Tempo"},
     {"type":"distance","meters":1000,"targetPace":"7:00","name":"Soğuma"}
   ]}}

── interval günü ──────────────
{"date":"2026-06-20","type":"interval","title":"6×400 interval",
 "workout":{"name":"6x400",
   "steps":[
     {"type":"distance","meters":1000,"targetPace":"6:30","name":"Isınma"},
     {"type":"distance","meters":400,"targetPace":"4:30","name":"Hızlı","isRest":false},
     {"type":"time","durationSeconds":90,"isRest":true,"name":"Dinlenme"},
     {"type":"distance","meters":400,"targetPace":"4:30","name":"Hızlı","isRest":false},
     {"type":"time","durationSeconds":90,"isRest":true,"name":"Dinlenme"},
     {"type":"distance","meters":1000,"targetPace":"7:00","name":"Soğuma"}
   ]}}

── test günü ──────────────────
{"date":"2026-07-05","type":"test","title":"2400m deneme",
 "workout":{"name":"Zaman denemesi",
   "steps":[
     {"type":"distance","meters":1000,"targetPace":"6:30","name":"Isınma"},
     {"type":"distance","meters":2400,"name":"Test — max efor"},
     {"type":"distance","meters":500,"targetPace":"7:30","name":"Soğuma"}
   ]}}

═══════════════════════════════
GENEL KURALLAR
═══════════════════════════════
1. Çıktı YALNIZCA geçerli JSON; markdown, ```code block``` veya açıklama YOK.
2. Tüm tarihler $todayStr–$raceStr arasında, sıralı.
3. Son 2 haftada taper (yoğunluk %20–30 azalt).
4. Yarış günü type=race.
5. En az 1 test günü (planın ortasında).
6. title ve description Türkçe; pace formatı M:SS.

Planı şimdi üret.''';
  }

  static String _estimatePace(TrainingGoal goal) {
    final parts = goal.targetTime.split(':');
    if (parts.length != 2) return '?';
    final min = int.tryParse(parts[0]);
    final sec = int.tryParse(parts[1]);
    if (min == null || sec == null) return '?';
    final totalSec = min * 60 + sec;
    final km = goal.distanceMeters / 1000;
    if (km <= 0) return '?';
    final paceSec = totalSec / km;
    final pMin = paceSec ~/ 60;
    final pSec = (paceSec % 60).round();
    return '$pMin:${pSec.toString().padLeft(2, '0')}';
  }
}
