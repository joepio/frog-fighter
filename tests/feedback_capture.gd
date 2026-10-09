extends SceneTree
const Game=preload("res://src/main.gd")
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=Game.new();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.visible=false
	game.in_menu=false;game.running=true
	game.remove_child(game.world);game.world.free()
	game.sim=Sim.new([{"slot":0},{"slot":1}],"versus",1)
	var sim=game.sim;sim.countdown=0;sim.pickups=[];sim.crates=[]
	for p in sim.frogs:
		p.pos=Vector2(-1.8 if p.slot==0 else 1.8,7.23);p.invincible=0;p.ground=2
	sim.frogs[0].weapon="bramble";sim.frogs[0].ammo=70
	game.world=World.new();game.add_child(game.world);game.world.build(sim)
	game.world.camera.size=10.5;game.world.camera.position=Vector3(0,11,30);game.world.camera.look_at(Vector3(0,7.5,0))
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720);root.show()
	for i in 8: await process_frame
	sim.step(1.0/120,[{"fire":true,"aim":Vector2.RIGHT},{}])
	game.world.update()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	var path="user://frog-feedback.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-output="):path=arg.trim_prefix("--capture-output=")
	quit(root.get_texture().get_image().save_png(path))
