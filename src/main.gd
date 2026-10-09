extends Node
var game_audio = preload("res://src/game_audio.gd").new()
const Simulation=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
const Hud=preload("res://src/hud.gd")
const Bridge=preload("res://src/bridge.gd")
var settings = preload("res://src/settings.gd").new()
var sim:RefCounted
var world:Node3D
var hud:Control
var bridge:Node
var roster:Array=[]
var running:=false
var in_menu:=true
var paused_local:=false
var human_count:=1
var bot_count:=3
var round_lives:=3
var fullscreen:=false
var selected_mode:="versus"
var selected_arena:="terrarium"
var arena_round:=0
var best_wave:=0
var next_round:=1
var result_banner_time:=0.0
var last_result:=""
var victory_time:=0.0
var celebrating:=false
var pending_sim:RefCounted
var pending_world:Node3D
var pending_view:SubViewport
var pending_key:=""
var preparing:=false
var preparation_generation:=0
var back_release:=0.0
var activity_timer:=0.0
var capture_path:=""
var capture_frame:=180
var rendered_frames:=0
var demo:=false
var headless:=false
var probe_timer:=0.0
var render_msec:Array[float]=[]

func _ready()->void:
	add_child(game_audio)
	headless=DisplayServer.get_name()=="headless"
	Engine.max_fps=120
	load_settings()
	# The GameNight autoload, with GameNightScreen keeping its window off the
	# party's screen while warming. Scenes run without it make their own.
	bridge=get_node_or_null("/root/GameNight")
	if bridge==null:bridge=Bridge.new();add_child(bridge)
	bridge.prepared.connect(prepare)
	bridge.started.connect(start_managed)
	bridge.resumed.connect(start_managed)
	bridge.paused.connect(pause_managed)
	bridge.disposed.connect(dispose_managed)
	bridge.roster_changed.connect(update_profiles)
	bridge.daemon_disconnected.connect(func():get_tree().quit())
	bridge.setting_changed.connect(setting_changed)
	bridge.declare_settings(settings.SPECS)
	var layer:=CanvasLayer.new();add_child(layer)
	hud=Hud.new();hud.game=self;hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(hud)
	for arg in OS.get_cmdline_user_args():
		if arg=="--demo":demo=true
		elif arg=="--survival":selected_mode="survival"
		elif arg.begins_with("--arena=") and arg.trim_prefix("--arena=") in Simulation.Arenas.IDS+["cycle"]:selected_arena=arg.trim_prefix("--arena=")
		elif arg.begins_with("--players="):human_count=clampi(int(arg.get_slice("=",1)),1,4)
		elif arg.begins_with("--capture="):capture_path=arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-frame="):capture_frame=int(arg.get_slice("=",1))
	if bridge.launched_by_daemon:in_menu=false
	elif demo:start_local()
	else:show_menu()
	# The project boots minimized so a warming launch never flashes a window;
	# a standalone launch claims the screen itself.
	if not headless and not bridge.launched_by_daemon:
		get_window().mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		DisplayServer.window_move_to_foreground()

func setting_changed(key:String,value:Variant)->void:
	if not settings.change(key,value):return
	if key=="mode":selected_mode=value
	elif key=="arena":selected_arena=value
	elif key=="lives":round_lives=int(value)
	if sim!=null:settings.apply_live(sim)

func load_settings()->void:
	var config:=ConfigFile.new()
	if config.load("user://pond.cfg")==OK:
		best_wave=int(config.get_value("records","wave",0))
		human_count=clampi(int(config.get_value("play","players",1)),1,4)
		selected_mode=str(config.get_value("play","mode","versus"))
		if selected_mode not in ["versus","survival"]:selected_mode="versus"
		selected_arena=str(config.get_value("play","arena","terrarium"))
		if selected_arena not in Simulation.Arenas.IDS+["cycle"]:selected_arena="terrarium"
		bot_count=clampi(int(config.get_value("play","bots",3)),0,4-human_count)
		round_lives=int(config.get_value("play","lives",3))
		if round_lives not in [1,3,5]:round_lives=3
		fullscreen=bool(config.get_value("play","fullscreen",false))
	validate_players()

