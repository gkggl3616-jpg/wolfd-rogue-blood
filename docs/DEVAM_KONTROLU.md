# Kalan eksiklerin devamı

Son eklenenler ve kaynak sınırları: [0.12 PC referansları ve fotoğraflar](PC_REFERANS_012.md). Yeni özelliklerde 102 kontrol; 44 eski ekranın yeni görüntüsü ve 16 ek görüntü, toplam 60 OpenGL çekimi.

Bu devam çalışan yerel oyunu ve kaynak arayüzünü ilerletir. Son istek doğrultusunda gerçek sunucu hariç ayrı **0.12.0 çevrimdışı sürüm** hazırlanır. Tam PC oyunu olarak işaretlenmez. [Çevrimdışı kapsam ve kullanım](CEVRIMDISI_SURUM.md).

- Son oynanış referansına göre ortalı kurt kamerası, yuvarlak görsel kontroller, kaynak mermi/pençe/şarjör simgeleri, 19 harita radarı ve isabet/hasar geri bildirimi eklendi. Kolay/Normal/Zor botlar aynı 8 isabet hasarı ve 100 can kullanır; tepki/nişan/hafıza/siper/takla kararları değişir. Koşu, gerçek görüş engelleri, sonlu mühimmat ve basamaklar denetlenir. [Ayrıntı ve kaynak sınırları](OYNANIS_REFERANSI.md).

- 19 kaynak haritada yerel bot maçı, önceden hazırlanmış yürüyüş ağları ve erişilebilir/kapsül boşluğu olan doğma adayları eklendi. Her tur kendi gezinme haritasını kullanır; önceki sahnenin gecikmiş temizliği yeni turun sorgularına karışmaz. 10 hedef, 90 saniye ve en fazla dört bot yeni yerel eğitim kurallarıdır.
- Çevrimdışı uygulamanın 903 silahlık yerel koleksiyonu gerçek hesap veya satın alma gerektirmez. Ayrı Android paket adı eski uygulama/kayıtların silinmesini gerektirmez; INTERNET izni kapalıdır.
- Oda ekranında aynı yere yazılan iki kaynak başlık alanı düzeltildi. Yerel mod/görev metinleri kendi alanlarına sığar. Sonuç başlığı kaynak mod yazısının üstüne binmez; kazanılmamış turlarda zafer rozeti gösterilmez.

- İkinci ana silah yuvası gerçek ekipman kaydına bağlandı. Yuva seçilip Kullan ile atanır; `1` / ana silah düğmesi iki ana silah arasında geçer. Ayrı silahların cephaneleri ayrı kalır, aynı silah iki yuvada çoğalmaz. Eski şema 2 kayıtları korunur.
- Silah ve karakter değişimi önce kaynak/model/animasyonları hazırlar, sonra kaydeder, ardından canlı modeli değiştirir. Kaynak veya kayıt hatası mevcut seçimi/modeli bozmaz. Başarısız hazır nesneler temizlenir.
- 48 karakterin kendi 16 gerçek LTB donorü SHA-256 ve bütün kemik adları/ebeveyn sırasıyla doğrulandı. Kaynak `T_WallDashAtk` zamanları/pozları mevcut GLB'lere ayrı `airborne_attack` olarak eklendi; eski geometri/animasyon verisi korunur. [Dosya bazlı kanıt](airborne-attack-source.json).
- Güç eşyası takılıyken kurt koşusu → zıplama → GÜÇLÜ / sağ fare işlemi çalışır. Vuruş penceresinde bir kez, gerçek menzil/yön/görüş hattı ile hasar verir. Menü, form değişimi, eşya çıkarma veya yere iniş hareketi temizler. Eksik klip başka pozla doldurulmaz. Kaynak süre/poz ayrı; **80 hasar, 3,1 m menzil, 10 m/sn hareket, %35 vuruş penceresi ve 0,15 sn ek bekleme yeni mobil ayarlardır**. PC sayısal dengesi çözüldü denmez.
- Düşman yakın saldırısı duvar arkasına geçmez. Kükreme sırasında eşzamanlı pençe hasarı, iptal edilmiş havadaki saldırının sonradan vurması ve yeni tura eski saldırı bekleme süresinin taşınması engellendi.
- 331 kaynak kart yüzü 4×2 düzende önizlenir. Normal/Master filtresi, arama, seçim ve sayfalama çalışır. Kart sahipliği, geliştirme ve ödül sonucu üretilmez. Klavye/ekran boyutu değişiminde arama, imleç ve seçim korunur; envanter/kart son sayfaları örtüşen kısmi sayfalara kaymaz.
- PC `weapontext.dat` dosyasındaki 298 kaydın beş UTF-16 alanı tamamen çözüldü. Yalnızca tam kimlik+ad eşleşen 226 eşya bağlandı; 218 açıklama doldu. PC ağırlık/mühimmat/mod metinleri, bu sürümün gerçek yerel hasar/şarjör/atış/yükleme ayarlarından ayrı gösterilir. Eşleşmeyen 677 eşya için tahmin yapılmaz.
- Yerel PC panelinin bozuk/eksik yanıtı profili/bakiyeyi kısmen değiştiremez. İşlem yanıtı oyuncu, istek, para birimi ve tutarla eşleşmelidir. Yanlış oyuncu yanıtı veya yalnızca HTTP 200 başarı sayılmaz. Kesirli/geçersiz miktarlar reddedilir; belirsiz sonuç otomatik tekrarlanmaz. Bu kontroller üretim oyun sunucusu değildir.

## Doğrulama

Godot 4.7.2 ile **17 doğrulama adımı** geçer: 40 Python testi, 69 gerçek GUI akış kontrolü, 236 çevrimdışı harita/maç kontrolü, 120 dövüş/klip/poz kontrolü, 85 oynanış referansı, 62 bot davranışı, 23 dokunma, 35 kayıt, 7 yerel protokol, 155 harita sesi, 20 yaşam döngüsü ve 8.454 kaynak bileşen kontrolü dahil. Yeni saldırı bütün 48 karakterde yüklenip örnek vuruş pozunda sonlu kemik dönüşümleriyle sınanır. Bu, bütün animasyon kareleri/ışık/efektlerin PC görsel kabulü değildir.

[44 yazılım OpenGL görüntüsü](mobile-visual-validation.json), dört ekran boyutunda kart/ikinci silah/özellik/saldırı ve gerçek haritadaki botlu maç/oda/sonuç görünümlerini kapsar. [Mantık raporu](mobile-validation.json) kaynak kod özetiyle eşleşir. Fiziksel Android cihaz testi yapılmadı.

Yeniden üretim:

```sh
python tools/add_source_action.py --donors /path/to/verified/pc/animation-donors
python tools/build_weapon_text.py /path/to/weapontext.dat
python tools/validate_mobile.py --godot /path/to/godot-4.7.2 --report docs/mobile-validation.json
```

## Açık kalan

19 özgün haritanın bütün PC maç kuralları/etkileşimleri, 62 mod/alt mod, #46'nın PC mod kanıtı, bütün kaynak görsel/efekt/ışık kabulü ve Android fiziksel cihaz kabulü tamamlanmadı. Gerçek hesap/oda/maç/envanter hizmeti bu çevrimdışı sürümün kapsamı dışındadır. Kutu açma ve kart geliştirme gerçek hesap/ödül servisi olmadan çalışıyor diye gösterilmez. Font 51 ve kaynak arayüzün eksik/uyuşmayan kayıtları önceki denetimde açık kalır. Tam-PC teslim kapısı değiştirilmedi; çevrimdışı paket ayrı kimlik ve denetim kullanır, dolgu içerik eklenmez.
