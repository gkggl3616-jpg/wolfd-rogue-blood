extends SceneTree
var checks=0
var failures=[]

func _initialize():call_deferred("run")
func check(value,label):
	checks+=1
	if not value:failures.append(label);push_error(label)
func frames(count=3):
	for i in range(count):await process_frame

func run():
	root.size=Vector2i(1280,720)
	var game=load("res://main.tscn").instantiate();game.test_mode=true;root.add_child(game);await frames()
	check(game.book.settings.directions,"New profiles use the four direction buttons requested for this update")
	game.start_round();game.spawn_clock=1000;await frames(10)
	check(game.touch.buttons.filter(func(button):return button.visible).all(func(button):return button.action in ["forward","backward","left","right"] or button.get_child(1).texture!=null),"Circular directions have arrow graphics and action controls have original item images")
	check(is_equal_approx(game.player.pivot.rotation.x,game.player.pitch),"First look cannot jump from an unapplied initial pitch")
	check(game.source_hud.slots.all(func(button):return button.flat and button.get_child(0).texture!=null),"Weapon belt uses actual equipped icons without generic text plates")
	check(game.source_hud.cross.is_visible_in_tree(),"Human aiming reticle is visible")
	var health_digits=game.source_hud.health_view.find_widget("HealthPoint")
	check(health_digits.is_visible_in_tree() and health_digits.modulate.r>health_digits.modulate.g,"Real HP remains visible through its transparent plate")
	game.player.switch_form();await frames(25)
	check(game.touch.buttons[0].get_child(1).texture==game.touch.icon_textures.wolf_fire,"Wolf attack switches from bullet to the source claw image")
	check(game.touch.buttons[3].get_child(1).texture==game.touch.icon_textures.roar,"Wolf reload control uses its actual roar action image")
	check(game.player.camera.position.x==0 and game.player.camera_arm.position.y>0.5,"Wolf camera centers the model and raises the swept arm")
	check(absf(game.player.camera.fov-70)<0.2,"Wolf projection reaches its calibrated field of view")
	check(not game.source_hud.cross.visible and game.source_hud.slots.all(func(button):return not button.visible),"Wolf view hides human reticle and weapon strip")
	var wall=game.block(game.player.global_position+Vector3(0,2.5,2),Vector3(4,5,0.25),"576371")
	await frames(8)
	check(game.player.camera_arm.get_hit_length()<3.3,"Raised third-person camera still retracts at an actual wall")
	wall.queue_free();game.player.switch_form();await frames(20)
	check(game.player.camera_arm.position.y==0 and not game.player.third_person,"Human form restores the arm origin and first person")
	game.player.position=Vector3(0,0.1,0);game.player.velocity=Vector3.ZERO;game.player.set_physics_process(false)
	game.spawn_enemy();var enemy=game.enemies.get_child(0);enemy.set_physics_process(false);enemy.position=Vector3(0,0.1,-1.6)
	await frames()
	game.player.action_time=0;game.player.shot_cooldown=0;game.attack()
	check(enemy.health<100 and game.source_hud.feedback.hit_time>0,"A real weapon hit triggers the source hit marker")
	var previous_health=enemy.health
	wall=game.block(Vector3(0,1.5,-0.8),Vector3(3,3,0.2),"576371");await frames()
	game.source_hud.feedback.reset();game.player.shot_cooldown=0;game.attack()
	check(enemy.health==previous_health and game.source_hud.feedback.hit_time==0,"A blocked shot cannot show a false hit marker")
	game.take_damage(8,Vector3(4,1,0))
	check(game.health==92 and game.source_hud.feedback.hurt_time>0 and game.source_hud.feedback.arrow.get_meta("has_direction"),"Real damage supplies feedback and its actual direction")
	game.menu_open=true;game.take_damage(8);await frames()
	check(game.health==92 and game.source_hud.feedback.hurt_time==0,"Menu blocks damage and clears combat overlays")
	game.menu_open=false;wall.queue_free()
	game.local_room={"mode":0,"map":84};check(game.start_round(),"Source-map match starts")
	game.spawn_clock=1000;await frames()
	var radar=game.source_hud.radar
	check(radar.visible and radar.current_number==84,"Radar follows the actual loaded source map")
	check(radar.records.size()==34,"Radar contains only the 34 selected maps")
	for row in radar.records:
		var resource=load(row.asset) as Texture2D
		check(resource!=null and row.originalPcRadar==false,"Radar image is explicitly a derived floor plan: "+str(row.number))
		var nav=game.map_catalog.offline_record(int(row.number))
		check(row.navigationSha256==nav.sha256,"Radar projection matches current navigation: "+str(row.number))
	var origin=radar.record.worldOrigin
	check(radar.projection(Vector3(origin[0],0,origin[1])).is_zero_approx(),"World origin maps to the image origin")
	var far=radar.projection(Vector3(origin[0]+radar.record.worldSize,0,origin[1]+radar.record.worldSize))
	check(far.is_equal_approx(radar.size),"World extent maps to the image extent")
	var point=radar.projection(game.player.position)
	check(point.x>=0 and point.y>=0 and point.x<=radar.size.x and point.y<=radar.size.y,"Actual source spawn projects inside its own radar")
	for dimensions in [Vector2i(1024,768),Vector2i(1920,1080),Vector2i(2160,992)]:
		root.size=dimensions;await frames()
		var viewport=game.get_viewport().get_visible_rect()
		check(viewport.encloses(game.source_hud.radar.get_global_rect()),"Radar remains inside display "+str(dimensions))
		for button in game.touch.buttons:
			if button.visible:check(viewport.has_point(button.position),"Active touch target stays on display")
	game.queue_free();await frames()
	print("GAMEPLAY_REFERENCE_QA ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
