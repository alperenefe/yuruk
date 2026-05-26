# CI/CD: GitHub Actions → Firebase App Distribution

**Repo:** [alperenefe/yuruk](https://github.com/alperenefe/yuruk)  
**Android paket adı:** `com.alper.yuruk.yuruk`

Müzik Teorisi ile aynı akış: `deploy-remote.ps1` veya `[apk]` push → CI → Firebase.

## Uygulama içi güncelleme

Release APK açılışta güncellemeyi kontrol eder. **Geçmiş** sekmesinde «Güncellemeyi kontrol et». İlk seferde tester Google girişi.

---

## Müzik Teorisi’nden ne tekrarlanır?

Firebase / GCP projesi: **`kosu-497509`**

| Secret | Durum |
|--------|--------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `kosu-497509-….json` (GitHub’a eklendi) |
| `FIREBASE_TESTER_GROUPS` | `testers` |
| `FIREBASE_ANDROID_APP_ID` | `1:102727725395:android:6387639a3e3d28e97b31a6` |
| `GOOGLE_SERVICES_JSON` | İsteğe bağlı |

**Firebase App Testers API** → Google Cloud, proje **kosu-497509** üzerinde etkin olmalı.

---

## Firebase (bir kez — bu uygulama)

1. [Firebase Console](https://console.firebase.google.com/) → **music trainer** (veya yeni proje).
2. **Add app** → Android → paket: `com.alper.yuruk.yuruk`.
3. **App Distribution** → bu uygulama için dağıtımı etkinleştir.
4. **App ID**’yi kopyala (`1:…:android:…`).
5. GitHub → [yuruk/settings/secrets/actions](https://github.com/alperenefe/yuruk/settings/secrets/actions) → secret’ları ekle.

---

## GitHub secret’ları

| Secret | Zorunlu |
|--------|---------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Evet |
| `FIREBASE_ANDROID_APP_ID` | Evet (bu uygulamaya özel) |
| `FIREBASE_TESTER_GROUPS` veya `FIREBASE_TESTER_EMAILS` | Biri |
| `GOOGLE_SERVICES_JSON` | Hayır |
| `ANDROID_KEYSTORE_*` | Hayır |

---

## Dağıtım

| İstek | Komut |
|--------|--------|
| Sadece kod | `git push` veya `.\scripts\git-push.ps1` |
| Kod + APK | `.\scripts\git-push.ps1 -Deploy` |
| Commit ile APK | `git commit -m "… [apk]"` + `git push` |

~10–15 dk sonra Firebase maili / link → **Kur**.

---

## Yerel hızlı kurulum

```powershell
cd c:\cursorProjects\yuruk
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
