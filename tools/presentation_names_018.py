"""Localize source texture families; these are not claims of official shop captions."""
import re,pathlib
FAMILIES={
'crocodile':'Timsah','nazca':'Nazca','skull':'Kurukafa','haitai':'Haitai','rhino':'Gergedan','smilodon':'Kılıç Diş','raptor':'Raptor','cerberus':'Cerberus','wing':'Kanat','axe':'Balta','sun':'Güneş','jaguar':'Jaguar','softnyx':'Softnyx','anchor':'Çapa','horus':'Horus','triceratops':'Triceratops','mammoth':'Mamut','mommoth':'Mamut','flame':'Alev','shark':'Köpek Balığı','olympicf':'Olimpiyat','torch':'Meşale','fmoon':'Dolunay','joy_game':'Joygame','wolf_bowl':'Wolf Bowl','thunder':'Yıldırım','star':'Yıldız','cyclone':'Kasırga','turkey_flag':'Türk Bayrağı','zebra':'Zebra','cobra':'Kobra','fox':'Tilki','death':'Ölüm','unicorn':'Tek Boynuz','dice':'Zar','tiger':'Kaplan','snake':'Yılan','scorpion':'Akrep','eagle':'Kartal','worldcup_trophy':'Dünya Kupası','world_ball':'Dünya Kupası Topu','exodus':'Diriliş','butterfly':'Kelebek','beuty':'Güzellik','crown':'Taç','dragon':'Ejder','phoenix':'Anka Kuşu','autumn':'Sonbahar','lycan':'Likan','medusa':'Medusa','mmu':'MMU','winter':'Kış','christmastheme':'Yılbaşı','snow':'Kar Tanesi','spring':'İlkbahar','endurance':'Dayanıklılık','angelheart':'Melek Kalbi','wolfy':'Wolfy','new bolivia':'Yeni Bolivya','westernskull':'Vahşi Batı Kurukafa','kebab':'Kebap','burningwolf':'Ateş Kurdu','brave one':'Cesaret','steampunk':'Steampunk','yin-yang':'Yin Yang','tunche':'Tunche','condor':'Kondor','blessing night':'Kutsal Gece','legend wolf':'Efsane Kurt','10th anniversary':'10. Yıl','pride battle wolf':'Klan Savaş Kurdu','blessing wolf':'Kutsal Kurt','wtk_2018':'WTK 2018','new_legend_wolf':'Yeni Efsane Kurt','eagle_warrior':'Savaşçı Kartal','copa2019_gold':'Copa 2019 Altın','copa2019_silver':'Copa 2019 Gümüş','copa2019_bronze':'Copa 2019 Bronz','blessing_flower':'Kutsal Çiçek','judgment_anubis':'Anubis','angelwings':'Melek Kanatları','lord_of_sipan':'Sipan Efendisi','trophy':'Kupa','aries':'Koç','gemini':'İkizler','leo':'Aslan Burcu','libra':'Terazi','sagittarius':'Yay','aquarius':'Kova','taurus':'Boğa Burcu','cancer':'Yengeç','virgo':'Başak','pisces':'Balık','blacktiger':'Kara Kaplan','sakura':'Sakura','watergun':'Su Tabancası','easter':'Paskalya','cresecent':'Hilal','ramadan':'Ramazan','honey bee':'Bal Arısı','ghost':'Hayalet','ailen':'Uzaylı','maya':'Maya'}
COUNTRIES={'de':'Almanya','fr':'Fransa','pl':'Polonya','ru':'Rusya','it':'İtalya','us':'ABD','ar':'Arjantin','bo':'Bolivya','pr':'Porto Riko','vn':'Vietnam','america':'Amerika','germany':'Almanya','france':'Fransa','argentina':'Arjantin','bolivia':'Bolivya','peru':'Peru','venezuela':'Venezuela','arabemirates':'Birleşik Arap Emirlikleri','mexico':'Meksika','egypt':'Mısır','malaysia':'Malezya','singapore':'Singapur','korea':'Kore'}
COLORS={'gl':'Altın','dr':'Bordo','db':'Lacivert','dp':'Mor','sp':'SP'}
def tattoo_alias(row):
 stem=pathlib.PurePosixPath(row['sourceTexture'].replace('\\','/')).stem.lower()
 key=re.sub('^(tattoo|tatoo)_','',stem);color='';variant=''
 if key.rsplit('_',1)[-1] in COLORS:key,color=key.rsplit('_',1);color=COLORS[color]
 key=key.strip('()')
 m=re.search(r'_?0([23])$',key)
 if m:key=key[:m.start()];variant=' II' if m[1]=='2' else ' III'
 role={'body':'Sırt','left':'Sol','right':'Sağ'}[row['role']]
 if key=='gm':base='OG';color=color or 'Gümüş'
 elif key.startswith(('flag_','fb_','w_')):
  prefix,country=key.split('_',1);base=COUNTRIES.get(country,country.title())+(' Futbol' if prefix=='fb' else ' Bayrağı')
 elif key in FAMILIES:base=FAMILIES[key]
 elif not row['name'].lower().startswith(('tattoo','tatoo')):
  base=re.sub(r'\s*\([^)]*\)','',row['name']).strip()
  base=re.sub(r'\s*(Dövmesi|Dözmesi|Sövmesi|Dövme)\s*','',base,flags=re.I).strip()
  for c in COLORS.values():base=re.sub(r'\s*'+c+r'\s*$', '',base,flags=re.I)
  base=base.replace("Ejder'in",'Ejder').replace('Zelanda','Yeni Zelanda').replace('Brazilya','Brezilya').replace('İtalyan','İtalya').replace('Fransız','Fransa')
 else:raise ValueError('Untranslated family '+stem)
 name=base+variant+' Dövmesi ('+((color+'-') if color else '')+role+')'
 return name,key+variant+color
