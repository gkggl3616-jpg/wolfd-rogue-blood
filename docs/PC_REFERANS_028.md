# 0.28 · Kaynak silahlar, bomba hareketi ve çevrimdışı farklar

Kullanıcının son isteği gereği bu çalışma **kaynak kodu ve gerçek oyun fotoğrafları** içindir. Yeni APK hazırlanmadı veya yayımlanmadı. Önceden yayımlanan 0.27 APK bu değişiklikleri içermez. Çevrimdışı kapsam, 34 harita, 903 silahlık katalog ve videoya bağlı göreli arayüz yerleşimi korunur.

[Fotoğraf klasörü](review/update-028) · [Önceki ayrıntılı inceleme](PC_REFERANS_027.md)

## Kaynakla kapatılan farklar

| Alan | Bu çalışmadaki değişiklik | Kanıt |
|---|---|---|
| Silah ayarları | 903 satırın şarjör kapasitesi, atış aralığı, temel/sıçrama hasarı, saçma sayısı, model ölçeği ve birinci kişi konumu özgün ikili tablodan bağlandı. Aynı satır içindeki iki alternatif silah öneki ayrı çözüldü. | [Alan sınırları ve bağımsız örnekler](weapon-rules-source-028.json) |
| Kamera ve envanter | Bütün silahlara aynı kamera konumunu uygulama kaldırıldı. Özellik paneli oyunda kullanılan kaynak temel değerleri ve özgün animasyon süresini gösterir. | [903 kaydın motor testi](mobile-028-validation.json) |
| Bomba hazırlama/atma | 31 ayrı bomba el modeline gerçek `prefire/postfire` kemik hareketleri eklendi. Mermi, saldırı sayacı ve uçan model, özgün `fire_key` anında oluşur. Bırakmadan silah değiştirme atışı iptal eder ve bombayı korur. | [216 modelin hareket/olay dökümü](weapon-motion-source-028.json) |
| Silah sesleri | 903 satırın ateş, üç dolum ve seçme sesi eşleştirildi. Sağlanan sesler özgün animasyon anahtarlarında çalar; örneğin AK dolumu 333/1266/1833 ms olaylarını kullanır. | [Ses kaynağı ve bulunmayan dosyalar](weapon-audio-source-028.json) |
| Pompalı dolumu | Kaynak `SUPAS` mühimmat ailesinin `Reload` klibi bir mermi ekler, `Reload2` bitirme hareketini oynatır. Ateşe basmak mevcut ekleme sonrasında bitirme hareketine geçer. Şarjör tek seferde doldurulmaz. | [Gerçek dolum akışı](mobile-028-validation.json) |
| Uçan mühimmat | Silahların istediği 72 özgün tanımın 66 ayrı model/kaplaması, kaynak sınıfı, hızı, yerçekimi ve ömrü bağlandı. Ok, roket ve enerji atışı gerçek fiziksel uçuş/temas kullanır. 26 özgün çarpma efekti bağı çözüldü. Enerji mermisinin kaynak saydamlık eğrisini opaklık sayıp görünmez bırakma ve eski parçacıkları uçan nesneyle sürükleme hataları giderildi. | [Kaynak ve kapsam](projectile-source-028.json) |
| Fizik hataları | Yüksek hızlı mermi ince duvardan atlamaz. Alan hasarının görüş kontrolü karakter gövdelerini duvar saymaz. Mayın karakter kapsülünün tamamına göre algılar; dostu tetik saymaz. Yapışan mühimmat hedefi izler. Sahibi ölen/silinen aktörün atılmış bombası maç sürerken çalışır; ölüm sonrası oyuncu elemesi sayılır. | [Gerçek motor çarpışma testleri](mobile-028-validation.json) |
| Silah değiştirme | Her silahın kalan atış bekleme süresi ayrı korunur. Başka silaha geçmek öncekinin beklemesini taşımaz veya sıfırlayarak atış hızını aşmaz. | [Regresyon](mobile-028-validation.json) |
| Beş mod | Kaynak 1022 Bomba, 1023 Bıçak, 1024 Tabanca, 1025 Keskin Nişancı ve 1026 Ağır Silah varyantları açıldı. Silah izinleri özgün bit maskesinden gelir; form, harita, puan ve süre sınırları korunur. Aynı haritada mod değiştirildiğinde eski başlığın önbellekte kalması düzeltildi. Başlangıç ekipmanı sahip olunan izinli silahlardan seçilir. | [Kaynak kurallar](../godot/assets/gameplay/source.json) ve [gerçek maç testleri](mobile-028-validation.json) |
| Bot ekipmanı | Bu beş varyantta botlar izinli özgün üçüncü kişi silah modellerini taşır; sonlu mühimmat/şarjör ve kaynak atış aralığı kullanır. Ağır silah botu özgün EM-134Minigun HH modelini kullanır. İsabet hasarı 8 ve can zorluğa göre değiştirilmez. | [HH model/kaplama kökeni](bot-weapons-source-028.json) |
| Bot geçişleri | Gerçek yatay hareket sınırı içindeki yeni adaylar arandı. Yalnız gerçek kapsül kalkış/iniş sınamasını geçen yönler eklendi: toplam 122 bağlantı, önceki 85'e göre +37. | [329 fizik kontrolü](bot-traversal-validation-015.json), [reddedilen adaylar ve sınırlar](bot-route-research-028.json) |

