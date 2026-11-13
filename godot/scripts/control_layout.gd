extends RefCounted
const ACTIONS=["fire","jump","crouch","reload","transform","sprint","aim","forward","backward","left","right","roll","support","energy","slot_primary","slot_pistol","slot_knife","slot_grenade","menu","inventory","scoreboard","interact"]
static func valid(data):
 if not data is Dictionary or data.size()>ACTIONS.size():return false
 for key in data:
  var row=data[key]
  if not key in ACTIONS or not row is Array or row.size()!=3:return false
  for value in row:
   if not (value is float or value is int) or not is_finite(float(value)):return false
  if row[0]<0 or row[0]>1 or row[1]<0 or row[1]>1 or row[2]<0.6 or row[2]>2:return false
 return true
static func scale_for(data,key):return float(data.get(key,[0,0,1])[2])
static func center(data,key,base,dimensions,radius):
 var row=data.get(key);var at=Vector2(row[0],row[1])*dimensions if row!=null else base
 return at.clamp(Vector2.ONE*radius,dimensions-Vector2.ONE*radius)
