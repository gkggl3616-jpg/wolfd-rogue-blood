# Wolf Rogue Blood

Godot **4.7.2** ile Android'e taşınan, geliştirmesi süren oyun. **0.20.0 çevrimdışı APK** ayrı `com.wolfrogue.blood.offline` kimliğiyle üretildi ve paket/imza denetiminden geçti. 34 kaynak haritada botlu yerel maç ve 903 silahlık mağaza kataloğu ve sahip olunan eşyalardan oluşan envanter içerir. Bu depo henüz eksiksiz PC oyunu değildir. [Sürümün kapsamı ve kullanım](docs/CEVRIMDISI_SURUM.md), [APK doğrulaması](docs/android-offline-build.json).

[Tek APK indir](https://github.com/gkggl3616-jpg/wolfd-rogue-blood/releases/download/v0.20.0-offline/WolfRogueBlood-0.20.0-offline.apk) · [Oynanış görünümü ve bot değişiklikleri](docs/OYNANIS_REFERANSI.md)

[0.20 dövme resimleri, düzenlenebilir kontroller, YP/SP ve Yıkım turları](docs/PC_REFERANS_020.md)

[0.19 kurt çizimi ve çift pençe](docs/PC_REFERANS_019.md)

[0.18 özgün harita fotoğrafları, OG ve 206 kaynak set](docs/PC_REFERANS_018.md)

[0.13 değişiklikleri ve fotoğraflar](docs/PC_REFERANS_013.md) · Maç başı ekipman/kurt seçimi, altı kaynak mutasyon modeli, onaylanan hediyeler, güç yuvaları ve referans üst menüsü.

[0.12 değişiklikleri ve fotoğraflar](docs/PC_REFERANS_012.md) · Harita fotoğrafları, rütbeler, ikinci şifre, kutular, kol dövmeleri, yerel Kurt Avı/öğretici ve Wolf Pass.

## Devralınan çalışma

`main`, 0.4 sürümünde kalmıştı. `content-import-small` dalı yalnızca içerik aktarımının 29/136 bölümüne ulaşmıştı. Yayımlanan **v0.8.0-test** APK'sının SHA-256 özeti doğrulandı; 18 oyun betiği ve eksik kaynaklar buradan kurtarıldı. Betiklerin yorumları/özgün biçimlendirmesi geri getirilemez. 1.364 kaynak dönüşümü kurtarma aracı tarafından kayıplı olarak işaretlendi; kurtarılan dosyalar özgün düzenlenebilir kaynakla aynı kabul edilmez.

Windows'taki yayımlanmamış son çalışma bu ortamda yok. Özellikle son ışık haritası bağları, son arayüz düzeltmeleri ve bunların test kayıtları APK'dan geri alınmış gibi gösterilmez. [Kurtarma kaydı](docs/recovery-0.8.json), [kaynak dosyaları](docs/recovered-assets.json), [tarihsel 0.4 README](docs/history/README-0.4.md).

## Bu devam çalışmasında uygulananlar

- Son oynanış videosuna göre kurt kamerası, kompakt HUD ve yön düğmeleri yenilendi. Bütün oyun içi eylem düğmeleri yuvarlak ve görselli: mermi, pençe ve gerçek modelden şarjör. Mevcut 19 haritanın her birine konum/yön gösteren türetilmiş radar eklendi. Kolay/Normal/Zor insan-kurt botları aynı can ve isabet hasarıyla; görüş, hafıza, koşu, siper, takla ve sınırlı şarjör/yedek davranışını kullanır. [Kaynaklar, sınırlar ve fotoğraflar](docs/OYNANIS_REFERANSI.md).

- 19 kaynak haritaya ayrı çevrimdışı bot maçı eklendi. Önceden hazırlanmış yürüyüş ağları, erişilebilir ve kapsül boşluğu olan bot doğma noktaları, gerçek haritada başlat/ölüm/süre/sonuç/tekrar akışı bulunur. #46'nın özgün mod eşleşmesi uydurulmadan bağımsız yerel eğitimde açılması sağlandı. Özgün PC modlarının hazır olma denetimleri korunur.
- Giriş, lobi, yerel oda, koleksiyon ve ayarlar tek kaynak arayüz katmanına taşındı. 365 düzen / 4.934 bileşen oluşturulur; kaynak atlasları ve 1024×768 koordinatları, verilen PC videolarındaki gibi iki eksende ekrana yayılarak kullanılır. 3B karakter oranı ayrı korunur. Üst simge menüsü, yatay beş ekipman seti, solda etkin silahlar ve sağda 3×3 eşya listesi yeniden kuruldu. İkinci ana silah, bağımsız cephane geçişi ve 331 kaynak kart yüzü önizlemesi eklendi. Ayar taslağı, geri/iptal ve beş ekipman seti gerçek GUI tıklamalarıyla sınanır. Bu, bütün özgün ekran davranışlarının tamamlandığı anlamına gelmez. [Arayüzün kapsamı ve açık eşlemeler](docs/ARAYUZ_YENIDEN_KURULUM.md).
- Parmak sahipliği olan çoklu dokunma: hareket, kamera ve düğmeler birbirine geçmez. Aynı düğmeye basan ikinci parmak, birinci bırakıldığında eylemi kaybetmez. Menü/HUD dokunuşları kamera veya ateşe dönüşmez.
- Uygulama arka plandayken sahne, çatışma ve şarjör süresi durur. Dönüşte oyuncu **Devam et** seçmeden çatışma başlamaz.
- Müzik, ortam/efekt, silah ve menü sesi ayrı kanallarda ayarlanır. Eski ana ses tercihi korunur.
- Kayıt yazımı kontrol edilir; başarısız işlem bakiye, eşya, karakter, dövme, ayar veya ekipman setini kalıcı olmuş gibi değiştirmez. Bozuk/yeni şemalı eski kayıt sessizce silinmez.
- Kaynak bölgesi belirsiz dövmeler rastgele UV'ye takılamaz. Eski kayıttaki belirsiz seçim dosyadan silinmez, modele uygulanmaz.
- Seçili haritaların 46 ses nesnesinin 43'ü sahneye bağlanır. Üçünün istediği **am_fire_sm_loop.wav**, verilen RAR dizininde ve ses kataloğunda yoktur; yerine başka ses kullanılmaz. İç/dış yarıçap zayıflaması yeni mobil uyarlamadır.
- Arşiv içeriği karşılaştırmasında farklı çıkan `am_bell.wav` ve `am_hawk.wav`, verilen PC RAR'ındaki özgün PCM dosyalarıyla değiştirildi. Dosyalar yeniden kodlanmadı. [Kaynak kanıtı](docs/original-audio-restoration.json).
- 19601 güç eşyası ve kaynak `wall_hold` klibi varsa havada duvar teması sırasında kurt koşusu + ateş, süreli tutunmayı başlatır. İleriyi bırakma, eğilme, menü ve form değişimi tutunmayı bitirir; zıplama fiziksel dışa itiş verir. 48 karaktere kendi doğrulanmış kaynak `T_WallDashAtk` klibiyle havada güçlü saldırı bağlandı. Sayısal değerler yeni mobil ayarlarıdır. **Bütün temas yönlerinde animasyon hizası henüz görsel olarak onaylanmadı.**
- Karakter önizleme kamerası gerçek model sınırlarına ve ekran oranına göre çerçeve kurar. Menüler geniş ekranda arka plandaki dünyayı açıkta bırakmaz.

## Çalıştırma ve doğrulama

Godot'ta `godot/project.godot` dosyasını içe aktar ve F5'e bas. Kaynaklar sahneye göre yüklenir; haritaların tümü aynı anda açılmaz.

```sh
python -m pip install -r tools/requirements.txt
python tools/validate_mobile.py --godot /path/to/godot-4.7.2 --report docs/mobile-validation.json
```

Windows'ta APK oluşturmadan doğrulama:

```powershell
./tools/build_android.ps1 -Godot C:\path\godot.exe -ValidateOnly
```

Bu denetim veri/yerel yönetici testleri, Godot içe aktarımı, kayıt, dokunma, oyun, odak, cephane, harita sesi, duvara tutunma ve kaynak arayüz/GUI akışı kontrollerini çalıştırır. [Son mantık kontrolü](docs/mobile-validation.json) penceresiz testtir. [Görüntü kontrolü](docs/mobile-visual-validation.json) ayrı OpenGL örnekleridir. Fiziksel telefon ve Android emülatörü testi yapılmadı.

## Gerçek PC kaynaklarına erişim

Verilen Drive RAR dosyası **4.743.112.316 bayt**; başlık envanterinde **74.967 kayıt** bulunur. Dizinler ve tekrarlanan ağaçlar bu sayıya dahildir. Açılmış toplam 19,66 GB bildirimi benzersiz/oynanabilir içerik sayısı veya APK boyutu değildir.

[Dosya envanteri](docs/pc-archive-inventory.json.gz), [dosya bazlı aktarım kaydı](docs/transfer-coverage.json.gz), [kapsam özeti](docs/transfer-coverage-summary.json). Yol eşleşmesi, kaynağın byte kimliği veya oyundaki işlevinin kanıtı sayılmaz.

Bu devamda yalnızca başlıklar listelenmedi: **74.967 kaydın bütün üye içeriği okunup SHA-256 ile özetlendi**; tekrarlanan ağaçlar ve RAR'ın QO metaverisi ayrı tutulur. [Tam içerik taraması](docs/pc-content-scan-summary.json). 3.073 benzersiz LTB yükünün 2.949'unda desteklenen model metaverisi çözüldü; kalan 124 dosya desteklenmeyen sürüm/mesh veya render tarzı gibi başka LTB türleri içerir. Bunlar oynanabilir karakter sayılmaz. 365 arayüz tanımı, 18.862 doku ve dört fontun katalog kaynak özetleri verilen RAR ile eşleşir; bu kontrol piksel veya oyun davranışı eşitliği değildir. [Arayüz kaynak byte kontrolü](docs/ui-source-byte-validation.json).

Yerel proje dosyalarının tamamı okunup özetlenir; JSON, GLB/PNG başlıkları ve sabit `res://` bağımlılıkları [proje taramasında](docs/project-file-audit-summary.json) denetlenir.

Tüm arşivi diske çıkarmadan belirli bir kaynak dosyasını al:

```sh
python -m pip install -r tools/archive-requirements.txt
python tools/pc_archive.py extract docs/pc-archive-inventory.json.gz "wolfteam kurtları/Root/wt_attributes/exitemtext.dat" /path/to/exitemtext.dat
```

Sistem `libarchive` kütüphanesinde RAR5 desteği gerekir. Araç dosya boyutu ve RAR bütünlüğünü denetler, çıkarılan dosyanın SHA-256 köken kaydını yazar; PC ikililerini çalıştırmaz.

Tam içerik taramasını yeniden üretmek için bazı sıkıştırma bloklarında bağımsız Unix `unrar` çözücüsü de gerekir:

```sh
python tools/scan_pc_archive.py 1UqJsReUFibnxW8_WMu1i_ys9cjSonhGA --unrar /path/to/unrar
python tools/build_ui_catalog.py --content-scan docs/pc-content-scan.jsonl.gz
python tools/build_transfer_ledger.py
python tools/audit_project.py
```

Kesilen tarama `--resume` ile tam ve doğrulanmış kayıtlarından sürer. İndirme bütün arşivi yerel diske çıkarmadan aralıklı okunur. Dosyası bulunmuş, özetlenmiş veya modele çevrilmiş olması; bağımlılık, davranış ve görsel kabul aşamalarını tamamlamaz.

## Tam sürüm ve APK koşulları

[Tam PC sürümünün teslim engelleri](assets/delivery-status.json) `python tools/check_delivery.py` ile yeniden hesaplanır. Varsayılan derleme yolu bu denetimi korur. Kullanıcının son istediği **gerçek sunucu hariç, mümkün olan yerel sürüm** için ayrı `-Offline` / `build_offline_android.py` yolu, ayrı uygulama kimliği ve `check_offline_ready.py` denetimi vardır. Çevrimdışı APK, tamamlanmış PC aktarımı olarak işaretlenmez.

- Seçilen 19 temel harita korunur ve 15 yeni kaynak harita eklenir (toplam 34): **58, 59, 65, 72, 1, 2, 26, 31, 44, 46, 50, 110, 57, 100, 97, 92, 82, 83, 84**. 19'u bağımsız çevrimdışı botlu eğitimde açılır; özgün PC maç kuralları değildir. Özgün modlara bağlı gezinti 18 haritada bulunur; 46'nın PC mod bağlantısı belirsizdir ve 47 ile değiştirilmez.
- 62 mod/alt modun özgün maç kuralları, tur akışı ve sonuçları tamamlanmadı.
- 48 çiftin önceki katalogda kabul edilmiş olması, kurtarılan her modelin bütün durumlarının yeniden doğrulandığı anlamına gelmez. 216 silah modeli / 903 kaynak varyantı da 903 ayrı, tam doğrulanmış silah davranışı demek değildir.
- Özgün arayüz akışlarının tümü, hesap/oda/maç sunucusu, bütün efekt grafikleri ve gömülü ışık haritalarının çalışma zamanı uygulaması eksik.
- Önceki Android imzalama özel anahtarı bu ortama bağlı değil. Bu nedenle çevrimdışı sürüm ayrı paket adı kullanır; eski uygulamayı güncellemeye veya kayıtlarını silmeye çalışmaz. Fiziksel cihaz kabulü yapılmadı.
- Kullanıcının **en az 3 GB gerçek içerik** koşulu sağlanmış değildir. Boyut için dolgu, kopya veya Windows ikilisi eklenmez. Yukarıdaki APK bağlantısı ayrı çevrimdışı sürümdür; tam PC aktarımı değildir.

Yerel yönetici paneli korunur: `python server.py`, ardından `http://127.0.0.1:8765`. Bu yerel geliştirme sistemi, üretim hesabı veya çevrimiçi sunucu değildir; yinelenen işlem kimliği tekrar ödeme yapmaz.

Son devam: [havada güçlü saldırı, kayıt geçişleri ve arayüz doğrulaması](docs/DEVAM_KONTROLU.md).
