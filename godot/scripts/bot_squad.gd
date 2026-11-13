extends RefCounted
# Local teamwork: reports contain observed positions, never unseen live poses.
var game
var clock=0.0
var contacts={}
var claims={}
func reset():clock=0;contacts.clear();claims.clear()
func advance(delta):
 clock+=delta
 for team in contacts.keys():
  if contacts[team].until<=clock or not game.actor_alive(contacts[team].target.get_ref()):contacts.erase(team)
 for key in claims.keys():
  if claims[key].until<=clock or not game.actor_alive(claims[key].actor.get_ref()):claims.erase(key)
func report(actor,target,point):
 contacts[actor.team]={"source":actor.roster_id,"target":weakref(target),"point":point,"until":clock+float(actor.profile.memory)}
func contact(actor):
 var row=contacts.get(actor.team,{})
 if row.is_empty() or row.source==actor.roster_id or row.until<=clock or not game.actor_alive(row.target.get_ref()):return {}
 return row
func available(actor,point):
 for claim in claims.values():
  if claim.team==actor.team and claim.id!=actor.roster_id and claim.until>clock and point.distance_to(claim.point)<1.6:return false
 return true
func reserve(actor,point,purpose):
 if not available(actor,point):return false
 claims[actor.roster_id+":"+purpose]={"id":actor.roster_id,"team":actor.team,"actor":weakref(actor),"point":point,"until":clock+(12.0 if purpose=="cover" else 4.0)};return true
func covering_fire(actor):
 for other in game.enemies.get_children():
  if other!=actor and game.actor_alive(other) and other.team==actor.team and other.sees_player and other.tactics!=null and clock-other.tactics.last_shot<1.4:return true
 return false
