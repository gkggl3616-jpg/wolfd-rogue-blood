# Wolf Rogue Blood — karakter denetimi

Statik model/iskelet/animasyon denetimi. Mesh geometrisi ve animasyonların görsel sonucu oyun motorunda doğrulanmadı.

## Sayımlar

- archivesEntries: 39884
- modelDefinitions: 620
- uniqueReferencedModels: 398
- characterDirectoryModels: 539
- parsedModels: 539
- dependencyEdges: 445
- missingChildModels: 0
- exactSkeletonEdges: 393
- differentSkeletonEdges: 52
- differentBindPoseEdges: 439
- skeletonGroups: 23
- structuralCandidates: 205
- approvedCharacters: 1

Model kayıtları kostüm/varyantları ve NPC tanımlarını da kapsar. Bunlar benzersiz oynanabilir karakter sayısı değildir. Yaklaşık 130 karakter iddiası bu sayımla doğrulanmış sayılmaz.

## Kadro kuralı

Karakterler otomatik eklenmez. Yalnızca açıkça onaylanan ve kaynak/dönüşüm özetleri eşleşen çiftler çevrimdışı deneme sürümüne alınır. Pedro RE insan/kurt çifti için örnek duruş/koşu/saldırı görüntüleri ve Godot otomatik oyun testleri kontrol edildi. Bu, bütün animasyonların kare kare veya fiziksel Android cihazda test edildiği anlamına gelmez. Diğer karakterler kapalı kalır.

Kemik adları ve hiyerarşisi eşitliği, dinlenme pozu eşitliği veya görsel animasyon uyumluluğu anlamına gelmez. İnsan ve kurt iskeletlerinin birbiriyle aynı olması beklenmez; her form kendi animasyon sağlayıcısıyla karşılaştırılır.

## Kayıtlar

