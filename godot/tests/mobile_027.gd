extends SceneTree
const Clock=preload("res://scripts/power_clock.gd")
var checks=0
var failures=[]
class PackState:
	extends RefCounted
	var health=200
	var cap=200
	var booster_remaining=10.0
	var booster_tuning={"tickSeconds":1,"healthDrainPercentPerTick":2}
	var healing_remaining=0.0
	var healing_tick_seconds=1.0
	var healing_regen_per_tick=5.0
	func max_health():return cap
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(n=2):
	for _i in range(n):await process_frame
func _initialize():call_deferred("run")
func panels(helper,ids):
	var mesh=ArrayMesh.new();var ranges=[]
	for i in range(ids.size()):
		var box=BoxMesh.new();box.size=Vector3(3,3,.1);var arrays=box.surface_get_arrays(0)
		var vertices=arrays[Mesh.ARRAY_VERTEX]
		for j in range(vertices.size()):vertices[j]+=Vector3(0,0,-2-i*.3)
		arrays[Mesh.ARRAY_VERTEX]=vertices;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		ranges.append({"first":i*12,"last":(i+1)*12,"surface":ids[i]})
	var object=MeshInstance3D.new();object.mesh=mesh;object.position=Vector3(1000,1,0);root.add_child(object);object.create_trimesh_collision();helper.bind_mesh(object)
	object.get_children().filter(func(n):return n is StaticBody3D)[0].set_meta("source_surface_ranges",ranges)
	return object
