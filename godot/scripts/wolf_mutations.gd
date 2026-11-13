extends RefCounted
# Normal wolf HP=240 is the user's PC reference. Other mutation HP deltas,
# speed and damage remain offline balance, not decoded PC statistics.
const HUMAN_HEALTH=100
const TYPES={
 "normal":{"name":"Normal Kurt","health":240,"speed":6.0,"damage":45,"guard":false,"cloak":false,"bars":[2,2,2,2]},
 "power":{"name":"Güç Kurt","health":270,"speed":5.7,"damage":60,"guard":false,"cloak":false,"bars":[4,3,3,2]},
 "guardian":{"name":"Gardiyan Kurt","health":320,"speed":4.4,"damage":40,"guard":true,"cloak":false,"bars":[5,5,2,1]},
 "ghost":{"name":"Hayalet Kurt","health":225,"speed":6.8,"damage":35,"guard":false,"cloak":true,"bars":[2,2,2,4]}}
var catalog={}
func _init():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mutations/catalog.json"))
func profile(id):return TYPES.get(id,TYPES.normal)
func model(id,team):
	for row in catalog.models:
		if row.id==id and row.team==team:return row
	return {}
