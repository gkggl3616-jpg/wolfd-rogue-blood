# Wolf Rogue Blood

Godot 4.7.2 ile yeni yazılmış **oynanabilir çevrimdışı deneme arenası**, mobil kontroller, yerel yönetici paneli ve PC varlıklarının karakter/iskelet denetimi.

Bu, özgün Windows oyununun tam portu değildir. Tek onaylı insan/kurt çiftiyle ilk oynanabilir sürümdür; yaklaşık 130 karakter, özgün haritalar ve çevrimiçi sistemler tamamlanmış değildir.

## Oyunu aç

Godot içinde [godot/project.godot](godot/project.godot) dosyasını içe aktar ve F5'e bas. Projeye ait ana sahne, fizik, karakterler, temel oyun mantığı ve Android dışa aktarma ayarları artık bu klasördedir. [Oyun kontrolleri ve kapsam](godot/README.md).

- Pedro RE insan/kurt dönüşümü, her formda 7 iskelet klibi.
- 90 saniye / 10 hedeflik arena, can, mermi, şarjör, pençe saldırısı ve yeniden başlatma.
- Sol hareket çubuğu, sağ bakış alanı, nişan, ateş, fiziksel eğilme, zıplama ve koşu.
- Yerel nakit, KP, altın, GP ve geliştirme yöneticisi.

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

Geliştirme anahtarı ve özel oyuncu kayıtları depoya eklenmez. Ses, nihai silah sanatları, çevrimiçi maç/hesap sunucusu, bütün karakterlerin aktarımı ve özgün haritalar sonraki geliştirme işleridir.
