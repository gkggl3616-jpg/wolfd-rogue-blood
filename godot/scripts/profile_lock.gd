extends RefCounted
const Store=preload("res://scripts/atomic_store.gd")
var path="user://profile-lock.json"
var persistent=true
var record={}
var unlocked=true
var blocked=false
var attempts=0
var retry_at=0

func _init(enabled=true,save_path="user://profile-lock.json"):
	persistent=enabled;path=save_path
	if persistent and FileAccess.file_exists(path):
		var result=Store.read_json(path);record=result.data
		blocked=not result.ok or record.get("version")!=1 or not record.get("enabled") is bool
		if record.get("enabled",false):
			blocked=blocked or not record.get("salt","") is String or str(record.get("salt","")).length()!=32 or not record.get("digest","") is String or str(record.get("digest","")).length()!=64
	unlocked=not blocked and not is_enabled()

func is_enabled():return record.get("enabled",false)==true
func valid_pin(value):
	if not value is String or value.length()!=4:return false
	for digit in value:
		if digit not in "0123456789":return false
	return true
func digest(pin,salt):
	var value=salt+":"+pin
	for i in range(12000):value=(salt+value).sha256_text()
	return value
func verify(pin):
	if blocked or not valid_pin(pin) or Time.get_ticks_msec()<retry_at:return false
	if is_enabled() and digest(pin,record.salt)==record.digest:
		attempts=0;unlocked=true;return true
	attempts+=1
	if attempts>=5:retry_at=Time.get_ticks_msec()+30000;attempts=0
	return false
func configure(pin,current=""):
	if blocked or not valid_pin(pin):return false
	if is_enabled() and not verify(current):return false
	var salt=Crypto.new().generate_random_bytes(16).hex_encode()
	var candidate={"version":1,"enabled":true,"salt":salt,"digest":digest(pin,salt)}
	if persistent and not Store.write_json(path,candidate):return false
	record=candidate;unlocked=true;return true
func disable(current):
	if blocked or not verify(current):return false
	var candidate={"version":1,"enabled":false}
	if persistent and not Store.write_json(path,candidate):return false
	record=candidate;unlocked=true;return true
