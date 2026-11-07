# Kalıcı video yerleşim kuralı

Kullanıcının 2026-11-07 tarihli açık talebi: “butonların tuşların YP SP, izlediğin videoda neredeyse her şeyi aynı yere koy ve bu kural her zaman geçerli”. Kural `AGENTS.md` içinde gelecek güncellemeler için de kayıtlıdır.

Referanslar: [kurt kaydı](https://drive.google.com/file/d/1aLtBA24fugZ04CYmRADJls8D40z33vBj/view) 06:42 ve [Yıkım kaydı](https://drive.google.com/file/d/1dWltFGibelqf2i_8XReiOvH5_MS5pVse/view) 00:50, 02:00, 13:01. [Kaynak kareler](review/video-reference/) depoda korunur.

- Can ve YP sol alttadır. Kaynak `HPBack`, `HealthPoint`, `CryHealthPoint` ve özgün sayı atlasları doğrudan kullanılır. Kurt canı beyaz, insan canı kırmızıdır. YP ayrı değer olarak canın altındadır; kapasite metni sonradan yanına eklenmez.
- SP, şarjör ve yedek sağ altta aynı özgün `WeaponBack` içinde `WeaponPoint`, `CurrentBullet`, `MaxBullet` göstergeleridir. Silah adı aynı sütunun altındadır. Bu alanlar yeni özellik için yukarı veya ortaya taşınmaz.
- Skor üst ortada, saat altında; radar ve harita adı sağ üstte; öldürme akışı sağdadır. Kaynak 1024×768 arayüz geometrisi videodaki gibi ekran oranına uygulanır.
- Hazırlıkta ilk dört sütun Standart/SLH 1/SLH 2/SLH 3 düzenindedir; soldaki boşluk, satır yüksekliği ve karartılmış bant kaynak kareye bağlıdır. Beşinci kayıtlı set kaydırılarak erişilir. Mutasyon kartları aynı satır ve genişliktedir.
- Saldırı/savunma değişiminde kaynaktaki `pl_change.dtx` paneli aynı dikdörtgende gösterilir; yeni bir metin kutusu çizilmez.
- Kurulan bombanın turuncu kaynak sayı atlası üst ortadaki süre alanını kullanır. İşlem ilerlemesi alt ipucu bölgesindedir; can/YP ve SP/cephane konumları korunur.
- Maç sonunda kaynak `gr_cc_bg` ödül görünümünde üstte dört kart, sol altta beşinci alan; `gr_bg` ayrıntılarında üstte kırmızı, altta mavi takım ve sağda bireysel sonuç bulunur. Ayrıntı/Geri ve Tamam düğmelerinin kaynak 1024×768 düzenindeki Y konumları ödüllerde 727, ayrıntılarda 701'dir. Sonuç ekranında lobi üst menüsü gösterilmez. [Ödül](review/video-reference/result-awards-12m54.png) ve [ayrıntı](review/video-reference/result-details-12m58.png) referans kareleri korunur.
- PC kayıtlarında dokunmatik tuş yoktur. Mobil düğmeler solda hareket, sağda iki eylem satırı olarak boş kenarlardadır; can/YP, SP/cephane, radar, bildirim ve merkezdeki karakter alanını kapatmaz. Yuvarlak şekilleri ekran oranıyla ovalleşmez. Kullanıcının açıkça sürükleyip kaydettiği düzen korunur.

Varsayılan konumlar `godot/scripts/video_layout.gd` dosyasındadır. Yeni ekran veya özellik bu yerleşimi değiştiremez; kaynakta karşılığı varsa aynı alan kullanılır. Bir konumun özgün PC karşılığı yoksa mobil uyarlama olduğu belirtilir. `video_layout_021.gd` üç ekran boyutunda ölçülen bilgi alanlarını, dairesel düğmeleri, açık kalan görüş alanını ve ekipman satırını sınar. Yeni/değişen ekranların gerçek motor görüntüsü alınmadan yerleşim tamamlandı sayılmaz.