func save_settings()->void:
	var config:=ConfigFile.new()
	config.set_value("records","wave",best_wave);config.set_value("play","players",human_count);config.set_value("play","mode",selected_mode)
	config.set_value("play","bots",bot_count);config.set_value("play","lives",round_lives)
	config.set_value("play","fullscreen",fullscreen);config.set_value("play","arena",selected_arena)
	config.save("user://pond.cfg")

func validate_players()->void:
	bot_count=clampi(bot_count,1 if selected_mode=="versus" and human_count==1 else 0,4-human_count)

func set_players(value:int)->void:
	human_count=clampi(value,1,4);validate_players();save_settings();hud.make_menu()

func set_bots(value:int)->void:
	bot_count=value;validate_players();save_settings();hud.make_menu()

func set_lives(value:int)->void:
	round_lives=value;save_settings();hud.make_menu()

func set_arena(value:String)->void:
	selected_arena=value;save_settings();hud.make_menu()

func set_fullscreen(value:bool)->void:
	fullscreen=value
	if not headless and not bridge.launched_by_daemon:get_window().mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	save_settings()
	if in_menu:hud.make_menu()

func local_roster(bots_only:bool=false)->Array:
	var out:Array=[];var pads:=Input.get_connected_joypads()
	var names:=["Moss","Ripple","Poppy","Butter"]
	validate_players()
	for i in range(4 if bots_only else human_count+(bot_count if selected_mode=="versus" else 0)):
		out.append({"slot":i,"id":str(i),"name":names[i],"color":Simulation.COLORS[i],
			"bot":bots_only or i>=human_count,"device":pads[i] if i<pads.size() else -1})
	return out

func select_mode(value:String)->void:
	selected_mode=value;validate_players();save_settings();hud.make_menu()

func show_menu()->void:
	paused_local=false;in_menu=true;running=false;roster=local_roster(true)
	new_round();sim.countdown=0;hud.make_menu()
	for p in sim.frogs:p.invincible=0.0

func toggle_menu()->void:
	if paused_local:resume_local()
	elif in_menu:start_local()
	else:
		paused_local=true;in_menu=true
		hud.make_menu()

func resume_local()->void:
	paused_local=false;in_menu=false
	# Releasing menu controls must not queue a jump or throw into the match.
	for p in sim.frogs:
		var input:Dictionary=controls(p) if not p.bot else {}
		p.jump_prev=input.get("jump",false);p.throw_prev=input.get("throw",false)
	hud.hide_menu()

func start_local()->void:
	in_menu=false;paused_local=false;running=true;arena_round=0;roster=local_roster(demo)
	hud.hide_menu();new_round();save_settings();back_release=0

func round_arena()->String:
	return Simulation.Arenas.IDS[arena_round%Simulation.Arenas.IDS.size()] if selected_arena=="cycle" else selected_arena

func round_key(players:Array)->String:
	return JSON.stringify([round_arena(),selected_mode,next_round,round_lives,players])

func discard_prepared()->void:
	preparation_generation+=1
	if is_instance_valid(pending_view):pending_view.queue_free()
	pending_view=null;pending_world=null;pending_sim=null;pending_key=""

func prepare_next_round()->void:
	if preparing or not is_instance_valid(world):return
	var players:Array=local_roster(demo) if in_menu and not paused_local else roster
	var key_value:String=round_key(players)
	if key_value==pending_key:return
	discard_prepared()
	pending_key=key_value
	pending_sim=Simulation.new(players,selected_mode,next_round,round_arena())
	# Same-arena restarts only need fresh simulation data, not new scenery.
	if world.sim.arena_id==pending_sim.arena_id:return
	preparing=true
	var generation:int=preparation_generation
	var viewport:=SubViewport.new();viewport.own_world_3d=true
	viewport.size=get_viewport().get_visible_rect().size
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var preview:=World.new();viewport.add_child(preview);preview.sim=pending_sim
	await preview.build_stage(true)
	preparing=false
	if generation!=preparation_generation:
		viewport.queue_free();return
	pending_view=viewport;pending_world=preview

