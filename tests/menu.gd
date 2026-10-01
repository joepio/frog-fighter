extends SceneTree
var failures:=0
var checks:=0

func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)

func _initialize()->void:call_deferred("run")

func run()->void:
	var config_path:="user://pond.cfg"
	var previous:String=FileAccess.get_file_as_string(config_path) if FileAccess.file_exists(config_path) else ""
	var game:Node=load("res://main.tscn").instantiate();root.add_child(game)
	await process_frame
	check(game.in_menu and game.hud.menu.visible,"Standalone starts at menu")
	game.select_mode("survival");game.human_count=2;game.start_local()
	check(not game.in_menu and game.running and game.sim.mode=="survival","Menu starts selected mode")
	check(game.sim.frogs.size()==2,"Survival contains the selected human team only")
	game.sim.countdown=0
	for i in range(5):await physics_frame
	var at:float=game.sim.clock
	var original:RefCounted=game.sim
	var start:=InputEventJoypadButton.new();start.button_index=JOY_BUTTON_START;start.pressed=true
	root.push_input(start,true);await process_frame
	check(game.paused_local and game.in_menu and is_instance_valid(game.hud.menu),"Controller Start opens the full settings menu during play")
	check(game.hud.menu.get_children().any(func(item):return item.get_meta("menu_key","")=="players"),"Paused menu exposes player count settings")
	for i in range(5):await physics_frame
	check(game.sim.clock==at,"Local pause freezes game clock")
	start.pressed=false;root.push_input(start,true);await process_frame
	start.pressed=true;root.push_input(start,true);await process_frame
	check(not game.in_menu and not game.paused_local and game.sim==original,"Start resumes the same match")
	for i in range(3):await physics_frame
	check(game.sim.clock>at,"Local resume advances same match")
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	root.push_input(escape,true)
	check(game.in_menu and game.paused_local,"Escape opens the same settings menu")
	escape.echo=true;root.push_input(escape,true)
	check(game.in_menu,"Holding Escape does not repeatedly toggle the menu")
	escape.echo=false;escape.pressed=false;root.push_input(escape,true)
	escape.pressed=true;root.push_input(escape,true)
	check(not game.in_menu and game.sim==original,"Escape resumes without replacing the match")
	game.toggle_menu();game.set_players(3);game.set_lives(1)
	check(game.sim==original and game.sim.frogs.size()==2,"Changing paused settings preserves current match until New match")
	for item in game.hud.menu.get_children():
		if item.get_meta("menu_key","")=="restart":item.pressed.emit();break
	check(not game.in_menu and not game.paused_local and game.sim.frogs.size()==3 and game.sim.frogs[0].lives==1,"New match applies settings directly from the pause menu")
	check(game.find_children("*","AudioStreamPlayer",true,false).is_empty(),"No sound effect players are created")
	game.sim.over=true;game.results_time=5.99
	for i in range(3):await physics_frame
	check(not game.sim.over and game.sim.countdown>0,"Results transition to a fresh round")
	game.show_menu();game.select_mode("versus");game.set_players(1);game.set_bots(3);game.start_local()
	check(game.sim.frogs.size()==4 and game.sim.frogs[1].bot,"Standalone versus fills spare seats with bots")
	game.show_menu();game.set_players(2);game.set_bots(1);game.set_lives(5)
	game.start_local()
	check(game.sim.frogs.size()==3 and game.sim.frogs.filter(func(p):return not p.bot).size()==2,"Menu applies human and bot counts independently")
	check(game.sim.frogs.all(func(p):return p.lives==5),"Menu applies chosen lives")
	game.load_settings();check(game.human_count==2 and game.bot_count==1 and game.round_lives==5,"Match settings persist together")
	game.show_menu()
	var control:Button=null
	for item in game.hud.menu.get_children():
		if item.get_meta("menu_key","")=="players":control=item
	game.hud.menu_row=1
	var right:=InputEventJoypadButton.new();right.button_index=JOY_BUTTON_DPAD_RIGHT;right.pressed=true
	root.push_input(right,true);right.pressed=false;root.push_input(right,true)
	check(game.human_count==3,"D-pad right changes player count immediately without A")
	right.pressed=true;root.push_input(right,true);right.pressed=false;root.push_input(right,true)
	check(game.human_count==4 and game.bot_count==0,"Visible player selector updates team size and bot capacity")
	var down:=InputEventJoypadMotion.new();down.axis=JOY_AXIS_LEFT_Y;down.axis_value=.9
	root.push_input(down,true)
	check(game.hud.menu_row==3,"Stick down skips unavailable bots row")
	root.push_input(down,true)
	check(game.hud.menu_row==3,"Repeated axis events do not skip multiple rows")
	down.axis_value=0;root.push_input(down,true)
	game.start_local()
	game.bridge.launched_by_daemon=true
	game.sim.frogs[0]["controller"]="test-pad"
	game.bridge.frames={"test-pad":{"axes":[0,0,0,0,0,0],"buttons":16}}
	game.bridge.frame_at=Time.get_ticks_msec()
	var input:Dictionary=game.controls(game.sim.frogs[0])
	check(input.jump and not input.tongue,"LB jumps without firing the tongue in managed play")
	game.bridge.frames["test-pad"].buttons=4
	input=game.controls(game.sim.frogs[0]);check(input.get("throw",false),"Controller X throws the held weapon")
	game.bridge.launched_by_daemon=false
	var a:Vector2=game.world.screen_point(Vector2(-5,5));var b:Vector2=game.world.screen_point(Vector2(5,5))
	check(b.x>a.x,"Camera keeps rightward movement screen-right")
	game.show_menu();game.set_arena("terrarium");game.hud.menu_row=4
	game.hud.menu_move(Vector2i.RIGHT)
	check(game.selected_arena=="vineway","Level row cycles directly with right")
	game.load_settings();check(game.selected_arena=="vineway","Arena selection is saved")
	game.start_local();check(game.sim.arena_id=="vineway","Play loads the selected level")
	game.toggle_menu();original=game.sim;game.set_arena("canopy");game.resume_local()
	check(game.sim==original and game.sim.arena_id=="vineway","Changing level while paused preserves the match on Resume")
	game.start_local();check(game.sim.arena_id=="canopy","New match applies the selected level")
	game.set_arena("cycle");game.start_local()
	var toured:Array=[game.sim.arena_id]
	for i in range(game.Simulation.Arenas.IDS.size()-1):game.new_round();toured.append(game.sim.arena_id)
	check(toured==game.Simulation.Arenas.IDS,"Tour plays each arena once before repeating")
	game.new_round();check(game.sim.arena_id=="terrarium","Tour wraps after all arenas")
	# Portrait decoding must preserve independent profile IDs and transparency.
	game.hud.portraits.clear()
	game.sim.frogs[0].skin_color="#aa8866"
	var px:Array=[];px.resize(48*48);px[0]="#ff00ff"
	game.sim.frogs[0].avatar={"v":1,"w":48,"h":48,"px":px}
	for i in range(3):await process_frame
	game.best_wave=9;game.save_settings();game.best_wave=0;game.load_settings()
	check(game.best_wave==9,"Survival best wave persists")
	if previous.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))
	else:
		var f:=FileAccess.open(config_path,FileAccess.WRITE);f.store_string(previous);f.close()
	game.queue_free();await process_frame
	print("Frog Fighter menu/lifecycle: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
