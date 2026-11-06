extends RefCounted

# Replace only after the complete UTF-8 payload has been flushed and read back.
# Never delete the previous save to make a rename succeed.
static func write_json(path: String, data: Dictionary) -> bool:
	var pending = path + ".pending"
	var payload = JSON.stringify(data)
	var file = FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK or FileAccess.get_file_as_string(pending) != payload:
		DirAccess.remove_absolute(pending)
		return false
	if DirAccess.rename_absolute(pending, path) != OK:
		DirAccess.remove_absolute(pending)
		return false
	return true

static func read_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": {}, "reason": "unreadable"}
	var parser = JSON.new()
	var error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {"ok": false, "data": {}, "reason": "invalid_json"}
	return {"ok": true, "data": parser.data, "reason": ""}
