# Wolf Rogue Blood

Godot 4.7.2 ile yeni yazılmış **oynanabilir çevrimdışı deneme arenası**, mobil kontroller, yerel yönetici paneli ve PC varlıklarının karakter/iskelet denetimi.

Bu, özgün Windows oyununun tam portu değildir. Tek onaylı insan/kurt çifti, özgün haritaların temel geometri gezintisi ve ilk şahıs AK-47/el animasyonlarıyla geliştirme sürümüdür. Bütün karakterler, tam harita/mod davranışları ve çevrimiçi sistemler tamamlanmış değildir. [Aktarımın durumu ve kaynak sınırları](docs/AKTARIM_DURUMU.md).

## Oyunu aç

Godot içinde [godot/project.godot](godot/project.godot) dosyasını içe aktar ve F5'e bas. Projeye ait ana sahne, fizik, karakterler, temel oyun mantığı ve Android dışa aktarma ayarları artık bu klasördedir. [Oyun kontrolleri ve kapsam](godot/README.md).

- Pedro RE insan/kurt dönüşümü, her formda 7 iskelet klibi.
- 90 saniye / 10 hedeflik arena, can, mermi, şarjör, pençe saldırısı ve yeniden başlatma.
- Dört yön düğmesi, sağ bakış alanı, büyük ateş düğmesi, nişan, fiziksel eğilme, zıplama ve ayrı KOŞ düğmesi. Envanterden isteğe bağlı hareket çubuğuna geçilebilir.
- Yerel nakit, KP, altın, GP ve geliştirme yöneticisi.
- İnsan birinci şahısta, kurt çarpışma kontrollü üçüncü şahıs kamerayla oynanır.

## Seçilen haritalar ve mod sınırları

Kullanıcının seçtiği 19 dosya korundu: **58, 59, 65, 72, 1, 2, 26, 31, 44, 46, 50, 110, 57, 100, 97, 92, 82, 83, 84**. Bunların 18'i kaynak ikili tablolarda `(dünya kategorisi, harita kimliği)` ile modlara bağlandı. 62 mod/alt mod kaydı var; insan/kurt ve silah kısıtlaması varyantları birleştirilmedi. Örneğin Cappadocia Destruction, Ruins Wolf Rush, Secret Lab ve Gate Dark Wolfhunt modlarına bağlıdır. Aynı numarayı başka kategoride kullanan bir kayıt eşleşme sayılmaz.

**46 · Göbekli Tepe:** Tam dosya adına ait mod bağlantısı doğrulanamadı. Seçim kaydı korunur ve kapalıdır; 47 numaralı gece/etkinlik sürümü yerine eklenmedi. Kaynakta tanımı bulunmayan 15000/15001 mod bağlantıları da beklemeye alındı.

Oyun menüsünde ve localhost panelindeki **Mod ve haritalar** bölümünde önce mod seçilir, sadece o moda bağlı seçili haritalar listelenir. 19 temel geometri dönüştürüldü; kaynak doğma noktaları ve üretilen çarpışmalar motor içinde kontrol edildi. Modu doğrulanan 18 harita **Haritayı gez · Önizleme** ile açılır. Özgün maç kuralları henüz aktarılmadı; normal mod başlatma kapalıdır. Rastgele seçim yalnızca aynı modun hazır maç haritalarından yapılabilir; başka moda veya deneme arenasına geçmez. Gezinti, arena düşmanları/timer/ödülleri çalıştırmaz.

[Harita–mod listesi](docs/SECILEN_HARITA_MODLARI.md) · [Kaynak kanıtları](docs/selected-map-modes.json). Yeniden üretmek için: `python tools/build_map_catalog.py "yeni-paket-klasoru"`.

## Koşu ve envanter

KOŞ düğmesi normal koşuyu tek dokunuşla açıp kapatır. Klavyede Shift basılı tutularak da koşulur. **Özel Kurt Yeteneği (19601)** yerel deneme envanterinde vardır, ilk kullanımda takılı değildir. Envanterde güç slotuna takıldıktan sonra kurt formunda ileriye 0,30 saniye içinde iki ayrı basış dört ayak koşusunu başlatır; ikinci basış tutulur. İleriyi bırakmak, eğilmek, form değiştirmek, menü veya uygulama odağını kaybetmek koşuyu keser. Eşya takılı değilse veya insan formundaysan çift basış kurt koşusunu açmaz. Koşarken ateş vücut saldırısı yapar. Eşya kaydı yalnızca bu cihazda tutulur; gerçek hesap envanteri aktarılmış değildir.

Aktivasyon ve güç slotu şartı kaynak `exitemtext.dat` içindeki 19601 numaralı açıklamadan doğrulandı. **0,30 saniye, hız çarpanları ve saldırı hasarı yeni mobil ayarlarıdır; özgün sayısal değerler diye sunulmaz.** Aynı açıklamadaki duvara tutunma ve havada güçlü saldırı henüz uygulanmadı. [Kaynak kural ve alıntı](docs/movement-source-rules.json).

AK-47'nin özgün ilk şahıs/el modeli ve duruş, yürüyüş, ateş, şarjör, seçme klipleri aktarıldı. Şarjör 30, ateş aralığı 150 ms kaynak yapılandırmadan; şarjör animasyonu 2,5 saniye. İlgili özgün ateş/şarjör sesleri de var. Bütün silahlar veya özgün render efektleri tamamlanmış değildir.

