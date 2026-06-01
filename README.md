# Sanctuary Health Mobil Sağlık Uygulaması

Bu repository, mobil programlama dersi dönem projesi için geliştirilen **Sanctuary Health** uygulamasını içerir.

Uygulama kaynak kodları şu klasördedir:

```text
smart_health_app/
```

> Not: Projenin uygulama adı Sanctuary Health, Flutter proje klasörü ise `smart_health_app` olarak durmaktadır.

## Proje Özeti

Sanctuary Health; ilaç takibi, günlük hatırlatıcılar, su takibi, aktivite kaydı, profil yönetimi, barkod tarama, yakındaki eczane/hastane arama ve gizlilik/veri kontrolü özelliklerini içeren Flutter tabanlı bir sağlık uygulamasıdır.

## Öne Çıkan Özellikler

- Firebase Authentication ile giriş, kayıt, şifre sıfırlama ve çıkış
- Firestore ile kullanıcı bazlı veri senkronizasyonu
- Yerel veri depolama
  - Mobil/desktop için SQLite
  - Web için local storage / SharedPreferences
- İlaç ekleme ve günlük ilaç tamamlandı takibi
- İlaç hatırlatıcı bildirimleri
- Google Places ile yakındaki eczane/hastane arama
- Google Static Maps ile harita üzerinde işaretleme
- Cihaz konumuna erişim
- Barkod tarama ekranı
- Aktivite ve su takibi
- Profil düzenleme
- Privacy & Data ekranı ile yerel veri temizleme ve hesap silme

## Ders İsterleriyle Uyumluluk

| İster | Durum |
|---|---|
| En az 5 farklı ön yüz tasarımı | Karşılanıyor |
| En az 5 layout/UI elemanı kullanımı | Karşılanıyor |
| Bildirim, harita gibi ileri özellikler | Karşılanıyor |
| Bir servisten veri alarak ön yüzde gösterme | Karşılanıyor |
| Yerel depolama / ekranlar arası veri aktarımı | Karşılanıyor |
| 3rd party kütüphane kullanımı | Karşılanıyor |
| Cihaz konum/kamera özelliklerine erişim | Karşılanıyor |
| Versiyon kontrol | GitHub üzerinden karşılanıyor |

## Kullanılan Teknolojiler

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Google Places API
- Google Static Maps API
- SQLite / SharedPreferences
- Geolocator
- Mobile Scanner
- Flutter Local Notifications
- GitHub Actions

## Kurulum

Önce uygulama klasörüne girin:

```bash
cd C:\Users\Baris\Desktop\sarpmobile\smart_health_app
```

Paketleri yükleyin:

```bash
flutter pub get
```

## Google Maps API Key ile Çalıştırma

Harita ve yakındaki eczane/hastane araması için Google Maps API key gereklidir.

Chrome üzerinde çalıştırmak için:

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Android cihazda çalıştırmak için:

```bash
flutter run -d android --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Windows üzerinde çalıştırmak için:

```bash
flutter run -d windows --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

API key çalışmazsa Google Cloud Console üzerinde şunları kontrol edin:

- Places API veya Places API (New) açık mı?
- Maps Static API açık mı?
- API key kısıtlarında bu API'lere izin verildi mi?
- Web için referrer kısıtlarında şunlar var mı?
  - `http://localhost:*`
  - `http://127.0.0.1:*`

## Firebase Ayarları

Firebase tarafında şunlar aktif olmalıdır:

- Authentication > Email/Password
- Firestore Database
- Android uygulama package name:

```text
com.sanctuaryhealth.smart_health_app
```

Gerekli dosyalar:

```text
smart_health_app/lib/firebase_options.dart
smart_health_app/android/app/google-services.json
```

## Firestore Rules

Kullanıcıların sadece kendi verilerine erişmesi için önerilen Firestore kuralı:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/data/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

## Test ve Analiz

```bash
flutter analyze --no-pub
flutter test test\widget_test.dart --no-pub
```

Son yerel doğrulama:

- `flutter analyze --no-pub`: başarılı
- `flutter test test\widget_test.dart --no-pub`: başarılı

## GitHub Linki

```text
https://github.com/sarpsolaklar/sarpmobile
```

## Notlar

- Google Maps API key kaynak koda yazılmamıştır; uygulama `--dart-define` ile alır.
- Yayın ortamında Google Places çağrılarının backend veya Firebase Cloud Functions arkasına taşınması daha güvenlidir.
- Android release signing için özel keystore henüz yapılandırılmamıştır.
