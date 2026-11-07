# Wolf Rogue Blood çalışma kuralları

- Geçerli kapsam çevrimdışı Android sürümüdür; gerçek sunucu kapsam dışındadır. Tam PC aktarımı veya fiziksel Android testi yapılmış gibi işaretleme.
- Kullanıcının son isteği: mevcut 19 haritayı koruyup rastgele 15 yeni kaynak harita ekle (toplam 34). Önceki Giriş/İki Tapınak hariç tutması korunur. Yeni haritalar geometri, takım doğma noktaları ve navigasyonla doğrulanmadan hazır sayılmaz.
- Her oyun güncellemesinde yeni/değişen özelliklerin gerçek oyun içi ekran görüntülerini al ve kullanıcıya fotoğraflarla göster. Doğrulanmış tek APK'yı GitHub sürüm dosyası olarak paylaşmak kullanıcı tarafından yetkilendirildi.
- Oyun içi mobil düğmeler yuvarlak ve görselli olmalı. Ateşli silahta mermi, kurt saldırısında pençe, şarjör yenilemede gerçek şarjör görseli kullan. Eylem ve gösterilen görsel uyuşmalı.
- Botlar Kolay/Normal/Zor profilleri kullanır; isabet hasarı ve can zorluğa göre değişmez. 80/95/110 oyun karar profili değerleridir, insan IQ ölçümü değildir. Görüş, yol, takla ve sonlu mühimmat/şarjör durumları gerçek olmalı.
- Kaynak model/doku/ses kökenini koru. Bilinmeyen PC istatistiği, çevrimiçi sahiplik, ödül veya ağ sonucu uydurma. Videodaki özel bot kodu ve “Turu kazandınız” bandı özgün PC kaynağı diye eklenmez.
- Godot 4.7.2 ve `tools/validate_mobile.py` ile değişikliklere uygun doğrulamayı çalıştır. APK'yı ZIP/kaynak bağımlılıkları, imza, kimlik ve izinleriyle doğrula; tam-PC teslim denetimini çevrimdışı denetim yerine geçirme.
- Özel anahtarlar ve yetkilendirme bilgileri depoya veya araç çıktısına eklenmez.

- Son PC referanslarının kaydı `docs/pc-reference-expansion.json` içindedir. Harita fotoğrafları gerçek PC tablosuna, rütbe ad/simgeleri kaynak class.txt dosyasına bağlıdır; yerel GP eşikleri özgün PC eşiği diye sunulmaz.

- Kalıcı kullanıcı kuralı (2026-11-07): Dört referans videosunda bir öğe neredeyse arayüz, menü, can, YP, SP, süre, skor, radar, cephane, yetenek ve silah alanı aynı göreli konumda kalır. Yeni özellik veya güncelleme bu yerleşimi değiştiremez. Varsayılan geometri `godot/scripts/video_layout.gd` üzerinden gelir; yeni ekranlar önce kaynak kareyle karşılaştırılır. PC videosunda bulunmayan mobil tuşlar bilgi alanlarını ve merkezdeki karakteri kapatmadan kenarlara yerleştirilir; mobil uyarlama özgün PC tuş konumu diye sunulmaz. Kullanıcının açıkça yaptığı kontrol düzenlemesi ayrı tercihtir; yeni özellik eklerken varsayılan düzen keyfî değiştirilmez.