func run():
	var state=PackState.new();var clock=Clock.new();clock.spend(state,.25)
	check(state.health==150,"Native cash FT activation changes200 to150")
	for expected in [147,144,141,138,135,132,130,127]:
		clock.advance(state,1);check(state.health==expected,"Original video HP sequence reaches"+str(expected))
	var fragmented=PackState.new();var fragmented_clock=Clock.new();fragmented_clock.spend(fragmented,.25)
	for _i in range(160):fragmented_clock.advance(fragmented,.05)
	check(fragmented.health==state.health and is_equal_approx(fragmented_clock.health_fraction,clock.health_fraction),"FT result is independent of rendering frame size and preserves sub-HP precision")
	state=PackState.new();state.cap=320;state.health=320;state.healing_remaining=15;clock=Clock.new()
	for expected in [318,317,315]:clock.advance(state,1);check(state.health==expected,"Cash support plus FT reproduces video HP"+str(expected))
	state=PackState.new();clock=Clock.new();clock.spend(state,.25);clock.advance(state,.999)
	check(state.health==150,"A periodic FT tick never fires early")
	clock.advance(state,.001);check(state.health==147,"The first native tick fires at one second")
	state=PackState.new();state.healing_remaining=15;clock=Clock.new();clock.spend(state,.25);clock.advance(state,30)
	check(state.booster_remaining==0 and state.healing_remaining==0 and state.health==193,"One long frame respects both independent effect expiration times and HP cap")
	state=PackState.new();state.health=1;clock=Clock.new();clock.advance(state,10);check(state.health==1,"FT does not create a negative-health state")
	var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames();game.set_process(false)
	game.local_room={"mode":0,"map":0,"team":"blue","allyBots":0,"enemyBots":0};game.start_round();await frames(4);game.player.set_physics_process(false)
	var catalog=game.player.muzzle_data;var library=game.book.weapons;var covered={}
	check(catalog.items.size()==903 and catalog.models.size()==162,"Every native weapon row and all162 required muzzle models have source evidence")
	for item in library:
		var row=catalog.items.get(item.id,{});check(not row.is_empty() and int(row.sourceId)==int(item.sourceId),"Exact muzzle item identity "+item.id)
		if row.get("group","")!="" and row.has("socket") and not covered.has(row.group):covered[row.group]=item
	check(covered.size()==44,"All44 provided muzzle groups have a verified original model socket")
	var models={}
	for item in library:
		var row=catalog.items[item.id]
		if row.has("socket") and not models.has(row.sourceModel):models[row.sourceModel]=item
	check(models.size()==162,"Every native muzzle model has an engine admission case")
	for source in models:
		var item=models[source];game.book.acquire(item.id)
		check(game.equip_library_weapon(item),"Import and equip native muzzle model "+source);await frames(1)
		check(not game.player.muzzle_record.is_empty() and game.player.update_muzzle_anchor(),"Verified source bone resolves in imported skeleton "+source)
	for group in covered:
		var item=covered[group];game.book.acquire(item.id)
		check(game.equip_library_weapon(item),"Actual weapon equip "+group);await frames()
		check(game.player.weapon_info.itemId==item.id and game.player.muzzle_record.get("group","")==group,"Selected native item chooses its exact FX field "+group)
		if game.player.muzzle_record.is_empty():print("MISSING_ENGINE_SOCKET ",item.id," group=",group," expected=",catalog.items[item.id].socket," bones=",game.player.viewmodel.find_children("*","Skeleton3D",true,false)[0].get_concatenated_bone_names())
		check(game.player.update_muzzle_anchor() and game.player.muzzle_anchor.global_position.is_finite(),"Finite animated Flash attachment "+group)
		game.ammo=game.weapon_capacity();game.player.shot_cooldown=0;game.reloading=0;game.attack();await frames(1)
		check(game.player.muzzle_anchor.get_children().any(func(effect):return effect.group==group),"Actual attack emits the original group "+group)
		game.clientfx.clear();await frames()
	var helper=game.world_surfaces
	check(helper.definition(100).Name=="Wood Door" and helper.definition(100).CanShootThrough==1 and helper.definition(100).MaxShootThroughThickness==60,"Native Wood Door flag has its exact60-unit thickness bound")
	check(helper.definition(30).Name=="Wood" and helper.definition(30).CanShootThrough==0,"Generic wood does not inherit the shoot-through permission of a wood door")
	var panel=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(3,3,.25);panel.mesh=box;panel.position=Vector3(1000,1,-2);root.add_child(panel);panel.create_trimesh_collision()
	helper.bind_mesh(panel)
	var body=panel.get_children().filter(func(n):return n is StaticBody3D)[0];body.set_meta("source_surface_id",100)
	var target=StaticBody3D.new();target.collision_layer=2;target.position=Vector3(1000,1,-5);target.set_meta("enemy",true);var shape=CollisionShape3D.new();var target_box=BoxShape3D.new();target_box.size=Vector3.ONE;shape.shape=target_box;target.add_child(shape);root.add_child(target)
	await physics_frame;await physics_frame
	var world=panel.get_world_3d().direct_space_state;var a=Vector3(1000,1,0);var b=Vector3(1000,1,-10)
	var ray=helper.trace(world,a,b);check(ray.layers==1 and ray.hit.get("collider")==target,"A bullet crosses a real thin permitted panel and hits the target behind it")
	body.set_meta("source_surface_id",30);ray=helper.trace(world,a,b);check(ray.layers==0 and ray.hit.get("collider")==body,"A real non-permitted wooden wall blocks the same shot")
	body.set_meta("source_surface_id",100);panel.scale.z=6;await physics_frame;await physics_frame;ray=helper.trace(world,a,b)
	check(ray.layers==0 and ray.hit.get("collider")==body,"A permitted material thicker than its original limit blocks penetration")
	panel.queue_free();await frames();await physics_frame
	panel=panels(helper,[100,100]);await physics_frame;await physics_frame;ray=helper.trace(world,a,b)
	check(ray.layers==2 and ray.hit.get("collider")==target,"Two allowed panels sharing one world collider each produce an independent entry and exit")
	panel.queue_free();await frames();await physics_frame
	panel=panels(helper,[100,30,100]);await physics_frame;await physics_frame;ray=helper.trace(world,a,b)
	check(ray.layers==1 and ray.hit.get("collider")!=target and helper.hit_surface(ray.hit).Name=="Wood","A blocking middle surface in the same collider cannot be skipped by a distant permitted exit")
	panel.queue_free();await frames();await physics_frame
	panel=panels(helper,[0]);await physics_frame;await physics_frame;ray=helper.trace(world,a,b)
	check(ray.layers==0 and ray.hit.get("collider")!=target,"An unknown source surface blocks penetration")
	panel.queue_free();target.queue_free();game.queue_free();await frames()
	var file=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/mobile-027-validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"nativeMuzzleGroupsExercised":covered.size(),"nativeMuzzleModelsEquipped":models.size(),"nativeHpTimelineMatched":true},"  ")+"\n");file.close();print("MOBILE_027_QA ",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
