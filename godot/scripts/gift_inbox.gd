extends RefCounted
const LIFETIME=7*86400
var state={"sequence":0,"messages":[],"powerCounts":{},"powerSlots":{},"entitlements":{},"welcome":false}
func valid(data):
	if not data is Dictionary:return false
	for key in ["powerCounts","powerSlots","entitlements"]:
		if not data.get(key) is Dictionary:return false
	if not data.get("messages") is Array or data.messages.size()>256:return false
	if not (data.get("sequence") is int or data.get("sequence") is float) or not is_finite(float(data.sequence)) or data.sequence<0 or data.sequence!=int(data.sequence):return false
	var ids={};var sources={}
	if not data.get("welcome",false) is bool:return false
	for slot in data.powerSlots:
		if slot not in ["support","energy","bag","claw"] or not data.powerSlots[slot] is String:return false
	for value in data.entitlements.values():
		if value!=true:return false
	for message in data.messages:
		if not message is Dictionary or not message.get("id") is String or ids.has(message.id):return false
		ids[message.id]=true
		if message.get("kind","") not in ["cash","box","power","weapon","character","tattoo"] or message.get("status","") not in ["pending","accepted"]:return false
		for key in ["created","expires","amount"]:
			var value=message.get(key)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0:return false
		if message.amount<1 or message.amount!=int(message.amount) or message.amount>1000000:return false
		if message.expires<message.created:return false
		for key in ["item","name","sourceKey","sender"]:
			if not message.get(key) is String:return false
		if message.sourceKey.is_empty() or sources.has(message.sourceKey):return false
		sources[message.sourceKey]=true
	for count in data.powerCounts.values():
		if not (count is int or count is float) or not is_finite(float(count)) or count<0 or count!=int(count) or count>999999:return false
	return true
func enqueue(candidate,kind,item,name,amount,source_key,sender="Sistem"):
	if kind not in ["cash","box","power","weapon","character","tattoo"] or amount<1 or amount!=int(amount) or amount>1000000 or source_key.is_empty():return {}
	for message in candidate.messages:
		if message.sourceKey==source_key:return message
	if candidate.messages.size()>=256:
		var disposable=candidate.messages.filter(func(row):return row.status=="accepted" or row.expires<Time.get_unix_time_from_system())
		if disposable.is_empty():return {}
		candidate.messages.erase(disposable[0])
	candidate.sequence+=1
	var now=Time.get_unix_time_from_system()
	var message={"id":"gift-%d" % int(candidate.sequence),"kind":kind,"item":item,"name":name,"amount":amount,"sourceKey":source_key,"sender":sender,"created":now,"expires":now+LIFETIME,"status":"pending"}
	candidate.messages.append(message);return message
func pending_count():return state.messages.filter(func(row):return row.status=="pending" and row.expires>=Time.get_unix_time_from_system()).size()