func new_round(quick:bool=false)->void:
	var previous_aim:Dictionary={}
	if quick and sim!=null:
		for p in sim.frogs:previous_aim[p.slot]=p.aim
	var prepared:bool=pending_key==round_key(roster) and pending_sim!=null and not preparing
	sim=pending_sim if prepared else Simulation.new(roster,selected_mode,next_round,round_arena())
	next_round+=1
	if not in_menu:arena_round+=1
	settings.apply_live(sim)
	for p in sim.frogs:
		p.lives=int(settings.values.lives) if bridge.launched_by_daemon else round_lives
		p["starting_lives"]=p.lives
	sim.countdown=.8
	if quick:
		for p in sim.frogs:
			if previous_aim.has(p.slot):p.aim=previous_aim[p.slot]
	result_banner_time=0;celebrating=false;victory_time=0
	if is_instance_valid(world) and world.can_reuse(sim):
		world.reset(sim,pending_world if prepared else null)
	else:
		if is_instance_valid(world):remove_child(world);world.queue_free()
		world=World.new();add_child(world);world.build(sim)
	discard_prepared()

func _physics_process(dt:float)->void:
	if sim==null or paused_local or (not running and not in_menu):return
	if sim.over and not celebrating:
		celebrating=true;victory_time=0
		if not in_menu: game_audio.play_cue("win")
		last_result=sim.winner+(" wins" if sim.mode=="versus" and sim.winner!="Draw" else "")
		result_banner_time=2.0
		if sim.mode=="survival":best_wave=maxi(best_wave,sim.wave);save_settings()
		if bridge.launched_by_daemon:bridge.notify_finished(bridge.session)
	if celebrating:
		victory_time+=dt
		# Keep the winner playable if scenery preparation needs another frame.
		if victory_time>=2.0 and not preparing:new_round(true)
	var inputs:Array=[]
	for p in sim.frogs:inputs.append({} if in_menu else (sim.bot(p) if p.bot else controls(p)))
	if not world.fx_ready:
		sim.update_aim(inputs);return
	sim.step(dt,inputs)
	if running and not in_menu:
		for cue in sim.events: game_audio.play_cue(cue)

