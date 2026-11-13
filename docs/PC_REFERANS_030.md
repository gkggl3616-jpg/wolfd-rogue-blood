# 0.30 · Kaynak ışık verileri, bot namlu efektleri ve Android paketi

Son kullanıcı talimatı APK üretimi ve GitHub'da paylaşımı yeniden yetkilendirdi. Çalışmanın kapsamı çevrimdışı Android oyunudur. 0.28 ve 0.29 kaynak geliştirmeleri de bu pakete dahildir. 34 harita, 903 silahlık kaynak katalog, Giriş/İki Tapınak hariç tutması ve videolara bağlı göreli arayüz yerleşimi korunur.

[Gerçek yeni oyun fotoğrafları](review/update-030) · [Önceki 902 referans karesi](review/update-029/reference-every-5s) · [APK paket/imza raporu](android-offline-test-build-030.json)

## Bu sürümde çözülen farklar

- **34 haritanın gömülü ışık verisi:** 9.219 özgün RGB24 ışık haritası, kaynak motorun sınır denetimli tekrar/literal çözümüyle okundu. Doku geçişinin ikinci UV alanını ışık UV'si sanmak yerine, özgün ışık geçişinin kendi UV0 koordinatları tam kaynak üçgen konumlarıyla eşlendi. 973.960 üçgen ışık dokusunu kullanıyor; eşlemesi kesin olmayan 4.154 üçgen mevcut kaynak köşe rengine dönüyor. Geometri üçgen dizisinin SHA-256 değeri mevcut kaynak GLB ile her haritada birebir doğrulandı. Çarpışma ve navigasyon değiştirilmedi. Atlaslar, kaynak yüzey renkleri ve saydamlık Godot shader'ına bağlandı. [Kaynak kaydı](map-lighting-source-030.json), [paket kataloğu](../godot/assets/maps/lighting/index.json).
- **Botun üçüncü kişi namlu efekti:** HH silah kaydındaki özgün efekt adı, silah iskeletindeki doğrulanmış `Flash` soketine bağlandı. 23 farklı grup gerçek kaynak kemikleri üzerinde sınanıyor. Parçacıkların kaynak saydamlık yönü ve tekil ömür boyunca boyut eğrisi düzeltildi; dünya boyutu birinci kişi görsel büyütmesiyle karıştırılmıyor. FT ve pençe efektleri ayrı kalıyor. MSD-90 PX kaynak HH modelinde `Flash` yok; üç roket profilinin istediği `WT-RL2_HH_Muzz` grubu da arşivde yok. Bu dört eksiklik yanlış soket/efektle doldurulmadı. [Motor kontrolü](mobile-030-validation.json).
- **Oda bot kimliği:** Oyuncunun adını veya karakter ekipmanını değiştirmesi mevcut oda kadrosunu yeniden rastgeleleştirmiyor. Kaldırılmış bot yuvaları yeni karakter/silah seçiminin benzersizlik havuzunu işgal etmiyor; canlı kalan botun kimliği korunuyor.
- **Gerçek paket bağımlılığı:** Yeni `.bin.gz` ışık akışları Android dışa aktarım filtresine eklendi. APK denetimi yeni ışık kataloğunu ve 59 profillik bot silah kataloğunu da tarıyor. Yalnızca editörde çalışan fakat APK'da kaybolan ışık dosyalarına izin verilmiyor.

Gömülü ışık atlaslarının çözülmesi özgün renderer'ın bütünüyle yeniden kurulması anlamına gelmez. Shader'daki 2× aydınlatma kazancı genel kaynak motordaki doygunluk yolu temel alınarak kullanılan yerel çizim ayarıdır; bu WolfTeam istemcisinin kesin konsol değeri doğrulanmış değildir. Atlasların kenar filtrelemesi ve Godot renk uzayı da özgün Direct3D çıktısıyla piksel eşitliği sağlamaz.

## Kalan farklar ve araştırma sonucu

**Tam PC eşitliği veya “0 eksik” iddiası yoktur.** [0.28](PC_REFERANS_028.md) ve [0.29](PC_REFERANS_029.md) incelemeleri güncellenerek aşağıdaki açık alanlar korunur:

