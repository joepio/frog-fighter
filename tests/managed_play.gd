extends SceneTree
var failures:=0
var checks:=0
var game:Node
const SOLO=[{"index":0,"occupant":{"kind":"local","player_id":"p1"},"controller":"pad"}]
const PLAYERS=[{"id":"p1","name":"Probe"}]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frame(buttons:int,stick:Vector2=Vector2.ZERO)->void:
	game.bridge.frames={"pad":{"controller":"pad","buttons":buttons,"axes":[int(stick.x*32767),int(stick.y*32767),0,0,0,0]}}
	game.bridge.frame_at=Time.get_ticks_msec();game._process(0.016)
func tap(buttons:int)->void:
	frame(0);frame(buttons);frame(0)
func settle()->void:
	for i in 300:
		frame(0)
		if not game.preparing and not game.restart_pending:return
		await process_frame
	check(false,"Selected map finishes preparing within 300 frames")
func capture(suffix:String)->void:
	if DisplayServer.get_name()=="headless":return
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--capture="):continue
		var path:=arg.trim_prefix("--capture=").get_basename()+suffix+".png"
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		root.size=Vector2i(1600,900);root.mode=Window.MODE_WINDOWED;root.show()
		for i in 8:await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(path)
func run()->void:
	OS.set_environment("GAMENIGHT","0")
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.capture_path="" # This test owns its multi-step captures, not main's auto-quit.
	game.set_process(false);game.set_physics_process(false)
	game.headless=true # Keep display ownership local to this isolated test.
	game.bridge.launched_by_daemon=true;game.bridge.set_process(false)
	game.selected_mode="versus"
	game.selected_arena="terrarium"
	await game.prepare("solo",SOLO,PLAYERS)
	check(game.roster.size()==2 and game.roster[1].bot,"Solo versus gets an AI opponent")
	check(game.roster[0].id=="p1" and game.roster[0].controller=="pad","Host player and input identity are preserved")
	game.bridge.phase="running";game.start_managed("solo")
	frame(128);check(not game.in_menu,"Start held across launch must first be released")
	frame(0);frame(128)
	check(game.in_menu and game.paused_local and game.hud.menu.get_child_count()==6,"Host Start opens settings and round actions")
	var clock:float=game.sim.clock
	game._physics_process(.1);check(game.sim.clock==clock,"Pause menu freezes simulation")
	frame(128);check(game.in_menu,"Held Start does not resume")
	frame(0);frame(128);check(not game.in_menu and not game.paused_local,"Fresh Start resumes same match")
	frame(0);frame(128);frame(0);frame(8192)
	check(game.hud.menu_row==1,"Host D-pad navigates managed menu")
	var old:RefCounted=game.sim
	tap(32768)
	check(game.selected_arena=="vineway" and game.settings.values.arena=="vineway","Host D-pad right changes selected map")
	tap(16384)
	check(game.selected_arena=="terrarium","Host D-pad left changes selected map back")
	frame(0,Vector2.RIGHT);frame(0,Vector2.RIGHT)
	check(game.selected_arena=="vineway","Held analog direction changes once before repeat delay")
	frame(0);tap(8192);tap(32768)
	check(game.selected_mode=="survival","Mode is controller-editable")
	tap(8192);tap(32768)
	check(game.round_lives==4 and game.settings.values.lives==4,"Lives use the shared setting value")
	check(game.sim==old and old.arena_id=="terrarium" and old.mode=="versus","Paused selections do not replace current match")
	await capture("-settings")
	tap(128)
	check(game.sim==old and not game.in_menu and game.hud.menu==null,"Start resumes current map despite pending selections")
	# Reproduce A + held navigation in the exact frame Resume closes the menu.
	tap(128);frame(0);frame(1|8192,Vector2.DOWN)
	game.hud.menu_move(Vector2i.DOWN);game.hud.make_menu()
	check(not game.in_menu and not game.paused_local and game.hud.menu==null,"Held navigation and delayed rebuild cannot resurrect closed menu")
	await capture("-resumed")
	tap(128)
	for i in 4:tap(8192)
	check(game.hud.menu_row==4,"D-pad reaches Start new round")
	tap(1)
	check(game.hud.menu==null,"New round immediately removes all menu controls")
	await settle()
	check(game.sim!=old and not game.in_menu and not game.paused_local and not game.restart_pending,"Map transition finishes and unpauses")
	check(game.sim.arena_id=="vineway" and game.sim.mode=="survival" and game.sim.frogs[0].lives==4,"New round applies selected map mode and lives")
	check(game.roster.size()==1 and game.roster[0].controller=="pad","Survival removes only generated solo opponent and keeps host identity")
	await capture("-new-round")
	for i in 3:
		tap(128);frame(0);frame(1|8192)
		check(game.hud.menu==null and not game.in_menu,"Repeated Resume has no orphan controls")
	for i in 3:
		tap(128)
		for row in 4:tap(8192)
		old=game.sim;tap(1);await settle()
		check(game.sim!=old and not game.paused_local and game.hud.menu==null,"Repeated New round closes and resumes reliably")
	# Host pause can interrupt an unfinished map build without a delayed restart.
	tap(128);game.setting_changed("arena","grotto");game.hud.menu_row=4
	old=game.sim;tap(1)
	check(game.restart_pending and game.preparing,"Cold map starts an incremental transition")
	game.bridge.phase="paused";game.pause_managed("solo");await settle()
	check(game.sim==old and not game.running and not game.restart_pending and game.hud.menu==null,"Host pause cancels pending restart without resurrecting menu")
	game.bridge.phase="running";game.start_managed("solo");frame(0)
	tap(128)
	game.bridge.phase="paused";game.pause_managed("solo")
	check(game.hud.menu==null and not game.paused_local,"Host pause clears the local menu")
	game.bridge.phase="running";game.start_managed("solo")
	check(not game.in_menu and game.hud.menu==null,"Host resume starts with menu closed")
	# Back remains the release-gated host action even with the Start menu open.
	frame(0);tap(128);frame(0);frame(64)
	check(game.back_release==0,"Back still sends the host overlay request from the menu")
	frame(64);check(game.back_release==0,"Held Back cannot retrigger the host action")
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
	game.discard_prepared()
	while game.preparing:await process_frame
	game.free()
	print("MANAGED_PLAY_", "PASS" if failures==0 else "FAIL", " ",checks," checks")
	quit(0 if failures==0 else 1)
