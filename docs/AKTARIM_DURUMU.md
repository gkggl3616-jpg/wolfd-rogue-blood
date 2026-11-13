# Devralma sonrası aktarım durumu

Yeni tam sürüm ve yeni APK yayımlanmadı. Son yayımlanan 0.8 test APK'sı, bütünlük doğrulamasından sonra kod ve içerik kurtarma kaynağı olarak kullanıldı; kullanıcıya yeni teslim olarak sunulmadı.

| Alan | Gerçek gözlem | Açık kalan |
|---|---|---|
| Kod | 0.8'den 18 betik kurtarıldı; kayıt/ses/odak/girdi düzeltmeleri ve tek kaynak arayüz denetleyicisi uygulandı | Windows'taki APK sonrası kaynak ve test değişiklikleri yok |
| Harita | İzinli 19 geometri ve nesne tabloları korunuyor; 18 gezinti | 62 özgün mod/alt modun maç uygulaması, etkileşimli nesneler ve #46 mod kanıtı |
| Ses | 46 nesneden 43'ü gerçek kaynak kataloğuyla bağlı; bell/hawk için RAR sürümü seçildi, özgün PCM süreleri sınandı | #97'de üç am_fire_sm_loop.wav başvurusu kaynakta eksik; özgün zayıflama eğrisi doğrulanmadı |
| Karakter | Önceki katalogda 48 kabul edilmiş çift; mevcut örnek çifte ait görüntü alındı | Kurtarılan modellerin bütün gerekli animasyon durumlarında yeni görsel kabulü yok |
| Silah | 216 model / 903 varyantlık önceki katalog ve oyun kodu korundu; cephane/silme hatası kontrolleri geçti | İkinci ana silah ve bağımsız cephane geçişi çalışır; bütün silahların özgün kuralları, eklenti ve üçüncü şahıs eşleri tamamlanmadı |
| Kurt | Kaynak 19601 koşulu, T_WallHold_L, çarpışmalı tutunma/duvardan atlama ve 48 karakterin kendi donoründen T_WallDashAtk havada güçlü saldırı klibi | Bütün yönlerde temas pozu onayı, bütün karelerde görsel kabul ve eksik klipli karakterler |
| Dövme | Belirsiz bölgeye takma engellendi; kayıt hatası geri alınıyor | Bütün UV eşleri, özgün bonuslar ve bütün karakterlerde görsel kabul |
| Arayüz | 365 kaynak düzeni / 4.934 bileşen için çizim/girdi katmanı, doğal koordinatlar, kaynak mesaj/ayar/oda/koleksiyon akışı ve gerçek GUI kontrolleri | Bütün özgün C++ ekran davranışları; Display/30001, 12 eksik doku, 147 atlas bölgesi, font 51 ve piksel karşılaştırması |
| Işık/efekt | Önceki sprite varlıkları mevcut; örnek efekt ve sahne temizliği sınandı | Son yerel ışık haritası çözüm/binding kayıtları, gerçek aydınlatma ve tüm efekt grafikleri |
| Sunucu | Localhost yönetici sistemi ve idempotent bakiyeler korundu | Yetkili üretim hesabı, oda, maç, eşleştirme ve ilerleme hizmetleri |
| Android | Paket adı korundu; sonraki geliştirme sürüm kodu 9 olarak ayrıldı | İmzalama anahtarı, güncelleme/kurulum ve fiziksel cihaz performans doğrulaması |

Kurtarılan görüntüler ve modeller orijinal düzenlenebilir kaynakla aynı değildir. Araç 1.364 kayıplı dönüşüm bildirdi. Tarihsel `engineImported` veya `visualValidation` alanları yeni ve eksiksiz kabul sayılmaz. [Kurtarma raporu](recovery-0.8-report.txt).

Harita tutunma süresi 2 s, ek bekleme 0,8 s, duvardan itiş 4 m/s yeni mobil ayarlarıdır. Kaynakta doğrulanan şey güç slotu/aktivasyon açıklaması ve animasyonun varlığıdır; özgün sayısal denge çözüldü denmez. [Kaynak ve sınırlar](wall-hold-source.json).

[Dosya bazlı kayıt](transfer-coverage.json.gz), 74.967 RAR kaydının okunmuş içerik özetlerini içerir. Başlık listesiyle sınırlı değildir. Tekrarlanan dizinleri, QO metaverisini veya LTB uzantılı render tarzlarını benzersiz oynanabilir içerik saymaz. 3.073 benzersiz LTB yükünden 2.949'unun desteklenen model metaverisi çözüldü; 124 yük desteklenmeyen biçim/sürüm/mesh olarak ayrı tutulur. Önceki çalışmadaki 40.225 dosya, 3.366 model veya 737.797 ışık yüzeyi sayıları doğrulanmış güncel toplamlar diye aktarılmadı.

[Arayüz kapsamı](ARAYUZ_YENIDEN_KURULUM.md), [kaynak byte eşlemesi](ui-source-byte-validation.json), [yerel proje taraması](project-file-audit-summary.json). Test ve kaynak özeti başarısı tam sürüm bayrağını açmaz.

Son devamda 331 kaynak kart yüzü için dört sütunlu, aramalı ve sayfalı önizleme eklendi. Sahiplik/geliştirme hizmeti olmadan kart kullanımı kapalıdır. 226 kesin kimlik+ad eşleşmesiyle PC silah metni bağlandı; 218 açıklama doldu. PC metin bilgisi ile gerçek yerel oyun ayarları ayrı gösterilir. Silah/karakter değişimleri kaynak doğrulama → kayıt → canlıya geçiş sırasındadır; hata eski çalışan modeli ve seçimi korur. Yerel panel yanıtı oyuncu/istek/para birimi/tutar ile eşleşmeden bakiye güncellenmez. [Devam doğrulaması](DEVAM_KONTROLU.md).
