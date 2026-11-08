extends RefCounted
static func find(skeleton,socket,source_bones=[]):
	var exact=skeleton.find_bone(socket.boneName)
	if exact>=0:return exact
	# glTF/Godot disambiguates a bone whose name also belongs to a mesh.
	# Accept its source index only when the complete joint order/hierarchy
	# agrees, including the importer's numeric suffix for renamed nodes.
	if source_bones.size()!=skeleton.get_bone_count():return -1
	for i in range(source_bones.size()):
		var source=source_bones[i];var expected=-1 if source.parent==null else int(source.parent)
		if skeleton.get_bone_parent(i)!=expected:return -1
		var name=skeleton.get_bone_name(i);var original=str(source.name)
		if name!=original and not (name.begins_with(original+"_") and name.trim_prefix(original+"_").is_valid_int()):return -1
	return int(socket.bone)
