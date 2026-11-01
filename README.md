# Wolf Rogue Blood

PC paketlerinden çıkarılan kontrol/karakter raporları, mobil giriş laboratuvarı ve yerel yönetici paneli. Yeni ürün adı **Wolf Rogue Blood**, kısa adı **Wolf Rogue**, ana Windows dosya adı **WolfRogue.dat**.

**Bu sürüm bir başlangıç projesidir. Orijinal PC oyununun mobil portu veya oynanabilir bir oyun değildir.** Oyun motoru, kaynak proje, oturum sunucusu ve gerçek oyuncu veritabanı verilmediği için bunlarla bağlantı kurulmadı. Yerel oyuncular panelde oluşturulur; PC oyununun hesaplarını etkilemez.

## Başlat

Python 3.10 veya sonrası yeterlidir; ek paket kurulumu gerekmez.

```powershell
python server.py
```

Chrome'da http://localhost:8765 adresini aç. Windows'ta sunucuyu arka planda başlatıp Chrome'u açmak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start.ps1
```

Bu komuttaki yürütme seçeneği yalnızca bu işlem için geçerlidir; sistem ayarını değiştirmez. Farklı port: `python server.py --port 8766`.

## Hazır özellikler

- Test oyuncusu oluşturma ve seçme.
- Nakit, KP, altın ve GP (gelişim puanı) verme.
- SQLite üzerinde kalıcı kayıt ve son 100 işlemin geçmişi.
- Miktar sınırları, atomik bakiye güncellemesi ve aynı işlem kimliğinde çift ödeme engeli.
- Dokunmatik hareket çubuğu, bakış alanı, ateş, eğilme, zıplama, şarjör, dönüşüm ve silah seçimi.
- Bütün bulunan komutlar için ek dokunmatik düğmeler; hassasiyet ve tam ekran.
- Tuş arşivinde arama, PC atamaları ve önerilen mobil karşılıkları.
- İnsan/kurt eş adayları, animasyon ve iskelet farkları için karakter denetimi ekranı.

## Yeni karakter incelemesi

Yeni paketteki 539 karakter klasörü modeli tamamen ayrıştırıldı. Model yapılandırmasında 620 varyant/NPC kaydı ve 398 benzersiz model başvurusu var; bunlar 620 farklı oynanabilir karakter anlamına gelmez. Yaklaşık 130 karakter sayısı doğrulanmadı.

445 ortak animasyon modeli bağlantısının tamamı bulundu. 393 bağlantıda kemik adları ve hiyerarşisi aynı; 52 bağlantıda fark var. Dinlenme pozları ayrıca karşılaştırılır; aynı hiyerarşi tek başına animasyonun görsel olarak doğru olduğu anlamına gelmez.

[Karakter raporu](docs/KARAKTERLER.md), [sayısal özet](docs/character-summary.json) ve [tam denetim verisi](docs/character-audit.json.gz) depodadır. `assets/roster.json` yalnızca onaylı oyun kadrosudur ve şu an boştur. Eşi eksik, eşleşmesi belirsiz, iskeleti/animasyonu doğrulanmamış karakterler otomatik dahil edilmez. Yapısal adaylar da motor aktarımı ve görsel testten geçmelidir.

```powershell
python tools/audit_characters.py "C:\oyun-paketlerinin-klasoru"
python tools/check_android_ready.py
```

İkinci komut şu an eksik oyun projesini/onaylı karakterleri raporlayarak 2 koduyla çıkar; APK üretildiği iddia edilmez. Eksik olanlar: Android hedefi olan düzenlenebilir motor projesi ve oyun mantığı, dönüştürülmüş modeller/animasyonlar, motor içi test ve gerçek oyun/hesap sunucusu kaynakları. Windows istemci programı ve DLL'ler bunların yerine geçmez.

## WolfRogue.dat adlandırması

[legacy/WolfRogue.dat](legacy/WolfRogue.dat) istenen yeni adla kopyalanmış Windows istemci programıdır. [Dosya özeti](legacy/binary-manifest.json) özgün dosyayla byte eşitliğini doğrular. Bu dosya kaynak kod veya Android uygulaması değildir. Özgün klasöre dokunulmadı; gömülü ürün adları, imzalar ve hizmet adresleri binary içinde değiştirilmedi. Bunların bütünüyle yeniden markalanması kaynak projeden yeniden derleme ister. Bu referans kopyanın bağımsız çalıştığı iddia edilmez.

## Tarama

4 paketin dizinleri okundu: **41.560 dizin/dosya kaydı**, **139 tanımlı komut**, **73 atanmış komut**. Bütün `AddAction` ve `rangebind` satırları listelendi. Komutların oyun içinde çalışması doğrulanmadı. Bazı komutlar aynı tuşu paylaşır; bazıları yalnızca motor tanımıdır.

- [Bütün kontroller ve çakışmalar](docs/KONTROLLER.md)
- [Paket özeti ve SHA-256 değerleri](docs/archive-summary.json)
- [Sonradan oyun bağlantısı eklemek](docs/ENTEGRASYON.md)

Taramanın yeniden üretilmesi:

```powershell
python tools/scan_xfs.py "C:\oyun-paketlerinin-klasoru"
```

Araç sadece dosyaları okur. Kaynak `.xfs` paketlerini değiştirmez veya çalıştırmaz. Paketlerin tamamı açılmadı; bütün dizin indeksleri ve `autoexec.cfg` kontrol içeriği çözüldü. Tanınmayan dosya adı baytları envanterde `�` ile gösterilebilir; dizin kayıtlarının sayısı ve konumları korunur.

Tam kayıt listesi tarama sırasında yerelde `docs/archive-inventory.json` ve sıkıştırılmış `.json.gz` kopyası olarak üretilir. Depoda daha küçük `archive-summary.json` raporu bulunur.

## Sonradan eklenecekler

Gerçek oyun için motor projesi (Unity/Godot/Unreal vb.), oyun sahneleri/kuralları, sunucu kaynakları, kimlik doğrulama ve oyuncu veritabanı gerekir. Android/iOS derlemesi henüz yok. Mobil düğmelerin motor içindeki davranışları oyun adaptörüyle uygulanmalı.

Panel yalnızca `127.0.0.1` üzerinden dinler. İnternete açılacak bir yönetim sistemi olarak tasarlanmadı; yayın öncesinde hesap doğrulama, yönetici rolleri ve sunucu tarafı yetkilendirme gerekir. Oyuncu verileri `data/players.sqlite3` içinde saklanır ve Git'e gönderilmez.

Orijinal `.xfs` dosyaları bu depoya eklenmedi. Bu depo panel, tarama aracı ve raporları içerir. Büyük oyun paketleri için ayrı varlık depolaması/LFS düzeni gerekir. GitHub normal Git deposunda 100 MiB üstü dosyaları kabul etmez: [GitHub dosya sınırları](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github).

## Kontrol

```powershell
python -m unittest discover -s tests -v
node --check web/app.js
```