| Alan | Doğrulanan son durum |
|---|---|
| Bridge #37 ve Ruins #72 yolları | Native fizik BSP blokları kaynak nesne bölümünün başlangıcına kadar bayt sınırlarıyla çözümlendi. Bridge'de 23.438, Ruins'te 35.168 kaynak çarpışma üçgeni çıkarıldı. Doğru yüz yönü ve eşzamanlı harita güncellemesiyle denenen navigasyon, 64/256 karşı takım başlangıç çifti arasında geçerli yol üretmedi. Deneysel veri oyunun çalışan çarpışmasını/navigasyonunu değiştirmedi. Kaynak WorldModel konumları ve hareketli/katı nesne davranışı çözülmeden hayalî köprü veya ışınlanma eklenmedi. [Deney kaydı](native-map-physics-research-030.json). |
| Diğer harita çizimi | Yerleşik ışık katmanı eklendi; özgün gökyüzü/dinamik ışık/sis sistemi ve atlanmış WorldModel nesnelerinin tam sunumu hâlâ açık. |
| Mod kuralları | 67 kaynak modun 14'ü mevcut çevrimdışı/kaynak kapsamda destekleniyor. Diğer modlar aynı ölüm maçı kuralının farklı adı olarak açılmadı. Gerçek sunucu önceki kapsam kararıyla hariç. |
| Özel mühimmat | 72 tanımın özgün uçuş/model verileri ve mevcut fizik davranışları korunuyor; hologram/tespit gibi bütün özel sınıfların özgün istemci/sunucu kural eşitliği tamamlanmadı. |
| Karakter ve silah istatistikleri | Bütün modern eşya/karakter istatistikleri, FT hız birimlerinin PC dönüşümü ve silaha özel üçüncü kişi beden hareket bankalarının tümü çözümlenmedi. Kaynak can/süre/kapasite/atış aralığı kanıtı yerel taktik ayarlarından ayrıdır. |
| Eksik özgün dosyalar | Altı silah sesi, bazı yüzey/yangın/roket sesleri, üç roket profilinin namlu grubu, bir HH modelin Flash soketi ve varsayılan pençe dokusu gibi önceki açık kaynak eksikleri sürüyor. |
| Android cihaz | ZIP, kaynak bağlantıları, paket sürümü, imza ve hizalama yazılımla doğrulanır; fiziksel telefon/emülatör üzerinde oynama yapılmış sayılmaz. |

Seviye 62 kaynak rütbenin ad/simgesiyle mevcut GP kaydına bağlıdır. GP eşikleri önceki yerel düzen olarak kalır; özgün PC GP tablosu diye sunulmaz. Bot taktikleri yerel fizik simülasyonudur. Nakit/altın FT'nin başlangıç ve saniyelik kesirli HP yüzdeleri 0.27 kaynak kanıtıyla korunur.

## Doğrulama ve teslim

[Tam regresyon](mobile-validation.json), [355 yeni motor kontrolü](mobile-030-validation.json), [sekiz botlu karşılaşma](bot-squad-029-validation.json), [yeni OpenGL fotoğrafları](update-030-visual-validation.json) ve [APK paket/imza raporu](android-offline-test-build-030.json) gerçek sonuçları ayrı kaydeder. Fotoğraflar Godot/OpenGL görüntüleridir; telefon veya özgün PC ekranı olarak sunulmaz. Namlu yakın planları kısa kaynak efektini incelemek için kontrollü duruş ve zaman kullanır.

**Sonuç:** 38/38 regresyon aşaması; 355 yeni motor kontrolü; 21 gerçek OpenGL grubunda 413 görüntü; 57 yeni görüntünün dört sayfalık gözle incelemesi. Çalışma zamanı SHA-256: `e9e6e5a6a84bcebe56009728f14dc63b804632ca5afcf2425925480a06ee7ca5`.

İmzalı APK: **1,678,162,515 bayt**, `825a9b4a6e2daa48a8dce62776294767985b61fb04370f09e4deec69c8c930b4`. 48 katalog, kaynak bağlantıları, ZIP CRC, paket/sürüm, v2/v3 imza, üç ABI ve 16 KiB hizalama doğrulandı. Bu paket/imza kanıtı fiziksel telefon veya bütün PC kurallarının test edildiği anlamına gelmez.
