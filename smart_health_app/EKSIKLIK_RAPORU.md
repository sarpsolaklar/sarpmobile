# Sanctuary Health - Eksiklik Analiz Raporu

Analiz tarihi: 25 Mayis 2026

Kapsam: `smart_health_app` Flutter uygulamasi, kok dizindeki statik HTML prototipleri ve temel proje yapilandirmasi.

## Uygulama Durumu

25 Mayis 2026 tarihinde oncelikli aksiyon planinin ilk uygulama turu baslatildi. Bu rapordaki bazi eksikler artik kismen veya tamamen giderildi: Firebase Auth giris/kayit/sifre sifirlama akisi, bildirim servis baslatma, Android/iOS izinleri, tarih bazli ilac loglari, hatali ilac listeleme metni, widget test iskeleti, README, uygulama adi, debug release signing temizligi, CI iskeleti, Firestore kullanici bazli yazma/okuma servisi, profil/aktivite validasyonu ve Privacy & Data ekrani eklendi.

Son dogrulama: `flutter analyze --no-pub` basarili. `flutter test test\widget_test.dart --no-pub` kod calismadan once yerel `Yuksek Lisans` dizin yolunun native asset hook tarafindan hatali ayrismasi nedeniyle basarisiz oldu.

## Yonetici Ozeti

Proje calisan bir Flutter prototipi seviyesinde ilerlemis; ilac takibi, aktivite kaydi, profil, su takibi, barkod, konum ve AI asistan ekranlari mevcut. Ancak urunlesme acisindan kritik eksikler var: kimlik dogrulama gercek degil, Firebase bagimliliklari kullanilmiyor, bazi ozellikler yer tutucu, test dosyasi Flutter sablonundan kalmis, Android/iOS izinleri eksik, release imzalama debug key ile yapiliyor ve statik analiz/test komutlari makul surede tamamlanmadi.

## Kritik Eksikler

### 1. Giris ve kayit akisi gercek degil

- `lib/screens/login_screen.dart` icinde `_handleLogin()` herhangi bir e-posta, parola, Firebase Auth veya form dogrulamasi yapmadan dogrudan dashboard'a geciyor.
- "Forgot Password?" ve "Create one" butonlari bos callback ile duruyor.
- `firebase_auth` bagimliligi `pubspec.yaml` icinde var, ancak `lib` altinda `FirebaseAuth` kullanimi yok.

Etkisi: Uygulamada kullanici hesabi, oturum, kayit, sifre yenileme ve veri sahipligi modeli yok. Saglik verisi iceren bir uygulama icin bu en oncelikli guvenlik/urun eksigi.

Oneri: Firebase Auth tabanli giris, kayit, sifre sifirlama, oturum kontrolu ve hata durumlari eklenmeli. Splash ekran login'e sabit gitmek yerine mevcut oturumu kontrol etmeli.

### 2. Saglik verileri buluta senkronize edilmiyor

- `cloud_firestore` bagimliligi var, fakat kodda Firestore kullanimi yok.
- Ilaclar ve aktiviteler SQLite'a, profil ve su takibi SharedPreferences'a yaziliyor.
- Kullanici degisirse veya cihaz degisirse veriler ayrismiyor/senkronize olmuyor.

Etkisi: "Sign in to sync your health data" metni urun davranisini yansitmiyor. Kullanici verileri cihazla sinirli kaliyor.

Oneri: Kullanici UID'sine bagli Firestore koleksiyonlari tasarlanmali; local cache/sync stratejisi netlestirilmeli.

### 3. Bildirim servisi baslatilmiyor ve platform izinleri eksik

- `NotificationService.instance.init()` cagrisi bulunamadi.
- Android Manifest icinde `POST_NOTIFICATIONS`, exact alarm veya ilgili izinler yok.
- iOS Info.plist icinde bildirim/konum aciklama metinleri yok.
- Servis baslamadigi icin `_initialized` false kalabilir ve hatirlatici planlama sessizce basarisiz olur.

Etkisi: Ilac hatirlatici ozelligi UI'da var gorunur, fakat pratikte calismama riski yuksek.

Oneri: `main()` icinde servis init edilmeli, Android 13+ bildirim izni ve gerekli alarm izinleri eklenmeli, iOS izin metinleri tamamlanmali.

### 4. Mobil platform izinleri tamamlanmamis

- `geolocator` ve `mobile_scanner` kullaniliyor, fakat Android Manifest'te konum/kamera izinleri yok.
- iOS Info.plist'te `NSLocationWhenInUseUsageDescription` ve kamera kullanim aciklamasi yok.

Etkisi: Harita ve barkod tarama ozellikleri cihazda izin hatasiyla calismayabilir ya da store incelemesinden kalabilir.

Oneri: Android ve iOS izinleri, kullaniciya gosterilecek aciklama metinleri ve izin reddi akislari tamamlanmali.

### 5. Release yapilandirmasi guvenli degil

- Android release build `signingConfigs.getByName("debug")` ile imzalaniyor.
- `android/app/build.gradle.kts` icinde uygulama kimligi ve signing icin TODO yorumlari duruyor.

