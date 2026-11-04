# Devralma sonrası aktarım durumu

Yeni tam sürüm ve yeni APK yayımlanmadı. Son yayımlanan 0.8 test APK'sı, bütünlük doğrulamasından sonra kod ve içerik kurtarma kaynağı olarak kullanıldı; kullanıcıya yeni teslim olarak sunulmadı.

| Alan | Gerçek gözlem | Açık kalan |
|---|---|---|
| Kod | 0.8'den 18 betik kurtarıldı; giriş/kayıt/ses/odak/önizleme düzeltmeleri uygulandı | Windows'taki APK sonrası kaynak ve test değişiklikleri yok |
| Harita | İzinli 19 geometri ve nesne tabloları korunuyor; 18 gezinti | 62 özgün mod/alt modun maç uygulaması, etkileşimli nesneler ve #46 mod kanıtı |
| Ses | 46 nesneden 43'ü gerçek kaynak kataloğuyla bağlı; sahne çıkışında temizleniyor | #97'de üç am_fire_sm_loop.wav başvurusu kaynakta eksik; özgün zayıflama eğrisi doğrulanmadı |
| Karakter | Önceki katalogda 48 kabul edilmiş çift; mevcut örnek çifte ait görüntü alındı | Kurtarılan modellerin bütün gerekli animasyon durumlarında yeni görsel kabulü yok |
| Silah | 216 model / 903 varyantlık önceki katalog ve oyun kodu korundu; cephane/silme hatası kontrolleri geçti | Bütün silahların özgün kuralları, eklenti ve üçüncü şahıs eşleri tamamlanmadı |
| Kurt | Kaynak 19601 koşulu, T_WallHold_L klibi, çarpışmalı süreli tutunma ve duvardan atlama mantığı | Bütün yönlerde temas pozu onayı, havada güçlü saldırı ve eksik klipli karakterler |
| Dövme | Belirsiz bölgeye takma engellendi; kayıt hatası geri alınıyor | Bütün UV eşleri, özgün bonuslar ve bütün karakterlerde görsel kabul |
| Arayüz | Kaynak arayüz varlıkları ve 0.8 ekran kodu kurtarıldı; kamera boyutu ve ekranı kaplama düzeltildi | Bütün özgün ekran/işlem akışları, Display/30001 gibi açık eşlemeler |
| Işık/efekt | Önceki sprite varlıkları mevcut; örnek efekt ve sahne temizliği sınandı | Son yerel ışık haritası çözüm/binding kayıtları, gerçek aydınlatma ve tüm efekt grafikleri |
| Sunucu | Localhost yönetici sistemi ve idempotent bakiyeler korundu | Yetkili üretim hesabı, oda, maç, eşleştirme ve ilerleme hizmetleri |
| Android | Paket adı korundu; sonraki geliştirme sürüm kodu 9 olarak ayrıldı | İmzalama anahtarı, güncelleme/kurulum ve fiziksel cihaz performans doğrulaması |

Kurtarılan görüntüler ve modeller orijinal düzenlenebilir kaynakla aynı değildir. Araç 1.364 kayıplı dönüşüm bildirdi. Tarihsel `engineImported` veya `visualValidation` alanları yeni ve eksiksiz kabul sayılmaz. [Kurtarma raporu](recovery-0.8-report.txt).

Harita tutunma süresi 2 s, ek bekleme 0,8 s, duvardan itiş 4 m/s yeni mobil ayarlarıdır. Kaynakta doğrulanan şey güç slotu/aktivasyon açıklaması ve animasyonun varlığıdır; özgün sayısal denge çözüldü denmez. [Kaynak ve sınırlar](wall-hold-source.json).

[Dosya bazlı kayıt](transfer-coverage.json.gz) bütün RAR başlıklarını içerir. Tekrarlanan dizinleri benzersiz içerik veya oyun işlevi saymaz. Önceki çalışmadaki 40.225 dosya, 3.366 model veya 737.797 ışık yüzeyi sayıları bu ortamda doğrulanmış güncel toplamlar diye aktarılmadı.
