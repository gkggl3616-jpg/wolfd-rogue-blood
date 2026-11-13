extends RefCounted
# Explicit offline balance and source field mappings live in the data file.
var rules=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/mobile-match.json"))
var streak=0
var streak_clock=0.0
var awards=[]
var earned=0
var spent=0
func begin():
 streak=0;streak_clock=0;awards.clear();earned=0;spent=0
 return int(rules.sp.start)
func advance(delta):
 streak_clock=maxf(0,streak_clock-delta)
 if streak_clock<=0:streak=0
 for row in awards:row.remaining=maxf(0,row.remaining-delta)
 awards=awards.filter(func(row):return row.remaining>0)
func death():streak=0;streak_clock=0
func reward(event):return int(rules.sp.rewards.get(event,0))
func award(balance,event,label=""):
 var cap=int(rules.sp.capacity);var next=mini(1000000000,balance+reward(event))
 if cap>0:next=mini(cap,next)
 var credited=maxi(0,next-balance)
 if credited>0:
  earned+=credited
  awards.push_front({"event":event,"label":label,"amount":credited,"remaining":3.0})
  if awards.size()>4:awards.resize(4)
 return next
func elimination(balance,headshot):
 streak=streak+1 if streak_clock>0 else 1;streak_clock=float(rules.sp.streakSeconds)
 balance=award(balance,"kill","Hedef etkisiz")
 if headshot:balance=award(balance,"headshot","Tam kafadan")
 if streak>=2:balance=award(balance,"streak"+str(mini(4,streak)),"Seri öldürme · %d" % streak)
 return balance
func loadout_cost(book,index):
 if index<0 or index>=book.loadouts.size():return 1000000000
 if index==0:return 0
 return int(rules.sp.nonstarterWeaponCost)*book.loadouts[index].values().filter(func(id):return id!="" and not book.default_owned.has(id)).size()
func mutation_cost(id):return int(rules.sp.mutationCosts.get(id,1000000000))
func yp_capacity(character,mutation,gear,equipment_bonus=0):
 var values=character.get("sourceStats",{}).get("wolf",{}).get("values",[])
 var character_bonus=float(values[3]) if values.size()>3 else 0.0
 var base=float(rules.yp.baseByMutation.get(mutation,rules.yp.baseByMutation.normal))
 return maxi(0,roundi(base*(1.0+(character_bonus+float(gear.get("healthPercent",0))+float(equipment_bonus))/100.0)))
func yp_decay():return float(rules.yp.decayPerSecond)
