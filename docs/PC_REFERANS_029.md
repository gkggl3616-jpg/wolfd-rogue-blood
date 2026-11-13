# 0.29 · Kurt hareketi, botlar ve rütbeye bağlı seviye

Bu çalışma çevrimdışı kaynak ve oyun fotoğrafları içindir. **Yeni APK hazırlanmadı/yayımlanmadı.** Son APK olan 0.27 bu değişiklikleri içermez. 34 harita, 903 silah, Giriş/İki Tapınak hariç tutması ve videoya bağlı göreli arayüz yerleşimi korunur.

[Yeni gerçek oyun fotoğrafları](review/update-029) · [902 karelik referans taraması](review/update-029/reference-every-5s) · [Önceki açık farklar](PC_REFERANS_028.md)

## Yeniden inceleme

Altı özgün oyun kaydı yeniden bütünüyle çözüldü; **74:53.352** toplam sürede her 5 saniyelik noktada ilk mevcut kare alındı. **902 özgün boyutlu ekran görüntüsü**, gerçek PTS ve SHA-256 ile doğrulandı; hepsini içeren **59 zaman damgalı sayfanın tamamı** gözle incelendi. Sayfalar fotoğraf klasörünün `reference-every-5s` altındadır. Özgün boyutlu tekil JPEG'ler inceleme çalışma alanında tutulur; yayımlanan paftalar bunların küçültülmüş kopyalarıdır.

FT başlangıcı (`old1`, 27–30 sn), buz kaplaması (`new1`, 54–56 sn), hava saldırısı ve örtüşen etkiler (`new2`, 23:08–23:11) ayrıca 125 ms aralıklı **64 ardışık örnekle** kontrol edildi. Kaynak dosya hashleri, 902 zaman noktası, bütün sayfa hashleri, üç hareket dizisi ve gözlemler [inceleme kaydındadır](video-audit-029.json).

