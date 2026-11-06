extends RefCounted
var catalog={}
func _init():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/ranks.json"))
func current(gp):
	var found=catalog.ranks[0]
	for row in catalog.ranks:
		if int(row.localMinimumGp)>gp:break
		found=row
	return found
func next(gp):
	for row in catalog.ranks:
		if int(row.localMinimumGp)>gp:return row
	return {}
