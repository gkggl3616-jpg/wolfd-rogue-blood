# Güncel teslim: 0.25.0 ayrı test APK’sı

**Wolf Rogue Blood Test**, `com.wolfrogue.blood.offline.test`. Mevcut kurulumun yanında ayrı kayıtla çalışır. Dosya: `/workspace/artifacts/WolfRogueBlood-0.25.0-test.apk`, **1.573.199.303 bayt**. 34 harita ve mevcut içerik korunur; 0.21–0.25 değişiklikleri pakete dahildir. [FT düzeltmesi, video incelemesi ve açık kalan farklar](PC_REFERANS_025.md), [paket/imza raporu](android-offline-test-build-025.json). 33 regresyon aşaması ve 210 gerçek OpenGL görüntüsü geçti. Fiziksel telefon testi yapılmadı.

Aşağıdaki 0.20 kaydı önceki üretim paketinin tarihsel belgesidir.

# 0.20.0 çevrimdışı Android sürümü

[**Tek APK indir — WolfRogueBlood-0.20.0-offline.apk**](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.20.0-offline/WolfRogueBlood-0.20.0-offline.apk)

**1,553,638,330 bayt (1.55 GB)**. Android 7.0 / API 24 ve üzeri; ARM64, ARMv7, x86_64. Kimlik `com.wolfrogue.blood.offline`, sürüm kodu 20. Önceki çevrimdışı APK ile aynı imza; uygulama verisini silmeden üzerine güncellenebilir.

SHA-256: `f2cba63574cca01ddd25c30596f1b0d963334b8cc5142cb3df53021345936f2e`.

[APK denetimi](android-offline-build.json): **54,330 ZIP girdisi, 38 katalog, 23,396 çözümlenen kaynak**, CRC, v2/v3 imza ve 16 KiB ZIP hizalaması. ARM64/x86_64 ELF hizalaması 16 KiB, ARMv7 4 KiB. İzin listesi boş; INTERNET izni yok. Fiziksel Android cihazı/emülatörü üzerinde test yapılmadı.

## Bu sürüm

- 819 dövmenin tamamında özgün mağaza kartı; ayrı kol/gövde görselleri, tüm sırtlarda onaylı OG yönü ve çizim sırası.
- Büyük kapatma simgesi, kaynak sayfaların önünde kapanma düğmesi ve genişletilmiş mobil dokunma alanları.
- Ayarlar → Kontrol → Kontrolleri düzenle: düğmeleri sürükle, %60–%200 boyutlandır, kaydet/iptal/varsayılan. Hareket/eylem, güç, silah ve menü kontrolleri birlikte ayarlanır.
- Kademeli kükreme YP'si, YP'den önce düşen hasar ve dövmeye bağlı ek YP tutma. Ayrı, sonlu SP bakiyesi; ekipman/mutasyon bedeli ve öldürme kazanımı. Sayısal değerler belgelenmiş çevrimdışı uyarlamadır; tam PC sunucu değerleri değildir.
- Dört kaynak Yıkım varyantı, altı kaynak haritanın 12 özgün bomba alanı, seçilebilir tur kazanma hedefi/tur süresi, yeni turda doğuş, tur sırasında kalıcı ölüm, bomba kurma/çözme ve bot hedef davranışı.
- Önceki tek APK kapsamı ve sınırsız Nakit/KP tercihi korunur. Gerçek sunucu kapsam dışıdır.

[Kaynaklar, video durumları, kapsam ve fotoğraflar](PC_REFERANS_020.md).

## Korunan oyun kapsamı

34 kaynak haritada yerel bot maçları; beş kaynak Ölüm Oyunu varyantı, yerel Kurt Avı/Kurt Savaşı/öğretici; 903 kullanılabilir silah; 182 insan/kurt çifti; ayrı takım seçimleri; beş ekipman seti ve iki ana silah yuvası. Yuvarlak görselli eylem/yön düğmeleri, ateş sırasında nişan sürükleme, takılı yetenekle kurt koşusu ve çift ileri basma korunur. Dost/rakip için ayrı 0–4 bot seçimi, sonlu mühimmat/şarjör, sabit zorluk hasarı ve takım doğma alanları vardır.

Yıkım ek olarak 12 özgün bomba alanında doğrulanır. 0.17 kaynak efekt/ses bağları, en fazla 3 metre takla, kükremede renkli dövme, fiziksel geçiş kabulü, görev/hediye/kutu/rütbe ilerlemesi korunur. Önceden kabul edilen hediyeler ve ilerleme silinmez. Gerçek sunucu ve çevrimiçi hesap sahipliği kapsam dışıdır.

## Doğrulama ve sınırlar

[27 regresyon aşaması](mobile-validation.json), 40 Python testi, [43 yeni dövme/kontrol/YP/SP/tur kontrolü](mobile-020-validation.json), [620 harita/iki takım/maç kontrolü](offline-match-validation.json) geçti. 155 güncel arayüz/oyun ekranı ve önceki 268 kaynak model kabul resmi dosya özetleriyle bağlıdır. Bunlar Godot 4.7.2 çalışma istasyonu kontrolleridir.

**Tam PC eşitliği değildir.** 426 eşyanın kaynak satış fiyatı sıfır/kaydı eksiktir; tahmini fiyat eklenmedi. Satın alma her bileşenden bir kalıcı yerel kopyadır; kaynak süre/kampanya ve tüm paket adetleri uygulanmış değildir. Kaynak zırh puanlarının gösterilmesi, bütün bölgesel zırh/donma etkilerinin çalıştığı anlamına gelmez. Diğer maç modları, etkileşimli dünya parçaları ve bazı özel efekt/ses koşulları eksiktir. #72 Ruins, #37 Bridge, #106 UnderWorld haritalarında bütün takım alanları arasında bot rotası yoktur; botlar erişilebilir yüzeyde devriye gezer. Efekt kataloğunun 158 eksik/desteklenmeyen düğüm kaydı korunur. Hatasızlık veya fiziksel telefon uyumluluğu garanti edilmiş sayılmaz.

## Yeniden üretim

Godot **4.7.2**, Android export şablonu, SDK/JDK ve özel imza gerekir. Anahtar/parola depoda değildir.

```sh
python tools/configure_mobile_imports.py
godot --headless --path godot --editor --import --quit
python tools/validate_mobile.py --godot /path/to/godot --report docs/mobile-validation.json
DISPLAY=:0 python tools/capture_mobile.py --godot /path/to/godot
python tools/check_offline_ready.py --report docs/offline-readiness.json
python tools/build_offline_android.py --godot /path/to/godot --sdk /path/to/sdk \
  --keystore /private/offline.keystore --password-file /private/password \
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.20.0-offline.apk
```

Tam-PC-teslim denetimi çevrimdışı denetim yerine kullanılmaz.