Android çıktısı `WolfRogueBlood-debug.apk` adıyla üretilir. Geliştirme imzası, arm64 + armv7, yatay ekran. Fiziksel telefonda test edilmedi ve mağaza yayını değildir.

## Chrome yerel paneli

Python 3.10+ yeterlidir; ek Python paketi gerekmez:

```powershell
python server.py
```

Chrome'da http://localhost:8765 adresini aç. Alternatif: `powershell -NoProfile -ExecutionPolicy Bypass -File .\start.ps1` (yalnızca bu işlem için).

Panel test oyuncusu oluşturur; nakit/KP/altın/GP ekler ve son 100 işlemi gösterir. Kayıtlar `data/players.sqlite3` içinde kalır ve Git'e gönderilmez. Aynı işlem kimliğiyle yinelenen istek ikinci kez ödeme yapmaz.

**PC Godot sürümü:** Paneldeki ilk test oyuncusuna bağlanır; yönetici eklemeleri ve arena ödülleri bu oyuncuya işlenir. **Android:** Kendi cihazındaki yerel kayıt ve oyun içi yönetici menüsü kullanılır; telefondaki localhost PC anlamına gelmez. Panel yalnızca 127.0.0.1 üzerinden dinler, internet yönetim sistemi değildir.

## Karakterler

- 539 karakter klasörü modeli tam olarak ayrıştırıldı.
- Yapılandırmada 620 varyant/NPC kaydı ve 398 benzersiz model başvurusu var. Bunlar benzersiz oynanabilir karakter sayısı değildir.
- 445 ortak animasyon dosyası bağlantısının hepsi bulundu. 393 bağlantıda kemik adları/hiyerarşi aynı; 52'sinde fark var.
- Aynı hiyerarşi aynı dinlenme pozu veya görsel animasyon kalitesi demek değildir. 23 ayrı hiyerarşi grubu tespit edildi.
- İnsan/kurt eşi belirsiz, kaynakları eksik veya iskelet uyumu doğrulanmamış karakterler kadroya alınmaz. 205 kayıt yapısal adaydır; otomatik oyun kadrosu değildir.
- Şu an yalnızca **Pedro RE, Model0 + Model2** çifti kabul edildi. Kaynak/dönüşüm özetleri [assets/roster.json](assets/roster.json) ve oyun kopyasında tutulur. Oyun da bu onay listesini okur.

[Karakter raporu](docs/KARAKTERLER.md) · [Özet](docs/character-summary.json) · [Tam denetim (gzip)](docs/character-audit.json.gz)

Kabul edilen çiftin duruş, koşu ve saldırı örnek kareleri çevrimdışı render edilip incelendi. Godot kaynak içe aktarımı ve otomatik oyun testleri geçti. Bütün animasyon kareleri veya fiziksel Android performansı test edildiği iddia edilmez. Kurt modelindeki üç isteğe bağlı, çalışma anında doku alan dövme katmanı taban dönüşümde dışarıda bırakıldı; taban gövde/baş/tüy/zırh kaplamaları mevcuttur.

## Kontrollerin kaynağı

İlk paketlerin ayar taraması: 139 tanımlı komut, 73 atanmış komut. [Bütün kontrol tanımları](docs/KONTROLLER.md) ve [ilk paket özeti](docs/archive-summary.json). Bu arşiv, yeni deneme arenasında 139 komutun hepsinin uygulanmış olduğu anlamına gelmez; arenanın uygulanmış tuşları Godot README'sinde listelenir.

## WolfRogue.dat

[legacy/WolfRogue.dat](legacy/WolfRogue.dat), sağlanan Windows istemcisinin istenen yeni dosya adıyla hazırlanmış birebir kopyasıdır. [SHA-256 kaydı](legacy/binary-manifest.json). Bu dosya kaynak kod veya APK değildir ve Android paketine eklenmez. Özgün klasöre dokunulmadı. Gömülü eski ürün adları, imzalar ve hizmet başvuruları binary içinde değiştirilmedi; bunların tümünü yeniden markalamak kaynak projeden yeniden derleme gerektirir.

## Yeniden üretim

```powershell
python tools/scan_xfs.py "paket-klasoru"
python tools/audit_characters.py "yeni-paket-klasoru"
python -m pip install -r tools/requirements.txt
python tools/convert_character.py "yeni-paket-klasoru" --output godot/assets/characters/pedro-re
```

Son komut varlıkları yeniden üretir. Özetler değişirse onay listesi de tekrar doğrulanmalıdır. Büyük özgün `.xfs` paketleri depoda yoktur. Tam ilk paket envanteri yerelde üretilir; karakter denetim verisi depoda sıkıştırılmıştır.

## Kontrol ve Android derlemesi

```powershell
python -m unittest discover -s tests -v
node --check web/app.js
python tools/check_android_ready.py
godot --headless --path godot --fixed-fps 60 --script res://tests/smoke.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_android.ps1 -Godot "godot-program-yolu"
```

Android için eşleşen Godot 4.7.2 şablonları, JDK 17 ve Android SDK gerekir. Bu bilgisayarda kuruldu. [Godot'un resmi Android dışa aktarma yönergeleri](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html). Son derlemenin özeti [docs/android-build.json](docs/android-build.json) içindedir.

Geliştirme anahtarı ve özel oyuncu kayıtları depoya eklenmez. Tam ses/efekt sistemi, bütün silahlar, çevrimiçi maç/hesap sunucusu, bütün karakterler ve özgün harita/mod davranışları bekleyen işlerdir.
