# Wolf Rogue Blood çalışma kuralları

- 0.31 kullanıcı düzeltmesi: Normal kurt ana canı 240, insan temel canı 100; oyuncu ve botlar aynı form temellerini kullanır. Diğer mutasyonların önceki yerel can farkları korunur; doğrulanmamış karakter alanları HP diye yorumlanmaz. YP ayrı kalır. Zaten seçili kurdu onaylamak tekrar SP harcatmaz; farklı kurtların kaynak fiyatları korunur. Koşuda üst/alt gövde kaynak maskeleri birlikte kullanılır; bütün kapalı istemci animasyon izleyicileri tamamlandı diye sunulmaz. Bot siperi gerçek çarpışma/görüş ve paylaşılan görülmüş konuma bağlı olmalı; görünmeyen hedefin canlı konumunu paylaşma.


- Son kullanıcı talimatı (0.30 çalışması): kalan PC farklarını araştırıp gider; doğrulanmış APK üret ve GitHub üzerinden paylaş. Önceki APK hazırlama/yayımlama yasağı bu açık talimatla kaldırıldı. Çevrimdışı kapsam ve video yerleşimi korunur. Çözülemeyen alanları tamamlanmış diye işaretleme.

- Kalıcı FT düzeltmesi (0.25): mor el parlaması Mor Pençe sahipliğine bağlı değildir; yalnızca başarıyla etkinleştirilen enerji/FT paketi süresince görünür. FT hareketi hızlandırır ve ana candan bedel alır. İlk yardım ayrı yaşam başına kullanım sınırına sahiptir; tekrar kullanılabilen paket sahipliği her basışta tüketilmez. Kaynakta çözülemeyen hız birimi ve video/sürüm zaman farkı kesin PC değeri diye sunulmaz.

- Geçerli kapsam çevrimdışı Android sürümüdür; gerçek sunucu kapsam dışındadır. Tam PC aktarımı veya fiziksel Android testi yapılmış gibi işaretleme.
- Kullanıcının son isteği: mevcut 19 haritayı koruyup rastgele 15 yeni kaynak harita ekle (toplam 34). Önceki Giriş/İki Tapınak hariç tutması korunur. Yeni haritalar geometri, takım doğma noktaları ve navigasyonla doğrulanmadan hazır sayılmaz.
- Her oyun güncellemesinde yeni/değişen özelliklerin gerçek oyun içi ekran görüntülerini al ve kullanıcıya fotoğraflarla göster. Doğrulanmış tek APK'yı GitHub sürüm dosyası olarak paylaşmak kullanıcı tarafından yetkilendirildi.
- Oyun içi mobil düğmeler yuvarlak ve görselli olmalı. Ateşli silahta mermi, kurt saldırısında pençe, şarjör yenilemede gerçek şarjör görseli kullan. Eylem ve gösterilen görsel uyuşmalı.
- Botlar Kolay/Normal/Zor profilleri kullanır; isabet hasarı ve can zorluğa göre değişmez. 80/95/110 oyun karar profili değerleridir, insan IQ ölçümü değildir. Görüş, yol, takla ve sonlu mühimmat/şarjör durumları gerçek olmalı.
- Kaynak model/doku/ses kökenini koru. Bilinmeyen PC istatistiği, çevrimiçi sahiplik, ödül veya ağ sonucu uydurma. Videodaki özel bot kodu ve “Turu kazandınız” bandı özgün PC kaynağı diye eklenmez.
- Godot 4.7.2 ve `tools/validate_mobile.py` ile değişikliklere uygun doğrulamayı çalıştır. APK'yı ZIP/kaynak bağımlılıkları, imza, kimlik ve izinleriyle doğrula; tam-PC teslim denetimini çevrimdışı denetim yerine geçirme.
- Özel anahtarlar ve yetkilendirme bilgileri depoya veya araç çıktısına eklenmez.

- Son PC referanslarının kaydı `docs/pc-reference-expansion.json` içindedir. Harita fotoğrafları gerçek PC tablosuna, rütbe ad/simgeleri kaynak class.txt dosyasına bağlıdır; yerel GP eşikleri özgün PC eşiği diye sunulmaz.

- Kalıcı kullanıcı kuralı (2026-11-07): Kullanıcının tüm referans videolarında bir öğe neredeyse arayüz, menü, can, YP, SP, süre, skor, radar, cephane, yetenek ve silah alanı aynı göreli konumda kalır. Yeni özellik veya güncelleme bu yerleşimi değiştiremez. Varsayılan geometri `godot/scripts/video_layout.gd` üzerinden gelir; yeni ekranlar önce kaynak kareyle karşılaştırılır. PC videosunda bulunmayan mobil tuşlar bilgi alanlarını ve merkezdeki karakteri kapatmadan kenarlara yerleştirilir; mobil uyarlama özgün PC tuş konumu diye sunulmaz. Kullanıcının açıkça yaptığı kontrol düzenlemesi ayrı tercihtir; yeni özellik eklerken varsayılan düzen keyfî değiştirilmez.

- İki yeni kurt kaydının gerçek dosya/kare incelemesi ve açık eşitlik sınırları `docs/PC_REFERANS_024.md` ile `docs/video-wolf-review-024.json` içindedir. Yeni bir otomatik video özeti doğrudan görüntü kanıtı yerine geçmez.
- Altı oyun kaydının yeniden taraması, FT'nin can/YP kanıtı ve 0.24'teki yanlış eşya/efekt bağının düzeltmesi `docs/PC_REFERANS_025.md` ve `docs/video-audit-025.json` içindedir. 0.24 belgesindeki Mor Pençe bağlantısını yeniden uygulama.

- Kalıcı inceleme kuralı (0.26): Seyrek kare/temas paftası incelemesini videonun tamamını kesintisiz izlemek diye sunma. Uzun kayıtları ses ve hareket içeren ardışık parçalarla incele; otomatik çözümleme eksik aralıklarını ve başarısız işleri açıkça kaydet. Modelin "enerji mermisi", "zemin patlaması", "hız rampası", "final kararması" gibi tahminlerini gerçek kare ve kaynak doğrulaması olmadan oyun kuralına dönüştürme. 0.26 inceleme yöntemi ve sınırları `docs/PC_REFERANS_026.md` içindedir.

- FT zaman/can kuralı (0.27): `docs/power-timing-source-027.json` ve iki kaydın özgün HP dizisi, her saniye mevcut kesirli ana HP üzerinden yüzde kaybını doğrular. Nakit FT: ilk %25, sonra saniyede %2, 10 saniye; altın FT: ilk %50, sonra saniyede %5, kaynak ikili süre 7 saniye. Ekran değeri aşağı yuvarlanır, iç kesir korunur. İlk yardımın +2/+5 HP tikleri ayrıdır; yanlış dakika başına düz eksiltmeyi geri getirme. Hız +50/+100 biriminin PC dönüşümü hâlâ doğrulanmamıştır.

- 0.29: altı oyun kaydından 5 saniyede bir alınan 902 kare yeniden incelendi; kesintisiz insan izlemesi diye sunulmaz. Botlar sekiz canlı yuvada farklı ve yeniden doğuşta sabit ad/karakter/izinli silah kullanır. Pençe ekipmanı açık yerel bot yüklemesidir; eksik varsayılan kaynak dokusu yerine özgünmüş gibi doku uydurulmaz. Seviye mevcut GP ve 62 kaynak rütbeye bağlıdır; GP eşikleri yereldir, ikinci XP cüzdanı tutulmaz. 0.29 sırasında APK istenmemişti; 0.30 son talimatı APK üretimini yetkilendirir.
