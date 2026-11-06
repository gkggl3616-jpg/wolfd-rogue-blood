# 0.18.0 çevrimdışı Android sürümü

[**Tek APK indir — WolfRogueBlood-0.18.0-offline.apk**](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.18.0-offline/WolfRogueBlood-0.18.0-offline.apk)

**1,563,594,677 bayt (1.56 GB)**. Android 7.0 / API 24 ve üzeri; ARM64, ARMv7, x86_64. Kimlik `com.wolfrogue.blood.offline`, sürüm kodu 18. Önceki çevrimdışı APK ile aynı imza; uygulama verisini silmeden üzerine güncellenebilir.

SHA-256: `df28331df26f7788e1e14faeb0e7466f06cbf64afee61badba572c25c8e75497`.

[APK denetimi](android-offline-build.json): **54,317 ZIP girdisi, 35 katalog, 23,396 çözümlenen kaynak**, CRC, v2/v3 imza ve 16 KiB ZIP hizalaması. ARM64/x86_64 ELF hizalaması 16 KiB, ARMv7 4 KiB. İzin listesi boş; INTERNET izni yok. Fiziksel Android cihazı/emülatörü üzerinde test yapılmadı.

## Bu sürüm

- Güvenli alana ve gerçek telefon pikseline uyan üst menü; ayrı ve özgün sıradaki ALTIN/KP/NAKİT/JT sütunu; 44 piksel düğmeler ve Diğer menüsü. Klan Zinciri/Wolf Pass kaldırıldı.
- 182 insanda özgün silahsız menü duruşu. 164 özgün karakter kartı; kalan 18 kart karakterin kendi modelinden üretildi.
- OG'nin ayrı sol kol, sırt, sağ kol resimleri aynı sırada. İkinci sarı OG satırını oluşturan eski kimlikler tek görsel kartta birleştirildi; sahiplikleri korunur.
- 819 kaynak dövmenin yerelleştirilmiş adı (816 ayrı kart), 161 karakterin kaynak istatistikleri, doğrulanmış dövme dönüşüm hızı.
- 34 haritanın tamamında özgün seçim resmi. 67 kaynak modun Türkçe görünen adı; özgün sağ oda ayarlarında mod/harita/puan/süre/kapasite, kapasiteye uyan bot sayısı ve kaynak davet penceresi.
- 206 eksiksiz kaynak setin özgün sayısal fiyatla satışı ve atomik hediye teslimi. 86 önceki fiyatı belirsiz eşyaya set üzerinden erişim.
- Kullanıcının tercihiyle sınırsız Nakit ve KP (∞); Altın/GP sınırlı. Başlangıç envanteri sınırlı, satın alınan eşyalar hediye kutusunda kabul edilir.

[Kaynaklar, video analizi, değişiklikler ve gerçek fotoğraflar](PC_REFERANS_018.md).

## Korunan oyun kapsamı

34 kaynak haritada yerel bot maçları; beş kaynak Ölüm Oyunu varyantı, yerel Kurt Avı/Kurt Savaşı/öğretici; 903 kullanılabilir silah; 182 insan/kurt çifti; ayrı takım seçimleri; beş ekipman seti ve iki ana silah yuvası. Yuvarlak görselli eylem/yön düğmeleri, ateş sırasında nişan sürükleme, takılı yetenekle kurt koşusu ve çift ileri basma korunur. Dost/rakip için ayrı 0–4 bot seçimi, sonlu mühimmat/şarjör, sabit zorluk hasarı ve takım doğma alanları vardır.

0.17 kaynak efekt/ses bağları, en fazla 3 metre takla, kükremede renkli dövme, fiziksel geçiş kabulü, görev/hediye/kutu/rütbe ilerlemesi korunur. Önceden kabul edilen hediyeler ve ilerleme silinmez. Gerçek sunucu ve çevrimiçi hesap sahipliği kapsam dışıdır.

## Doğrulama ve sınırlar

[24 regresyon aşaması](mobile-validation.json), 40 Python testi, [297 yeni arayüz/kayıt/OG/duruş kontrolü](presentation-018-validation.json), [620 harita/iki takım/maç kontrolü](offline-match-validation.json) geçti. 132 güncel arayüz/oyun ekranı ve önceki 268 kaynak model kabul resmi dosya özetleriyle bağlıdır. Bunlar Godot 4.7.2 çalışma istasyonu kontrolleridir.

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
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.18.0-offline.apk
```

Tam-PC-teslim denetimi çevrimdışı denetim yerine kullanılmaz.
