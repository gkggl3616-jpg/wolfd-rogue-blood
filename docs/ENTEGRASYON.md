# Motor ve sunucu bağlantısı

## Mobil girişler

`web/app.js`, `window` üzerinde `wrb:input` olayları yayınlar. Bu olay bir tarayıcı kontrol sözleşmesidir; mevcut PC istemcisini kontrol etmez.

```javascript
window.addEventListener('wrb:input', ({detail}) => {
  // detail.action: Forward, Fire, Jump, Move, Look veya arşivdeki komut adı
  // detail.phase: start, end, change
  // detail.value: 1/0 veya eksen nesnesi
  // detail.time: performance.now() zaman damgası
  gameAdapter.handleInput(detail);
});
```

`Move` için `value: {x, y}` eksenleri -1..1 aralığında, ileri pozitif y'dir. Çapraz hareket normalize edilir. `Look` için `value: {yaw,pitch,dx,dy}` derece cinsindedir; aşağı bakış pozitif pitch'tir. Gerçek motor, kamera işaretini kendi koordinat sistemine uyarlamalıdır. Hareket çubuğu ayrıca Forward/Backward/StrafeLeft/StrafeRight start/end olayları üretir; motor bu ikisinden birini tüketmeli, hareketi iki kere uygulamamalıdır.

Ateş, etkileşim, eğilme ve diğer düğmeler basma/bırakma üretir. Tek atımlık işler için start olayını kullan. Oyun durumunun komutun geçerli olup olmadığına karar vermesi gerekir. Pencere odağı kaybolduğunda ve sekme değiştiğinde basılı girişler bırakılır. Çoklu dokunmada hareket, bakış ve ateş için ayrı pointer kimlikleri kullanılır.

## Bakiye servisi

Mevcut `Store` sınıfı yalnızca yeni yerel test verisini yönetir. Gerçek hesap bağlantısında `add_player`, `snapshot` ve `grant` davranışlarını sunucu/veritabanı adaptörüne taşı. İstemciden gelen bakiye veya yetkiye güvenme. Nakit/KP/altın/GP anlamları kullanıcı isteğine göre ayrı alanlar olarak oluşturuldu; paketlerde gerçek hesap şeması bulunmadı.

Yerel API:

- `GET /api/state`: test oyuncuları, son 100 işlem ve geçerli yerel oturum belirteci.
- `POST /api/players`: `{name}`.
- `POST /api/grants`: `{playerId,currency,amount,reason,requestId}`. currency: cash/kp/gold/gp. amount: 1..1.000.000 tam sayı.
- POST istekleri `X-Admin-Token` başlığını gerektirir. Yalnızca yerel Host/Origin kabul edilir.
- Aynı `requestId` ve içerik tekrarlandığında bakiye tekrar artmaz; aynı kimlikle farklı içerik reddedilir. Başarısız ağ isteğini aynı kimlikle yeniden gönderebilirsin.

Bu yerel oturum belirteci internet için yönetici kimlik doğrulamasının yerini tutmaz. Canlıya geçiş için kullanıcı/rol doğrulaması, denetim kaydı, TLS ve ayrı sunucu yapılandırması eklenmelidir. Yerel paneli doğrudan internete açma.

## Paketler

`archive-inventory.json.gz` dört özgün dosyanın byte boyutunu, SHA-256 özetini ve bütün dizin kayıtlarını içerir. Gzip açılınca JSON elde edilir; tarama aracı açık kopyayı da yerelde üretir. Bu bilgiler özgün paketleri yerelde bulup doğrulamak içindir. `.xfs` kaynak projeye çevrilmedi. Ses/model/kaplamaların kullanılabilir motor varlıklarına dönüşümü ve kullanım hakları ayrıca değerlendirilmelidir.
