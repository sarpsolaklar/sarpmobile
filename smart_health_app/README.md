# Sanctuary Health

Bu klasör, Sanctuary Health Flutter uygulamasının ana kaynak kodlarını içerir.

## Klasör İçeriği

```text
lib/                 Dart kaynak kodları
android/             Android proje dosyaları
ios/                 iOS proje dosyaları
web/                 Web proje dosyaları
test/                Widget testleri
pubspec.yaml         Flutter bağımlılıkları
```

## Uygulama Özellikleri

- Firebase Authentication ile giriş, kayıt ve şifre sıfırlama
- Firestore ile kullanıcı bazlı veri senkronizasyonu
- SQLite ve SharedPreferences ile yerel veri saklama
- İlaç ekleme, listeleme ve günlük tamamlandı takibi
- Bildirim ile ilaç hatırlatma
- Google Places ile yakındaki eczane/hastane arama
- Google Static Maps ile harita önizlemesi
- Konum erişimi
- Barkod tarama ekranı
- Aktivite, su ve profil takibi
- Privacy & Data ekranı

## Kurulum

```bash
flutter pub get
```

## API Key ile Çalıştırma

Harita ve yakındaki sağlık noktaları ekranı için Google Maps API key gerekir.

Chrome için:

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Android için:

```bash
flutter run -d android --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Windows için:

```bash
flutter run -d windows --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

## Google Cloud Gereksinimleri

Google Cloud Console üzerinde şu API'ler açık olmalıdır:

- Places API veya Places API (New)
- Maps Static API

Web testleri için API key referrer kısıtlarına şunları ekleyin:

```text
http://localhost:*
http://127.0.0.1:*
```

## Firebase Gereksinimleri

Firebase üzerinde:

- Authentication > Email/Password aktif olmalı
- Firestore Database oluşturulmalı
- Firestore Rules kullanıcı bazlı erişime göre ayarlanmalı

Önerilen Firestore Rules:

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

Son doğrulama:

- `flutter analyze --no-pub`: başarılı
- `flutter test test\widget_test.dart --no-pub`: başarılı
