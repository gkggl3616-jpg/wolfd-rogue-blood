# 0.16.0 çevrimdışı Android sürümü

[**Tek APK indir — WolfRogueBlood-0.16.0-offline.apk**](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.16.0-offline/WolfRogueBlood-0.16.0-offline.apk)

**1.535.468.008 bayt (1,54 GB)**. Android 7.0 / API 24 ve üzeri; ARM64, ARMv7, x86_64. Kimlik `com.wolfrogue.blood.offline`, sürüm kodu 16. Önceki çevrimdışı sürümlerle aynı sertifikayı kullanır; uygulama verisini silmeden üzerine güncellenebilir.

SHA-256: `4d4ae037fde2e2767123d2e30724785bdf94d34a08ed5482fc1677452835cc83`.

[APK denetimi](android-offline-build.json): **53.365 ZIP girdisi. 27 katalog. 23.022 çözümlenen kaynak**, CRC, v2/v3 imza ve 16 KiB ZIP hizalaması. ARM64/x86_64 ELF hizalaması 16 KiB, ARMv7 4 KiB. **İzin listesi boş**, INTERNET izni yok. Fiziksel cihaz/emülatör testi yapılmadı.

## Bu sürüm

[Değişiklikler, kaynak kanıtları ve gerçek fotoğraflar](PC_REFERANS_016.md).

- 182 kullanılabilir insan/kurt çifti: 134 yeni çift, gerçek kırmızı/mavi takım modelleri ve ayrı kaydedilen takım seçimleri.
- 34 kaynak harita: önceki 19 + 15 ek harita; doğru takım doğma grupları, radarlar ve seçim görselleri.
- 819 dövme, sol kol–sırt–sağ kol set düzeni; eşya kimliğine bağlı doğrulanmış güçler. 11 kaynak pençenin ayrı oranları ve gerçek el kemiği/doku izleri.
- Kaynak adındaki kalite etiketleriyle filtre ve kart renkleri; parmakla envanter kaydırma; ateşi tutarken nişanı sürükleme; telefon güvenli alanı ve tam model kadrajı.
- Büyük, saydam karakter/kurt önizlemesi; kaynak kırmızı/mavi takım simgeleri. Ek STATS kutusu ve dövme rafı kaldırıldı.
- Takla mesafesi en fazla 3 metre; kükremede renkli dövme korunur. 52 karakterin kaynak kükreme efekt bağları eklendi.
- Kendi takımı ve rakipler için ayrı 0–4 bot seçimi; dost ateşi engeli, iki takım skoru ve dost botlu maçta yeniden doğuş.
- Botlar uygun dar geçişte çömelir, fiziksel olarak doğrulanan 78 kısa geçişi kullanır.

0.14'ten gelen görsel dövme kayıtları korunur. Eski kaydın eşya kimliği bulunmuyorsa, gücünü bağlamak için ilgili eşyayı tekrar **Tak** ile seç. Aynı resmi kullanan farklı eşyaların gücü tahmin edilmez.

## Kullanım ve doğrulama

**Oda oluştur → Çevrimdışı · Botlu Eğitim → harita seç → Başlat.** Ayrıca eğitim arenası, yerel Kurt Avı ve öğretici bulunur. İki ana silah, beş ekipman seti, 903 kullanılabilir silah, hediye kabulü, yerel görev/kutu/GP/rütbe akışları korunur. Gerçek sunucu veya çevrimiçi hesap sahipliği taklit edilmez.

[21 regresyon aşaması](mobile-validation.json), 40 Python testi, [620 harita/iki takım/maç kontrolü](offline-match-validation.json), [62 bot kontrolü](bot-validation.json), [191 ekipman/hediye kontrolü](round-equipment-gift-validation.json), [yeni dokunma/kayıt kontrolleri](mobile-015-validation.json) geçti. 100 güncel arayüz/oyun ekranı ve 268 yeni model resmi dosya özetleriyle bağlıdır. Bunlar Godot 4.7.2 çalışma istasyonu kontrolleridir.

**Tam PC eşitliği değildir.** #72 Ruins, #37 Bridge ve #106 UnderWorld'de bütün takım alanları arası bot rotaları bağlı değildir. Botlar erişilebilir yüzeylerde devriye gezer. Özgün etkileşimli dünya parçaları, bütün kükreme efektleri/sesleri ve bazı eşya değiştiricileri bekliyor. OG/09 dövmesi ve varsayılan pençe izi doğrulanabilir kaynakta bulunamadı. Önceki alınamayan kaynak sesler/122 ek model ve erişilemeyen YouTube videoları 0.15 kaydında korunur; yeni üç TikTok görüntüsü ve kükreme kaynakları bu kez incelenebildi. [Güncel kapsam](PC_REFERANS_016.md). Hatasızlık veya fiziksel telefon uyumluluğu garanti edilmiş sayılmaz.

## Yeniden üretim

Godot **4.7.2**, aynı sürüm Android export şablonu, SDK/JDK ve özel imza dosyaları gerekir. Anahtar/parola depoya eklenmez.

```sh
python tools/configure_mobile_imports.py
godot --headless --path godot --editor --import --quit
python tools/validate_mobile.py --godot /path/to/godot --report docs/mobile-validation.json
DISPLAY=:0 python tools/capture_mobile.py --godot /path/to/godot
python tools/check_offline_ready.py --report docs/offline-readiness.json
python tools/build_offline_android.py --godot /path/to/godot --sdk /path/to/sdk \
  --keystore /private/offline.keystore --password-file /private/password \
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.16.0-offline.apk
```

Mevcut harita yürüyüş ağları ve fiziksel kabulden geçmiş atlayışlar depoya dahildir. Ağı yeniden üretmek, `traversals.json` kaynak özetlerini ve fiziksel atlayış kabulünü de yeniden gerektirir. Tam-PC-teslim denetimi değiştirilmedi; çevrimdışı denetim onun yerine geçmez.
