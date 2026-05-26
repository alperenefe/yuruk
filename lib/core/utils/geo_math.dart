import 'dart:math';

/// İki GPS noktası arasındaki yön açısını (bearing) hesaplar.
double bearingBetween(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLon = (lon2 - lon1) * (pi / 180);
  final lat1Rad = lat1 * (pi / 180);
  final lat2Rad = lat2 * (pi / 180);
  final y = sin(dLon) * cos(lat2Rad);
  final x = cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
  return atan2(y, x) * (180 / pi);
}

/// İki açı arasındaki mutlak farkı [0, 180] aralığında döndürür.
double angleDiff(double a, double b) {
  double diff = (b - a).abs() % 360;
  if (diff > 180) diff = 360 - diff;
  return diff;
}