| Kimlik | İsim | Form | Animasyon | Eş adayları | Durum / sorunlar |
|---|---|---|---:|---|---|
| Model0 | Pedro_RE | human | 552 | Model2, Model475 | Deneme sürümünde: pedro-re |
| Model1 | Christopher_RE | human | 552 | Model3, Model471 | Motor/görsel onay bekliyor |
| Model2 | Pedro_RE Wolf | wolf | 75 | Model0, Model474 | Deneme sürümünde: pedro-re |
| Model3 | Christopher_RE Wolf | wolf | 75 | Model1, Model470 | Motor/görsel onay bekliyor |
| Model4 | SSLeut | wolf | 72 | yok | counterpart_not_found |
| Model5 | Hero_Casual | wolf | 68 | yok | counterpart_not_found |
| Model6 | SSRogue | wolf | 68 | yok | counterpart_not_found |
| Model7 | Hero | wolf | 68 | yok | counterpart_not_found |
| Model8 | SSoldier | wolf | 69 | yok | counterpart_not_found |
| Model9 | Hero_Hospital | wolf | 69 | yok | counterpart_not_found |
| Model10 | Ninja | wolf | 63 | yok | counterpart_not_found |
| Model11 | HARMGuardPurple | wolf | 63 | yok | counterpart_not_found |
| Model12 | HARMGuardBlue | wolf | 63 | yok | counterpart_not_found |
| Model13 | HARMGuardSilver | wolf | 63 | yok | counterpart_not_found |
| Model14 | HARMIndia | wolf | 68 | yok | counterpart_not_found |
| Model15 | HARMIndia2 | wolf | 68 | yok | counterpart_not_found |
| Model16 | Bruno | wolf | 68 | yok | counterpart_not_found |
| Model17 | DrSchenker | wolf | 68 | yok | counterpart_not_found |
| Model18 | MrJones | wolf | 68 | yok | counterpart_not_found |
| Model19 | MimeKing | wolf | 68 | yok | counterpart_not_found |
| Model20 | Adriana | human | 506 | Model24, Model185, Model203, Model35, Model277, Model283, Model401 | counterpart_requires_review |
| Model21 | Angela | human | 506 | Model25, Model181, Model199, Model255, Model273, Model279, Model397 | counterpart_requires_review |
| Model22 | Pedro | human | 552 | Model26, Model183, Model201, Model32, Model275, Model285, Model399 | counterpart_requires_review |
| Model23 | Christopher | human | 552 | Model27, Model179, Model197, Model253, Model271, Model281, Model395 | counterpart_requires_review |
| Model24 | AdrianaWolf | wolf | 72 | Model20, Model282, Model332 | Motor/görsel onay bekliyor |
| Model25 | AngelaWolf | wolf | 72 | Model21, Model63, Model278, Model328 | counterpart_ambiguous |
| Model26 | PedroWolf | wolf | 72 | Model22, Model284, Model330 | Motor/görsel onay bekliyor |
| Model27 | ChristopherWolf | wolf | 72 | Model23, Model280, Model326 | Motor/görsel onay bekliyor |
| Model28 | Lusian | wolf | 71 | yok | counterpart_not_found |
| Model29 | ModifiedWolf | wolf | 67 | yok | counterpart_not_found |
| Model30 | Asmon | wolf | 73 | yok | counterpart_not_found |
| Model256 | Leviathan | wolf | 71 | yok | counterpart_not_found |
| Model257 | Bahamah | wolf | 73 | yok | counterpart_not_found |
| Model33 | Hawkins | human | 552 | yok | counterpart_not_found |
| Model36 | Moshin | human | 552 | Model37, Model161, Model225, Model233, Model241, Model299, Model307, Model315 | counterpart_requires_review |
| Model37 | MoshinWolf | wolf | 72 | Model36, Model314 | Motor/görsel onay bekliyor |
| Model38 | Lin | human | 506 | Model39, Model159, Model227, Model235, Model243, Model309, Model317 | counterpart_requires_review |
| Model39 | LinWolf | wolf | 72 | Model38, Model64, Model316 | counterpart_ambiguous |
| Model40 | Reinhard | human | 552 | Model41, Model157, Model221, Model229, Model237, Model295, Model303, Model311 | counterpart_requires_review |
| Model41 | ReinhardWolf | wolf | 72 | Model40, Model310 | Motor/görsel onay bekliyor |
| Model42 | Marien | human | 506 | Model43, Model155, Model223, Model231, Model239, Model305, Model313 | skin_or_render_style_missing, counterpart_requires_review |
| Model43 | MarienWolf | wolf | 72 | Model42, Model65, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model44 | AngelaSE | human | 506 | Model45, Model329, Model387, Model429 | counterpart_requires_review |
| Model45 | AngelaWolfSE | wolf | 72 | Model44 | Motor/görsel onay bekliyor |
| Model46 | ChristopherSE | human | 552 | Model47, Model327, Model389, Model427 | counterpart_requires_review |
| Model47 | Christopher_SE_wolf | wolf | 72 | Model46 | Motor/görsel onay bekliyor |
| Model48 | AdrianaSE | human | 506 | Model49, Model333, Model391, Model433 | Motor/görsel onay bekliyor |
| Model49 | Adriana_SE_wolf | wolf | 72 | Model48 | Motor/görsel onay bekliyor |
| Model50 | PedroSE | human | 552 | Model51, Model331, Model393, Model431 | counterpart_requires_review |
| Model51 | PedroSEwolf | wolf | 72 | Model50, Model392 | counterpart_ambiguous |
| Model52 | Tomita | human | 506 | Model53, Model121, Model137, Model145, Model165, Model189, Model251, Model269, Model325, Model357 | counterpart_requires_review |
| Model53 | Tomitawolf | wolf | 72 | Model52, Model324, Model356 | Motor/görsel onay bekliyor |
| Model54 | YigitDemir | human | 552 | Model55, Model119, Model135, Model143, Model187, Model249, Model267, Model297, Model323, Model355 | counterpart_requires_review |
| Model55 | Yigitwolf | wolf | 72 | Model54, Model322, Model354 | Motor/görsel onay bekliyor |
| Model56 | Ivanov | human | 506 | Model57, Model117, Model133, Model141, Model163, Model193, Model247, Model265, Model321, Model361 | counterpart_requires_review |
| Model57 | IvanovWolf | wolf | 72 | Model56, Model320, Model360 | skeleton_requires_review |
| Model58 | Geremi | human | 552 | Model59 | Motor/görsel onay bekliyor |
| Model59 | GeremiWolf | wolf | 72 | Model58 | Motor/görsel onay bekliyor |
| Model60 | PlayerWinter | human | 552 | yok | counterpart_not_found |
| Model61 | Player | human | 552 | yok | counterpart_not_found |
| Model62 | Adriana_adult | human | 506 | yok | counterpart_not_found |
| Model63 | Angela | human | 506 | Model25 | counterpart_requires_review |
| Model64 | Lin | human | 506 | Model39 | counterpart_requires_review |
| Model65 | Marien | human | 506 | Model43 | counterpart_requires_review |
| Model66 | Marien SE | human | 506 | Model67, Model341 | Motor/görsel onay bekliyor |
| Model67 | Marien SE Wolf | wolf | 72 | Model66 | Motor/görsel onay bekliyor |
| Model68 | Reinhard SE | human | 552 | Model69, Model339 | Motor/görsel onay bekliyor |
| Model69 | Reinhard_SE_wolf | wolf | 72 | Model68 | Motor/görsel onay bekliyor |
| Model70 | Lin SE | human | 506 | Model71, Model345 | Motor/görsel onay bekliyor |
| Model71 | Lin_SE_wolf | wolf | 72 | Model70 | Motor/görsel onay bekliyor |
| Model72 | Moshin SE | human | 552 | Model73, Model343 | Motor/görsel onay bekliyor |
| Model73 | Moshin SE wolf | wolf | 72 | Model72 | Motor/görsel onay bekliyor |
| Model74 | Sarah | human | 506 | Model75, Model129, Model349 | Motor/görsel onay bekliyor |
| Model75 | Sarahwolf | wolf | 72 | Model74 | Motor/görsel onay bekliyor |
| Model76 | Riccardo | human | 552 | Model77, Model127, Model205, Model347 | counterpart_requires_review |
| Model77 | Riccardowolf | wolf | 72 | Model76, Model346 | Motor/görsel onay bekliyor |
| Model78 | Kate | human | 506 | Model79, Model125, Model353 | Motor/görsel onay bekliyor |
| Model79 | KateWolf | wolf | 72 | Model78 | Motor/görsel onay bekliyor |
| Model80 | Matt | human | 552 | Model81, Model123, Model351 | counterpart_requires_review |
| Model81 | MattWolf | wolf | 72 | Model80, Model128 | counterpart_ambiguous |
| Model82 | Angela_ESC | human | 506 | yok | counterpart_not_found |
| Model83 | Christopher_ESC | human | 552 | yok | counterpart_not_found |
| Model84 | Adriana_ESC | human | 506 | yok | counterpart_not_found |
| Model85 | Pedro_ESC | human | 552 | Model97 | counterpart_requires_review |
| Model86 | Marien_ESC | human | 506 | yok | counterpart_not_found |
| Model87 | Reinhard_ESC | human | 552 | yok | counterpart_not_found |
| Model88 | Lin_ESC | human | 506 | yok | counterpart_not_found |
| Model89 | Moshin_ESC | human | 552 | Model99 | counterpart_requires_review |
| Model90 | Angela_Hero | human | 506 | yok | counterpart_not_found |
| Model91 | Christopher_Hero | human | 552 | yok | counterpart_not_found |
| Model92 | Adriana_Hero | human | 506 | yok | counterpart_not_found |
| Model93 | Pedro_Hero | human | 552 | yok | counterpart_not_found |
| Model94 | Christopher_TSC | human | 552 | Model95 | Motor/görsel onay bekliyor |
| Model95 | Christopher_TSC_Wolf | wolf | 72 | Model94 | Motor/görsel onay bekliyor |
| Model96 | Pedro_TSC | human | 552 | Model97 | counterpart_requires_review |
| Model97 | Pedro_TSC_Wolf | wolf | 72 | Model85, Model96 | counterpart_ambiguous |
| Model98 | Hamadah_TSC | human | 552 | Model99 | counterpart_requires_review |
| Model99 | Hamadah_TSC_Wolf | wolf | 72 | Model89, Model98, Model298 | counterpart_ambiguous, counterpart_requires_review |
| Model100 | Geremi_TSC | human | 552 | Model101 | Motor/görsel onay bekliyor |
| Model101 | Geremi_TSC_Wolf | wolf | 72 | Model100 | Motor/görsel onay bekliyor |
| Model102 | Yigit_TSC | human | 552 | Model103 | Motor/görsel onay bekliyor |
| Model103 | Yigit_TSC_Wolf | wolf | 72 | Model102 | Motor/görsel onay bekliyor |
| Model104 | Tomita SE | human | 506 | Model105, Model365, Model417 | Motor/görsel onay bekliyor |
| Model105 | Tomita SE wolf | wolf | 72 | Model104 | Motor/görsel onay bekliyor |
| Model106 | YigitDemir SE | human | 552 | Model107, Model363 | Motor/görsel onay bekliyor |
| Model107 | Yigit SE wolf | wolf | 72 | Model106 | Motor/görsel onay bekliyor |
| Model108 | Ivanov SE | human | 506 | Model109, Model369, Model415 | Motor/görsel onay bekliyor |
| Model109 | Ivanov SE Wolf | wolf | 72 | Model108 | Motor/görsel onay bekliyor |
| Model110 | Geremi SE | human | 552 | Model111, Model367 | Motor/görsel onay bekliyor |
| Model111 | Geremi SE Wolf | wolf | 72 | Model110 | Motor/görsel onay bekliyor |
| Model112 | YavuzSelim | human | 552 | Model113 | Motor/görsel onay bekliyor |
| Model113 | Yavuz_Selim_Wolf | wolf | 72 | Model112 | Motor/görsel onay bekliyor |
| Model114 | Geremi Military | human | 552 | Model115 | Motor/görsel onay bekliyor |
| Model115 | Geremi_Military_Wolf | wolf | 72 | Model114 | Motor/görsel onay bekliyor |
| Model116 | Ivanov Military | human | 506 | Model117 | counterpart_requires_review |
| Model117 | Ivanov_Military_Wolf | wolf | 72 | Model56, Model116, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model118 | Yigit Military | human | 552 | Model119 | counterpart_requires_review |
| Model119 | Yigit_Military_Wolf | wolf | 72 | Model54, Model118, Model322, Model354 | counterpart_ambiguous |
| Model120 | Tomita Military | human | 506 | yok | counterpart_not_found |
| Model121 | Tomitawolf | wolf | 72 | Model52, Model324, Model356 | Motor/görsel onay bekliyor |
| Model122 | Matt_Christmas | human | 552 | yok | counterpart_not_found |
| Model123 | MattWolf | wolf | 72 | Model80, Model128 | counterpart_ambiguous |
| Model124 | Kate_Christmas | human | 506 | yok | counterpart_not_found |
| Model125 | KateWolf | wolf | 72 | Model78 | Motor/görsel onay bekliyor |
| Model126 | Riccardo_Christmas | human | 552 | yok | counterpart_not_found |
| Model127 | Riccardowolf | wolf | 72 | Model76, Model346 | Motor/görsel onay bekliyor |
| Model128 | Matt | human | 506 | Model81, Model123, Model351 | counterpart_requires_review |
| Model129 | Sarahwolf | wolf | 72 | Model74 | Motor/görsel onay bekliyor |
| Model130 | Geremi Suit | human | 552 | yok | counterpart_not_found |
| Model131 | Geremi song_Suit_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model132 | Ivanov_Suit | human | 506 | Model133 | counterpart_requires_review |
| Model133 | Ivanov_Suit_Wolf | wolf | 72 | Model56, Model132, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model134 | Yigit_Suit | human | 552 | Model135 | counterpart_requires_review |
| Model135 | Yigit_Suit_Wolf | wolf | 72 | Model54, Model134, Model322, Model354 | counterpart_ambiguous |
| Model136 | Tomita_Suit | human | 506 | Model137 | counterpart_requires_review |
| Model137 | Tomita_Suit_Wolf | wolf | 72 | Model52, Model136, Model324, Model356 | counterpart_ambiguous |
| Model138 | Geremi Valentine | human | 552 | yok | counterpart_not_found |
| Model139 | Geremi song_Valentine_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model140 | Ivanov_Valentine | human | 506 | Model141 | counterpart_requires_review |
| Model141 | Ivanov_Valentine_Wolf | wolf | 72 | Model56, Model140, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model142 | Yigit_Valentine | human | 552 | Model143 | counterpart_requires_review |
| Model143 | Yigit_Valentine_Wolf | wolf | 72 | Model54, Model142, Model322, Model354 | counterpart_ambiguous |
| Model144 | Tomita_Valentine | human | 506 | Model145 | counterpart_requires_review |
| Model145 | Tomita_Valentine_Wolf | wolf | 72 | Model52, Model144, Model324, Model356 | counterpart_ambiguous |
| Model146 | Matt baker SE | human | 552 | Model147, Model291 | skeleton_requires_review, counterpart_requires_review |
| Model147 | Matt Baker SE wolf | wolf | 72 | Model146 | skeleton_requires_review, counterpart_requires_review |
| Model148 | Kate Blume SE | human | 506 | Model149, Model293, Model419 | counterpart_requires_review |
| Model149 | Kate Blume_SE_wolf | wolf | 72 | Model148 | skeleton_requires_review |
| Model150 | Alexsandro Del Riccardo SE | human | 552 | Model151, Model287 | skeleton_requires_review, counterpart_requires_review |
| Model151 | Alexsandro Del Riccardo_SE_wolf | wolf | 72 | Model150 | skeleton_requires_review, counterpart_requires_review |
| Model152 | Sarah Linda SE | human | 506 | Model153, Model289, Model421 | counterpart_requires_review |
| Model153 | Sarah Linda SE Wolf | wolf | 72 | Model152 | skeleton_requires_review |
| Model154 | Marien GI | human | 506 | Model155 | skeleton_requires_review, counterpart_requires_review |
| Model155 | Marien_GI_Wolf | wolf | 72 | Model42, Model154, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model156 | Reinhard_GI | human | 552 | Model157 | skeleton_requires_review, counterpart_requires_review |
| Model157 | Reinhard_GI_Wolf | wolf | 72 | Model40, Model156, Model310 | counterpart_ambiguous, counterpart_requires_review |
| Model158 | Lin_GI | human | 506 | Model159 | counterpart_requires_review |
| Model159 | Lin_GI_Wolf | wolf | 72 | Model38, Model158, Model316 | counterpart_ambiguous |
| Model160 | Hamadah_GI | human | 552 | Model161 | skeleton_requires_review, counterpart_requires_review |
| Model161 | Hamadah_GI_Wolf | wolf | 72 | Model36, Model160, Model314 | counterpart_ambiguous, counterpart_requires_review |
| Model162 | Ivanov_Adult | human | 506 | Model163 | counterpart_requires_review |
| Model163 | Ivanov_Adult_Wolf | wolf | 72 | Model56, Model162, Model320, Model360, Model414 | skeleton_requires_review, counterpart_ambiguous |
| Model164 | Tomita_Adult | human | 506 | Model165 | counterpart_requires_review |
| Model165 | Tomita_adult_Wolf | wolf | 72 | Model52, Model164, Model324, Model356, Model416 | counterpart_ambiguous |
| Model166 | Kate_Adult | human | 506 | Model167 | counterpart_requires_review |
| Model167 | Kate_Adult_wolf | wolf | 72 | Model166, Model418 | counterpart_ambiguous |
| Model168 | Sarah Adult | human | 506 | Model169 | counterpart_requires_review |
| Model169 | Sarah_adult_Wolf | wolf | 72 | Model168, Model420 | counterpart_ambiguous |
| Model170 | GM Red MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model171 | GM Red MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model172 | GM Red WOMAN | human | 506 | Model173, Model177, Model215, Model219 | counterpart_requires_review |
| Model173 | GM Red WOMAN Wolf | wolf | 72 | Model172, Model176, Model214, Model218 | skeleton_requires_review |
| Model174 | GM Blue MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model175 | GM Blue MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model176 | GM Blue WOMAN | human | 506 | Model173, Model177, Model215, Model219 | counterpart_requires_review |
| Model177 | GM Blue WOMAN Wolf | wolf | 72 | Model172, Model176, Model214, Model218 | skeleton_requires_review |
| Model178 | Christopher UDF | human | 552 | Model179 | counterpart_requires_review |
| Model179 | Christopher UDF Wolf | wolf | 72 | Model23, Model178, Model280, Model326 | counterpart_ambiguous |
| Model180 | Angela UDF | human | 506 | Model181 | counterpart_requires_review |
| Model181 | Angela UDF Wolf | wolf | 72 | Model21, Model180, Model278, Model328 | counterpart_ambiguous |
| Model182 | Pedro UDT | human | 552 | Model183 | counterpart_requires_review |
| Model183 | Pedro UDT Wolf | wolf | 72 | Model22, Model182, Model284, Model330 | counterpart_ambiguous |
| Model184 | Adriana UDF | human | 506 | Model185 | counterpart_requires_review |
| Model185 | Adriana UDF Wolf | wolf | 72 | Model20, Model184, Model282, Model332 | counterpart_ambiguous |
| Model186 | Yigit_SFMovie | human | 552 | Model187 | counterpart_requires_review |
| Model187 | Yigit_SFMovie_Wolf | wolf | 72 | Model54, Model186, Model322, Model354 | counterpart_ambiguous |
| Model188 | Tomita_SFMovie | human | 506 | Model189 | counterpart_requires_review |
| Model189 | Tomita_SFMovie_Wolf | wolf | 72 | Model52, Model188, Model324, Model356 | counterpart_ambiguous |
| Model190 | Geremi SFMovie | human | 552 | yok | counterpart_not_found |
| Model191 | Geremi song_SFMovie_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model192 | Ivanov_SFMovie | human | 506 | Model193 | counterpart_requires_review |
| Model193 | Ivanov_SFMovie_Wolf | wolf | 72 | Model56, Model192, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model194 | Simon Bolivar | human | 552 | Model195 | skeleton_requires_review, counterpart_requires_review |
| Model195 | Simon Bolivar wolf | wolf | 72 | Model194 | skeleton_requires_review, counterpart_requires_review |
| Model196 | Christopher Action Movie | human | 552 | Model197 | counterpart_requires_review |
| Model197 | Christopher Action Movie Wolf | wolf | 72 | Model23, Model196, Model280, Model326 | counterpart_ambiguous |
| Model198 | Angela Action Movie | human | 506 | Model199 | counterpart_requires_review |
| Model199 | Angela Action Movie Wolf | wolf | 72 | Model21, Model198, Model278, Model328 | counterpart_ambiguous |
| Model200 | Pedro Action Movie | human | 552 | Model201 | counterpart_requires_review |
| Model201 | Pedro Action Movie Wolf | wolf | 72 | Model22, Model200, Model284, Model330 | counterpart_ambiguous |
| Model202 | Adriana Action Movie | human | 506 | Model203 | counterpart_requires_review |
| Model203 | Adriana Action Movie Wolf | wolf | 72 | Model20, Model202, Model282, Model332 | counterpart_ambiguous |
| Model204 | Riccardo Jungle | human | 552 | Model205 | counterpart_requires_review |
| Model205 | Riccardo Jungle wolf | wolf | 72 | Model76, Model204, Model346 | counterpart_ambiguous |
| Model206 | Sarah Jungle | human | 506 | Model207 | Motor/görsel onay bekliyor |
| Model207 | Sarah Jungle Wolf | wolf | 72 | Model206 | Motor/görsel onay bekliyor |
| Model208 | Matt Jungle | human | 552 | Model209 | Motor/görsel onay bekliyor |
| Model209 | Matt Jungle Wolf | wolf | 72 | Model208 | Motor/görsel onay bekliyor |
| Model210 | Kate Jungle | human | 506 | Model211 | Motor/görsel onay bekliyor |
| Model211 | Kate Jungle wolf | wolf | 72 | Model210 | Motor/görsel onay bekliyor |
| Model212 | MVP Red MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model213 | MVP Red MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model214 | MVP Red WOMAN | human | 506 | Model173, Model177, Model215, Model219 | counterpart_requires_review |
| Model215 | MVP Red WOMAN Wolf | wolf | 72 | Model172, Model176, Model214, Model218 | skeleton_requires_review |
| Model216 | MVP Blue MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model217 | MVP Blue MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model218 | MVP Blue WOMAN | human | 506 | Model173, Model177, Model215, Model219 | counterpart_requires_review |
| Model219 | MVP Blue WOMAN Wolf | wolf | 72 | Model172, Model176, Model214, Model218 | skeleton_requires_review |
| Model220 | Reinhard_Desert | human | 552 | Model221 | counterpart_requires_review |
| Model221 | Reinhard_Desert_Wolf | wolf | 72 | Model40, Model220, Model310 | counterpart_ambiguous |
| Model222 | Marien Desert | human | 506 | Model223 | counterpart_requires_review |
| Model223 | Marien_Desert_Wolf | wolf | 72 | Model42, Model222, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model224 | Hamadah_Desert | human | 552 | Model225 | counterpart_requires_review |
| Model225 | Hamadah_Desert_Wolf | wolf | 72 | Model36, Model224, Model314 | counterpart_ambiguous |
| Model226 | Lin_Desert | human | 506 | Model227 | counterpart_requires_review |
| Model227 | Lin_Desert_Wolf | wolf | 72 | Model38, Model226, Model316 | counterpart_ambiguous |
| Model228 | Reinhard_Halloween | human | 552 | Model229 | counterpart_requires_review |
| Model229 | Reinhard_Halloween_Wolf | wolf | 72 | Model40, Model228, Model310 | counterpart_ambiguous |
| Model230 | Marien Halloween | human | 506 | Model231 | counterpart_requires_review |
| Model231 | Marien_Halloween_Wolf | wolf | 72 | Model42, Model230, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model232 | Hamadah_Halloween | human | 552 | Model233 | counterpart_requires_review |
| Model233 | Hamadah_Halloween_Wolf | wolf | 72 | Model36, Model232, Model314 | counterpart_ambiguous |
| Model234 | Lin_Halloween | human | 506 | Model235 | counterpart_requires_review |
| Model235 | Lin_Halloween_Wolf | wolf | 72 | Model38, Model234, Model316 | counterpart_ambiguous |
| Model236 | Reinhard_Thanksgiving | human | 552 | Model237 | counterpart_requires_review |
| Model237 | Reinhard_Thanksgiving_Wolf | wolf | 72 | Model40, Model236, Model310 | counterpart_ambiguous |
| Model238 | Marien Thanksgiving | human | 506 | Model239 | counterpart_requires_review |
| Model239 | Marien_Thanksgiving_Wolf | wolf | 72 | Model42, Model238, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model240 | Hamadah_Thanksgiving | human | 552 | Model241 | counterpart_requires_review |
| Model241 | Hamadah_Thanksgiving_Wolf | wolf | 72 | Model36, Model240, Model314 | counterpart_ambiguous |
| Model242 | Lin_Thanksgiving | human | 506 | Model243 | counterpart_requires_review |
| Model243 | Lin_Thanksgiving_Wolf | wolf | 72 | Model38, Model242, Model316 | counterpart_ambiguous |
| Model244 | Geremi WorldWar | human | 552 | yok | counterpart_not_found |
| Model245 | Geremi song_WorldWar_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model246 | Ivanov_WorldWar | human | 506 | Model247 | counterpart_requires_review |
| Model247 | Ivanov_WorldWar_Wolf | wolf | 72 | Model56, Model246, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model248 | Yigit_WorldWar | human | 552 | Model249 | counterpart_requires_review |
| Model249 | Yigit_WorldWar_Wolf | wolf | 72 | Model54, Model248, Model322, Model354 | counterpart_ambiguous |
| Model250 | Tomita_WorldWar | human | 506 | Model251 | counterpart_requires_review |
| Model251 | Tomita_WorldWar_Wolf | wolf | 72 | Model52, Model250, Model324, Model356 | counterpart_ambiguous |
| Model252 | Christopher Christmas | human | 552 | Model253 | skeleton_requires_review, counterpart_requires_review |
| Model253 | Christopher Christmas Wolf | wolf | 72 | Model23, Model252, Model280, Model326 | counterpart_ambiguous, counterpart_requires_review |
| Model254 | Angela Christmas | human | 506 | Model255 | counterpart_requires_review |
| Model255 | Angela Christmas Wolf | wolf | 72 | Model21, Model254, Model278, Model328, Model496 | counterpart_ambiguous |
| Model31 | Pedro Christmas | human | 552 | Model32 | skeleton_requires_review, counterpart_requires_review |
| Model32 | Pedro Christmas Wolf | wolf | 72 | Model22, Model31, Model284, Model330 | counterpart_ambiguous, counterpart_requires_review |
| Model34 | Adriana Christmas | human | 506 | Model35 | counterpart_requires_review |
| Model35 | Adriana Christmas Wolf | wolf | 72 | Model20, Model34, Model282, Model332 | counterpart_ambiguous |
| Model258 | GM Red MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model259 | GM Red MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model260 | GM Blue MAN | human | 552 | Model171, Model175, Model213, Model217, Model259, Model261 | skeleton_requires_review, counterpart_requires_review |
| Model261 | GM Blue MAN Wolf | wolf | 72 | Model170, Model174, Model212, Model216, Model258, Model260 | skeleton_requires_review, counterpart_requires_review |
| Model262 | Geremi Ski | human | 552 | yok | counterpart_not_found |
| Model263 | Geremi song_Ski_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model264 | Ivanov_Ski | human | 506 | Model265 | counterpart_requires_review |
| Model265 | Ivanov_Ski_Wolf | wolf | 72 | Model56, Model264, Model320, Model360 | skeleton_requires_review, counterpart_ambiguous |
| Model266 | Yigit_Ski | human | 552 | Model267 | counterpart_requires_review |
| Model267 | Yigit_Ski_Wolf | wolf | 72 | Model54, Model266, Model322, Model354 | counterpart_ambiguous |
| Model268 | Tomita_Ski | human | 506 | Model269 | counterpart_requires_review |
| Model269 | Tomita_Ski_Wolf | wolf | 72 | Model52, Model268, Model324, Model356 | counterpart_ambiguous |
| Model270 | Christopher vallantine | human | 552 | Model271 | counterpart_requires_review |
| Model271 | Christopher vallantine Wolf | wolf | 72 | Model23, Model270, Model280, Model326 | counterpart_ambiguous |
| Model272 | Angela vallantine | human | 506 | Model273 | counterpart_requires_review |
| Model273 | Angela vallantine Wolf | wolf | 72 | Model21, Model272, Model278, Model328 | counterpart_ambiguous |
| Model274 | Pedro vallantine | human | 552 | Model275 | counterpart_requires_review |
| Model275 | Pedro vallantine Wolf | wolf | 72 | Model22, Model274, Model284, Model330 | counterpart_ambiguous |
| Model276 | Adriana vallantine | human | 506 | Model277 | counterpart_requires_review |
| Model277 | Adriana vallantine Wolf | wolf | 72 | Model20, Model276, Model282, Model332 | counterpart_ambiguous |
| Model278 | Angela_Spring | human | 506 | Model25, Model181, Model199, Model255, Model273, Model279, Model397 | counterpart_requires_review |
| Model279 | Angela Spring Wolf | wolf | 72 | Model21, Model278, Model328 | Motor/görsel onay bekliyor |
| Model280 | Christopher_Spring | human | 552 | Model27, Model179, Model197, Model253, Model271, Model281, Model395 | counterpart_requires_review |
| Model281 | Christopher Spring Wolf | wolf | 72 | Model23, Model280, Model326 | Motor/görsel onay bekliyor |
| Model282 | Adriana_Spring | human | 506 | Model24, Model185, Model203, Model35, Model277, Model283, Model401 | counterpart_requires_review |
| Model283 | Adriana Spring Wolf | wolf | 72 | Model20, Model282, Model332 | Motor/görsel onay bekliyor |
| Model284 | Pedro_Spring | human | 552 | Model26, Model183, Model201, Model32, Model275, Model285, Model399 | counterpart_requires_review |
| Model285 | Pedro Spring Wolf | wolf | 72 | Model22, Model284, Model330 | Motor/görsel onay bekliyor |
| Model286 | Riccardo  Suit | human | 552 | yok | counterpart_not_found |
| Model287 | Alexsandro Del Riccardo_SE_wolf | wolf | 72 | Model150 | skeleton_requires_review, counterpart_requires_review |
| Model288 | Sarah  Suit | human | 506 | yok | counterpart_not_found |
| Model289 | Sarah Linda SE Wolf | wolf | 72 | Model152 | skeleton_requires_review |
| Model290 | Matt  Suit | human | 552 | yok | counterpart_not_found |
| Model291 | Matt Baker SE wolf | wolf | 72 | Model146 | skeleton_requires_review, counterpart_requires_review |
| Model292 | Kate  Suit | human | 506 | yok | counterpart_not_found |
| Model293 | Kate Blume_SE_wolf | wolf | 72 | Model148 | skeleton_requires_review |
| Model294 | Reinhard_WorldCup | human | 552 | Model295 | counterpart_requires_review |
| Model295 | Reinhard_WorldCup_Wolf | wolf | 72 | Model40, Model294, Model310 | counterpart_ambiguous |
| Model296 | Yigit_WorldCup | human | 552 | Model297 | counterpart_requires_review |
| Model297 | Yigit_WorldCup_Wolf | wolf | 72 | Model54, Model296, Model322, Model354 | counterpart_ambiguous |
| Model298 | Hamadah_WorldCup | human | 552 | Model99, Model299 | counterpart_ambiguous, counterpart_requires_review |
| Model299 | Hamadah_WorldCup_Wolf | wolf | 72 | Model36, Model298, Model314 | counterpart_ambiguous, counterpart_requires_review |
| Model300 | Geremi WorldCup | human | 552 | yok | counterpart_not_found |
| Model301 | Geremi song_WorldCup_Wolf | wolf | 72 | yok | counterpart_not_found |
| Model302 | Reinhard_Casual | human | 552 | Model303 | counterpart_requires_review |
| Model303 | Reinhard_Casual_Wolf | wolf | 72 | Model40, Model302, Model310 | counterpart_ambiguous |
| Model304 | Marien Casual | human | 506 | Model305 | counterpart_requires_review |
| Model305 | Marien_Casual_Wolf | wolf | 72 | Model42, Model304, Model312 | counterpart_ambiguous, counterpart_requires_review |
| Model306 | Hamadah_Casual | human | 552 | Model307 | counterpart_requires_review |
| Model307 | Hamadah_Casual_Wolf | wolf | 72 | Model36, Model306, Model314 | counterpart_ambiguous |
| Model308 | Lin_Casual | human | 506 | Model309 | counterpart_requires_review |
| Model309 | Lin_Casual_Wolf | wolf | 72 | Model38, Model308, Model316 | counterpart_ambiguous |
| Model310 | Reinhard Summer | human | 552 | Model41, Model157, Model221, Model229, Model237, Model295, Model303, Model311 | counterpart_requires_review |
| Model311 | ReinhardWolf summer | wolf | 72 | Model40, Model310 | Motor/görsel onay bekliyor |
| Model312 | Marien summer | human | 506 | Model43, Model155, Model223, Model231, Model239, Model305, Model313 | counterpart_requires_review |
| Model313 | MarienWolf Summer | wolf | 72 | Model42, Model312 | counterpart_requires_review |
| Model314 | Moshin Summer | human | 552 | Model37, Model161, Model225, Model233, Model241, Model299, Model307, Model315 | counterpart_requires_review |
| Model315 | MoshinWolf Summer | wolf | 72 | Model36, Model314 | Motor/görsel onay bekliyor |
| Model316 | Lin Summer | human | 506 | Model39, Model159, Model227, Model235, Model243, Model309, Model317 | counterpart_requires_review |
| Model317 | LinWolf Summer | wolf | 72 | Model38, Model316 | Motor/görsel onay bekliyor |
| Model318 | Geremi Song Autumn | human | 552 | yok | counterpart_not_found |
| Model319 | GeremiWolf Autumn | wolf | 72 | yok | counterpart_not_found |
| Model320 | Ivanov Autumn | human | 506 | Model57, Model117, Model133, Model141, Model163, Model193, Model247, Model265, Model321, Model361 | counterpart_requires_review |
| Model321 | IvanovWolf | wolf | 72 | Model56, Model320, Model360 | skeleton_requires_review |
| Model324 | Tomita Atutmn | human | 506 | Model53, Model121, Model137, Model145, Model165, Model189, Model251, Model269, Model325, Model357 | counterpart_requires_review |
| Model325 | Tomitawolf | wolf | 72 | Model52, Model324, Model356 | Motor/görsel onay bekliyor |
| Model322 | YigitDemir | human | 552 | Model55, Model119, Model135, Model143, Model187, Model249, Model267, Model297, Model323, Model355 | counterpart_requires_review |
| Model323 | Yigitwolf | wolf | 72 | Model54, Model322, Model354 | Motor/görsel onay bekliyor |
| Model328 | Angela_Dragon | human | 506 | Model25, Model181, Model199, Model255, Model273, Model279, Model397 | counterpart_requires_review |
| Model329 | AngelaWolf_D | wolf | 72 | Model44 | Motor/görsel onay bekliyor |
| Model326 | Christopher_Spring | human | 552 | Model27, Model179, Model197, Model253, Model271, Model281, Model395 | counterpart_requires_review |
| Model327 | Christopher_Wolf_D | wolf | 72 | Model46 | Motor/görsel onay bekliyor |
| Model332 | Adriana_Dragon | human | 506 | Model24, Model185, Model203, Model35, Model277, Model283, Model401 | counterpart_requires_review |
| Model333 | Adriana_SE_wolf | wolf | 72 | Model48 | Motor/görsel onay bekliyor |
| Model330 | Pedro_Dragon | human | 552 | Model26, Model183, Model201, Model32, Model275, Model285, Model399 | counterpart_requires_review |
| Model331 | PedroSEwolf | wolf | 72 | Model50, Model392 | counterpart_ambiguous |
| Model334 | Barut_Legend | human | 552 | Model335 | counterpart_requires_review |
| Model335 | BarutWolf_L | wolf | 72 | Model334 | skeleton_requires_review |
| Model336 | Ates_Legend | human | 552 | Model337 | skeleton_requires_review, counterpart_requires_review |
| Model337 | Ates_Wolf_D | wolf | 72 | Model336 | skeleton_requires_review, counterpart_requires_review |
| Model350 | Matt Winter | human | 552 | yok | counterpart_not_found |
| Model351 | Matt Wolf | wolf | 72 | Model80, Model128 | counterpart_ambiguous |
| Model352 | Kate Winter | human | 506 | yok | counterpart_not_found |
| Model353 | KateWolf | wolf | 72 | Model78 | Motor/görsel onay bekliyor |
| Model348 | Sarah Winter | human | 506 | yok | counterpart_not_found |
| Model349 | Sarahwolf | wolf | 72 | Model74 | Motor/görsel onay bekliyor |
| Model346 | Riccardo | human | 552 | Model77, Model127, Model205, Model347 | counterpart_requires_review |
| Model347 | Riccardowolf | wolf | 72 | Model76, Model346 | Motor/görsel onay bekliyor |
| Model340 | Marien_Halloween02 | human | 506 | yok | counterpart_not_found |
| Model341 | MarienWolf_D | wolf | 72 | Model66 | Motor/görsel onay bekliyor |
| Model338 | Reinhard_Halloween02 | human | 552 | yok | counterpart_not_found |
| Model339 | Reinhard_Wolf_D | wolf | 72 | Model68 | Motor/görsel onay bekliyor |
| Model344 | LinMeiling_Halloween02 | human | 506 | yok | counterpart_not_found |
| Model345 | LinMeiling_SE_wolf | wolf | 72 | Model70 | Motor/görsel onay bekliyor |
| Model342 | Moshin_Halloween02 | human | 552 | yok | counterpart_not_found |
| Model343 | MoshinSEwolf | wolf | 72 | Model72 | Motor/görsel onay bekliyor |
| Model358 | Geremi Song ChristmasTheme | human | 552 | yok | counterpart_not_found |
| Model359 | GeremiWolf ChristmasTheme | wolf | 72 | yok | counterpart_not_found |
| Model360 | Ivanov ChristmasTheme | human | 506 | Model57, Model117, Model133, Model141, Model163, Model193, Model247, Model265, Model321, Model361 | counterpart_requires_review |
| Model361 | IvanovWolf | wolf | 72 | Model56, Model320, Model360 | skeleton_requires_review |
| Model356 | Tomita Atutmn | human | 506 | Model53, Model121, Model137, Model145, Model165, Model189, Model251, Model269, Model325, Model357 | counterpart_requires_review |
| Model357 | Tomitawolf | wolf | 72 | Model52, Model324, Model356 | Motor/görsel onay bekliyor |
| Model354 | YigitDemir | human | 552 | Model55, Model119, Model135, Model143, Model187, Model249, Model267, Model297, Model323, Model355 | counterpart_requires_review |
| Model355 | Yigitwolf | wolf | 72 | Model54, Model322, Model354 | Motor/görsel onay bekliyor |
| Model364 | Tomita Christmas SE | human | 506 | yok | counterpart_not_found |
| Model365 | Tomita SE wolf | wolf | 72 | Model104 | Motor/görsel onay bekliyor |
| Model362 | YigitDemir Christmas SE | human | 552 | yok | counterpart_not_found |
| Model363 | Yigit SE wolf | wolf | 72 | Model106 | Motor/görsel onay bekliyor |
| Model368 | Ivanov Christmas SE | human | 506 | yok | counterpart_not_found |
| Model369 | Ivanov SE Wolf | wolf | 72 | Model108 | Motor/görsel onay bekliyor |
| Model366 | Geremi Christmas SE | human | 552 | yok | skin_or_render_style_missing, counterpart_not_found |
| Model367 | Geremi SE Wolf | wolf | 72 | Model110 | Motor/görsel onay bekliyor |
| Model370 | Raynor_Legend | human | 552 | Model371 | skeleton_requires_review, counterpart_requires_review |
| Model371 | Raynor Legend Wolf | wolf | 72 | Model370 | skeleton_requires_review, counterpart_requires_review |
| Model372 | Bane_Legend | human | 552 | yok | counterpart_not_found |
| Model373 | Bane_Wolf_D | wolf | 72 | yok | skeleton_requires_review, counterpart_not_found |
| Model374 | Vanessa Furtado | human | 506 | Model375, Model437 | counterpart_requires_review |
| Model375 | Vanessa Furtado Wolf | wolf | 72 | Model374, Model436, Model530 | skeleton_requires_review, counterpart_ambiguous, counterpart_requires_review |
| Model376 | Megan Savante | human | 506 | Model377, Model441, Model533 | counterpart_ambiguous, counterpart_requires_review |
| Model377 | Megan Savante wolf | wolf | 72 | Model376, Model440, Model532 | skeleton_requires_review, counterpart_ambiguous, counterpart_requires_review |
| Model378 | Hans Muller | human | 552 | Model379, Model435 | counterpart_requires_review |
| Model379 | Hans Muller wolf | wolf | 72 | Model378, Model434 | skeleton_requires_review, counterpart_ambiguous |
| Model380 | Seif al Haq | human | 552 | Model381, Model439 | counterpart_requires_review |
| Model381 | Seif al Haq wolf | wolf | 72 | Model380, Model438 | skeleton_requires_review, counterpart_ambiguous |
| Model382 | san martin | human | 552 | Model383 | counterpart_requires_review |
| Model383 | san martin Wolf_D | wolf | 72 | Model382 | skeleton_requires_review |
| Model384 | Tupac | human | 552 | Model385 | counterpart_requires_review |
| Model385 | Tupacwolf | wolf | 72 | Model384 | skeleton_requires_review |
| Model386 | AngelaSWAT | human | 506 | yok | counterpart_not_found |
| Model387 | AngelaWolfSE | wolf | 72 | Model44 | Motor/görsel onay bekliyor |
| Model388 | ChristopherSWAT | human | 552 | yok | counterpart_not_found |
| Model389 | Christopher_SE_wolf | wolf | 72 | Model46 | Motor/görsel onay bekliyor |
| Model390 | AdrianaSWAT | human | 506 | yok | skin_or_render_style_missing, counterpart_not_found |
| Model391 | Adriana_SE_wolf | wolf | 72 | Model48 | Motor/görsel onay bekliyor |
| Model392 | PedroSE | human | 552 | Model51, Model331, Model393, Model431 | counterpart_requires_review |
| Model393 | PedroSEwolf | wolf | 72 | Model50, Model392 | counterpart_ambiguous |
| Model394 | Christopher Desert OPS | human | 552 | Model395 | counterpart_requires_review |
| Model395 | Christopher Desert OPS Wolf | wolf | 72 | Model23, Model280, Model326, Model394 | counterpart_ambiguous |
| Model396 | Angela Desert OPS | human | 506 | Model397 | counterpart_requires_review |
| Model397 | Angela Desert OPS Wolf | wolf | 72 | Model21, Model278, Model328, Model396 | counterpart_ambiguous |
| Model398 | Pedro Desert OPS | human | 552 | Model399 | counterpart_requires_review |
| Model399 | Pedro Desert OPS Wolf | wolf | 72 | Model22, Model284, Model330, Model398 | counterpart_ambiguous |
| Model400 | Adriana Desert OPS | human | 506 | Model401 | counterpart_requires_review |
| Model401 | Adriana Desert OPS Wolf | wolf | 72 | Model20, Model282, Model332, Model400 | counterpart_ambiguous |
| Model402 | Saladin_ramadan | human | 552 | Model403 | counterpart_requires_review |
| Model403 | Saladin_ramadan_wolf | wolf | 72 | Model402 | skeleton_requires_review |
| Model404 | Saladin_Neo_ramadan | human | 552 | Model405 | counterpart_requires_review |
| Model405 | Saladin_Neo_ramadan_wolf | wolf | 72 | Model404 | skeleton_requires_review |
| Model406 | Rashid_ramadan | human | 552 | Model407 | counterpart_requires_review |
| Model407 | Rashid_ramadan_wolf | wolf | 72 | Model406 | skeleton_requires_review |
| Model408 | Rashid_Neo_ramadan | human | 552 | Model409 | counterpart_requires_review |
| Model409 | Rashid_Neo_ramadan_wolf | wolf | 72 | Model408 | skeleton_requires_review |
| Model410 | Ceyda Ersoy | human | 506 | Model411, Model423 | counterpart_ambiguous, counterpart_requires_review |
| Model411 | Ceyda Ersoy wolf | wolf | 65 | Model410 | counterpart_requires_review |
| Model412 | Esra Ersoy | human | 506 | Model413, Model425 | counterpart_ambiguous, counterpart_requires_review |
| Model413 | Esra Ersoy Wolf | wolf | 65 | Model412 | counterpart_requires_review |
| Model414 | Ivanov Adult | human | 506 | Model163 | counterpart_requires_review |
| Model415 | Ivanov SE Wolf | wolf | 72 | Model108 | Motor/görsel onay bekliyor |
| Model416 | Tomita adult | human | 506 | Model165 | counterpart_requires_review |
| Model417 | Tomita SE wolf | wolf | 72 | Model104 | Motor/görsel onay bekliyor |
| Model418 | Kate Adult | human | 506 | Model167 | counterpart_requires_review |
| Model419 | Kate Blume_SE_wolf | wolf | 72 | Model148 | skeleton_requires_review |
| Model420 | Sarah Adult | human | 506 | Model169 | counterpart_requires_review |
| Model421 | Sarah Linda SE Wolf | wolf | 72 | Model152 | skeleton_requires_review |
| Model422 | Stephanie | human | 506 | Model423 | counterpart_requires_review |
| Model423 | Ceyda Ersoy wolf | wolf | 65 | Model410, Model422 | counterpart_ambiguous, counterpart_requires_review |
| Model424 | Antonela | human | 506 | Model425 | counterpart_requires_review |
| Model425 | Esra Ersoy Wolf | wolf | 65 | Model412, Model424 | counterpart_ambiguous, counterpart_requires_review |
| Model426 | Chiristopher_WorldWar | human | 552 | Model427 | counterpart_requires_review |
| Model427 | Chiristopher_WorldWar Wolf | wolf | 72 | Model46, Model426 | counterpart_ambiguous |
| Model428 | Angela_WorldWar | human | 506 | Model429 | counterpart_requires_review |
| Model429 | Angela_WorldWar Wolf | wolf | 72 | Model44, Model428 | counterpart_ambiguous |
| Model430 | Pedro_WorldWar | human | 552 | yok | counterpart_not_found |
| Model431 | PedroSEwolf | wolf | 72 | Model50, Model392 | counterpart_ambiguous |
| Model432 | Adriana_WorldWar | human | 506 | yok | counterpart_not_found |
| Model433 | Adriana_SE_wolf | wolf | 72 | Model48 | Motor/görsel onay bekliyor |
| Model434 | Hans Muller | human | 552 | Model379, Model435 | counterpart_requires_review |
| Model435 | Hans Muller wolf | wolf | 72 | Model378, Model434 | skeleton_requires_review, counterpart_ambiguous |
| Model436 | Vanessa Furtado | human | 506 | Model375, Model437 | counterpart_requires_review |
| Model437 | Vanessa Furtado Wolf | wolf | 72 | Model374, Model436, Model530 | skeleton_requires_review, counterpart_ambiguous, counterpart_requires_review |
| Model438 | Seif al Haq | human | 552 | Model381, Model439 | counterpart_requires_review |
| Model439 | Seif al Haq wolf | wolf | 72 | Model380, Model438 | skeleton_requires_review, counterpart_ambiguous |
| Model440 | Megan Savante | human | 506 | Model377, Model441, Model533 | counterpart_ambiguous, counterpart_requires_review |
| Model441 | Megan Savante wolf | wolf | 72 | Model376, Model440, Model532 | skeleton_requires_review, counterpart_ambiguous, counterpart_requires_review |
| Model442 | Ceyda Ersoy Summer | human | 506 | Model443 | Motor/görsel onay bekliyor |
| Model443 | Ceyda Ersoy summer wolf | wolf | 65 | Model442 | Motor/görsel onay bekliyor |
| Model444 | Esra ErsoySummer | human | 506 | Model445 | Motor/görsel onay bekliyor |
| Model445 | Esra Ersoy Summer Wolf | wolf | 65 | Model444 | Motor/görsel onay bekliyor |
| Model446 | Hanna | human | 506 | Model447 | Motor/görsel onay bekliyor |
| Model447 | Hanna wolf | wolf | 65 | Model446 | Motor/görsel onay bekliyor |
| Model448 | Eliana | human | 506 | Model449 | Motor/görsel onay bekliyor |
| Model449 | Eliana Wolf | wolf | 65 | Model448 | Motor/görsel onay bekliyor |
| Model450 | Sahale Mora | human | 552 | Model451 | counterpart_requires_review |
| Model451 | Sahale Mora Wolf | wolf | 72 | Model450 | skeleton_requires_review |
| Model452 | Jacy BrewSter | human | 506 | Model453 | Motor/görsel onay bekliyor |
| Model453 | Jacy BrewSter Wolf | wolf | 72 | Model452 | Motor/görsel onay bekliyor |
| Model454 | James Douglas | human | 552 | Model455 | counterpart_requires_review |
| Model455 | James Douglas Wolf | wolf | 72 | Model454 | skeleton_requires_review |
| Model456 | Rose Fox | human | 506 | Model457 | counterpart_requires_review |
| Model457 | Rose Fox Wolf | wolf | 72 | Model456 | skeleton_requires_review |
| Model458 | Hanna X_mas | human | 506 | Model459 | Motor/görsel onay bekliyor |
| Model459 | Hanna X_mas wolf | wolf | 65 | Model458 | Motor/görsel onay bekliyor |
| Model460 | Eliana X_mas | human | 506 | Model461 | Motor/görsel onay bekliyor |
| Model461 | Eliana X_mas Wolf | wolf | 65 | Model460 | Motor/görsel onay bekliyor |
| Model462 | Sahale Mora - MadMax SE | human | 552 | Model463 | counterpart_requires_review |
| Model463 | Sahale Mora - MadMax wolf SE | wolf | 72 | Model462 | skeleton_requires_review |
| Model464 | Jacy BrewSter - MadMax SE | human | 506 | Model465 | counterpart_requires_review |
| Model465 | Jacy BrewSter - MadMax SE Wolf | wolf | 72 | Model464 | skeleton_requires_review |
| Model466 | James Douglas - MadMax SE | human | 552 | Model467 | counterpart_requires_review |
| Model467 | James Douglas - MadMax SE Wolf | wolf | 72 | Model466 | skeleton_requires_review |
| Model468 | Rose Fox - MadMax SE | human | 506 | Model469 | counterpart_requires_review |
| Model469 | Rose Fox - MadMax SE Wolf | wolf | 72 | Model468 | skeleton_requires_review |
| Model470 | Christopher_RE | human | 552 | Model3, Model471 | Motor/görsel onay bekliyor |
| Model471 | Christopher_RE Wolf | wolf | 75 | Model1, Model470 | Motor/görsel onay bekliyor |
| Model472 | Angela_RE | human | 506 | Model473 | Motor/görsel onay bekliyor |
| Model473 | Angela_RE Wolf | wolf | 75 | Model472 | Motor/görsel onay bekliyor |
| Model474 | Pedro_RE | human | 552 | Model2, Model475 | Motor/görsel onay bekliyor |
| Model475 | Pedro_RE Wolf | wolf | 75 | Model0, Model474 | Motor/görsel onay bekliyor |
| Model476 | LinMeiling_RE | human | 506 | Model477 | Motor/görsel onay bekliyor |
| Model477 | LinMeiling_RE Wolf | wolf | 75 | Model476 | Motor/görsel onay bekliyor |
| Model478 | Tetra | human | 506 | Model479, Model617 | Motor/görsel onay bekliyor |
| Model479 | Tetra Wolf | wolf | 62 | Model478, Model616 | Motor/görsel onay bekliyor |
| Model480 | Caracin | human | 506 | Model481, Model619 | Motor/görsel onay bekliyor |
| Model481 | Caracin Wolf | wolf | 62 | Model480, Model618 | Motor/görsel onay bekliyor |
| Model482 | Ruslan | human | 552 | Model483, Model625 | Motor/görsel onay bekliyor |
| Model483 | Ruslan Wolf | wolf | 75 | Model482, Model624 | Motor/görsel onay bekliyor |
| Model484 | Kyle | human | 552 | Model485, Model627 | Motor/görsel onay bekliyor |
| Model485 | Kyle Wolf | wolf | 75 | Model484, Model626 | Motor/görsel onay bekliyor |
| Model486 | Reinhard_RE | human | 552 | Model487 | Motor/görsel onay bekliyor |
| Model487 | Reinhard_RE Wolf | wolf | 75 | Model486 | Motor/görsel onay bekliyor |
| Model488 | Hamadah_RE | human | 552 | Model489 | Motor/görsel onay bekliyor |
| Model489 | Hamadah_RE Wolf | wolf | 75 | Model488 | Motor/görsel onay bekliyor |
| Model490 | Marien_RE | human | 506 | Model491 | Motor/görsel onay bekliyor |
| Model491 | Marien_RE Wolf | wolf | 75 | Model490 | Motor/görsel onay bekliyor |
| Model492 | Adriana_RE | human | 506 | Model493 | Motor/görsel onay bekliyor |
| Model493 | Adriana_RE Wolf | wolf | 75 | Model492 | Motor/görsel onay bekliyor |
| Model494 | Riccardo_Christmas | human | 552 | yok | counterpart_not_found |
| Model495 | Matt_Christmas | human | 552 | yok | counterpart_not_found |
| Model496 | Angela Christmas | human | 506 | Model255 | counterpart_requires_review |
| Model497 | Kate_Christmas | human | 506 | yok | counterpart_not_found |
| Model498 | Yigit_RE | human | 552 | Model499 | Motor/görsel onay bekliyor |
| Model499 | Yigit_RE Wolf | wolf | 75 | Model498 | Motor/görsel onay bekliyor |
| Model500 | Tomita Yasuko - Reboot | human | 506 | Model501 | Motor/görsel onay bekliyor |
| Model501 | Tomita_RE Wolf | wolf | 75 | Model500 | Motor/görsel onay bekliyor |
| Model502 | Geremi_RE | human | 552 | Model503 | Motor/görsel onay bekliyor |
| Model503 | Geremi_RE Wolf | wolf | 75 | Model502 | Motor/görsel onay bekliyor |
| Model504 | Ivanov_RE | human | 506 | Model505 | Motor/görsel onay bekliyor |
| Model505 | Ivanov_RE Wolf | wolf | 75 | Model504 | Motor/görsel onay bekliyor |
| Model506 | Barut_Legend_Reboot | human | 552 | Model507 | Motor/görsel onay bekliyor |
| Model507 | BarutWolf_L | wolf | 75 | Model506 | Motor/görsel onay bekliyor |
| Model508 | Ates - Red Legend Reboot | human | 552 | Model509 | Motor/görsel onay bekliyor |
| Model509 | Ates_Wolf_D | wolf | 75 | Model508 | Motor/görsel onay bekliyor |
| Model510 | Mert | human | 552 | Model511 | Motor/görsel onay bekliyor |
| Model511 | Mert Wolf | wolf | 75 | Model510 | Motor/görsel onay bekliyor |
| Model512 | Sarp | human | 552 | Model513 | Motor/görsel onay bekliyor |
| Model513 | Sarp Wolf | wolf | 75 | Model512 | Motor/görsel onay bekliyor |
| Model518 | PlayerWinter | human | 552 | yok | counterpart_not_found |
| Model519 | SSLeut | wolf | 72 | yok | counterpart_not_found |
| Model520 | Player | human | 552 | yok | counterpart_not_found |
| Model521 | Hero_Casual | wolf | 72 | yok | counterpart_not_found |
| Model526 | Christopher_CE | human | 552 | Model527 | Motor/görsel onay bekliyor |
| Model527 | Christopher_CE Wolf | wolf | 75 | Model526 | Motor/görsel onay bekliyor |
| Model528 | Pedro_CE | human | 552 | Model529 | Motor/görsel onay bekliyor |
| Model529 | Pedro_CE Wolf | wolf | 75 | Model528 | Motor/görsel onay bekliyor |
| Model530 | Vanessa Furtado WTK | human | 506 | Model375, Model437, Model531 | counterpart_ambiguous, counterpart_requires_review |
| Model531 | Vanessa Furtado WTK Wolf | wolf | 72 | Model530 | skeleton_requires_review, counterpart_requires_review |
| Model532 | Megan Savante | human | 506 | Model377, Model441, Model533 | counterpart_ambiguous, counterpart_requires_review |
| Model533 | Megan Savante wolf | wolf | 72 | Model376, Model440, Model532 | skeleton_requires_review, counterpart_ambiguous, counterpart_requires_review |
| Model534 | San Martin-Reborn | human | 552 | Model535 | counterpart_requires_review |
| Model535 | San Martin-Reborn WOLF | wolf | 72 | Model534 | skeleton_requires_review |
| Model536 | Tupac Amaru-Reborn | human | 552 | Model537 | counterpart_requires_review |
| Model537 | Tupac Amaru-Reborn Wolf | wolf | 72 | Model536 | skeleton_requires_review |
| Model538 | Simon Bolivar-Reborn | human | 552 | Model539 | skeleton_requires_review, counterpart_requires_review |
| Model539 | Simon Bolivar-Reborn Wolf | wolf | 72 | Model538 | skeleton_requires_review, counterpart_requires_review |
| Model540 | Simon Glazkov | human | 552 | Model541 | Motor/görsel onay bekliyor |
| Model541 | Simon Glazkov Wolf | wolf | 83 | Model540 | Motor/görsel onay bekliyor |
| Model542 | Amelli Binoche | human | 506 | Model543 | Motor/görsel onay bekliyor |
| Model543 | Amelli Binoche Wolf | wolf | 83 | Model542 | Motor/görsel onay bekliyor |
| Model544 | Ezel | human | 552 | Model545, Model593, Model621 | Motor/görsel onay bekliyor |
| Model545 | Ezel Wolf | wolf | 75 | Model544, Model592, Model620 | Motor/görsel onay bekliyor |
| Model546 | Azap | human | 552 | Model547, Model595, Model623 | Motor/görsel onay bekliyor |
| Model547 | Azap Wolf | wolf | 75 | Model546, Model594, Model622 | Motor/görsel onay bekliyor |
| Model548 | GM-2019_Blue_MAN | human | 552 | Model549 | skeleton_requires_review, counterpart_requires_review |
| Model549 | GM-2019_Blue_MAN Wolf | wolf | 72 | Model548 | skeleton_requires_review, counterpart_requires_review |
| Model550 | GM-2019_Red_Woman | human | 506 | Model551 | counterpart_requires_review |
| Model551 | GM-2019_Red_Woman Wolf | wolf | 72 | Model550 | skeleton_requires_review |
| Model552 | Saladin-Reboot | human | 552 | Model553, Model573, Model589 | counterpart_ambiguous, counterpart_requires_review |
| Model553 | Saladin-Reboot Wolf | wolf | 75 | Model552, Model572, Model588 | counterpart_ambiguous, counterpart_requires_review |
| Model554 | Rashid-Reboot | human | 552 | Model555, Model575, Model591 | counterpart_ambiguous, counterpart_requires_review |
| Model555 | Rashid-Reboot Wolf | wolf | 75 | Model554, Model574, Model590 | counterpart_ambiguous, counterpart_requires_review |
| Model556 | Muhammad Ramadan | human | 552 | Model557, Model597 | Motor/görsel onay bekliyor |
| Model557 | Muhammad Ramadan Wolf | wolf | 75 | Model556, Model596 | Motor/görsel onay bekliyor |
| Model558 | Ahmed_Elsaka_Reboot | human | 552 | Model559, Model599 | Motor/görsel onay bekliyor |
| Model559 | Ahmed_Elsaka_Reboot_Wolf | wolf | 75 | Model558, Model598 | Motor/görsel onay bekliyor |
| Model560 | Wilson Strotsky | human | 552 | Model561 | Motor/görsel onay bekliyor |
| Model561 | Wilson Strotsky Wolf | wolf | 75 | Model560 | Motor/görsel onay bekliyor |
| Model562 | EL-17 | human | 506 | Model563 | Motor/görsel onay bekliyor |
| Model563 | EL-17 Wolf | wolf | 75 | Model562 | Motor/görsel onay bekliyor |
| Model564 | Vanessa Furtado-Neon | human | 506 | Model565, Model609 | counterpart_requires_review |
| Model565 | Vanessa Furtado-Neon Wolf | wolf | 72 | Model564 | skeleton_requires_review |
| Model566 | Megan Savante-Neon | human | 506 | Model567 | counterpart_requires_review |
| Model567 | Megan Savante-Neon wolf | wolf | 72 | Model566 | skeleton_requires_review |
| Model568 | Seon | human | 552 | Model569 | Motor/görsel onay bekliyor |
| Model569 | Seon-wolf | wolf | 75 | Model568 | Motor/görsel onay bekliyor |
| Model570 | Leona | human | 506 | Model571 | Motor/görsel onay bekliyor |
| Model571 | Leona-wolf | wolf | 75 | Model570 | Motor/görsel onay bekliyor |
| Model572 | Saladin-Reboot | human | 552 | Model553, Model573 | counterpart_ambiguous, counterpart_requires_review |
| Model573 | Saladin-Reboot Wolf | wolf | 75 | Model552, Model572 | counterpart_ambiguous, counterpart_requires_review |
| Model574 | Rashid-Reboot | human | 552 | Model555, Model575 | counterpart_ambiguous, counterpart_requires_review |
| Model575 | Rashid-Reboot Wolf | wolf | 75 | Model554, Model574 | counterpart_ambiguous, counterpart_requires_review |
| Model576 | Brian | human | 552 | Model577 | Motor/görsel onay bekliyor |
| Model577 | Brian Wolf | wolf | 75 | Model576 | Motor/görsel onay bekliyor |
| Model578 | Youjin | human | 506 | Model579 | Motor/görsel onay bekliyor |
| Model579 | Youjin Wolf | wolf | 75 | Model578 | Motor/görsel onay bekliyor |
| Model580 | Steven Gerrard | human | 552 | Model581, Model585 | Motor/görsel onay bekliyor |
| Model581 | Steven Gerrard Wolf | wolf | 75 | Model580, Model584 | Motor/görsel onay bekliyor |
| Model582 | Selma | human | 506 | Model583, Model587 | Motor/görsel onay bekliyor |
| Model583 | Selma Wolf | wolf | 75 | Model582, Model586 | Motor/görsel onay bekliyor |
| Model584 | Steven Gerrard Camo | human | 552 | Model581, Model585 | Motor/görsel onay bekliyor |
| Model585 | Steven Gerrard Camo Wolf | wolf | 75 | Model580, Model584 | Motor/görsel onay bekliyor |
| Model586 | Selma | human | 506 | Model583, Model587 | Motor/görsel onay bekliyor |
| Model587 | Selma Camo Wolf | wolf | 75 | Model582, Model586 | Motor/görsel onay bekliyor |
| Model588 | Saladin-Reboot Camo | human | 552 | Model553, Model589 | counterpart_requires_review |
| Model589 | Saladin-Reboot Camo Wolf | wolf | 75 | Model552, Model588 | counterpart_requires_review |
| Model590 | Rashid-Reboot Camo | human | 552 | Model555, Model591 | counterpart_requires_review |
| Model591 | Rashid-Reboot Camo Wolf | wolf | 75 | Model554, Model590 | counterpart_requires_review |
| Model592 | Ezel_Villain | human | 552 | Model545, Model593, Model621 | Motor/görsel onay bekliyor |
| Model593 | Ezel Wolf_Villain | wolf | 75 | Model544, Model592, Model620 | Motor/görsel onay bekliyor |
| Model594 | Azap_Villain | human | 552 | Model547, Model595, Model623 | Motor/görsel onay bekliyor |
| Model595 | Azap Wolf_Villain | wolf | 75 | Model546, Model594, Model622 | Motor/görsel onay bekliyor |
| Model596 | Muhammad Ramadan Sicario | human | 552 | Model557, Model597 | Motor/görsel onay bekliyor |
| Model597 | Muhammad Ramadan Sicario Wolf | wolf | 75 | Model556, Model596 | Motor/görsel onay bekliyor |
| Model598 | Ahmed_Elsaka_Reboot Sicario | human | 552 | Model559, Model599 | Motor/görsel onay bekliyor |
| Model599 | Ahmed_Elsaka_Reboot_Wolf Sicario | wolf | 75 | Model558, Model598 | Motor/görsel onay bekliyor |
| Model600 | Alexsandro Del Riccardo_Hide | human | 552 | Model601 | skeleton_requires_review, counterpart_requires_review |
| Model601 | Alexsandro Del Riccardo_Hide_wolf | wolf | 72 | Model600 | skeleton_requires_review, counterpart_requires_review |
| Model602 | Matt Baker_Hide | human | 552 | Model603 | skeleton_requires_review, counterpart_requires_review |
| Model603 | Matt Baker Hide wolf | wolf | 72 | Model602 | skeleton_requires_review, counterpart_requires_review |
| Model604 | Christopher_Nano | human | 552 | Model605 | Motor/görsel onay bekliyor |
| Model605 | Christopher_Nano_Wolf | wolf | 75 | Model604 | Motor/görsel onay bekliyor |
| Model606 | Pedro_Nano | human | 552 | Model607 | Motor/görsel onay bekliyor |
| Model607 | Pedro_Nano_Wolf | wolf | 75 | Model606 | Motor/görsel onay bekliyor |
| Model608 | Vanessa Christmas | human | 506 | Model609 | counterpart_requires_review |
| Model609 | Vanessa Christmas Wolf | wolf | 72 | Model564, Model608 | skeleton_requires_review, counterpart_ambiguous |
| Model610 | Megan Christmas | human | 506 | Model611 | skin_or_render_style_missing, counterpart_requires_review |
| Model611 | Megan Christmas wolf | wolf | 72 | Model610 | skeleton_requires_review, counterpart_requires_review |
| Model612 | Angela_Nano | human | 506 | Model613 | skin_or_render_style_missing |
| Model613 | AngelaWolf_Nano | wolf | 75 | Model612 | counterpart_requires_review |
| Model614 | Lin_Nano | human | 506 | Model615 | Motor/görsel onay bekliyor |
| Model615 | LinWolf_nano | wolf | 75 | Model614 | Motor/görsel onay bekliyor |
| Model616 | Tetra camo | human | 506 | Model479, Model617 | Motor/görsel onay bekliyor |
| Model617 | Tetra Wolf camo | wolf | 62 | Model478, Model616 | Motor/görsel onay bekliyor |
| Model618 | Caracin camo | human | 506 | Model481, Model619 | Motor/görsel onay bekliyor |
| Model619 | Caracin Wolf Camo | wolf | 62 | Model480, Model618 | Motor/görsel onay bekliyor |
| Model620 | Ezel_Villain2 | human | 552 | Model545, Model593, Model621 | Motor/görsel onay bekliyor |
| Model621 | Ezel Wolf_Villain2 | wolf | 75 | Model544, Model592, Model620 | Motor/görsel onay bekliyor |
| Model622 | Azap_Villain2 | human | 552 | Model547, Model595, Model623 | Motor/görsel onay bekliyor |
| Model623 | Azap Wolf_Villain2 | wolf | 75 | Model546, Model594, Model622 | Motor/görsel onay bekliyor |
| Model624 | Ruslan Camo | human | 552 | Model483, Model625 | Motor/görsel onay bekliyor |
| Model625 | Ruslan Wolf Camo | wolf | 75 | Model482, Model624 | Motor/görsel onay bekliyor |
| Model626 | Kyle Camo | human | 552 | Model485, Model627 | Motor/görsel onay bekliyor |
| Model627 | Kyle Wolf Camo | wolf | 75 | Model484, Model626 | Motor/görsel onay bekliyor |

## Tekrar üretim

`python tools/audit_characters.py "paket-klasoru"`

LTB şema başvurusu: https://github.com/Five-Damned-Dollarz/io_scene_lithtech/blob/master/src/reader_ltb_pc.py. Ayrıştırıcı yalnızca standart kütüphane kullanır; dışarıdan indirilen kodu çalıştırmaz.