## İnceleme yöntemi ve açık kalanlar

Önceki [74:53 hareket/ses taraması](video-audit-026.json) ve [hedefli FT can/süre kanıtı](video-audit-027.json) korunur. Bu çalışmanın yeni kanıtı özgün PC dosyalarının alan/sınır/hash incelemesi, gerçek Godot fiziği ve OpenGL görüntüleridir. Bu, bütün videoları yeniden kesintisiz insan gözüyle izlemiş olmak olarak sunulmaz. FT'nin yalnız etkin paket süresince mor el efekti vermesi ve mevcut kesirli candan yüzde kaybı korunur.

Şu alanlar hâlâ tam PC eşitliği sağlamaz:

- **Ruins #72 ve Bridge #37 karşı takım bot yolları kopuk.** Yeni geçişler iki haritanın kendi erişilebilir bölgelerini iyileştirir; karşı takım sorunu çözülmüş sayılmaz. UnderWorld #106'nın önceki doğrulanmış karşı takım rotası korunur. Kaynak sıçrama alanlarının anlamı ve dünya BSP çarpışmaları doğrulanmadan görünmez zemin/ışınlanma eklenmedi.
- **Gömülü ışık haritaları uygulanmadı.** Üç kaynak DAT'ın ışık bloğu boyutları tekrar incelendi; sıkıştırılmış içerik güvenle çözülmedi. [Kaynak hashleri ve blok boyutları](map-lighting-research-028.json). Bütün dünya modeli/dinamik geometri ve özgün PC renderer davranışları tamamlanmış değildir.
- **Silah/karakter ayarlarının tamamı çözülmedi.** Bölgesel zırh, bütün mesafe/geri tepme alanları, alternatif mod girişleri, bütün kurt istatistik eşlemeleri ve FT hız biriminin dönüşümü açık. Kaynak temel silah alanları doğrulandı diye `sourceStatsVerified` bütünüyle doğru yapılmadı. Yedek mühimmat politikası yerel uyarlamadır.
- **Özel mühimmat sınıflarının bütün oyun kuralları tamamlanmadı.** Hologram kopyasının davranışı, bütün algılama/element etkileri ve sınıfa özgü PC ayrıntıları açık. 72 tanımın kaynak modeli/uçuşu bulunması bütün özel yeteneklerin tamamlandığı anlamına gelmez. Çarpışma küresi, .4 sekme katsayısı, 6 m alan hasarı eğrisi, mayın kurulum gecikmesi ve saçılma açısı açık yerel fizik uyarlamalarıdır. Kendine hasar/dost ateşi politikası da yereldir.
- Verilen arşivde **7 roket kaydının `WT-RL2_PV_Muzz` grubu**, ateş döngüsü/üç yüzey sesi, `guns/projectiles/snd/rocket.wav` ve altı özgün silah sesi bulunmuyor. İsim benzerliğine göre başka ses/efekt özgünmüş gibi eklenmedi; dosya adları kaynak raporlarında kayıtlıdır.
- 67 kaynak modun **14'ünde** mevcut yerel çatışma akışı desteklenir; kalan 53 başka kuralla açılmadı. Modern kaplama/hesap ekipmanlarının bütün eşlemeleri, birebir ses/efekt çizimi ve çevrimiçi sunucu kapsamı tamamlanmış değildir. Yeni mod botlarının silah el bağlantısı/yönelimi ve genel insan beden animasyonu mevcut mobil uyarlamadır; bütün özgün silaha özel HH hareket/yön eşlemeleri tamamlanmadı.

**Fiziksel Android cihaz veya emülatör testi yapılmadı. “0 eksik” sonucu verilmez.**

## Doğrulama

**36/36 regresyon aşaması, 3.126 hedefli kontrol ve 18 grupta 327 gerçek OpenGL görüntüsünün denetimi geçti.** Bunların 40 tanesi yeni 0.28 klasöründedir. Çevrimdışı kaynak denetimi engel bildirmedi. Çalışma zamanı SHA-256: `c99cea6a250bb9bc89f39815634c087e67bb79496dc6f32f264e89efb5beb4fe`.

[Hedefli 0.28 raporu](mobile-028-validation.json), [tam regresyon](mobile-validation.json), [40 yeni gerçek OpenGL görüntüsü](update-028-visual-validation.json) ve [çevrimdışı hazır olma denetimi](offline-source-validation-028.json). Görüntüler telefon çekimi değildir; gerçek Godot/OpenGL çalıştırmasından alınır. Hiçbir yeni APK/etiket/sürüm dosyası bu çalışma kapsamında yayımlanmaz.
