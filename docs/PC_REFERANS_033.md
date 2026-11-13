# Oda ekranı düzeltmeleri · 0.32 üzerine

Kullanıcının gönderdiği PC / 0.32 karşılaştırmasına odaklanan kaynak güncellemesidir. Yeni APK yayımlanmamıştır.

- Üst menü simgeleri kaynak 32×32 boyutunda ve sağdaki sık aralıklarında çizilir; geniş dokunma alanları korunur. GP çubuğunun tema kaynaklı fazla yüksekliği giderildi.
- Özgün yönetici oda başlığı görünür. Oyuncu satırlarının ek opak zemini çıkarıldı; kaynak saydam/dekor katmanları, küçük taç ve durum parçaları kullanılır. Botların ikinci satırında gerçek seçilmiş karakterleri gösterilir; uzak klan/rütbe/ping uydurulmaz.
- Kişi/süre değerleri `3 vs 3` / `10 dakika` biçimindedir. Normal seçenek N simgesi referanstan alınır. Kurt modunda gereksiz silah simgesi gizlenir. Saldırı/savunma kutucuğu yanlış alan adı yerine kaynak `TeamRoleChangeOption` alanına ve gerçek kurala bağlıdır.
- Boş vitrin alanı Mitro / Dolunay görsellerini taşır; KUTULAR düğmeleri mevcut yerel koleksiyonu açar. Özgün PC fiyatı, içerik tablosu veya satış hizmeti iddiası yoktur.
- Fazladan sol alt bot ayar düğmesi çıkarıldı; kaynak AYARLAR ve Diğer menüsü çalışır.
- TÜMÜ / KLAN / HAYKIRMA sekmeleri görünür. TÜMÜ gerçek yerel olayları ve düz metin mesajlarını gösterir; diğerleri bağlantı olmadan mesaj üretmez. Geçmiş oda başına 80 satırla sınırlıdır; yenileme olayları çoğaltmaz. Yeşil alt bant gerçek oda/mod/harita/profil/rütbe bilgilerini gösterir ve kendi alanına kırpılır.
- Oda ayarları, alttaki salt okunur metin/simgeleri ve vitrini gizler; Türkçe seçenekler komşu alanlara taşmaz. İptal gerçek odayı korur. Başlıksız eski kayıtlar güvenli varsayılanla açılır. Desteklenmeyen modun önizleme açıklaması görünür kalır.

[Gerçek görüntüler](review/update-033) · [OpenGL kanıtı](update-033-visual-validation.json) · [Kesitler ve köken](room-reference-art-033.json) · [Regresyonlar](offline-source-validation-033.json).

Son doğrulama: değişmeyen çalışma zamanı üzerinde 41/41 regresyon aşaması geçti. OpenGL turundaki 35 kontrol ve sekiz gerçek fotoğraf doğrulandı; fotoğrafların tamamı gözle incelendi.

Bu çalışma bütün uzun videolar yeniden izlendi diye sunulmaz. Harita/katılımcı/oda sahibi farkları seçili veriler olarak korunur. Eksik 51 numaralı kaynak yazı tipi ve kapsam dışındaki çevrimiçi hesap/sohbet/davet/satış hizmetleri nedeniyle tam piksel ve işlev eşitliği iddiası yoktur. Önceki harita ve menü hariç tutmaları korundu. Fiziksel Android testi yapılmadı. Mevcut 0.32 APK değişmemiştir.
