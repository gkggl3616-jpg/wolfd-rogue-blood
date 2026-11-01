# Wolf Rogue Blood — kontrol taraması

Statik yapılandırma taraması. Komut tanımı, oyun modunda çalıştığını kanıtlamaz. Klavye adları Windows DirectInput tarama kodu yorumudur; bölgesel noktalama değişebilir. Fare düğmeleri dosyadaki ham kodlarıyla korunmuştur.

139 komut; 73 komutta tuş ataması bulundu.

| Komut | ID | PC ataması | Mobil karşılık |
|---|---:|---|---|
| Forward | 0 | W | Sol sanal çubuk |
| Backward | 1 | S | Sol sanal çubuk |
| Activate | 2 | Fare düğmesi ##4 (etkileşim) | Ana dokunmatik düğme |
| Reload | 3 | R | Ana dokunmatik düğme |
| TurnAround | 4 | Backspace | Diğer kontroller menüsü |
| Duck | 5 | Sol Ctrl | Ana dokunmatik düğme |
| Jump | 6 | Space | Ana dokunmatik düğme |
| Speed | 7 | Sol Shift | Ana dokunmatik düğme |
| Fire | 8 | Fare düğmesi ##3 (ateş) | Ana dokunmatik düğme |
| Strafe | 9 | Sol Alt | Sol sanal çubuk |
| Left | 10 | Sol ok | Sağ bakış alanı |
| Right | 11 | Sağ ok | Sağ bakış alanı |
| StrafeLeft | 13 | A | Sol sanal çubuk |
| StrafeRight | 14 | D | Sol sanal çubuk |
| LookUp | 16 | Yukarı | Sağ bakış alanı |
| LookDown | 17 | Aşağı | Sağ bakış alanı |
| LeanLeft | 18 | V | Diğer kontroller menüsü |
| LeanRight | 19 | E | Diğer kontroller menüsü |
| Weapon_1 | 20 | Atanmamış | Silah / seçim menüsü |
| Weapon_2 | 21 | Atanmamış | Silah / seçim menüsü |
| Weapon_3 | 22 | Atanmamış | Silah / seçim menüsü |
| Weapon_4 | 23 | Atanmamış | Silah / seçim menüsü |
| Weapon_5 | 24 | Atanmamış | Silah / seçim menüsü |
| Weapon_6 | 25 | Atanmamış | Silah / seçim menüsü |
| Weapon_7 | 26 | Atanmamış | Silah / seçim menüsü |
| Weapon_8 | 27 | Atanmamış | Silah / seçim menüsü |
| Weapon_9 | 28 | Atanmamış | Silah / seçim menüsü |
| Weapon_10 | 29 | Atanmamış | Silah / seçim menüsü |
| Weapon_11 | 30 | Atanmamış | Silah / seçim menüsü |
| Weapon_12 | 31 | Atanmamış | Silah / seçim menüsü |
| Weapon_13 | 32 | Atanmamış | Silah / seçim menüsü |
| Weapon_14 | 33 | Atanmamış | Silah / seçim menüsü |
| Weapon_15 | 34 | Atanmamış | Silah / seçim menüsü |
| Weapon_16 | 35 | Atanmamış | Silah / seçim menüsü |
| Weapon_17 | 36 | Atanmamış | Silah / seçim menüsü |
| Weapon_18 | 37 | Atanmamış | Silah / seçim menüsü |
| Weapon_19 | 38 | Atanmamış | Silah / seçim menüsü |
| Weapon_20 | 39 | Atanmamış | Silah / seçim menüsü |
| Weapon_21 | 40 | Atanmamış | Silah / seçim menüsü |
| Weapon_22 | 41 | Atanmamış | Silah / seçim menüsü |
| Weapon_23 | 42 | Atanmamış | Silah / seçim menüsü |
| Weapon_24 | 43 | Atanmamış | Silah / seçim menüsü |
| Weapon_25 | 44 | Atanmamış | Silah / seçim menüsü |
| Weapon_26 | 45 | Atanmamış | Silah / seçim menüsü |
| Weapon_27 | 46 | Atanmamış | Silah / seçim menüsü |
| Weapon_28 | 47 | Atanmamış | Silah / seçim menüsü |
| Weapon_29 | 48 | Atanmamış | Silah / seçim menüsü |
| Weapon_30 | 49 | Atanmamış | Silah / seçim menüsü |
| Weapon_31 | 50 | Atanmamış | Silah / seçim menüsü |
| Weapon_32 | 51 | Atanmamış | Silah / seçim menüsü |
| Weapon_33 | 52 | Atanmamış | Silah / seçim menüsü |
| Weapon_34 | 53 | Atanmamış | Silah / seçim menüsü |
| Weapon_35 | 54 | Atanmamış | Silah / seçim menüsü |
| Weapon_36 | 55 | Atanmamış | Silah / seçim menüsü |
| Weapon_37 | 56 | Atanmamış | Silah / seçim menüsü |
| Weapon_38 | 57 | Atanmamış | Silah / seçim menüsü |
| Weapon_39 | 58 | Atanmamış | Silah / seçim menüsü |
| Weapon_40 | 59 | Atanmamış | Silah / seçim menüsü |
| NextAmmo | 60 | F | Diğer kontroller menüsü |
| ZoomIn | 61 | V | Diğer kontroller menüsü |
| ZoomOut | 62 | Atanmamış | Diğer kontroller menüsü |
| QuickSave | 64 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| QuickLoad | 65 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| PrevWeapon | 66 | V | Silah / seçim menüsü |
| NextWeapon | 67 | V | Silah / seçim menüsü |
| Score | 68 | Tab | Diğer kontroller menüsü |
| Mission | 69 | P | Diğer kontroller menüsü |
| MouseAim | 70 | Atanmamış | Sağ bakış alanı |
| CursorTog | 71 | Atanmamış | Diğer kontroller menüsü |
| CenterView | 72 | End | Diğer kontroller menüsü |
| HolsterWeapon | 73 | H | Diğer kontroller menüsü |
| SendMessage | 74 | Enter | Diğer kontroller menüsü |
| IncLayout | 75 | Atanmamış | Diğer kontroller menüsü |
| DecLayout | 76 | Atanmamış | Diğer kontroller menüsü |
| Inventory | 77 | M | Diğer kontroller menüsü |
| ChangeCharacter | 78 | 3 | Ana dokunmatik düğme |
| ChangePistol | 79 | 2 | Silah / seçim menüsü |
| ChangeRifle | 80 | 1 | Silah / seçim menüsü |
| ChangeGrenade | 81 | 4 | Silah / seçim menüsü |
| ChangeBomb | 82 | 5 | Silah / seçim menüsü |
| NextWeapon_6 | 83 | Atanmamış | Diğer kontroller menüsü |
| Choose_1 | 84 | Atanmamış | Silah / seçim menüsü |
| Choose_2 | 85 | Atanmamış | Silah / seçim menüsü |
| Choose_3 | 86 | Atanmamış | Silah / seçim menüsü |
| Choose_4 | 87 | Atanmamış | Silah / seçim menüsü |
| Choose_5 | 88 | Atanmamış | Silah / seçim menüsü |
| Choose_6 | 89 | Atanmamış | Silah / seçim menüsü |
| DuckLock | 92 | V | Diğer kontroller menüsü |
| LastWeapon | 93 | Q | Silah / seçim menüsü |
| CompassToggle | 101 | V | Diğer kontroller menüsü |
| ViewKeys | 102 | N | Diğer kontroller menüsü |
| ViewIntel | 103 | I | Diğer kontroller menüsü |
| MoveBody | 104 | G | Diğer kontroller menüsü |
| Flashlight | 105 | L | Diğer kontroller menüsü |
| Radio | 106 | V | Diğer kontroller menüsü |
| ViewZAxis | 107 | Atanmamış | Diğer kontroller menüsü |
| Number_1 | 120 | 1 | Silah / seçim menüsü |
| Number_2 | 121 | 2 | Silah / seçim menüsü |
| Number_3 | 122 | 3 | Silah / seçim menüsü |
| Number_4 | 123 | 4 | Silah / seçim menüsü |
| Number_5 | 124 | 5 | Silah / seçim menüsü |
| Number_6 | 125 | 6 | Silah / seçim menüsü |
| Number_7 | 126 | 7 | Silah / seçim menüsü |
| Number_8 | 127 | 8 | Silah / seçim menüsü |
| Number_9 | 128 | 9 | Silah / seçim menüsü |
| Number_0 | 129 | Atanmamış | Silah / seçim menüsü |
| RadioMessage1 | 130 | Z | Diğer kontroller menüsü |
| RadioMessage2 | 131 | X | Diğer kontroller menüsü |
| RadioMessage3 | 132 | C | Diğer kontroller menüsü |
| MouseSensitiveUp | 133 | ] | Diğer kontroller menüsü |
| MouseSensitiveDown | 134 | [ | Diğer kontroller menüsü |
| ScreenGammaUp | 135 | ' | Diğer kontroller menüsü |
| ScreenGammaDown | 136 | ; | Diğer kontroller menüsü |
| EffectVolumeUp | 137 | . | Diğer kontroller menüsü |
| EffectVolumeDown | 138 | , | Diğer kontroller menüsü |
| MakeScreenShot | 139 | F8 | Araçlar / motor uyarlaması gerekli |
| Messenger | 140 | F5 | Diğer kontroller menüsü |
| LeaveUnassigned | 201 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| Axis3 | -3 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| Axis2 | -2 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| Axis1 | -1 | Atanmamış | Araçlar / motor uyarlaması gerekli |
| AxisYaw | -10001 | Atanmamış | Sağ bakış alanı |
| AxisPitch | -10002 | Atanmamış | Sağ bakış alanı |
| AxisLeftRight | -10003 | Atanmamış | Sol sanal çubuk |
| AxisForwardBackward | -10004 | Atanmamış | Sol sanal çubuk |
| NormalMessage | 150 | Atanmamış | Diğer kontroller menüsü |
| TeamMessage | 94 | F2 | Diğer kontroller menüsü |
| PrideMessage | 151 | F4 | Diğer kontroller menüsü |
| Yes | 108 | Y | Diğer kontroller menüsü |
| No | 109 | N | Diğer kontroller menüsü |
| MedicalKit | 141 | Atanmamış | Diğer kontroller menüsü |
| QuickWeapon1 | 142 | Fare tekerleği | Silah / seçim menüsü |
| QuickWeapon2 | 143 | Fare tekerleği | Silah / seçim menüsü |
| WolfSteamPackUse | 144 | F | Diğer kontroller menüsü |
| WolfMedicalKitUse | 145 | T | Diğer kontroller menüsü |
| MultiWeaponChange | 146 | B | Silah / seçim menüsü |
| InGameWeaponView | 147 | ` | Diğer kontroller menüsü |
| Graffiti | 148 | H | Diğer kontroller menüsü |
| Recording | 149 | F9 | Araçlar / motor uyarlaması gerekli |

## Aynı tuşa atanmış komutlar

Birlikte atama, komutların eşzamanlı çalıştığını kanıtlamaz; oyun durumuna bağlı olabilir. Mobil laboratuvar bunları ayrı komutlar olarak sunar.

- V: LeanLeft, ZoomIn, PrevWeapon, NextWeapon, DuckLock, CompassToggle, Radio
- F: NextAmmo, WolfSteamPackUse
- H: HolsterWeapon, Graffiti
- 3: ChangeCharacter, Number_3
- 2: ChangePistol, Number_2
- 1: ChangeRifle, Number_1
- 4: ChangeGrenade, Number_4
- 5: ChangeBomb, Number_5
- N: ViewKeys, No
- Fare tekerleği: QuickWeapon1, QuickWeapon2

## Sınırlar

Paket indekslerinin tamamı okundu ve kayıt sınırları doğrulandı. Büyük dosyaların içeriği bütünüyle açılmadı. Kontrol listesi bulunan autoexec.cfg içindeki bütün AddAction ve rangebind satırlarını kapsar; oyun kodundaki sabit tuşları veya sunucu komutlarını kapsadığı iddia edilmez.
.xfs paketleri mobil uygulama kaynak kodu değildir. Oyun motoru, derleme projesi ve hesap sunucusu ayrıca gerekir.