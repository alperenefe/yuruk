class LocationServiceDisabledException implements Exception {
  final String message;

  LocationServiceDisabledException([
    this.message = 'Konum servisi kapalı. Lütfen ayarlardan konum servisini açın.',
  ]);

  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message;

  LocationPermissionDeniedException([
    this.message = 'Konum izni reddedildi. Uygulama ayarlarından konum iznini veriniz.',
  ]);

  @override
  String toString() => message;
}
