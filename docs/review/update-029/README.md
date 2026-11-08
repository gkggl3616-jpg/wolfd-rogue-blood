# 0.29 · Gerçek oyun fotoğrafları

**APK hazırlanmadı/yayımlanmadı.** Bu klasördeki 29 PNG (26 ana görüntü ve `source-worlds` altında 3 Taksim görüntüsü), yeni kaynak sürümünün gerçek Godot 4.7.2 / OpenGL çalıştırmasından alınmıştır. Telefon çekimi veya özgün PC ekranı değildir. Fotoğraflar kontrollü yerel test durumlarını kullanır; bot pozları bazı karelerde inceleme için dondurulmuştur.

[Değişiklikler, testler ve açık farklar](../../PC_REFERANS_029.md) · [Fotoğraf hashleri ve çalışma zamanı bağı](../../update-029-visual-validation.json) · [**Videoların 5 saniyelik 902 karesi**](reference-every-5s)

| Görmek istediğin alan | Fotoğraf |
|---|---|
| Özgün Taksim dünyasında kurt, FT, bot pençesi ve buz | [Üç gerçek kaynak dünya görüntüsü](source-worlds) |
| Sekiz farklı ad ve oda hazırlığı | [Oda](eight-distinct-ready-room-identities-029.png) |
| Farklı insan karakterleri ve kaynak silahları | [Sekiz bot](eight-distinct-characters-and-source-weapons-029.png) |
| Gerçek el soketinde pompalı | [Kutup · EXM-26](native-hand-red-0-Kutup-EXM-26%20CS-029.png) |
| Gerçek el soketinde tüfek | [Kuzgun · AKEI-47](native-hand-blue-0-Kuzgun-AKEI-47%20PT-029.png) |
| Botun taktik yaklaşması ve sonraki konumu | [Yaklaşma](bot-tactical-approach-029.png) · [Hareket/ateş](bot-moving-fire-and-reposition-029.png) |
| Mor Pençe sahipliği FT başlatmaz | [FT kapalı](purple-claw-without-ft-no-hand-glow-029.png) |
| FT açılışı, can bedeli ve el parlaması | [Etkin FT](ft-active-original-health-cost-029.png) · [Bir saniyelik yüzde kaybı](ft-one-second-percent-health-tick-029.png) |
| Paket süresi bittiğinde el efekti kapanır | [FT bitti](ft-expired-hand-glow-removed-029.png) |
| Özgün dokulu oyuncu pençe izi ve sönmesi | [Saldırı izi](player-source-claw-world-trail-029.png) · [Sönen kuyruk](player-source-claw-tail-fade-029.png) · [Kuyruk bitti](player-source-claw-tail-expired-029.png) |
| Kurt botunun iki saldırısı ve farklı pençe ekipmanı | [Saldırı](npc-native-attack-claw-trail-029.png) · [Diğer el](npc-native-attack_right-claw-trail-029.png) |
| Gerçek eleme GP'siyle seviye/rütbe geçişi | [Seviye 1 → 2](actual-kill-level-2-rank-result-progress-029.png) |
| Mevcut üst şeritte hesap seviyesi | [Seviye 1](level-1-existing-rank-and-gp-029.png) · [Seviye 2](saved-gp-level-2-header-029.png) |
| Profil ve mevcut rütbe simgeleri | [Profil](profile-existing-rank-level-2-029.png) · [Rütbeler](existing-rank-level-list-029.png) |

Ayrı `native-hand-*` fotoğrafları sekiz botun her birini yakın planda gösterir. Adlar, karakterler ve ana silahlar oda/yeniden doğuş kimliğine bağlıdır; farklı silah modellerinin hepsi özgün HH kaynaklarından gelir. Pençe sahipliği mor FT elini başlatmaz. Kameraya ve videoya bağlı HUD/mobil kontrol yerleri korunmuştur.

Seviye örneği, kontrollü yerel 95 GP başlangıcından mevcut eleme ödülüyle 105 GP'ye çıkar. Rütbe ad/simgeleri kaynaktır; GP eşikleri yereldir. Kalıcılık ve başarısız yazma davranışı [ayrı motor testinde](../../mobile-029-validation.json) gerçek geçici disk kaydıyla sınanır. Fotoğraftaki kontrollü GP bir çevrimiçi hesap kanıtı değildir.

Kaynak inceleme paftaları `reference-every-5s` altındadır. Oyundan alınan yeni PNG'ler ile özgün videoların JPEG paftaları birbirinden açıkça ayrılmıştır. Beş saniyelik kare taraması kesintisiz insan izlemesi diye sunulmaz. Fiziksel Android/emülatör testi yapılmadı. Ruins/Bridge karşı takım yolu ve [önceki açık farklar](../../PC_REFERANS_028.md) çözülmüş sayılmaz.