func controls(p:Dictionary)->Dictionary:
	if bridge.launched_by_daemon:
		var f:Dictionary=bridge.frame(p.get("controller",""))
		return {"move":Vector2(deadzone(Bridge.axis(f,0)),-deadzone(Bridge.axis(f,1))),
			"aim":Vector2(deadzone(Bridge.axis(f,2)),-deadzone(Bridge.axis(f,3))),
			"jump":Bridge.pressed(f,4) or Bridge.pressed(f,0),"tongue":Bridge.axis(f,4)>.2,
			"fire":Bridge.axis(f,5)>.2 or Bridge.pressed(f,5),"throw":Bridge.pressed(f,2),"grip":Bridge.pressed(f,1)}
	var c:Dictionary={"move":Vector2.ZERO,"aim":Vector2.ZERO,"jump":false,"tongue":false,"fire":false,"throw":false,"grip":false}
	var device:int=p.get("device",-1)
	if device>=0:
		if not Input.get_connected_joypads().has(device):return c
		c.move=Vector2(deadzone(Input.get_joy_axis(device,JOY_AXIS_LEFT_X)),-deadzone(Input.get_joy_axis(device,JOY_AXIS_LEFT_Y)))
		c.aim=Vector2(deadzone(Input.get_joy_axis(device,JOY_AXIS_RIGHT_X)),-deadzone(Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y)))
		c.jump=Input.is_joy_button_pressed(device,JOY_BUTTON_LEFT_SHOULDER) or Input.is_joy_button_pressed(device,JOY_BUTTON_A)
		c.tongue=Input.get_joy_axis(device,JOY_AXIS_TRIGGER_LEFT)>.2
		c.fire=Input.get_joy_axis(device,JOY_AXIS_TRIGGER_RIGHT)>.2 or Input.is_joy_button_pressed(device,JOY_BUTTON_RIGHT_SHOULDER)
		c.throw=Input.is_joy_button_pressed(device,JOY_BUTTON_X);c.grip=Input.is_joy_button_pressed(device,JOY_BUTTON_B)
		return c
	var keys:Array=[
		[KEY_A,KEY_D,KEY_W,KEY_S,KEY_SPACE,KEY_Q,KEY_F,KEY_E,KEY_SHIFT],
		[KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_CTRL,KEY_N,KEY_M,KEY_COMMA,KEY_PERIOD],
		[KEY_J,KEY_L,KEY_I,KEY_K,KEY_U,KEY_Y,KEY_O,KEY_H,KEY_P],
		[KEY_KP_4,KEY_KP_6,KEY_KP_8,KEY_KP_5,KEY_KP_0,KEY_KP_7,KEY_KP_9,KEY_KP_1,KEY_KP_3]][int(p.slot)%4]
	c.move=Vector2(float(key(keys[1]))-float(key(keys[0])),float(key(keys[2]))-float(key(keys[3])))
	c.jump=key(keys[4]);c.tongue=key(keys[5]);c.fire=key(keys[6]);c.throw=key(keys[7]);c.grip=key(keys[8])
	if p.slot==0:
		var pointer:=get_viewport().get_mouse_position()
		var origin:Vector3=world.camera.project_ray_origin(pointer)
		var direction:Vector3=world.camera.project_ray_normal(pointer)
		var target:Vector3=origin+direction*((.35-origin.z)/direction.z)
		c.aim=Vector2(target.x,target.y)-p.pos
		c.fire=c.fire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		c.tongue=c.tongue or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	else:
		# Keyboard-only guests aim with movement; releasing retains that direction.
		c.aim=c.move
	return c

func key(code:int)->bool:return Input.is_physical_key_pressed(code)
func deadzone(value:float)->float:return signf(value)*maxf(0,(absf(value)-.17)/.83)

func _process(dt:float)->void:
	game_audio.set_active(running and not in_menu, paused_local)
	if not paused_local and (running or in_menu):prepare_next_round()
	process_back(dt)
	if sim!=null and (running or in_menu) and not paused_local:world.update()
	hud.queue_redraw()
	probe_timer+=dt
	if probe_timer>.1:probe_timer=0;write_probe()
	activity_timer+=dt
	if bridge.launched_by_daemon and running and activity_timer>1 and sim!=null:
		activity_timer=0
		for p in sim.frogs:
			if p.bot:continue
			var c:Dictionary=controls(p)
			if c.move.length()>.2 or c.aim.length()>.2 or c.jump or c.fire or c.tongue:
				bridge._send({"type":"controller_input","session":bridge.session,"controller":p.get("controller","")})
	if not capture_path.is_empty():
		rendered_frames+=1
		if rendered_frames>60:render_msec.append(dt*1000)
		if rendered_frames==capture_frame:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(capture_path)
			if not render_msec.is_empty():
				render_msec.sort()
				print("FRAME ms median=",render_msec[render_msec.size()/2]," p95=",render_msec[int(render_msec.size()*.95)])
			print("CAPTURE ",capture_path);get_tree().quit()

func process_back(_dt:float)->void:
	if not bridge.launched_by_daemon:return
	var held:=false
	for seat in roster:held=held or Bridge.pressed(bridge.frame(seat.get("controller","")),6)
	if not held:back_release=1
	elif back_release>=1:
		back_release=0
		if running:bridge.request_overlay()

func _input(event:InputEvent)->void:
	if bridge.launched_by_daemon:return
	var menu_pressed:bool=event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_START,JOY_BUTTON_BACK]
	menu_pressed=menu_pressed or (event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE)
	if menu_pressed:
		if not in_menu or paused_local:toggle_menu()
		elif event is InputEventJoypadButton and event.button_index==JOY_BUTTON_START:start_local()
		get_viewport().set_input_as_handled()
	elif in_menu and hud.menu_input(event):get_viewport().set_input_as_handled()

