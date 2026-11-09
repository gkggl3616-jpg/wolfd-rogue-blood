# 0.31 · Kurt hareketi, seçim ve takım botları

Bu güncelleme, koşarken çömelmiş kalan kurt, engellere takılma, yanlış temel can, dokunmayla çalışmayan ilk kurt seçimi ve tek sıra ilerleyen botlar hakkındaki kullanıcı bildirimini ele alır. Çevrimdışı kapsam ve videoya bağlı göreli arayüz yerleşimi korunur.

[Oyun fotoğrafları ve iki hareket kaydı](review/update-031) · [Yeni TikTok incelemesi](video-audit-031.json) · [Kaynak üst/alt gövde kanıtı](wolf-pose-source-031.json) · [Motor kontrolleri](mobile-031-validation.json)

## Düzeltmeler

- **Kurt 240, insan 100 temel HP:** Normal kurt için kullanıcının istediği 240 uygulanır; oyuncu ve bot aynı form temelini kullanır. Zorluk canı değiştirmez. Harita keşfindeki eski 100 HP başlangıcı da düzeltildi. YP ayrı kalır. Power/Guardian/Ghost, önceki yerel farklarla 270/320/225 olur; bunlar bütün PC karakterlerinin çözülmüş özgün istatistiği değildir.
- **İlk seçim:** Başlangıç SP'si 0 ve Normal kartının fiyatı 50 olduğu için tüm kartların kilitlenmesi giderildi. Zaten takılı kurt bedelsiz onaylanır; farklı kurda geçişin kaynak fiyatı korunur. İlk parmak kimliği 0 dahil dokunma sahipliği, kaydırma iptali ve odağı kaybetme davranışı düzeltildi. Kontrol 1280×720, 1920×1080 ve 960×540 görünümde gerçek dokunma olaylarıyla sınandı.
- **Koşu/çömelme ayrımı:** Önceki oynatıcı yalnız alt gövdeyi kullandığından üst beden koşu sırasında eski duruşta kalabiliyordu. 27 özgün kurt iskeleti için kaynak Upper ağırlık maskesi, Upper/Lower klipleri ve gerçek saldırı anları korunarak 729 bileşik poz üretildi. Ayakta, koşu, çömelme, çömelerek koşu, havada duruş ve sağ/sol saldırı ayrı bağlanır. Kaynak takla ve uluma klipleri korunur.
- **Kalkış ve basamak:** Ayağa kalkış kontrolü artık karakterin üzerinde yeni kaplayacağı hacmi ölçer; altındaki destek zemini yanlışlıkla tavan sayılmaz. Gerçek alçak tavan kalkışı engeller. 0,38 metreye kadar basamak geçişi yukarı/ileri kapsül taraması ve yürünebilir üst yüzeyle doğrulanır. Takla bitişi aynı güvenli kalkış yolunu kullanır.
- **Takım botları:** Görülen hedefin son görülmüş noktası takım içinde süreli paylaşılır. Görünmeyen hedefin canlı konumu okunmaz. Ayrı yaklaşma ve siper noktaları rezerve edilir; yakın zamanda gerçekten ateş eden takım arkadaşının desteği yan yaklaşan botun rotasını etkiler. Farklı ad/karakter/silah kullanan mevcut sekiz yuva korunur.
- **Gerçek siper döngüsü:** Bot fiziksel sipere gider, bekler/çömelir, köşeye çıkar, kendi gerçek atış hattı açılınca ateş eder ve geri döner. Alçak can veya ateş altında kalma siper kararına girer. Çömelmiş göz ve namlu yüksekliği kapsüle bağlıdır. Arkadaşın işgal ettiği nokta boş siper sayılmaz; rezervasyon ve süre sonları temizlenir. Mühimmat ve şarjör yenileme gerçek kalır.

