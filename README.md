# Wolf Rogue Blood

PC paketlerinden çıkarılan kontrol raporu, mobil giriş laboratuvarı ve yerel yönetici paneli.

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
