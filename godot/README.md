# Wolf Rogue Blood — Godot 4.7.2

Yeni yazılmış çevrimdışı, oynanabilir deneme arenası. Orijinal Windows oyununun bütün oyun kurallarını ve çevrimiçi altyapısını taşımaz.

Godot'ta bu klasördeki `project.godot` dosyasını içe aktar; F6 ile sahneyi veya F5 ile oyunu çalıştır. Ana sahne `main.tscn`.

- 90 saniye / 10 hedeflik deneme, can, mermi, yedek mermi, şarjör ve tekrar başlatma.
- Kontrol edilen Pedro RE insan/kurt çifti; diğer karakterler eklenmedi.
- Her formda 7 iskelet klibi: duruş, koşu, zıplama, saldırı, eğilme, eğilerek ilerleme; insanda şarjör, kurtta kükreme.
- Sol sanal çubuk + sağ bakış + eylem düğmeleri; çoklu dokunma bırakma durumları otomatik testte kontrol edildi.
- İnsan birinci şahısta, kurt çarpışma kontrollü üçüncü şahıs kamerayla oynanır.
- PC: WASD, Space, Ctrl, Shift, 3 dönüşüm, sol fare ateş/pençe, sağ fare nişan, R şarjör/kükreme, Esc duraklat, F10 yönetici.
- Mod ve harita listesi: seçilen 19 dosyadan 18'inin kaynak mod bağlantısı doğrulandı. Yalnızca seçilen moda bağlı haritalar listelenir. Özgün sahneler/mod kuralları aktarılana kadar başlatma kapalıdır. Göbekli Tepe (#46) bağlantısı belirsiz olduğu için kapalı kalır.
- Android yerel yönetici menüsü nakit/KP/altın/GP verir; kayıt yalnızca o cihazdadır.
- PC'de localhost:8765 paneli açık ve bir test oyuncusu varsa ilk oyuncuya bağlanır. Bu bir canlı sunucu yönetim sistemi değildir.

Varlıklar `.xfs` kaynağından özel dönüştürücüyle aktarıldı. İnsan 5.434, kurt 5.838 üçgen. Kurt modelindeki çalışma anında doku isteyen üç isteğe bağlı dövme katmanı, taban gövde dönüşümüne alınmadı. Karakterlerin kaynak/dönüşüm özetleri ve kabul kuralı `assets/roster.json` içindedir.

Örnek duruş/koşu/saldırı kareleri çevrimdışı render edilip incelendi; Godot'ta kaynakların içe aktarılması ve temel oyun mantığı otomatik testten geçti. Fiziksel Android cihaz ve tüm animasyon kareleri test edilmiş değildir. Ses, tam silah sanatları, çevrimiçi maç, üretim hesabı, tam karakter mağazası ve özgün haritaların portu bu sürümde yoktur.

## Otomatik oyun testi

```powershell
godot --headless --path . --fixed-fps 60 --script res://tests/smoke.gd
```

## Android

Eşleşen Godot 4.7.2 Android şablonları, JDK 17 ve Android SDK gerekir. Mevcut bilgisayarda bunlar kuruldu. `export_presets.cfg` arm64 ve armv7 içeren geliştirme APK'sını tanımlar.

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug Android ../../WolfRogueBlood-debug.apk
```

Bu APK geliştirme anahtarıyla imzalanır; Google Play üretim yayını değildir. Android bakiyesi ile PC paneli ayrı yerel kayıtlar kullanır.