Bu yöntem kesintisiz gerçek zamanlı insan izlemesi veya bütün özgün karelerin tek tek incelenmesi olarak sunulmaz. Beş saniyelik aralık kısa hareketleri/sesleri kaçırabilir; üç kısa hareket dizisi bütün aralıklar için böyle bir iddia sağlamaz. Önceki [hareket/ses incelemesi](video-audit-026.json) ve [FT'nin kaynak can/süre kanıtı](power-timing-source-027.json) korunur. Yeni otomatik video tahmini oyun kuralına dönüştürülmedi.

Mor FT eli; buzun beyaz gövde kaplaması; camgöbeği/kırmızı pençe sunumu; kısa iyileşme artıları ve örtüşen halkalar ayrı incelendi. Buz görünümü tek başına sersemletme veya hareket cezası sayılmadı. Sarı halkalardan yeni hasar/hız kuralı çıkarılmadı. Karaktere göre görülen 200/320 kurt ve 330 insan canı, bütün kurtların temel canını değiştirme gerekçesi yapılmadı.

## Değişiklikler

| Alan | Son davranış | Kanıt |
|---|---|---|
| Kurt bot saldırısı | Özgün sol/sağ saldırı klipleri sırayla kullanılır. Hasar sabit 280 ms beklemesi yerine gerçek `fire_key` anında bir kez çözülür. Mesafe, gerçek görüş, düşman takım ve canlı maç şartları korunur. Menü/değişen klip/ölüm bekleyen darbeyi iptal eder. | [989 hedefli kontrol](mobile-029-validation.json), [kaynak olaylar](../godot/assets/gameplay/animation-events.json) |
| Pençe izi | Oyuncu ve kurt botu aynı kaynak kemik uçları/dokusunu ve `spline` anahtarlarını kullanır. Önceki örnekler dünya konumunda kalır; aktör dönünce/yer değiştirince sürüklenmez. Emisyon bitince eski kuyruk sönerek kaybolur. 180 ms kuyruk ömrü açık yerel çizim uyarlamasıdır. | [Paylaşılan çizim](../godot/scripts/claw_trail.gd), gerçek OpenGL fotoğrafları |
| Eksik varsayılan pençe | `swingTrail_default.dtx` sağlanan arşivde yoktur. Botlara mevcut doğrulanmış kaynak pençe eşyaları açık yerel ekipman olarak atanır; başka bir doku eksik varsayılanmış gibi sunulmaz. Oyuncunun ekipmanı bot tarafından ödünç alınmaz. | [Bot kadrosu](../godot/scripts/bot_roster.gd), [kaynak güç eşyaları](../godot/assets/items/power.json) |
| FT ayrımı | Mor el parlaması yalnız başarıyla etkin FT süresince görünür. Pençe sahipliği FT'yi başlatmaz; pençe değişimi etkin FT'yi sonlandırmaz. Mevcut kesirli candan başlangıç ve saniyelik yüzde kaybı ile ayrı iyileşme korunur. Botun pençe ekipmanı ona kendiliğinden FT vermez. | Önceki 0.25/0.27 regresyonları ve yeni fotoğraflar |
| Ayrı bot kimlikleri | En çok sekiz canlı yuvada farklı ad, takımına uygun farklı kaynak karakter ve izinli farklı ana silah vardır. Oda önizlemesi, maç, skor/eleme ve yeniden doğuş aynı yuvanın kimliğine bağlanır. Bot etiketi görünür kalır; çevrimiçi oyuncu/rütbe taklidi yoktur. | On beş yerel/kaynak mod bağlamında kadro kontrolleri; gerçek oda ve sekiz aktör fotoğrafı |
| Kaynak bot silahları | 11 kategoride 59 HH silah/kaplama profili eklendi. Kapasite ve atış aralığı kaynak tablodan, dolum süresi kaynak klipten gelir. Sağ el bağlantısı gerçek `RightHand` soketi dönüşümünü kullanır; animasyonlu elin dönüşünü iptal eden eski yerleşim ve ikinci kök ölçeği düzeltildi. | [59 modelin kökeni/hashleri](bot-arsenal-source-029.json), [varlık denetimi](../tools/check_bot_arsenal.py) |
| Sonlu mühimmat | Tükenen ana silah izinli, sonlu yan silaha ve sonra bıçağa geçebilir. Eski silaha dönmek mermi üretmez. SUPAS bot dolumunda kaynak ekleme klibi bir mermi ekler, yedek bitince veya yeterli mermiyle tehdit görünce kaynak bitirme süresi tamamlanır. | Gerçek motor mühimmat/dolum kontrolleri |
| Bot kararları | Hücum, yan yaklaşma, destek ve keşif rolleri; silaha göre menzil; hareket ederken ateş; çok yaklaşana karşı mesafe açma; gerçek siper ve kısmi şarjör fırsatı eklendi. Hedefler nav ağı, kapsül boşluğu, yol, atış görüşü ve takım arkadaşı aralığıyla sınanır. Takılı kalma gerçek hız sıfırken hareket niyetinden de anlaşılır; bağlantılı bir kurtarma yolu seçilir. | Gerçek fizik içinde yan hareket ve ateş, görüş/duvar, siper, kaçış ve sonlu mühimmat testleri; [sekiz aktörün 8 saniyelik gerçek karşılaşmasında](bot-squad-029-validation.json) sekizi de 7,2–17,6 m ilerledi, sekiz farklı silahla toplam 112 atış yapıldı. Bu koşu Android hız ölçümü değildir. |
| Bot rota bilgisi | İlk arama hedefi statik karşı takım doğma noktalarından erişilebilen farklı yuvaya göre seçilir. Gizli oyuncunun canlı konumu bu arama hedefi değildir. Son görülmüş/duyulmuş nokta hafızası, görüş kesilmesi ve mevcut gerçek sıçrama bağlantıları korunur. | Yeni taktik kodu ve mevcut 34 haritalık fizik/navigasyon regresyonu |
| Hasar/zorluk | Kolay/Normal/Zor canı 100, doğrudan isabet hasarı 8 olarak kalır. Karar, tepki, isabet dağılımı, hafıza ve kaçış değişir. 80/95/110 yerel karar profili adlandırmasıdır; ölçülmüş insan IQ'su değildir. | [65 bot davranış kontrolü](bot-validation.json) |
| Seviye/rütbe | Hesap seviyesi mevcut kaydedilen GP'den ve **62 mevcut kaynak rütbeden** hesaplanır. İkinci XP cüzdanı yoktur. Gerçek eleme GP'si eşiği geçince seviye/rütbe yükselir; eski GP kaydı aynı seviyeyi geri getirir. Yazma başarısızsa GP, seviye ve yükselme olayı değişmez. | 62 eşik, gerçek disk kaydı, başarısız yazma ve gerçek eleme/sonuç testi |
| Seviye arayüzü | Mevcut üst şerit, profil ve rütbe listesinde seviye görünür. Sonuç ekranında kaynak ok alanı GP ilerlemesini, iki uç mevcut/sonraki rütbeyi ve ad alanı seviye geçişini gösterir. Bot ad boyutu baş hizasına indirildi. HUD/mobil kontrol yerleri taşınmadı. | Yeni oyun fotoğrafları ve video yerleşim regresyonu |

Rütbe ad/simgeleri kaynak `class.txt` içeriğindendir. **GP eşikleri yereldir:** önceki `100 × rütbe_indeksi²` düzeni korunur; PC'nin doğrulanmış GP tablosu diye sunulmaz. En yüksek yerel seviye 62'dir (372.100 GP). Kaynak madalya/GP/sunucu fiyatı veya yeni bitirme ödülü uydurulmadı. Wolf Pass ayrı mevcut yerel etkinlik ilerlemesidir; hesap seviyesini değiştirmez.

## Açık sınırlar

Bu çalışma tam PC eşitliği veya “0 eksik” teslimi değildir. Önceki [0.28 açık farkları](PC_REFERANS_028.md#inceleme-yöntemi-ve-açık-kalanlar) geçerlidir: **Ruins #72 ve Bridge #37 karşı takım yolları kopuk**, gömülü ışık haritaları/özgün renderer, bütün özel mühimmat kuralları ve modern ekipman eşlemeleri tamamlanmış değildir. 67 kaynak modun 14'ü desteklenir. Bazı özgün ses/efekt dosyaları arşivde yoktur. Wolf/FT hız birimlerinin bütünü, bütün PC karakter/silah istatistikleri ve silaha özel üçüncü kişi beden hareketleri çözümlenmiş sayılmaz. Yeni soket dönüşümü bu hareket bankalarının tamamlandığı anlamına gelmez. Bot taktikleri özgün PC sunucu bot kodu değil, yerel fizik simülasyonudur.

**Fiziksel Android cihaz/emülatör testi yapılmadı.** Fotoğraflar gerçek Godot/OpenGL çalıştırmasındandır; telefon fotoğrafı veya özgün PC ekranı diye sunulmaz. Test fotoğraflarında kontrollü yerel GP/poz/durum başlangıçları kullanılır. Disk kalıcılığı ayrı motor testinde gerçek geçici dosyayla doğrulanır.

## Doğrulama

**37/37 regresyon aşaması geçti.** Yeni özellikler için 989 hedefli kontrol ve ayrıca sekiz aktörlü karşılaşmada 13 kontrol başarılıdır (toplam 1.002 yeni kontrol). [Tam regresyon](mobile-validation.json), [989 kontrol](mobile-029-validation.json) ve [13 karşılaşma kontrolü](bot-squad-029-validation.json) aynı sabit çalışma zamanına bağlıdır.

**20 grupta 356 gerçek OpenGL görüntüsünün dosya/hash ve çalışma zamanı bağı denetimi geçti; 29'u bu güncellemeye aittir.** Yeni 29 görüntü ayrıca gözle incelendi. Bu sayı 902 kaynak video karesinden ayrıdır. [26 ana fotoğraf](update-029-visual-validation.json), [üç Taksim fotoğrafı](update-029-source-visual-validation.json) ve [çevrimdışı kaynak denetimi](offline-source-validation-029.json).

Çalışma zamanı SHA-256: `2b15bc62851de3ce98ed6f530765cc6b1976567c0bc0c453c2f3cab244e456a7`.

APK, sürüm etiketi veya yeni derleme dosyası yayımlanmadı.
