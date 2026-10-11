extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	OS.set_environment("GAMENIGHT", "0")
	var game:Node=load("res://main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	game.bridge.launched_by_daemon=true;game.bridge.set_process(false)
	game.selected_mode="versus"
	await game.prepare("probe", [{"index":0,"occupant":{"kind":"local","player_id":"p1"},"controller":"pad"}], [{"id":"p1","name":"Probe"}])
	game.bridge.phase="running";game.start_managed("probe")
	game.bridge.frames={"pad":{"controller":"pad","buttons":0,"axes":[0,0,0,0,0,0]}}
	game.bridge.frame_at=Time.get_ticks_msec();game._process(0.016)
	game.bridge.frames.pad.buttons=128;game._process(0.016)
	print("MANAGED_PROBE ",JSON.stringify({"frogs":game.sim.frogs.size(),"bots":game.sim.frogs.filter(func(p):return p.bot).size(),"start_menu":game.in_menu,"background_art":ResourceLoader.exists("res://art/garden.png"),"tests_in_pack":DirAccess.dir_exists_absolute("res://tests"),"build_in_pack":DirAccess.dir_exists_absolute("res://build")}))
	game.free();quit()