func _unhandled_input(event:InputEvent)->void:
	if bridge.launched_by_daemon:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ENTER:
			if in_menu:
				if paused_local:resume_local()
				else:start_local()
		elif event.keycode==KEY_F2 and in_menu:set_players(human_count%4+1)
		elif event.keycode==KEY_F3 and in_menu:select_mode("survival" if selected_mode=="versus" else "versus")
		elif event.keycode==KEY_F11:toggle_fullscreen()
	if event is InputEventJoypadButton and event.pressed:
		if in_menu and event.button_index==JOY_BUTTON_Y:select_mode("survival" if selected_mode=="versus" else "versus")

func toggle_fullscreen()->void:
	set_fullscreen(not fullscreen)

func prepare(session:String,seats:Array,players:Array)->void:
	running=false;in_menu=false;hud.hide_menu();roster=[];next_round=1;arena_round=0
	var used_tokens:Dictionary={}
	for seat in seats:
		var occupant:Dictionary=seat.get("occupant",{})
		if occupant.get("kind","empty")=="empty" or roster.size()>=4:continue
		var slot:int=int(seat.get("index",roster.size()))
		var id:String=occupant.get("player_id","")
		var profile:Dictionary={}
		for player in players:
			if str(player.get("id",""))==id:profile=player
		var token:String=seat.get("controller","")
		if used_tokens.has(token) and not token.is_empty():token=""
		used_tokens[token]=true
		roster.append({"slot":slot,"id":id,"name":profile.get("name","Frog %d"%(slot+1)),"color":profile.get("color",Simulation.COLORS[slot%4]),"skin_color":profile.get("skin_color","#eac794"),"avatar":profile.get("avatar",{}),"bot":occupant.get("kind")=="ai","controller":token})
	new_round()
	# A minimized, warming window never draws, so frame_post_draw would never fire.
	if not headless and DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_MINIMIZED:await RenderingServer.frame_post_draw
	else:await get_tree().process_frame
	bridge.ready_for_session(session)

func start_managed(_session:String)->void:
	running=true;back_release=0

func pause_managed(_session:String)->void:
	running=false

func dispose_managed(_session:String)->void:
	discard_prepared();celebrating=false;victory_time=0
	running=false;roster=[];sim=null
	if is_instance_valid(world):remove_child(world);world.queue_free()
	world=null

func update_profiles(_seats:Array,players:Array,_presence:Array)->void:
	if sim==null:return
	for p in sim.frogs:
		for profile in players:
			if str(profile.get("id",""))!=p.id:continue
			p.name=profile.get("name",p.name)
			p.skin_color=profile.get("skin_color",p.get("skin_color","#eac794"));p.avatar=profile.get("avatar",p.get("avatar",{}))
			# Rebuild visual meshes only when a profile color actually changes.
			var color:String=profile.get("color",p.color)
			if color!=p.color:
				p.color=color
				var i:int=sim.frogs.find(p)
				world.frogs[i].root.queue_free();world.frogs[i]=world.make_frog(Color(color))
			for source in roster:
				if source.id==p.id:source.name=p.name;source.color=p.color;source.skin_color=p.skin_color;source.avatar=p.avatar

func write_probe()->void:
	var path:=OS.get_environment("FROG_PROBE_PATH")
	if path.is_empty():return
	var players:Array=[]
	if sim!=null:
		for p in sim.frogs:players.append({"name":p.name,"x":p.pos.x,"y":p.pos.y,"lives":p.lives,"bot":p.bot,"controller":p.get("controller","")})
	var data:={"phase":bridge.phase,"session":bridge.session,"running":running,"clock":sim.clock if sim!=null else 0,"countdown":sim.countdown if sim!=null else 0,"players":players,"visible":DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_MINIMIZED,"muted":AudioServer.is_bus_mute(0)}
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(data))
