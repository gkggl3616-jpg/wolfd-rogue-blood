# 0.32 · Lobi, oda kurma ve oda ekranı

Son istek eski videolarla lobi/oda oluşturmayı eşleştirmekti. Bu sürüm gerçek yerel oda akışını ve kaynak ekran alanlarını düzeltir. Önceki kurt 240 / insan 100 HP, üst/alt gövde hareketleri, FT, bot siperi ve takım davranışı korunur.

[Yeni gerçek görüntüler](review/update-032) · [Video incelemesinin kapsamı](video-ui-audit-032.json) · [Yeni motor kontrolleri](mobile-032-validation.json)

## Giderilen somut farklar

- **Lobi sağ paneli:** Arşivdeki `interface/fieldlistscreen` zaten ayrı oda adı, harita, mod, seçenek simgesi, insan/kurt simgeleri, silah kuralı, kişi sayısı, hedef ve süre alanlarına sahipti. Önceki kod bunları gizleyip yerine büyük bir metin kutusu çiziyordu. Bu alanlar şimdi gerçek seçili odadan doldurulur; kaynak çerçeve ve koordinatlar kullanılır.
- **Seç ve katıl:** Satıra dokunmak odayı seçer ve önizlemeyi değiştirir. Ayrı kaynak **Katıl** düğmesi o odaya girer. Fareyle çift tıklama da giriş yapar. Küçük ekranda genişletilmiş dokunma alanları komşu satırı seçmez; parmağa en yakın satır ve aynı parmağın bırakışı kullanılır. Sürükleme iptal edilir.
- **Gerçek yerel oda listesi:** Oluşturulmuş farklı odalar ayrı sabit numarayla korunur. Mod filtresi, sıralama ve kaynak 16 satırlık sayfalama çalışır. Yenileme uzak oyuncu/oda uydurmaz. Liste uygulama yeniden açılınca atomik kayıttan yüklenir; kayıt hatası oda, takım ve kimlik sayacını değiştirmez.
- **Kaynak üst menü:** 1024×768 tuval üzerinde 58 birim yüksekliğinde sabit kalır. Önceki 72 fiziksel piksel şeridinin menü içeriğini ayrıca dikey sıkıştırıp kaydırması kaldırıldı. Aynı profil, GP, para ve araç konumları lobi/oda/oluşturma/envanterde korunur. Daha geniş fiziksel dokunma alanı resimleri büyütmez. Dokunmadan üretilen ikinci fare tıklaması iptal edilen hareketi yeniden çalıştıramaz. Geniş KLAN atlasının yanlış ilk32pikseli yerine özgün amblem kesiti ve metni kullanılır.
- **Oda kurma:** Gerçek lobi arka planda kalır, kaynak `createfield` penceresi onun üzerinde açılır. Yeni varsayılan oda ilk kabul edilmiş PC Ölüm Oyunu haritasını gerçek fotoğrafıyla gösterir. Eğitim modları yine seçilebilir. Harita resmine dokunmak mevcut galeriye gider; bot ayarları oluşturma sırasında üstteki Diğer eyleminden açılır. Kaynak pencerenin dışına ek düğme taşınmaz.
- **Şifre:** Kaynak parola alanı gerçek yerel oda girişini korur. Düz metin kalıcı dosyaya yazılmaz; oda başına rastgele tuz ve SHA-256 özeti tutulur. Yanlış parola odayı değiştirmez; iptal lobide kalır. Yeni oda öncekinin parolasını devralmaz. Bu bir çevrimiçi kimlik/oda hizmeti değildir.
- **Başlık ve taslak:** Eski arşiv alanı14karakterde Türkçe başlığı kesiyordu. Oluşturma ve ayarlarda48karakterlik yerel sınır uygulanır; özgün PC üst sınırı diye sunulmaz. Klavye/görünüm değişiminde metin, parola ve imleç korunur. İptal oda kaydını değiştirmez; onay aynı odanın kaydını düzenler.
- **Takım alanı:** Videodaki yeşil vurgu taşıyan özgün kırmızı/mavi başlık resmi kullanılır. Kaynak hazır/oda sahibi işaretleri ve gerçekten kapalı yuvaların KAPALI resmi görünür. Sekiz44birimlik satır gereksiz kaydırma olmadan yerleşir. Botların gerçek farklı adları korunur; uzak hesap rütbesi, klan üyeliği veya ping uydurulmaz.
- **Oda ayarları:** Kaynak mod seçeneği66birimlik kendi alanına döndü; komşu kişi alanına taşmaz. Harita seçimi kaynak411×19alanında kalır; galeri harita önizlemesine bağlıdır. Başlık/parola/mod/harita/kapasite/hedef/süre/takım ve saldırı-savunma değişimi gerçek ayarlarla bağlantılıdır.

