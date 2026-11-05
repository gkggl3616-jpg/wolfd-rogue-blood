# 0.13.0 çevrimdışı sürüm

Kullanıcının son kapsamı: mümkün olan yerel özellikleri tamamla ve doğrula; gerçek sunucu kapsam dışında. Bu sürümün Android kimliği `com.wolfrogue.blood.offline` olur. Eski tam sürüm uygulamasıyla ayrı kurulur. Önceki **0.10–0.12 çevrimdışı** sürümlerle paket adı ve sertifika aynıdır; 0.13, uygulama verisini silmeden üzerine güncellenebilir.

Üretilen tek APK: **WolfRogueBlood-0.13.0-offline.apk**, **2.028.204.301 bayt** (2,03 GB). Android 7.0 / API 24 ve üzeri; ARM64, ARMv7 ve x86_64. [Paket doğrulaması](android-offline-build.json): 49.916 ZIP girdisi, 24 katalog, 22.627 çözümlenmiş kaynak bağımlılığı, v2/v3 imza, 16 KiB ZIP hizalaması. ARM64 ve x86_64 ELF yükleme hizalaması 16 KiB; ARMv7 kitaplığı 4 KiB'dir. İzin listesi boştur. Fiziksel cihaz ve emülatör testi yapılmadı.

[GitHub’dan tek APK indir](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.13.0-offline/WolfRogueBlood-0.13.0-offline.apk).

SHA-256: `4195b818388fe9fb78066636af4e24db686ac81a5a1d452c8e8bdb352bf83f49`.

## 0.13 yenilikleri

[Son beş PC ekranı ve yeni fotoğraflar](PC_REFERANS_013.md): maç başı silah/kurt seçimi, altı gerçek mutasyon modeli, kabul edilen hediye kutusu, güç eşyaları, Standart/SLH 1–4 ve üst menü. 18 regresyon aşaması, 191 yeni özellik/model kontrolü ve 77 gerçek ekran görüntüsü geçti. İlk ilkyardım/enerji hediyelerini Hediye Kutusu’nda kabul et; Envanter → GÜÇ+ üzerinden yuvalara tak. Maçta yuvarlak eşya düğmeleriyle kullan.

## Önceki sürümden korunanlar

[Son oynanış videosu ve fotoğraflar](OYNANIS_REFERANSI.md): ortalanmış kurt kamerası, joystick, yuvarlak mermi/pençe/şarjör görselleri, kompakt HUD, 19 harita radarı ve gerçek isabet/hasar işaretleri. Kolay/Normal/Zor insan ve kurt botları aynı 8 isabet hasarı/100 canla oynar; görüş, hafıza, koşu, siper, takla, basamak ve sınırlı mühimmat/şarjör davranışları bulunur. Bunlar yerel AI kurallarıdır.

[0.12 PC referansları, yeni işlevler ve fotoğraflar](PC_REFERANS_012.md): özgün 19 harita fotoğrafı, kaynak oda oluşturma, 62 rütbe, isteğe bağlı ikinci şifre, atomik kutu açılışı, 59 kol dövmesi, yerel Kurt Avı/öğretici, görevler/Wolf Pass ve dairesel dürbün eklendi. 17 regresyon aşaması, 102 yeni özellik kontrolü ve toplam 60 OpenGL görüntüsü doğrulandı.

## Oynanabilenler

