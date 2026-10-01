extends SceneTree
## Staged native-renderer capture of real weapon simulation; excluded from exports.
const Game=preload("res://src/main.gd")
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var game:=Game.new();root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.visible=false
	game.in_menu=false;game.running=true
	var layer:=CanvasLayer.new();root.add_child(layer)
	var title:=Label.new();title.position=Vector2(55,35);title.add_theme_font_size_override("font_size",30);layer.add_child(title)
	var caption:=Label.new();caption.position=Vector2(55,78);caption.add_theme_font_size_override("font_size",18);layer.add_child(caption)
	var output:="user://previews"
	DirAccess.make_dir_recursive_absolute(output)
	var stages:Array=["acorn","seed","bramble","flame","organs"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg=="--fire-preview":stages=["flame_clear","flame"]
	for stage in stages:
		var kind:String="acorn" if stage=="organs" else ("flame" if stage=="flame_clear" else stage)
		game.remove_child(game.world);game.world.free()
		game.sim=Sim.new([{"slot":0},{"slot":1}],"versus",1)
		var sim:RefCounted=game.sim;sim.countdown=0;sim.pickups=[];sim.crates=[];sim.pickup_timer=99
		sim.platforms[2].pos=Vector2(0,6.5);sim.platforms[2].base=Vector2(0,6.5);sim.platforms[2].kind="fixed"
		for p in sim.frogs:
			p.pos=Vector2(-1.8 if p.slot==0 else 1.8,7.23);p.invincible=0;p.ground=2;p.lives=1
		sim.frogs[0].weapon=kind;sim.frogs[0].ammo=70
		sim.frogs[1].hp=24 if stage=="organs" else 100
		if stage=="flame_clear":sim.frogs[1].pos=Vector2(-9,10);sim.frogs[1].lives=3
		game.world=World.new();game.add_child(game.world);game.world.build(sim)
		game.world.camera.size=10.5;game.world.camera.position=Vector3(0,11,30);game.world.camera.look_at(Vector3(0,7.5,0))
		title.text="FROG FIGHTER  /  "+sim.WEAPON_NAMES[kind].to_upper()
		caption.text={"acorn":"Bark barrel · heavy acorn shot · sap-vine bindings","seed":"Pine-cone chamber · rapid needle spray","bramble":"Twisted briar pod · wide thorn blast","flame":"Dragonpod · pressurized sap · short flame stream"}[kind]
		if stage=="organs":title.text="FROG FIGHTER  /  KNOCKOUT";caption.text="Three squishy organ shapes join the flying limbs"
		if kind=="flame":caption.text="Shared fire · additive light · translucent edges · rising smoke"
		var impact_frame:=-1
		for frame in range(240 if kind=="flame" else 180):
			await process_frame
			for tick in range(2):
				var fire:bool=(frame>=30 and frame<85) if kind=="flame" else (frame in [30,96] or (kind=="seed" and frame in [43,56]))
				if frame==90 and kind!="flame":sim.frogs[1].hp=3
				var victim_input:Dictionary={"move":Vector2(.35,0)} if kind=="flame" and frame>90 and frame<135 else {}
				sim.step(1.0/120,[{"fire":fire,"aim":Vector2.RIGHT},victim_input])
			game.world.update()
			if impact_frame<0 and sim.frogs[1].hp<(24 if stage=="organs" else 100):impact_frame=frame
			if frame in [31,82,110,135,200] or (impact_frame>=0 and frame in [impact_frame,impact_frame+8,impact_frame+18,impact_frame+35]):
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output+"/"+stage+"-%03d.png"%frame)
	print("Impact preview complete");quit()
