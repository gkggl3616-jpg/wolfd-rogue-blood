extends RefCounted
# A directory of real, local configurations. No remote users or rooms are fabricated.
const Store=preload("res://scripts/atomic_store.gd")
var rooms=[]
var next_id=1
var selected_id=0
var persistent=false
var storage_path="user://local-rooms.json"
var save_blocked=false
var last_error=""
func configure(path,enabled):
	storage_path=path;persistent=enabled
	if not persistent or not FileAccess.file_exists(path):return
	var result=Store.read_json(path)
	if not result.ok or not valid(result.data):save_blocked=true;last_error="Yerel oda kaydı okunamadı.";return
	rooms=result.data.rooms.map(normalized);next_id=int(result.data.nextId);selected_id=int(result.data.get("selectedId",0))
func normalized(source):
	var row=source.duplicate(true)
	for key in ["roomId","mode","map","capacity","allyBots","enemyBots","pointGoal","roundGoal","matchSeconds"]:
		if row.has(key):row[key]=int(row[key])
	return row

func valid(data):
	if data.get("schema")!=1 or not data.get("rooms") is Array or data.rooms.size()>100:return false
	var ids={};var highest=0
	for room in data.rooms:
		if not room is Dictionary or not room.get("title") is String or room.title.strip_edges().length()<2 or room.title.length()>64:return false
		var id=int(room.get("roomId",0))
		if id<1 or ids.has(id) or room.get("team") not in ["red","blue"] or not room.get("mode") is float and not room.get("mode") is int or not room.get("map") is float and not room.get("map") is int:return false
		if room.has("passwordEdit") or room.has("password"):return false
		if room.get("passwordDigest","")!="" and (str(room.passwordDigest).length()!=64 or str(room.get("passwordSalt","")).length()!=32):return false
		ids[id]=true;highest=maxi(highest,id)
	return int(data.get("nextId",0))>highest
func by_id(id):
	for room in rooms:
		if int(room.roomId)==int(id):return room.duplicate(true)
	return {}
func commit(candidate,create=false):
	last_error=""
	if rooms.size()>=100 and create:last_error="Yerel oda listesi dolu.";return {}
	var row=candidate.duplicate(true);var id=int(row.get("roomId",0));var following=next_id
	if create or by_id(id).is_empty():id=next_id;following+=1
	row.roomId=id
	if row.has("passwordEdit"):
		var password=str(row.passwordEdit)
		if password=="":row.erase("passwordDigest");row.erase("passwordSalt")
		else:
			row.passwordSalt=Crypto.new().generate_random_bytes(16).hex_encode();row.passwordDigest=(row.passwordSalt+"\n"+password).sha256_text()
	row.erase("passwordEdit");row.erase("password")
	var proposed=rooms.filter(func(existing):return int(existing.roomId)!=id);proposed.append(row)
	var payload={"schema":1,"rooms":proposed,"nextId":following,"selectedId":id}
	if not valid(payload):last_error="Oda bilgileri geçerli değil.";return {}
	if save_blocked or persistent and not Store.write_json(storage_path,payload):last_error="Oda kaydedilemedi; önceki oda korundu.";return {}
	rooms=proposed;next_id=following;selected_id=id;return row.duplicate(true)
func remember(room):
	if room.is_empty():return {}
	var previous=by_id(room.get("roomId",0))
	if previous==room:return previous
	return commit(room)
func accepts_password(id,password):
	var row=by_id(id)
	if row.is_empty():return false
	return row.get("passwordDigest","")=="" or (str(row.passwordSalt)+"\n"+str(password)).sha256_text()==row.passwordDigest
func population(room):
	var half=int(clampi(int(room.get("capacity",16)),2,16)/2)
	return 1+clampi(int(room.get("allyBots",0)),0,mini(4,half-1))+clampi(int(room.get("enemyBots",4)),0,mini(4,half))
