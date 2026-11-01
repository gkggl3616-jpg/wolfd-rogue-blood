# Wolf Rogue Blood — aktarım durumu, 0.4.0

Bu APK eksiksiz özgün oyun değildir. Sağlanan kurulumda Windows istemcisi, derlenmiş DLL'ler ve paketlenmiş varlıklar bulunuyor; özgün düzenlenebilir oyun/sunucu kaynak projesi bulunmadı. Windows ikilisini `.dat` adıyla yeniden adlandırmak onu Android oyununa dönüştürmez. Mevcut Godot oyunu yeniden yazılıyor; kaynakta okunabilen kurallar ile yeni mobil ayarlar ayrı tutuluyor.

| Bölüm | Bu sürümde olan | Bekleyen |
|---|---|---|
| Haritalar | Kullanıcının seçtiği 19 dosyanın ana render geometrisi, yaklaşık 1 milyon üçgen; 19'unda kaynak doğma noktası ve üretilen çarpışma kontrolü | Tam fizik BSP'si, görünmez engeller, hareketli nesneler, merdiven/kapı/etkileşimler, ışık haritaları, bazı malzeme efektleri |
| Mod sınırları | 18 haritanın 62 kaynak mod/alt modla tam kategori+kimlik eşleşmesi | Özgün maç kuralları; #46 Göbekli Tepe'nin mod eşleşmesi |
| Harita gezintisi | Modu doğrulanan 18 harita APK'da gezilebilir; maç timer/düşman/ödülü çalıştırmaz | Özgün mod oynanışı ve ağ maçları |
| Karakterler | Yalnızca onaylı Pedro RE insan/kurt çifti; insan birinci şahıs, kurt üçüncü şahıs | Diğer eşlerin dönüştürülmesi, tüm hareketlerde görsel kontrol; 539 model dosyası / 620 tanım benzersiz karakter sayısı değildir |
| Dövmeler | Kaynak dosyaları envanterde tespit edildi | Dinamik dövme kaplamaları ve gerçek eşya/yetenek etkileri; üç isteğe bağlı dövme mesh'i şimdilik hariç |
| Kurt yeteneği | 19601 güç slotu kontrolü, ileriye çift basış, dört ayak koşu klibi, koşarken vücut saldırısı | Duvara tutunma, havada güçlü saldırı, özgün sayısal denge |
| Kontroller | Dört yön, aç/kapat KOŞ, ayrı büyük ateş, zıplama/eğilme/nişan/şarjör/dönüşüm; isteğe bağlı hareket çubuğu | Özgün 139 komutun hepsi uygulanmış değildir |
| Silah | Kaynaktan AK-47 ve el modeli, 5 klip, iki ses; kaynak şarjör/ateş aralığı | Tüm silahlar, eklenti seçimi, özgün geri tepme/hasar/efekt/mermi sistemi |
| Hesap ve yönetici | Yerel nakit/KP/altın/GP; PC localhost paneli; cihazda yerel güç slotu | Üretim hesabı, gerçek mağaza/envanter, yetkili oyun sunucusu, eşleştirme, çevrimiçi ilerleme |

Kurt koşusunun kaynağı, `Root/wt_attributes/exitemtext.dat` içindeki 19601 **Özel Kurt Yeteneği** açıklamasıdır. Tam tablo 1070 kayıt olarak çözüldü; aynı kimliği tekrarlayan kayıtlar bulunduğu için istenen eşya için benzersizlik ayrıca kontrol edilir. Kaynak alıntısı ve dosya özeti `movement-source-rules.json` içindedir. Dokunma süresi/hız çarpanları yerel mobil ayarlardır; özgün ikili kuralların tamamı çözüldü denmez.

Jungle haritasının kaynakta bulunmayan beş sky19 gökyüzü kaplaması korunmuş eksik kaydı olarak raporlanır; gökyüzü geometri parçaları önizlemeden çıkarılır. Bazı kaynak UV/normal değerleri geçersizdi: UV sıfırlamaları ve yeniden hesaplanan normal sayıları `map-conversion.json` içinde yazılıdır. Böyle bir önizleme tam görsel eşdeğerlik iddiası değildir.

## Doğrulama kapsamı

Kaynak iskelet hiyerarşisi, kaynak/dönüşüm dosya özetleri, Godot içe aktarımı, 19 haritanın ray/ayakta durma açıklığı kontrolü, mobil çoklu dokunma, güç slotu koşulları, çift basış zamanlaması ve örnek oyun davranışları otomatik kontrol edilir. Kurt koşusu/vücut saldırısı, AK-47 duruş/şarjör ve Container Ship/Cappadocia için örnek çevrimdışı görseller incelendi. Bütün animasyon kareleri, bütün haritaların görsel ayrıntıları ve fiziksel telefon performansı test edilmiş değildir.

## Kaynak biçimi başvuruları

- [LTB PC biçimi](https://github.com/Five-Damned-Dollarz/io_scene_lithtech/blob/master/src/reader_ltb_pc.py)
- [DAT v85 biçimi ve bölümleri](https://github.com/lokea2/DAT2LTA85)
- [LithTech dünya dışa aktarım biçimi](https://github.com/URAMetroid/Lith_Dat_Get)
- [Dünya kaplamalarında AlphaRef davranışı](https://github.com/jsj2008/lithtech/blob/master/runtime/render_a/src/sys/d3d/d3d_texture.cpp)

Bu projedeki ayrıştırıcılar bağımsız, sınır denetimli Python kodudur. Eski istemci, DLL veya kaynak paketlerdeki komutlar çalıştırılmadı. Başvurular biçimi anlamak için kullanıldı; üçüncü taraf araç ikilileri oyuna eklenmedi.
