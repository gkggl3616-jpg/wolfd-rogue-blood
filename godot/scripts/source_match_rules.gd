extends RefCounted
# The selected source mode supplies forms, score choices and time choices.
# Respawn delay and bot population remain explicit mobile simulation settings.
const SUPPORTED=[1000,1001,1010,1020,1021]
var enabled=false
var record={}
var goal=10
var seconds=90
var form_lock="mixed"
var winner=""
static func supports(mode):return int(mode) in SUPPORTED
func configure(room):
	enabled=supports(room.get("mode",0));winner="";goal=10;seconds=90;form_lock="mixed";record={}
	if not enabled:return
	record=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/source.json")).modes[str(int(room.mode))]
	var default_goal=record.goals.filter(func(r):return r.default);var default_time=record.times.filter(func(r):return r.default)
	goal=int(default_goal[0].points) if not default_goal.is_empty() else int(record.goals[0].points)
	seconds=int(default_time[0].seconds) if not default_time.is_empty() else int(record.times[0].seconds)
	if record.goals.any(func(r):return int(r.points)==int(room.get("pointGoal",-1))):goal=int(room.pointGoal)
	if record.times.any(func(r):return int(r.seconds)==int(room.get("matchSeconds",-1))):seconds=int(room.matchSeconds)
	form_lock="human" if int(record.redForm)==3 else ("wolf" if int(record.redForm)==4 else "mixed")
func weapon_allowed(category):
	if not enabled:return true
	if form_lock=="wolf":return false
	return not (int(record.id) in [1000,1020] and category in ["rocket","launcher","heavy","minigun"])
func title():return "Ölüm Oyunu (Kurt Savaşı)" if form_lock=="wolf" else ("Ölüm Oyunu (İnsan)" if form_lock=="human" else "Ölüm Oyunu")
func decide(red,blue):winner="red" if red>blue else ("blue" if blue>red else "draw");return winner
