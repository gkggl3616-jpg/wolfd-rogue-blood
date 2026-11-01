# Wolf Rogue Blood — Godot 4.7.2

Yeni yazılmış çevrimdışı, oynanabilir deneme arenası. Orijinal Windows oyununun bütün oyun kurallarını ve çevrimiçi altyapısını taşımaz.

Godot'ta bu klasördeki `project.godot` dosyasını içe aktar; F6 ile sahneyi veya F5 ile oyunu çalıştır. Ana sahne `main.tscn`.

- 90 saniye / 10 hedeflik deneme, can, mermi, yedek mermi, şarjör ve tekrar başlatma.
- Kontrol edilen Pedro RE insan/kurt çifti; diğer karakterler eklenmedi.
- İnsanda 7, kurtta 11 dönüştürülmüş klip; dört ayak koşusu ve vücut saldırısı oyuna bağlıdır. Dönüştürülmüş güçlü saldırı/duvar tutunma kliplerinin oyun kuralları henüz bağlı değildir.
- Dört yön düğmesi + sağ bakış + büyük ateş + ayrı aç/kapat KOŞ düğmesi; envanterden sanal çubuğa geçilebilir. Çoklu dokunma bırakma durumları otomatik testte kontrol edildi.
- Özel Kurt Yeteneği (19601) güç slotuna takılıyken kurt formunda ileriye iki kez basıp ikinci basışı tutmak dört ayak koşusunu açar. Bırakma/eğilme/form/menü/odak kaybı koşuyu keser. Eşya ilk kullanımda takılı değildir. Klavyede aynı W-W kuralı geçerlidir.
- Özgün AK-47 ve el modeli, 5 klip, ateş/şarjör sesleri. Şarjör 30, kaynak ateş aralığı 150 ms, şarjör klibi 2,5 saniye.
- İnsan birinci şahısta, kurt çarpışma kontrollü üçüncü şahıs kamerayla oynanır.
- PC: WASD, Space, Ctrl, Shift, 3 dönüşüm, sol fare ateş/pençe, sağ fare nişan, R şarjör/kükreme, I envanter, Esc duraklat, F10 yönetici.
- 19 haritanın temel geometrisi dönüştürüldü ve motor içinde doğma/çarpışma kontrolünden geçti. Modu doğrulanan 18 harita gezinti önizlemesi olarak açılır. Tam maç kuralları kapalıdır. Göbekli Tepe (#46) bağlantısı belirsiz olduğu için kapalı kalır.
- Android yerel yönetici menüsü nakit/KP/altın/GP verir; kayıt yalnızca o cihazdadır.
- PC'de localhost:8765 paneli açık ve bir test oyuncusu varsa ilk oyuncuya bağlanır. Bu bir canlı sunucu yönetim sistemi değildir.

Varlıklar `.xfs` kaynağından özel dönüştürücüyle aktarıldı. İnsan 5.434, kurt 5.838 üçgen. Kurt modelindeki çalışma anında doku isteyen üç isteğe bağlı dövme katmanı, taban gövde dönüşümüne alınmadı. Karakterlerin kaynak/dönüşüm özetleri ve kabul kuralı `assets/roster.json` içindedir.

Örnek duruş/koşu/saldırı, dört ayak koşusu, vücut saldırısı, silah/şarjör ve iki harita görünümü çevrimdışı render edilip incelendi. Godot'ta içe aktarma ve temel oyun mantığı otomatik testten geçti. Fiziksel Android cihaz, bütün animasyon kareleri ve bütün haritaların görsel ayrıntıları test edilmiş değildir. Bütün silahlar/sesler, tam mod kuralları, çevrimiçi maç, üretim hesabı ve tam karakter mağazası henüz yoktur. Ayrıntılar: `../docs/AKTARIM_DURUMU.md`.

## Otomatik oyun testi

```powershell
godot --headless --path . --fixed-fps 60 --script res://tests/smoke.gd
godot --headless --path . --fixed-fps 60 --script res://tests/map_previews.gd
```

## Android

Eşleşen Godot 4.7.2 Android şablonları, JDK 17 ve Android SDK gerekir. Mevcut bilgisayarda bunlar kuruldu. `export_presets.cfg` arm64 ve armv7 içeren geliştirme APK'sını tanımlar.

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug Android ../../WolfRogueBlood-debug.apk
```

Bu APK geliştirme anahtarıyla imzalanır; Google Play üretim yayını değildir. Android bakiyesi ile PC paneli ayrı yerel kayıtlar kullanır.
