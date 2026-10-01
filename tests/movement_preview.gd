extends SceneTree
const Game=preload("res://src/main.gd")
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var game:=Game.new();root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.visible=false
	game.remove_child(game.world);game.world.free()
	game.sim=Sim.new([{"slot":0},{"slot":1}],"versus",1)
	var sim:RefCounted=game.sim;sim.countdown=0;sim.pickups=[];sim.crates=[];sim.pickup_timer=999
	sim.platforms[2].pos=Vector2(0,6.5);sim.platforms[2].base=Vector2(0,6.5);sim.platforms[2].kind="fixed"
	for p in sim.frogs:p.pos=Vector2(-2.0 if p.slot==0 else 3.4,7.23);p.ground=2;p.invincible=999
	game.world=World.new();game.add_child(game.world);game.world.build(sim)
	game.world.camera.size=11;game.world.camera.position=Vector3(0,11,30);game.world.camera.look_at(Vector3(0,8,0))
	var layer:=CanvasLayer.new();root.add_child(layer)
	var title:=Label.new();title.text="FROG FIGHTER  /  QUICKER ON YOUR FEET";title.position=Vector2(55,35);title.add_theme_font_size_override("font_size",28);layer.add_child(title)
	var caption:=Label.new();caption.text="LB to jump · alternating steps · full jumps and short hops";caption.position=Vector2(55,78);caption.add_theme_font_size_override("font_size",18);layer.add_child(caption)
	for frame in range(360):
		await process_frame
		var move:float=.6 if frame<70 else (-.6 if frame<140 else 0.0)
		var jump:bool=(frame>=170 and frame<215) or frame==270
		for tick in range(2):sim.step(1.0/120,[{"move":Vector2(move,0),"jump":jump},{}])
		game.world.update()
		if frame in [40,70,190,230,280]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://movement-%03d.png"%frame)
	print("Movement preview complete");quit()
