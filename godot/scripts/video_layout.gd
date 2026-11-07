extends RefCounted
# Permanent reference: supplied PC recordings at 640x360. HUD coordinates are
# measured from video 1 (06:42) and video 4 (02:00), not ergonomic guesses.
const SIZE=Vector2(640,360)
const HUD={
 "health":["left",8,324],"sp_title":["right",72,319],"sp_value":["right",59,317],
 "weapon":["right",77,316],"weapon_name":["right",167.5,345.5],
 "score":["center",-98,2],"timer":["center",-27,31],
 "radar":["right",119,8],"map_name":["right",119,1],
 "feed":["right",192,115],"guide":["center",-175,321],
 "support":["left",74,335],"energy":["left",99,335],
 "awards":["right",225,230],"spectator":["center",-125,306],
 "own_name":["center",-172,2],"own_kills":["center",-143,18],
 "other_name":["center",105,2],"own_deaths":["center",134,18]
}
# PC recordings have no touch buttons. These mobile-only rows occupy the free
# margins between the measured HUD/feed/award regions; they never move the HUD.
const TOUCH={
 "fire":Vector2(.945,.824),"jump":Vector2(.875,.5556),"crouch":Vector2(.945,.5556),
 "reload":Vector2(.875,.824),"transform":Vector2(.805,.824),"sprint":Vector2(.105,.60),
 "aim":Vector2(.805,.5556),"roll":Vector2(.735,.824),"interact":Vector2(.735,.5556)
}
const MOVE=Vector2(.105,.75)
static func point(key,dimensions):
 var row=HUD[key];var units=dimensions/SIZE;var x=float(row[1])*units.x
 if row[0]=="right":x=dimensions.x-x
 elif row[0]=="center":x=dimensions.x*.5+x
 return Vector2(x,float(row[2])*units.y)
static func measure(value,dimensions):return value*dimensions/SIZE
