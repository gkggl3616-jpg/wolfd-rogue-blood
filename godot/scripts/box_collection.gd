extends RefCounted
# Explicit offline collection rules; PC/server prices and drop rates are unknown.
var catalog={}
var state={"counts":{},"history":[],"requests":[],"serial":0}
func _init():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/boxes.json"))
func box(id):
	for entry in catalog.boxes:
		if entry.id==id:return entry
	return {}
func valid_state(data):
	if not data is Dictionary or not data.get("counts") is Dictionary or not data.get("history") is Array or not data.get("requests") is Array:return false
	if not data.get("serial") is float and not data.get("serial") is int:return false
	if not is_finite(float(data.serial)) or float(data.serial)!=int(data.serial) or data.serial<0 or data.serial>1000000000:return false
	for id in data.counts:
		var count=data.counts[id]
		if box(id).is_empty() or not (count is float or count is int) or count!=int(count) or count<0 or count>999:return false
	if data.history.size()>64 or data.requests.size()>64:return false
	for entry in data.history:
		if not entry is Dictionary or not entry.get("rewardId") is String or not entry.get("boxId") is String or box(entry.boxId).is_empty():return false
		var matches=box(entry.boxId).rewards.filter(func(row):return row.id==entry.rewardId)
		if matches.size()!=1:return false
		for key in ["name","texture","role"]:
			if entry.get(key)!=matches[0][key]:return false
		if not entry.get("serial") is float and not entry.get("serial") is int:return false
		if entry.serial<1 or entry.serial>data.serial or entry.serial!=int(entry.serial):return false
	for request in data.requests:
		if not request is String:return false
	return true
func prepare(action,id,request,wallet):
	var entry=box(id)
	if entry.is_empty() or not request is String or request.is_empty() or request.length()>128:return {"ok":false,"error":"Geçersiz kutu işlemi."}
	if request in state.requests:return {"ok":true,"duplicate":true}
	var candidate=state.duplicate(true);var balance=wallet.duplicate();var count=int(candidate.counts.get(id,0));var reward={}
	if action=="buy":
		if balance.cash<int(entry.localPrice) or count>=999:return {"ok":false,"error":"Yerel nakit yetersiz veya kutu sınırı dolu."}
		balance.cash-=int(entry.localPrice);candidate.counts[id]=count+1
	elif action=="open":
		if count<1:return {"ok":false,"error":"Bu kutudan kalmadı."}
		candidate.counts[id]=count-1;candidate.serial+=1
		var random=RandomNumberGenerator.new();random.randomize()
		var item=entry.rewards[random.randi_range(0,entry.rewards.size()-1)]
		reward={"serial":candidate.serial,"boxId":id,"rewardId":item.id,"name":item.name,"texture":item.texture,"role":item.role,"utc":Time.get_unix_time_from_system()}
		candidate.history.push_front(reward)
		if candidate.history.size()>64:candidate.history.resize(64)
	else:return {"ok":false,"error":"Geçersiz kutu işlemi."}
	candidate.requests.append(request)
	if candidate.requests.size()>64:candidate.requests.pop_front()
	return {"ok":true,"duplicate":false,"state":candidate,"wallet":balance,"reward":reward}