Etkisi: Uygulama magazaya/veri guvenligi gerektiren ortama hazir degil.

Oneri: Release keystore, signing config, versioning ve build flavor stratejisi olusturulmali.

## Fonksiyonel Eksikler

### 6. AI asistan simulasyon seviyesinde

- `lib/screens/ai_assistant_screen.dart` kullanici mesajina sabit bir metin donduruyor.
- Tibbi guvenlik sinirlari, acil durum yonlendirmesi, kaynak belirtme, disclaimer ve model/backend entegrasyonu yok.

Etkisi: "AI Asistan" beklentisi karsilanmiyor; saglik alaninda yanlis guven yaratabilir.

Oneri: Backend uzerinden guvenli AI akisi, tibbi uyarilar, acil durum metinleri, sohbet gecmisi ve kaynak/yonlendirme politikasi eklenmeli.

### 7. Harita/eczane ozelligi yer tutucu

- `MapsIntegrationScreen` sadece koordinat yazdiriyor ve "Harita entegrasyonu buraya gelecek" metni iceriyor.
- Ayrica `map_screen.dart` adinda baska bir harita placeholder ekrani var, ancak rota olarak kullanilmiyor.
- Eczane/hastane arama, listeleme, rota, mesafe, acik/kapali durumu yok.

Etkisi: Dashboard'daki "Eczaneler" hizli aksiyonu gercek kullanici degeri uretmiyor.

Oneri: Tek harita ekrani secilmeli; Google Maps/Mapbox/OpenStreetMap entegrasyonu, nearby search API, liste+harita gorunumu ve hata/izin durumlari eklenmeli.

### 8. Barkod tarama sonucu ilac bilgisine donusmuyor

- Scanner barkodu okuyunca raw value donduruyor; urun/ilac veritabani sorgusu yok.
- SnackBar metni barkod degerini gostermiyor.
- Ayni yakalamada birden fazla pop tetiklenme riski var.

Etkisi: Barkod ozelligi sadece metin doldurma kisayolu gibi kaliyor.

Oneri: Barkoddan ilac ad/dosaj verisi getiren servis, tarama kilidi, hata durumu ve manuel duzeltme akisi eklenmeli.

### 9. Ilac listeleme ekraninda string interpolation hatasi var

- `lib/screens/medications_screen.dart` satirinda `'\${medication.dosage} • \${medication.time}'` literal olarak yazilmis.

Etkisi: Kullanici doz ve saati gercek deger olarak degil, `${medication.dosage}` benzeri metin olarak gorebilir.

Oneri: String basindaki kacis kaldirilmali: `'${medication.dosage} • ${medication.time}'`.

### 10. Gunluk ilac tamamlama modeli eksik

- `isDone` ilacin kendisinde saklaniyor; tarih bazli kayit yok.
- Ertesi gun otomatik sifirlama yok.

Etkisi: Bugun alindi bilgisi yarina tasinir ve ilac uyum takibi yanlislasir.

Oneri: `medication_logs` gibi tarih bazli tablo/koleksiyon eklenmeli; dashboard gunluk durumu bugunun kaydindan hesaplamali.

### 11. Aktivite ve profil verilerinde validasyon yok

- Aktivite alanlari negatif/asiri deger kabul edebilir.
- Profilde e-posta, yas, kilo, boy validasyonu yok.
- Varsayilan profil "Sarah Doe" olarak geliyor.

Etkisi: Yanlis veri, demo hissi ve tutarsiz metrikler olusur.

Oneri: Form validasyonlari, lokalizasyonlu hata mesajlari ve bos profil onboarding akisi eklenmeli.

### 12. UI metinleri karisik dilde

- Uygulamada Ingilizce ve Turkce metinler birlikte kullaniliyor.
- README ve web manifest aciklamasi varsayilan Flutter metni.

Etkisi: Urun kimligi ve kullanici deneyimi tutarsiz.

Oneri: Tek dil stratejisi veya Flutter localization yapisi eklenmeli; tr/en ARB dosyalariyla metinler ayrilmali.

## Teknik Borc ve Mimari Eksikler

### 13. State management bagimlilikleri kullanilmiyor

- `flutter_riverpod` ve `hooks_riverpod` bagimli, fakat kod `setState` ve singleton servislerle ilerliyor.

Etkisi: Bagimlilik sisme, test zorlugu ve ekranlar arasi veri yenileme problemleri olusur.

Oneri: Ya Riverpod kaldirilmali ya da auth/profile/medication/activity provider yapisi kurulup tutarli kullanilmali.

### 14. Hata yonetimi zayif

- Veritabani ve servis katmanlarinda bazi hatalar yutuluyor veya sadece `debugPrint` ile geciliyor.
- Kullaniciya tekrar dene, izin ayarlari, offline durum gibi iyilestirici aksiyonlar sunulmuyor.

Etkisi: Ozellikler sessizce calismayabilir; hata ayiklama ve destek zorlasir.

