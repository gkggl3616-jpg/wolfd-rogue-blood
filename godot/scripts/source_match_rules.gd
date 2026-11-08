extends RefCounted
# The selected source mode supplies forms, score choices and time choices.
# Respawn delay and bot population remain explicit mobile simulation settings.
const SUPPORTED=[1000,1001,1010,1020,1021,1022,1023,1024,1025,1026,3000,3001,3020,3021]
const WEAPON_KINDS={"pistol":2,"knife":4,"rifle":8,"smg":16,"sniper":32,"shotgun":64,"machinegun":128,"heavy":256,"rocket":512,"launcher":1024,"minigun":2048,"grenade":4096}
var enabled=false
var round_based=false
var record={}
var goal=10
var seconds=90
var form_lock="mixed"
var winner=""
static func supports(mode):return int(mode) in SUPPORTED
func configure(room):
	round_based=int(room.get("mode",0)) in [3000,3001,3020,3021]
	enabled=supports(room.get("mode",0));winner="";goal=10;seconds=90;form_lock="mixed";record={}
	if not enabled:return
	record=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/source.json")).modes[str(int(room.mode))]
	var default_goal=record.goals.filter(func(r):return r.default);var default_time=record.times.filter(func(r):return r.default)
	goal=int(default_goal[0].points) if not default_goal.is_empty() else int(record.goals[0].points)
	seconds=int(default_time[0].seconds) if not default_time.is_empty() else int(record.times[0].seconds)
	if record.goals.any(func(r):return int(r.points)==int(room.get("pointGoal",-1))):goal=int(room.pointGoal)
	if record.times.any(func(r):return int(r.seconds)==int(room.get("matchSeconds",-1))):seconds=int(room.matchSeconds)
	if round_based:
		goal=int(default_goal[0].rounds) if not default_goal.is_empty() else 5
		if record.goals.any(func(r):return int(r.rounds)==int(room.get("roundGoal",-1))):goal=int(room.roundGoal)
	form_lock="human" if int(record.redForm)==3 else ("wolf" if int(record.redForm)==4 else "mixed")
func weapon_allowed(category,source_kind=0):
	if not enabled:return true
	if form_lock=="wolf":return false
	var mask=int(record.sourceFlags[9])|(int(record.sourceFlags[10])<<8)
	return (mask&(int(source_kind) if source_kind>0 else int(WEAPON_KINDS.get(category,0))))!=0
func preferred_categories():
	match int(record.get("id",0)):
		1022:return ["grenade","knife"]
		1023:return ["knife"]
		1024:return ["pistol","knife","grenade"]
		1025:return ["sniper","pistol","knife","grenade"]
		1026:return ["heavy","rocket","launcher","grenade","knife"]
	return ["rifle","smg","shotgun","machinegun","sniper","pistol","knife","grenade"]
func title():
	if int(record.get("id",0)) in [1022,1023,1024,1025,1026]:return {1022:"Bomba",1023:"Bıçak",1024:"Tabanca",1025:"Keskin Nişancı",1026:"Ağır Silah"}[int(record.id)]
	return "Ölüm Oyunu (Kurt Savaşı)" if form_lock=="wolf" else ("Ölüm Oyunu (İnsan)" if form_lock=="human" else "Ölüm Oyunu")
func decide(red,blue):winner="red" if red>blue else ("blue" if blue>red else "draw");return winner