## Kaynak alanları

| Bölge | 1024×768 kaynak koordinatı |
|---|---|
| Üst şerit | 0,0 · 1024×58 |
| Lobi satırları | 11,117 · 587×21; 25 birim aralık,16satır |
| Lobi harita resmi | 611,133 · 407×99 |
| Oda kırmızı/mavi listeleri | 4,141 / 308,141 · her biri294×352 |
| Oda harita resmi | 611,277 · 407×99 |
| Oda kurma penceresi | 303,202 · 417×335 |

Kaynak geometri bağımsız yatay/dikey eksenlerle mevcut ekrana uyarlanır; bilgi alanlarının göreli yerleri değişmez. Dokunma hedefleri görünür resimden geniş olabilir.48fiziksel piksel hedef testiyle birlikte gerçek dokunma olayları da sınanır.

## Gerçek video incelemesi ve sınırlar

33:09 ve15:55 kayıtlarının lobi/oda içeren başlangıç aralıkları bu kez0,5saniye arayla toplam132örnekte incelendi; dokuz sayfanın tamamı gözle kontrol edildi. İncelenen aralıklar ve dosya/sayfa hash değerleri [JSON kaydındadır](video-ui-audit-032.json). Bu, bütün eski uzun videoların tekrar kesintisiz izlenmesi değildir.91saniyelik ayrı YouTube oda kurma kaydına yeni doğrudan erişim403, tarayıcı denemesi tünel hatası verdi. Eski otomatik sahne açıklaması yeni elle kare incelemesi gibi sunulmadı; oluşturma için sağlanan özgün arayüz dosyası kullanıldı.

**Tam PC eşitliği tamamlandı denmiyor.** Kayıtlar farklı tarih/tema/istemci sürümleri içerir; eksik yazı tipi ve bazı modern görseller piksel eşitliğini sınırlar. Harita galerisi mevcut yerel uyarlamadır. Videodaki çevrimiçi Mitro/Dolunay reklamları, uzak sohbet/davet/hesap hizmetleri ve sahiplikler uydurulmadı. Arşivde206bildirim/banner ilişkili giriş araştırıldı; aynı güncel web reklamlarının kaynak dosyası/servisi saptanmadı. [0.31'deki](PC_REFERANS_031.md) Bridge/Ruins yolları, diğer modlar, özel mühimmat, WorldModel/renderer ve kaynak dosya eksikleri de bu UI düzeltmesiyle kapanmış sayılmaz. Gerçek sunucu önceki kullanıcı kapsam kararıyla dışarıdadır. Fiziksel Android cihaz/emülatör testi yapılmadı.

## Son gerçek doğrulama

40/40 regresyon aşaması; 51 yeni kontrol; 24 OpenGL grubunda 474 fotoğraf.22 yeni lobi/oda fotoğrafı üç sayfada gözle incelendi. Çalışma zamanı SHA-256: `ea2cdb6e83c431506a95ea7ef4c849ed9dde822ad17ceeb3a354733cbe80833d`.

İmzalı APK **1,688,795,522 bayt**, SHA-256 `3c4dc45347ef71f86c448d08e97614cd9bcfe8a3d0bb4e297b1d7f271ab9236b`. 49 katalog, ZIP CRC, 23828 kaynak bağlantısı, paket/sürüm, v2/v3 imza ve16 KiBhizalama doğrulandı. Paket kanıtı fiziksel cihaz veya bütün PC davranışlarının tamamlandığı anlamına gelmez.