Oneri: Servis katmaninda typed result/error modeli, UI'da aksiyonlu hata durumlari ve loglama stratejisi eklenmeli.

### 15. Veritabani migrasyon stratejisi sinirli

- SQLite version sadece 2; `ALTER TABLE` hatasi bos catch ile yutuluyor.
- Index, foreign key, ilac loglari, kullanici ayrimi yok.

Etkisi: Veri evrimi riskli ve sessiz bozulmalar fark edilmeyebilir.

Oneri: Migrasyonlar test edilmeli, foreign key/indeksler eklenmeli, migration hata loglari anlamli hale getirilmeli.

### 16. Guvenlik ve gizlilik dokumani yok

- Saglik verisi islenmesine ragmen gizlilik politikasi, veri saklama, hesap silme, export ve consent akislari yok.
- Firebase config dosyalari repoda duruyor; Firebase API key tek basina secret olmayabilir, ama domain/restriction ve rule stratejisi belgelenmemis.

Etkisi: Uygulama gercek kullaniciya acilmaya hazir degil.

Oneri: Firebase rules, API key restriction, privacy policy, consent ekranlari, hesap/veri silme akislari eklenmeli.

## Test ve Kalite Eksikleri

### 17. Test dosyasi sablondan kalmis

- `test/widget_test.dart` "Counter increments smoke test" olarak duruyor.
- Uygulamada counter ve `+` ikonu bekliyor; mevcut app ile alakasiz.

Etkisi: Test paketi guven vermiyor ve buyuk ihtimalle fail ediyor.

Oneri: Login, medication CRUD, hydration, profile, activity ve notification scheduling icin birim/widget testleri yazilmali. Eski counter testi kaldirilmali.

### 18. Statik analiz ve test komutlari tamamlanmadi

- `flutter analyze` 120 saniyede timeout oldu.
- `flutter analyze --no-pub` 180 saniyede timeout oldu.
- `flutter test` 120 saniyede timeout oldu.

Etkisi: Kod kalitesi ve derlenebilirlik bu ortamda dogrulanamadi; CI riski var.

Oneri: Dependency/pub cache durumu kontrol edilmeli, CI workflow eklenmeli ve analiz/test komutlari deterministik hale getirilmeli.

### 19. CI/CD yok

- GitHub Actions veya benzeri otomatik analiz/test/build akisi gorulmedi.

Etkisi: Regresyonlar manuel fark edilir; release guveni dusuk kalir.

Oneri: `flutter analyze`, `flutter test`, Android build ve opsiyonel iOS build iceren CI eklenmeli.

## Dokumantasyon ve Proje Duzeni Eksikleri

### 20. README varsayilan Flutter sablonu

- Proje amaci, kurulum, calistirma, Firebase kurulumu, test, platform izinleri ve mimari anlatilmiyor.

Oneri: README yeniden yazilmali: ozellikler, setup, env/Firebase, komutlar, mimari, veri modeli, test ve release bolumleri eklenmeli.

### 21. Kok dizinde prototip ve uygulama ayrimi belirsiz

- Kokte `dashboard`, `profile`, `medications`, `health_map`, `login_register`, `splash_screen` gibi statik prototip klasorleri var.
- Gercek Flutter uygulamasi `smart_health_app` icinde.

Etkisi: Teslim edilecek urun ve referans tasarimlar ayrismiyor.

Oneri: Prototipler `design-prototypes/` altina alinmali veya README'de aciklanmali.

## Onceliklendirilmis Aksiyon Plani

1. Kimlik dogrulama, oturum kontrolu ve giris/kayit/sifre sifirlama akisini tamamla.
2. Android/iOS kamera, konum ve bildirim izinlerini ekle; NotificationService init cagrisi yap.
3. Test dosyasini sablondan kurtar; en azindan smoke testleri mevcut ekranlara gore yaz.
4. Ilac listeleme string interpolation hatasini duzelt.
5. Gunluk ilac log modeli ekle; `isDone` bilgisini tarih bazli hale getir.
6. Harita ve barkod ozelliklerini ya gercek entegrasyona bagla ya da MVP kapsamindan cikar.
7. Firestore senkronizasyon modelini netlestir ve yerel/bulut veri ayrimini tasarla.
8. README, manifest/app label ve release signing ayarlarini urunlesmeye uygun hale getir.
9. CI akisi ekle ve `flutter analyze` / `flutter test` komutlarinin surekli calistigini dogrula.
10. Localization, gizlilik politikasi ve saglik uygulamasi guvenlik uyarilarini tamamla.

## Kanit Olarak Incelenen Ana Dosyalar

- `lib/main.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/medications_screen.dart`
- `lib/screens/add_medication_screen.dart`
- `lib/screens/ai_assistant_screen.dart`
- `lib/screens/maps_integration_screen.dart`
- `lib/screens/scanner_screen.dart`
- `lib/screens/activity_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/database/database_helper.dart`
- `lib/services/profile_service.dart`
- `lib/services/notification_service.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `ios/Runner/Info.plist`
- `pubspec.yaml`
- `README.md`
- `test/widget_test.dart`
