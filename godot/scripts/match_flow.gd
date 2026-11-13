extends RefCounted
# Local room countdown, actual resource loading and initial preparation are
# separate states. No fabricated network readiness or percentage is displayed.
var game
var phase=""
var countdown=0.0
var ready_left=0.0
var start_flash=0.0
var room_snapshot={}
var owner_ui
var loading_path=""
var loaded_resource
var loading_frames=0
var last_countdown=-1
func starting():return phase in ["countdown","loading"]
func preparing():return ready_left>0
func request_start(ui):
	if not is_instance_valid(ui) or game.running or starting() or game.local_room.is_empty() or not game.is_local_mode(int(game.local_room.get("mode",-1))):return false
	var number=int(game.local_room.get("map",0));var mode=int(game.local_room.get("mode",0))
	if (number!=0 and game.map_catalog.offline_record(number).is_empty()) or (preload("res://scripts/source_match_rules.gd").supports(mode) and not game.map_catalog.belongs_to_mode(mode,number)):
		ui.show_error("Seçilen harita bu maç için hazır değil.");return false
	owner_ui=ui;room_snapshot=game.local_room.duplicate(true);phase="countdown";countdown=3.5;last_countdown=-1;play_countdown_step();ui.refresh();return true
func play_countdown_step():
	var number=clampi(ceili(maxf(0,countdown-.5)),0,3)
	if number==last_countdown:return
	last_countdown=number;game.game_audio.room_countdown(number)
func cancel_start():
	var panel=owner_ui
	game.game_audio.stop_room_countdown();last_countdown=-1
	phase="";countdown=0;loading_frames=0;loaded_resource=null;loading_path="";room_snapshot.clear();owner_ui=null
	if is_instance_valid(panel) and not panel.is_queued_for_deletion():panel.page="room";panel.refresh()
func reset_match():ready_left=0;start_flash=0
func prepare():ready_left=10.0;start_flash=0
func signal_start():ready_left=0;start_flash=1.2;game.game_audio.match_sound("round_start")
func advance_match(delta):
	if not game.running or game.menu_open or game.application_suspended:return
	start_flash=maxf(0,start_flash-delta)
	if ready_left<=0:return
	ready_left=maxf(0,ready_left-delta)
	if ready_left<=0:game.finish_round_selection();signal_start()
func advance_start(delta):
	if not starting() or game.application_suspended:return
	if not is_instance_valid(owner_ui) or owner_ui.is_queued_for_deletion() or game.local_room!=room_snapshot:
		cancel_start();return
	if phase=="countdown":
		countdown=maxf(0,countdown-delta)
		play_countdown_step()
		if countdown>0:return
		phase="loading";loading_frames=0
		var number=int(room_snapshot.get("map",0))
		if number!=0:
			loading_path=game.map_catalog.offline_record(number).get("previewAsset","")
			if loading_path=="" or ResourceLoader.load_threaded_request(loading_path,"PackedScene")!=OK:
				fail("Harita yüklemesi başlatılamadı.");return
		owner_ui.navigate("loading",false);return
	loading_frames+=1
	if loading_frames<2:return # Give the actual loading view a rendered frame.
	if loading_path!="":
		var status=ResourceLoader.load_threaded_get_status(loading_path)
		if status==ResourceLoader.THREAD_LOAD_IN_PROGRESS:return
		if status!=ResourceLoader.THREAD_LOAD_LOADED:fail("Harita yüklenemedi.");return
		loaded_resource=ResourceLoader.load_threaded_get(loading_path)
	var panel=owner_ui
	phase="";owner_ui=null;room_snapshot.clear()
	var success=game.start_round(true)
	loaded_resource=null;loading_path=""
	if not success and is_instance_valid(panel):panel.navigate("room",false);panel.show_error("Maç başlatılamadı; oda ayarları korundu.")
func fail(message):
	var panel=owner_ui;cancel_start()
	if is_instance_valid(panel):panel.show_error(message)
func loading_art():
	var record=game.map_catalog.map_record(int(room_snapshot.get("map",0)))
	# Exact source display-name identity only; unresolved names keep the source
	# loading background rather than borrowing another map's artwork.
	var stem=str(record.get("displayName","")).to_lower().replace(" ","_")
	var key="wt_interface/loading/ld_map_"+stem+".dtx"
	return key if preload("res://ui/source_theme.gd").texture(key)!=null else "wt_interface/all/loading_bg.dtx"