- Oda oluştur → **Çevrimdışı · Botlu Eğitim** → harita seç → **Başlat**. 19 kaynak harita ve ayrıca küçük eğitim arenası bulunur. #46 Göbekli Tepe de bu bağımsız yerel kurallarda açılır; özgün PC mod eşleşmesi kanıtlanmış sayılmaz.
- Botlar önceden hazırlanmış yürüyüş ağını kullanır. Her doğuşta oyuncuya ulaşan yol, aşağı zemin ışını, ayakta kapsül boşluğu ve diğer botlara uzaklık kontrol edilir. En fazla dört bot, 10 hedef ve 90 saniye bu mobil sürümün yerel kurallarıdır. Bunlar özgün PC mod değerleri değildir.
- Ölüm, süre bitişi, yerel hedef tamamlama ve seçilen haritada tekrar oynama çalışır. Menü ve arka plan sırasında oyun durur. Harita altına düşme güvenli noktaya döndürür ve 20 yerel can götürür.
- Aktarımı tamamlanmış **903 silah** bu uygulamanın yerel koleksiyonunda erişilebilirdir. Seçim, iki ana silah, beş ekipman seti, mühimmat ve kayıt işlemleri önceki kontrolleri korur. Bu bir çevrimiçi hesap sahipliği/satın alma kaydı değildir.
- 48 kullanılabilir insan/kurt çifti, dönüşüm, kurt koşusu, destekleyen karakterlerde kaynak duvar tutunması, kaynak havada saldırı, ses ve dokunmatik kontroller pakete dahildir.
- PC kaynak atlaslarıyla giriş/lobi/oda/sonuç/envanter/karakter/kart/ayar ekranları kullanılır. Oda başlığındaki çakışan kaynak alanı kaldırıldı; uzun yerel mod/görev metinleri alanlarına sığdırıldı. Kaynak zafer rozeti yalnızca kazanılan yerel turda görünür.

## Doğrulama sınırı

[Yerel maç raporu](offline-match-validation.json), her haritada kapsül boşluğu olan doğma adaylarını, yol aramayı, kısa gerçek bot hareketini, duraklatmayı, kazanma/ölme/yeniden başlatmayı denetler. Her haritanın her koridorunda uzun süreli bot hareketi veya bütün PC mekanikleri kabul edilmiş sayılmaz. [Mobil regresyon](mobile-validation.json) ve [44 OpenGL görüntüsü](mobile-visual-validation.json) güncel kod özetiyle bağlıdır.

Son proje taraması bütün 49 binden fazla izlenen/izlenebilir dosyayı okur. Tarayıcıdaki testlere ait eksik kaynak örnekleri ve test raporunun proje dışı çıktı yolu, kasıtlı QA girdileridir; APK çalışma zamanı katalog bağımlılıkları ayrıca doğrulanır.

APK denetimi ZIP/CRC, bütün çalışma zamanı katalog bağımlılıkları, üç yerel mimarinin ELF başlıkları, Android kimliği, SHA-256, imza ve 16 KiB hizalamasını kapsar. Çevrimdışı uygulamanın **INTERNET izni istememesi** zorunludur. Fiziksel Android cihazında test yapılmış sayılmaz.

62 özgün mod/alt mod, harita görevleri/etkileşimleri, bütün kaynak ışık ve efektlerin görsel eşitliği tamamlanmadı. Kaynakta eksik ses/font/eşlemeler önceki raporlarda açıktır. Kart geliştirme, özgün PC kutu oranları ve çevrimiçi hizmetler çalışıyor gibi gösterilmez. Yerel kutu ve görev ödülleri hediye kabul akışını kullanır. APK'ya boyut artırmak için dolgu konmaz. Eski tam-PC-teslim denetimi korunur; çevrimdışı denetim onun yerine geçmez.

## Yeniden üretim

Godot 4.7.2 ve aynı sürüm Android export şablonu gerekir. SDK/JDK yollarını Godot editöründe ayarla. Özel imza anahtarı ve parola dosyası depoya eklenmez. Aynı uygulamayı sonradan güncellemek için aynı anahtarı sakla.

```sh
godot --headless --path godot --script res://tests/prepare_offline_maps.gd
python tools/validate_mobile.py --godot /path/to/godot --report docs/mobile-validation.json
DISPLAY=:0 python tools/capture_mobile.py --godot /path/to/godot
python tools/check_offline_ready.py --report docs/offline-readiness.json
python tools/build_offline_android.py --godot /path/to/godot --sdk /path/to/sdk \
  --keystore /private/offline.keystore --password-file /private/password \
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.13.0-offline.apk
```

Çıktı ile aynı konumda `.validation.json` oluşur. Araç, export işlemi sıfır kod döndürse bile kesilmiş ZIP'i kabul etmez; doğrulanmış imzalı kopyanın hedefe aktarımını ayrıca SHA-256 ile kontrol eder. Windows'taki mevcut `build_android.ps1 -Offline` yolu da ayrı çevrimdışı denetimi kullanır.
