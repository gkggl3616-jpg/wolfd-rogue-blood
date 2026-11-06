# 0.17.0 çevrimdışı Android sürümü

[**Tek APK indir — WolfRogueBlood-0.17.0-offline.apk**](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.17.0-offline/WolfRogueBlood-0.17.0-offline.apk)

**1.562.434.631 bayt (1,56 GB)**. Android 7.0 / API 24 ve üzeri; ARM64, ARMv7, x86_64. Kimlik `com.wolfrogue.blood.offline`, sürüm kodu 17. Önceki çevrimdışı sürümlerle aynı sertifikayı kullanır; uygulama verisini silmeden üzerine güncellenebilir.

SHA-256: `dd1d782d0a0a4857a0357c82e730644d051a56749bd5d90bdd03a6393b651439`.

[APK denetimi](android-offline-build.json): **54.306 ZIP girdisi. 32 katalog. 23.416 çözümlenen kaynak**, CRC, v2/v3 imza ve 16 KiB ZIP hizalaması. ARM64/x86_64 ELF hizalaması 16 KiB, ARMv7 4 KiB. **İzin listesi boş**, INTERNET izni yok. Fiziksel cihaz/emülatör testi yapılmadı.

## Bu sürüm

- Varsayılan dört yön düğmesi; takılı kurt yeteneğine bağlı görselli koşu düğmesi ve çift ileri basma.
- Kullanıcının istediği sınırsız Nakit ve KP (∞); Altın/GP sınırlı kalır.
- Mağaza/gerçek sahiplik ayrımı, sınırlı başlangıç eşyaları, 1.414 eşya için özgün fiyat sütunuyla eşleşme ve hediye onayıyla satın alma. Fiyatı doğrulanmayanlar ücretsiz sayılmaz.
- Boyun kemiğiyle yana dönen kükreme ve elde hareketten geride kalan alt efekt konumları düzeltildi.

[Değişiklikler, kaynak kanıtları ve gerçek fotoğraflar](PC_REFERANS_017.md).

- 182 kullanılabilir insan/kurt çifti: 134 yeni çift, gerçek kırmızı/mavi takım modelleri ve ayrı kaydedilen takım seçimleri.
- 34 kaynak harita: önceki 19 + 15 ek harita; doğru takım doğma grupları, radarlar ve seçim görselleri.
- 819 dövme, sol kol–sırt–sağ kol set düzeni; eşya kimliğine bağlı doğrulanmış güçler. 11 kaynak pençenin ayrı oranları ve gerçek el kemiği/doku izleri.
- Kaynak adındaki kalite etiketleriyle filtre ve kart renkleri; parmakla envanter kaydırma; ateşi tutarken nişanı sürükleme; telefon güvenli alanı ve tam model kadrajı.
- Büyük, saydam karakter/kurt önizlemesi; kaynak kırmızı/mavi takım simgeleri. Ek STATS kutusu ve dövme rafı kaldırıldı.
- Takla mesafesi en fazla 3 metre; kükremede renkli dövme korunur. 52 karakterin kaynak kükreme efekt bağları eklendi.
- Kendi takımı ve rakipler için ayrı 0–4 bot seçimi; dost ateşi engeli, iki takım skoru ve dost botlu maçta yeniden doğuş.
- 628 ClientFX grubu, dört native el efekti tanımı, 95 kaynak efekt modeli ve animasyon karelerinden gerçek tetikler.
- 791 karakter/ses eşleştirmesi (134 ortak WAV); gerçek güçlü yer pençesi, dönüşüm ve maç duyuruları.
- Beş kaynak Ölüm Oyunu varyantı: 40–160 puan, 10–40 dakika, biçim kısıtları ve skora göre sonuç.
- Botlar uygun dar geçişte çömelir, fiziksel olarak doğrulanan 78 kısa geçişi kullanır.

Eski otomatik tam envanter, varsayılan eşyalara ve hediye defterinde onaylanmış alımlara geçirilir. Önceki bakiye ve kabul edilmiş hediyeler korunur. Kaynak resmi, sahiplik veya güç kimliği yerine kullanılmaz.

## Kullanım ve doğrulama

**Oda oluştur → Çevrimdışı · Botlu Eğitim → harita seç → Başlat.** Ayrıca eğitim arenası, yerel Kurt Avı ve öğretici bulunur. İki ana silah, beş ekipman seti, 903 kullanılabilir silah, hediye kabulü, yerel görev/kutu/GP/rütbe akışları korunur. Gerçek sunucu veya çevrimiçi hesap sahipliği taklit edilmez.

[23 regresyon aşaması](mobile-validation.json), 40 Python testi, [620 harita/iki takım/maç kontrolü](offline-match-validation.json), [62 bot kontrolü](bot-validation.json), [191 ekipman/hediye kontrolü](round-equipment-gift-validation.json), [yeni dokunma/kayıt kontrolleri](mobile-015-validation.json) geçti. 118 güncel arayüz/oyun ekranı ve 268 yeni model resmi dosya özetleriyle bağlıdır. Bunlar Godot 4.7.2 çalışma istasyonu kontrolleridir.

**Tam PC eşitliği değildir.** Mağazada 512 kimlikte fiyat doğrulanamadı. Kaynak süre/paket/kampanya alanlarının hepsi çözülmedi; alışveriş açıkça bir adet kalıcı yerel kullanım verir. Bütün dövme/pençe değiştiricileri tamamlanmadı. #72 Ruins, #37 Bridge ve #106 UnderWorld'de bütün takım alanları arası bot rotaları bağlı değildir. Botlar erişilebilir yüzeylerde devriye gezer. Özgün etkileşimli dünya parçaları, diğer maç modları, bazı özel ses/efekt koşulları ve bazı eşya değiştiricileri bekliyor. Efekt kataloğunda 158 eksik/desteklenmeyen düğüm raporlanır; bütün PC efektleri tamamlandı denmez. OG/09 dövmesi ve varsayılan pençe izi doğrulanabilir kaynakta bulunamadı. Önceki alınamayan kaynak sesler/122 ek model ve erişilemeyen YouTube videoları 0.15 kaydında korunur; yeni üç TikTok görüntüsü ve kükreme kaynakları bu kez incelenebildi. [Güncel kapsam](PC_REFERANS_017.md). Hatasızlık veya fiziksel telefon uyumluluğu garanti edilmiş sayılmaz.

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
  --temp /large/temporary/volume --output /output/WolfRogueBlood-0.17.0-offline.apk
```

Mevcut harita yürüyüş ağları ve fiziksel kabulden geçmiş atlayışlar depoya dahildir. Ağı yeniden üretmek, `traversals.json` kaynak özetlerini ve fiziksel atlayış kabulünü de yeniden gerektirir. Tam-PC-teslim denetimi değiştirilmedi; çevrimdışı denetim onun yerine geçmez.
