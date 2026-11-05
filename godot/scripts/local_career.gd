extends RefCounted
const MISSIONS=[
 {"id":"first","name":"Bir yerel maçı tamamla","stat":"matches","goal":1,"cash":100},
 {"id":"targets","name":"5 rakibi yen","stat":"kills","goal":5,"cash":150},
 {"id":"headshots","name":"3 kafadan isabet yap","stat":"headshots","goal":3,"cash":150},
 {"id":"hunt","name":"3 Kurt Avı raundu kazan","stat":"huntWins","goal":3,"cash":200},
 {"id":"tutorial","name":"Öğreticiyi tamamla","stat":"tutorials","goal":1,"cash":100}]
var state={"totals":{"matches":0,"kills":0,"headshots":0,"huntWins":0,"tutorials":0},"claimed":{},"matches":[]}
func valid(data):
	if not data is Dictionary or not data.get("totals") is Dictionary or not data.get("claimed") is Dictionary or not data.get("matches") is Array:return false
	for key in state.totals:
		var number=data.totals.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number!=int(number) or number>1000000000:return false
	if data.matches.size()>32:return false
	for id in data.matches:
		if not id is String:return false
	for id in data.claimed:
		if not id is String or data.claimed[id]!=true:return false
	return true
func result(id,kills,headshots,hunt_wins,tutorial):
	if id.is_empty() or id in state.matches:return state.duplicate(true)
	var next=state.duplicate(true);next.matches.append(id)
	if next.matches.size()>32:next.matches.pop_front()
	next.totals.matches+=1;next.totals.kills+=maxi(0,kills);next.totals.headshots+=maxi(0,headshots);next.totals.huntWins+=maxi(0,hunt_wins)
	if tutorial:next.totals.tutorials+=1
	return next
func claim(id,wallet):
	if state.claimed.get(id,false):return {"ok":false,"error":"Bu ödül zaten alındı."}
	var cash=0
	for mission in MISSIONS:
		if id==mission.id and int(state.totals[mission.stat])>=int(mission.goal):cash=int(mission.cash)
	if id.begins_with("pass-"):
		var suffix=id.trim_prefix("pass-")
		if not suffix.is_valid_int():return {"ok":false,"error":"Geçersiz seviye."}
		var level=suffix.to_int()
		if level>=1 and level<=10 and int(wallet.gp)>=level*100:cash=50+level*5
	if cash<=0:return {"ok":false,"error":"Ödül koşulu henüz tamamlanmadı."}
	var next=state.duplicate(true);var balance=wallet.duplicate();next.claimed[id]=true;balance.cash=mini(1000000000,int(balance.cash)+cash)
	return {"ok":true,"state":next,"wallet":balance,"rewardCash":cash}