Kaynak gövde ağırlıkları ve klip zamanları korunur; üst/alt döngülerin faz eşlemesi yerel uyarlamadır. Kapalı PC istemcisindeki bütün animasyon izleyicileri veya piksel eşitliği tamamlanmış değildir. Sıkıştırılmış poz bankası ikili float32 olarak paketlenir, gereken klip açılır ve en fazla üç kaynak bankası önbellekte tutulur.

## Yeni videonun gerçekten incelenen kapsamı

TikTok bağlantısının normal tarayıcıda sunduğu **33,877914 saniyelik** 1024×576/30fps dosya alındı. FFmpeg videoyu sonuna kadar çözdü; **0,2 saniyede bir 169 örnek**, 11 temas sayfasında gözle incelendi. Bu, her özgün karenin tek tek veya kesintisiz sesli izlenmesi diye sunulmaz. Kaynak dosya ve sayfa SHA-256 değerleri inceleme JSON'undadır.

Kayıtta ayakta koşu, çömelme/kalkış, durağan ve hareketli takla, çatı/kenar sıçrayışı, sağ/sol pençe, çömelerek saldırı, geçici saydamlık ve ayrı uluma parlaması görülür. Kurgu/hız değişimleri kesin hareket hızını çıkarmaya uygun değildir. Bu video bot takım savaşı göstermiyor; koordinasyon kullanıcının istediği yerel AI geliştirmesidir. 240 HP kullanıcının açık talebidir, bu görüntünün her karaktere kanıtladığı evrensel PC değeri değildir. Önceki FT yüzdeleri ve süreleri korunur.

Önceki uzun kayıtların 5 saniyelik 902 kare incelemesi [0.29 belgesinde](PC_REFERANS_029.md) durur; bu sürümde bunların tekrar kesintisiz izlendiği iddia edilmez.

## Doğrulama ve kalan PC farkları

[Regresyon raporu](mobile-validation.json), [42 yeni motor kontrolü](mobile-031-validation.json), [gerçek sekiz bot kaydı ve konum/atış/siper izi](update-031-visual-validation.json), [normal oyun kamerasında kurt hareket kaydı](update-031-wolf-demo-validation.json) ayrı kanıtlardır. Kayıtlar gerçek Godot/OpenGL görüntüsüdür, ses içermez. Bot kaydı 12 saniye boyunca aktör konumlarını elle yönlendirmeden çalışır; kurt kaydı kontrollü girişlerle 8 saniyelik koşu/çömelme/takla/pençe/sıçrama gösterir. Telefon ekran kaydı değildir.

**Tam PC eşitliği tamamlanmadı.** [0.30 açık farkları](PC_REFERANS_030.md) sürer: Bridge #37 ve Ruins #72 karşı takım yolları, atlanmış WorldModel/gökyüzü ve özgün renderer davranışı, 67 modun mevcut 14'ü dışındaki kurallar, bazı özel mühimmat sınıfları, eksik kaynak ses/namlu/pençe dosyaları ve bütün karakterlerin özgün istatistikleri. FT hız biriminin kesin PC dönüşümü çözülmedi. Gerçek sunucu kapsam dışıdır. Fiziksel Android cihaz/emülatör testi yapılmadı.

## Gerçek son paket sonucu

39/39 regresyon aşaması; 23 OpenGL grubunda 452 görüntü; yeni ana grupta 34 ve hareket grubunda 5 fotoğraf. İki sessiz oyun kaydı 120/80 gerçek kareden üretildi. Çalışma zamanı SHA-256: `94b1ccfbae5f59818fcf25c437496d9c2d812053a53e44f646358ed9f91c5cfc`.

İmzalı APK: **1,688,778,550 bayt**; SHA-256 `6482430f3cc0af9fb8a5b9bb776846eb564ec2e0f52b1428189fa40174632bd0`. 49 katalog, ZIP CRC, kaynak bağlantıları, kimlik/sürüm, v2/v3 imza ve 16 KiB hizalama doğrulandı. Fiziksel telefon testi veya bütün PC kurallarının tamamlandığı anlamına gelmez.
