# 0.19.0 çevrimdışı Android sürümü

[**Tek APK indir — WolfRogueBlood-0.19.0-offline.apk**](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.19.0-offline/WolfRogueBlood-0.19.0-offline.apk)

**1,553,559,799 bayt (1.55 GB)**. Android 7.0 / API 24 ve üzeri; ARM64, ARMv7, x86_64. Kimlik `com.wolfrogue.blood.offline`, sürüm kodu 19. Önceki çevrimdışı APK ile aynı imza; uygulama verisini silmeden üzerine güncellenebilir.

SHA-256: `7ac9b5992f54e143d993cd811fb592f2ead16dbe70e98b18afffe182d48d081f`.

[APK denetimi](android-offline-build.json): **54,321 ZIP girdisi, 37 katalog, 23,396 çözümlenen kaynak**, CRC, v2/v3 imza ve 16 KiB ZIP hizalaması. ARM64/x86_64 ELF hizalaması 16 KiB, ARMv7 4 KiB. İzin listesi boş; INTERNET izni yok. Fiziksel Android cihazı/emülatörü üzerinde test yapılmadı.

## Bu sürüm

- Diriliş/Reboot kurt gövdelerinde derinlik çizimi; karakterlerde sıkıştırılmış köşe verisi ve otomatik LOD kapalı. Kaynak modeller ve OG yönü korunur. Telefon üzerindeki sonuç henüz doğrulanmadı.
- Ekran genişliğine yayılan, çözünürlükle büyüyen üst menü. Hediye resimlerinde özgün atlas kesiti ve saydam boşluk temizliği.
- Sırayla gerçek UMFi1/UMFi2 pençe saldırıları; kullanıcının istediği %15 hız artışı.
- Her basışta yeniden başlayan kükreme; önceki ses/efekt temizlenir. Tamamlandığında yenilenen ayrı YP, önce YP'den düşen hasar ve taşmayan YP göstergesi. 200/99 sınırları belgelenmiş çevrimdışı uyarlamadır; tüm PC varyantlarının çözülmüş özgün değeri değildir.
- İşaretli KURT KOŞ düğmesi kaldırıldı; takılı yetenekle çift ileri koşu ve 3 metre takla korunur. Can/enerji düğmeleri doğru eşya resmiyle büyütüldü.
- Oda/lobi müzik yönlendirmesi ve efektler için ana çıkış tepe sınırlayıcısı. Maçta ve maç duraklatmasında lobi müziği çalmaz.
- 0.18'in özgün harita fotoğrafları, 206 kaynak seti, 816 ayrı dövme kartı ve mağaza/hediye akışları korunur. Sınırsız Nakit/KP ve sonlu Altın/GP tercihi sürer.

[Kaynaklar, değişiklikler, sınırlar ve gerçek fotoğraflar](PC_REFERANS_019.md).

## Korunan oyun kapsamı

34 kaynak haritada yerel bot maçları; beş kaynak Ölüm Oyunu varyantı, yerel Kurt Avı/Kurt Savaşı/öğretici; 903 kullanılabilir silah; 182 insan/kurt çifti; ayrı takım seçimleri; beş ekipman seti ve iki ana silah yuvası. Yuvarlak görselli eylem/yön düğmeleri, ateş sırasında nişan sürükleme, takılı yetenekle kurt koşusu ve çift ileri basma korunur. Dost/rakip için ayrı 0–4 bot seçimi, sonlu mühimmat/şarjör, sabit zorluk hasarı ve takım doğma alanları vardır.

0.17 kaynak efekt/ses bağları, en fazla 3 metre takla, kükremede renkli dövme, fiziksel geçiş kabulü, görev/hediye/kutu/rütbe ilerlemesi korunur. Önceden kabul edilen hediyeler ve ilerleme silinmez. Gerçek sunucu ve çevrimiçi hesap sahipliği kapsam dışıdır.

## Doğrulama ve sınırlar

[25 regresyon aşaması](mobile-validation.json), 40 Python testi, [45 yeni model/hediye/menü/saldırı/kükreme/ses kontrolü](mobile-019-validation.json), [620 harita/iki takım/maç kontrolü](offline-match-validation.json) geçti. 146 güncel arayüz/oyun ekranı ve önceki 268 kaynak model kabul resmi dosya özetleriyle bağlıdır. Bunlar Godot 4.7.2 çalışma istasyonu kontrolleridir.

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
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.19.0-offline.apk
```

Tam-PC-teslim denetimi çevrimdışı denetim yerine kullanılmaz.
