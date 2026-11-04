# Kaynak arayüzün yeniden kurulumu

Giriş, sunucu seçimi, lobi, yerel oda, oda oluşturma, duraklatma, sonuç, koleksiyon ve ayarlar artık tek arayüz denetleyicisini kullanır. Eski genel panel akışı kaldırıldı; eski betik yolları uyumluluk yönlendirmesi olarak bırakıldı. Kullanılmayan eski kart çizicisi kaldırıldı.

Kullanıcının verdiği [beş PC videosu](pc-video-references.json) incelendi. Kaynak 1024×768 koordinatları korunur; videolardaki 4:3 ve 16:9 görünüm gibi iki eksen ekrana ayrı ölçeklenir. Önceki tek katsayılı, kenarlarda boşluk bırakan düzen kaldırıldı. 3B önizleme ters ölçek ve fiziksel viewport boyutuyla karakter oranını korur. Bu değişiklik bütün ekranlarda piksel eşitliği kanıtı değildir.

`tools/build_ui_catalog.py`, 365 kaynak düzeni ve 4.934 bileşeni derler. 99 tür için çizim/girdi aileleri tanımlıdır. Bu sayı, 99 özgün C++ sınıfının bütün davranışlarının yeniden yazıldığı anlamına gelmez. Veri bağlanmamış listeler boş kalır; uygulanmamış servis düğmeleri başarı/ödül/oyuncu sonucu üretmez. İletişim kutuları açıkça çağrılmadan açılmaz.

2.783 ebeveyn başvurusundan 2.782'si kaynak isim/kimlik bilgisiyle bağlanır. `section/shop` içindeki `Display → 30001` için kaynak ebeveyn yoktur; başka ekrana tahmini bağlanmaz. Tekrarlanan bir bileşen adı, kimlik belirtilmeden ilk eşleşmeye yönlendirilmez.

Başlıklar yalnızca iki arayüz metin tablosundan çözülür; tooltip tablosundaki aynı numara başlık olarak kullanılmaz. Sekiz başlık çözülememiştir. Motorun gerçek `[Fonts]` bölümündeki dosyalar bağlanmıştır; 51 numaralı yüzün eşlemesi hâlâ belirsizdir. Bu yüz için ağır Square 721 Black yerine açıkça düzenli sistem fontu kullanılır; özgün font bulundu diye gösterilmez. Kaynakta bulunmayan 12 DTX dosyasına 29 başvuru ve mevcut doku boyutlarıyla uyuşmayan 147 sıfırdan farklı atlas bölgesi [ayrıntılı kayıtta](ui-source-audit.json) tutulur. Boş `[0,0,0,0]` bölgeler hata sayılmaz.

Üstteki büyük metin menüsü küçük, durumları kaynak atlaslardan gelen simgelere dönüştü. Genel düğmeler silah kartı yerine kaynak eylem plakasını kullanır. Envanterde beş ekipman seti solda yatay sekmelerdir; seçili setin dört gerçek silahı solda beş kaynak slot konumuna dizilir. İkinci ana silah uygulaması yoksa o slot kilitlidir. Sağdaki 3×3 liste, altında seçili eşya ve açıklama/özellik paneli bulunur. Silah simgeleri kaynak 210×75 bölgesinden çizilir; büyük kaynak görsellerinin kart dışına taşması engellendi. Uzun açıklamalar kendi alanında kaydırılır. Eski 25px kayıtlarla uyuşmayan 27px Türkçe atlas sekmeleri çalışma zamanında açıkça bağlanır.

Karakter kartlarının 38'i tam normalize edilmiş ad/model dosyası eşleşmesiyle özgün simgeye bağlıdır. Kalan 10 kart, kendi gerçek insan modelinden üretilmiş önizlemedir; başka karakterin simgesiyle doldurulmaz. [Bağlantı listesi](../godot/assets/ui/character-portraits.json) kaynak simge ile türetilmiş önizlemeyi ayırır. Güç ve dövmede seçili kurdun 3B önizlemesi kullanılır. Bölgesi bilinmeyen dövme takılmaz veya başka bölgedeki dövmeyi çıkarmaz.

Profil satırları gerçek Türkçe `mm_bg` görseline göre yeniden bağlandı. Arkadaşlar ve görevler eksik bir alt liste yerine kendi kaynak pencere çerçevelerini kullanır. Duraklatma/oyun içi seçenekler açık 3B sahnenin üzerinde açılır; eski opak menü perdesi oyun sırasında çizilmez. HUD canı sol alta, mühimmatı sağ alta ve süre/hedefi üst ortaya taşır; mobil dokunma katmanı ayrı kalır. Uygulanmamış iki takım maçının skoru veya SP sayacı gösterilmez.

Yerel işlemlerde gerçek oyun durumu kullanılır: beş ekipman seti, sahip olunan eşyalar, bağımsız cephane, karakter çifti ve bölgesi bilinen dövmeler. Oda ekranında yalnızca bu cihazdaki yerel oyuncu gösterilir. Özgün maçlar tamamlanmadığı için bu haritaların maç başlatma düğmesi kapalıdır; gezinti ayrı işlemdir. Özgün fiyatlar ve satın alma servisi doğrulanmadan ücretsiz eşya ekleme satın alma olarak gösterilmez.

Ayarlar önce taslakta değiştirilir. Uygulama bütün değerleri bir atomik kayıtla yazar; başarısız kayıt canlı ayarları değiştirmez. Geri çıkışta kaynak mesaj kutusu gösterilir; kutuyu kapatmak gezinme geçmişini veya taslağı tüketmez. Dört kaynak ses sürgüsü dört ayrı ses kanalına bağlıdır. İnsan/kurt önizlemesi kırmızı/mavi takım düğmelerine yanlış bağlanmaz.

Yapısal test bütün düzenleri oluşturur; girdi testi gerçek GUI tıklamalarıyla giriş/oda/ayar/ekipman akışını çalıştırır. OpenGL görüntüleri [görüntü kaydında](mobile-visual-validation.json), penceresiz kontroller [mantık kaydında](mobile-validation.json) bulunur. 50 GUI akış kontrolü ve 35 Python testi geçer. 33 OpenGL görüntüsü, 1024×768 / 1280×720 / 1920×1080 düzenlerini ve ek servis pencerelerini kapsar. Bunlar fiziksel Android testi veya otomatik piksel eşitliği karşılaştırması değildir.

Yeniden üretim:

```sh
python tools/build_ui_catalog.py
python tools/pc_archive.py extract docs/pc-archive-inventory.json.gz "wolfteam kurtları/Root/attributes/layout.txt" /path/to/layout.txt
python tools/build_ui_catalog.py --font-layout /path/to/layout.txt
python tools/build_character_portraits.py
/path/to/godot-4.7.2 --path godot --script ../tools/render_character_portraits.gd
python tools/validate_mobile.py --godot /path/to/godot-4.7.2 --report docs/mobile-validation.json
```

Ekranların global PC bileşimi, bütün servis/hesap işlemleri, bütün özel liste/diyalog davranışları ve bütün cihazlarda görsel kabul tamamlanmadı. Global gezinme, dokunma kontrolleri ve eğitim HUD'u hâlâ mobil uyarlama içerir. Bu çalışma **eksiksiz, birebir PC oyunu** diye işaretlenmez ve tam APK teslim kapısını açmaz.
