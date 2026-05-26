/// Firebase App Distribution — uygulama ici guncelleme metinleri.
abstract final class AppUpdateStrings {
  static const section = 'Uygulama güncellemesi';
  static const hint =
      'Firebase dağıtımındaki son sürümü kontrol eder. İlk seferde tester Google girişi; e-posta gerekmez.';
  static const check = 'Güncellemeyi kontrol et';
  static const upToDate = 'Uygulama güncel.';
  static const started = 'Yeni sürüm bulundu — indirme ve kurulum başladı.';
  static const debugOnly =
      'Uygulama içi güncelleme yalnızca release build ile çalışır (CI APK).';
  static const firebaseMissing =
      'Firebase yapılandırması eksik (google-services.json).';
  static const failed =
      'Güncelleme kontrolü başarısız. Tester hesabı ve interneti kontrol et.';
}
