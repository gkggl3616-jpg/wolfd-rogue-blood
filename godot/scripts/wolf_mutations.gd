extends RefCounted
# Local combat balance. The geometry, skins and animation donors are PC assets.
const TYPES={
 "normal":{"name":"Normal Kurt","health":100,"speed":6.0,"damage":45,"guard":false,"cloak":false,"bars":[2,2,2,2]},
 "power":{"name":"Güç Kurt","health":130,"speed":5.7,"damage":60,"guard":false,"cloak":false,"bars":[4,3,3,2]},
 "guardian":{"name":"Gardiyan Kurt","health":180,"speed":4.4,"damage":40,"guard":true,"cloak":false,"bars":[5,5,2,1]},
 "ghost":{"name":"Hayalet Kurt","health":85,"speed":6.8,"damage":35,"guard":false,"cloak":true,"bars":[2,2,2,4]}}
var catalog={}
func _init():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mutations/catalog.json"))
func profile(id):return TYPES.get(id,TYPES.normal)
func model(id,team):
	for row in catalog.models:
		if row.id==id and row.team==team:return row
	return {}
