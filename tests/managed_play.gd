extends SceneTree
var failures:=0
var game:Node
const SOLO=[{"index":0,"occupant":{"kind":"local","player_id":"p1"},"controller":"pad"}]
const PLAYERS=[{"id":"p1","name":"Probe"}]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func frame(buttons:int)->void:
	game.bridge.frames={"pad":{"controller":"pad","buttons":buttons,"axes":[0,0,0,0,0,0]}}
	game.bridge.frame_at=Time.get_ticks_msec();game._process(0.016)
func run()->void:
	OS.set_environment("GAMENIGHT","0")
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	game.headless=true # Keep display ownership local to this isolated test.
	game.bridge.launched_by_daemon=true;game.bridge.set_process(false)
	game.selected_mode="versus"
	await game.prepare("solo",SOLO,PLAYERS)
	check(game.roster.size()==2 and game.roster[1].bot,"Solo versus gets an AI opponent")
	check(game.roster[0].id=="p1" and game.roster[0].controller=="pad","Host player and input identity are preserved")
	game.bridge.phase="running";game.start_managed("solo")
	frame(128);check(not game.in_menu,"Start held across launch must first be released")
	frame(0);frame(128)
	check(game.in_menu and game.paused_local and game.hud.menu.get_child_count()==3,"Host Start opens managed pause menu")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture=") and DisplayServer.get_name()!="headless":
			root.size=Vector2i(960,540)
			for i in 8:await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	var clock:float=game.sim.clock
	game._physics_process(.1);check(game.sim.clock==clock,"Pause menu freezes simulation")
	frame(128);check(game.in_menu,"Held Start does not resume")
	frame(0);frame(128);check(not game.in_menu and not game.paused_local,"Fresh Start resumes same match")
	frame(0);frame(128);frame(0);frame(8192)
	check(game.hud.menu_row==1,"Host D-pad navigates managed menu")
	var old:RefCounted=game.sim
	frame(0);frame(1)
	check(game.sim!=old and not game.in_menu and game.roster[0].controller=="pad","New round keeps the host roster")
	game.bridge.phase="paused";game.pause_managed("solo");frame(0);frame(128)
	check(not game.in_menu and not game.running,"Host pause cannot be reopened by stale Start")
	game.selected_mode="survival"
	await game.prepare("survival",SOLO,PLAYERS)
	check(game.roster.size()==1 and game.sim.mode=="survival","Survival keeps only the human team")
	game.sim.countdown=0;game.running=true;game.in_menu=false
	for i in 30:game.sim.step(.1,[{}])
	check(not game.sim.enemies.is_empty(),"Solo survival spawns enemies")
	game.selected_mode="versus"
	var pair:Array=SOLO.duplicate(true)
	pair.append({"index":1,"occupant":{"kind":"ai"},"controller":""})
	await game.prepare("pair",pair,PLAYERS)
	check(game.roster.size()==2,"Explicit host AI seats are not duplicated")
	game.free()
	print("MANAGED_PLAY_", "PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
