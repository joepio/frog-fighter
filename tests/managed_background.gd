extends SceneTree
var game:Node
func _initialize()->void:call_deferred("run")
func run()->void:
	OS.set_environment("GAMENIGHT","0")
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	game.in_menu=false;game.hud.hide_menu()
	root.size=Vector2i(960,540)
	root.position=Vector2i(-20000,-20000)
	RenderingServer.render_loop_enabled=false
	var backdrop:Node
	for node in game.world.find_children("*","Node3D",true,false):
		if node.has_method("fit_camera"):backdrop=node;break
	assert(backdrop!=null)
	for i in 120:await process_frame
	print("BACKGROUND_HIDDEN_FRAMES ",backdrop.frames," update=",backdrop.viewport.render_target_update_mode)
	var failed:bool=backdrop.frames!=0 or backdrop.viewport.render_target_update_mode!=SubViewport.UPDATE_ALWAYS
	root.position=DisplayServer.screen_get_position()
	RenderingServer.render_loop_enabled=true
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var path:=arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			root.get_texture().get_image().save_png(path)
	print("BACKGROUND_HIDDEN_", "FAIL" if failed else "PASS")
	game.free();quit(1 if failed else 0)
