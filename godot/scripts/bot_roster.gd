extends RefCounted
# Offline identities and equipment, never online accounts or ownership grants.
const NAMES=["Kuzgun","Ayaz","Poyraz","Kıvılcım","GeceKartalı","Sarp","DemirPençe","Bozkır","Kutup","Gölgeİz","Çelik","Yıldırım","Pars","Bora","Kaya","Alaz"]
const ROLES=["assault","flanker","support","scout"]
var context=""
var members={}
var arsenal={}
func _init():arsenal=JSON.parse_string(FileAccess.get_file_as_string("res://assets/bots/arsenal.json")).profiles
func configure(game):
 var next=JSON.stringify([int(game.local_room.get("mode",0)),game.local_room.get("title",""),game.book.selected_characters,game.profile_name])
 if next!=context:context=next;members={}
func identity(game,team,slot):
 configure(game)
 var id=team+"-"+str(slot)
 if members.has(id):return members[id]
 var index=slot+(8 if team=="red" else 0);var name=NAMES[index%NAMES.size()]
 if name==game.profile_name:name+="_"+str(index+1)
 var used_characters=members.values().map(func(r):return r.characterId)
 var pool=game.book.characters.filter(func(r):return r.get("available",false) and r.get("sourceTeam","")==team and game.clientfx.catalog.characters.has(r.id) and not r.id in used_characters and not r.id in game.book.selected_characters.values())
 if pool.is_empty():pool=game.book.characters.filter(func(r):return r.get("available",false) and r.get("sourceTeam","")==team and not r.id in used_characters)
 var character=pool[(slot*3)%pool.size()] if not pool.is_empty() else game.book.character_for_team(team)
 var rules=preload("res://scripts/source_match_rules.gd").new();rules.configure(game.local_room)
 var used=members.values().map(func(r):return r.weaponId)
 var candidates=arsenal.values().filter(func(w):return rules.weapon_allowed(w.category,w.native.sourceKind) and not w.itemId in used)
 var preferred=rules.preferred_categories() if rules.enabled else ["rifle","smg","shotgun","machinegun","sniper","pistol"]
 if int(game.local_room.get("mode",0)) not in [1022,1023,1024,1025,1026]:candidates=candidates.filter(func(w):return w.category in preferred)
 if candidates.is_empty():candidates=arsenal.values().filter(func(w):return rules.weapon_allowed(w.category,w.native.sourceKind))
 candidates.sort_custom(func(a,b):
  var pa=preferred.find(a.category);var pb=preferred.find(b.category)
  if pa<0:pa=100
  if pb<0:pb=100
  return pa<pb if pa!=pb else a.source<b.source)
 var used_models=members.values().map(func(row):return arsenal.get(row.weaponId,{}).get("source",""))
 var fresh=candidates.filter(func(w):return not w.source in used_models)
 if not fresh.is_empty():candidates=fresh
 var role=ROLES[index%4]
 var preferred_role={"assault":"rifle","flanker":"smg","support":"machinegun","scout":"sniper"}[role]
 if team=="red" and slot==0:preferred_role="shotgun"
 if team=="red" and slot==3:preferred_role="pistol"
 var by_role=candidates.filter(func(w):return w.category==preferred_role)
 if not by_role.is_empty():candidates=by_role
 var weapon=candidates[slot%candidates.size()] if not candidates.is_empty() else {}
 var sidearms=arsenal.values().filter(func(w):return w.category=="pistol" and rules.weapon_allowed(w.category,w.native.sourceKind) and w.itemId!=weapon.get("itemId",""))
 var knives=arsenal.values().filter(func(w):return w.category=="knife" and rules.weapon_allowed(w.category,w.native.sourceKind))
 var secondary=sidearms[index%sidearms.size()].itemId if not sidearms.is_empty() else ""
 var knife=knives[index%knives.size()].itemId if not knives.is_empty() else ""
 var claws=game.power_catalog.items.filter(func(item):return item.get("trail",{}).get("asset","")!="")
 var row={"clawId":str(claws[index%claws.size()].id) if not claws.is_empty() else "","secondaryId":secondary,"knifeId":knife,"id":id,"team":team,"slot":slot,"name":name,"characterId":character.get("id",""),"weaponId":weapon.get("itemId",""),"role":ROLES[index%4],"side":-1 if index%2==0 else 1}
 members[id]=row;return row
func weapon(game,team,slot):
 var row=identity(game,team,slot);return arsenal.get(row.weaponId,{})
