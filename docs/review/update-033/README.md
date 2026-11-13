# Oda ekranı karşılaştırma düzeltmeleri

[PC / önce / sonra karşılaştırması](pc-before-after-033.jpg)

PNG dosyaları Godot 4.7.2 / OpenGL içinde alınmış gerçek görüntülerdir. JPG etiketlenmiş bir karşılaştırmadır. Bu kaynak kod güncellemesinde yeni APK üretilmedi; yayımlanmış 0.32 APK bu değişiklikleri içermez.

41/41 regresyon aşaması ve 35 OpenGL/akış kontrolü geçti; sekiz fotoğrafın tamamı gözle incelendi.

- [Kurt odası, 3 vs 3](wolf-room-1280.png)
- [Sekiz katılımcılı yerel oda](mixed-room-eight-players.png)
- [Çakışmaları giderilmiş oda ayarları](native-room-settings.png)
- [Saldırı / savunma durum kutucuğu](destruction-room-rule-state.png)
- [Vitrinden mevcut yerel kutu koleksiyonuna geçiş](showcase-opens-local-boxes.png)
- [960×540](room-960x540.png) · [2160×992](room-2160x992.png) · [1024×768](room-1024x768.png)

Harita, hesap, bot adları ve oda sahipliği gerçek yerel verilerdir. Örnekteki Giriş haritası ve WOLF PASS / KLAN ZİNCİRİ önceki kullanıcı kapsamı gereği eklenmedi. Başlat yerel oda sahibinin eylemidir. Klan/ping/uzak oyuncu ve sohbet bilgileri uydurulmadı. Vitrin kayıttan alınan görseldir; özgün PC kutularının fiyatı, içeriği veya satış hizmeti aktarılmış değildir. Eksik kaynak yazı tipi nedeniyle piksel eşitliği iddiası yoktur. Fiziksel Android testi yapılmadı.

[Görüntü kontrol kaydı](../../update-033-visual-validation.json) · [Görsel kökeni](../../room-reference-art-033.json) · [Regresyon raporu](../../offline-source-validation-033.json)
