# Kaynak arayüzün yeniden kurulumu

Giriş, sunucu seçimi, lobi, yerel oda, oda oluşturma, duraklatma, sonuç, koleksiyon ve ayarlar artık tek arayüz denetleyicisini kullanır. Eski genel panel akışı kaldırıldı; eski betik yolları uyumluluk yönlendirmesi olarak bırakıldı. Kullanılmayan eski kart çizicisi kaldırıldı.

Kaynak 1024×768 koordinatları sabit tutulur. Menü ve atlas bölgeleri tek katsayıyla ölçeklenir; geniş ekranda kenar boşluğu oluşur. Motorun `expand` ayarı, 4:3 ekranda ikinci bir kenar boşluğu katmanı oluşmasını önler. Bu ayar bütün kaynak düzenlerinin global PC pencere bileşimini kanıtlamaz.

`tools/build_ui_catalog.py`, 365 kaynak düzeni ve 4.934 bileşeni derler. 99 tür için çizim/girdi aileleri tanımlıdır. Bu sayı, 99 özgün C++ sınıfının bütün davranışlarının yeniden yazıldığı anlamına gelmez. Veri bağlanmamış listeler boş kalır; uygulanmamış servis düğmeleri başarı/ödül/oyuncu sonucu üretmez. İletişim kutuları açıkça çağrılmadan açılmaz.

2.783 ebeveyn başvurusundan 2.782'si kaynak isim/kimlik bilgisiyle bağlanır. `section/shop` içindeki `Display → 30001` için kaynak ebeveyn yoktur; başka ekrana tahmini bağlanmaz. Tekrarlanan bir bileşen adı, kimlik belirtilmeden ilk eşleşmeye yönlendirilmez.

Başlıklar yalnızca iki arayüz metin tablosundan çözülür; tooltip tablosundaki aynı numara başlık olarak kullanılmaz. Sekiz başlık çözülememiştir. Motorun gerçek `[Fonts]` bölümündeki dosyalar bağlanmıştır; 51 numaralı yüzün eşlemesi hâlâ belirsizdir. Kaynakta bulunmayan 12 DTX dosyasına 29 başvuru ve mevcut doku boyutlarıyla uyuşmayan 147 sıfırdan farklı atlas bölgesi [ayrıntılı kayıtta](ui-source-audit.json) tutulur. Boş `[0,0,0,0]` bölgeler hata sayılmaz.

Yerel işlemlerde gerçek oyun durumu kullanılır: beş ekipman seti, sahip olunan eşyalar, bağımsız cephane, karakter çifti ve bölgesi bilinen dövmeler. Oda ekranında yalnızca bu cihazdaki yerel oyuncu gösterilir. Özgün maçlar tamamlanmadığı için bu haritaların maç başlatma düğmesi kapalıdır; gezinti ayrı işlemdir. Özgün fiyatlar ve satın alma servisi doğrulanmadan ücretsiz eşya ekleme satın alma olarak gösterilmez.

Ayarlar önce taslakta değiştirilir. Uygulama bütün değerleri bir atomik kayıtla yazar; başarısız kayıt canlı ayarları değiştirmez. Geri çıkışta kaynak mesaj kutusu gösterilir; kutuyu kapatmak gezinme geçmişini veya taslağı tüketmez. Dört kaynak ses sürgüsü dört ayrı ses kanalına bağlıdır. İnsan/kurt önizlemesi kırmızı/mavi takım düğmelerine yanlış bağlanmaz.

Yapısal test bütün düzenleri oluşturur; girdi testi gerçek GUI tıklamalarıyla giriş/oda/ayar/ekipman akışını çalıştırır. OpenGL görüntüleri [görüntü kaydında](mobile-visual-validation.json), penceresiz kontroller [mantık kaydında](mobile-validation.json) bulunur. Bunlar fiziksel Android testi veya PC referans görüntüsüyle piksel karşılaştırması değildir.

Yeniden üretim:

```sh
python tools/build_ui_catalog.py
python tools/pc_archive.py extract docs/pc-archive-inventory.json.gz "wolfteam kurtları/Root/attributes/layout.txt" /path/to/layout.txt
python tools/build_ui_catalog.py --font-layout /path/to/layout.txt
python tools/validate_mobile.py --godot /path/to/godot-4.7.2 --report docs/mobile-validation.json
```

Ekranların global PC bileşimi, bütün servis/hesap işlemleri, bütün özel liste/diyalog davranışları ve bütün cihazlarda görsel kabul tamamlanmadı. Global gezinme, dokunma kontrolleri ve eğitim HUD'u hâlâ mobil uyarlama içerir. Bu çalışma **eksiksiz, birebir PC oyunu** diye işaretlenmez ve tam APK teslim kapısını açmaz.
