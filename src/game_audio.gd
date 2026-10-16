extends "res://src/cue_bank.gd"
var flame:AudioStreamPlayer
var flame_level:=0.0
var flame_firing:=false

func _ready() -> void:
	configure({
		"jump":["step",-17,.055,1.15,false], "land":["step",-15,.075,.85,false],
		"tongue":["air",-18,.12,1.5,false], "pickup":["bell",-19,.12,1.3,true],
		"collapse":["wood",-12,.08,.7,false], "fire_acorn":["shot",-14,.05,.85,false],
		"fire_seed":["shot",-17,.055,1.25,false], "fire_bramble":["shot",-13,.06,.72,false],
		"fire_flame":["air",-23,.35,.7,false], "fire_rail":["metal",-17,.1,1.25,false],
		"fire_grenade":["soft",-13,.08,.7,false], "fire_burr":["soft",-14,.08,.8,false],
		"hit":["heavy",-13,.07,1.1,false], "splat":["soft",-11,.15,.65,false],
		"wood":["wood",-23,.085,1.4,false], "explosion":["blast",-14,.13,1.0,false],
		"win":["success",-16,1.,1.,true],
	})
	flame=AudioStreamPlayer.new()
	var clip:AudioStreamWAV=load("res://assets/sfx/flame_loop.wav").duplicate()
	clip.loop_mode=AudioStreamWAV.LOOP_FORWARD
	clip.loop_begin=0
	clip.loop_end=int(round(clip.get_length()*clip.mix_rate))
	flame.stream=clip
	flame.bus=BUS
	flame.volume_db=-80
	add_child(flame)

func update_flame(frogs:Array,dt:float)->void:
	if not active or paused:
		stop_flame()
		return
	var firing:=false
	for frog in frogs:
		if frog.alive and frog.respawn<=0 and frog.last_weapon=="flame" and frog.shot_age<.12:
			firing=true
	if firing and not flame_firing: play_cue("fire_flame")
	flame_firing=firing
	# One shared bed, so four flamethrowers never multiply the room volume.
	flame_level=move_toward(flame_level,1.0 if firing else 0.0,dt*(12 if firing else 8))
	if flame_level<.001:
		flame.stop()
		return
	flame.volume_db=-20+linear_to_db(flame_level)
	if not flame.playing: flame.play()

func stop_flame()->void:
	flame_level=0.0
	flame_firing=false
	if is_instance_valid(flame): flame.stop()

func set_active(enabled:bool,pause_audio:bool=false)->void:
	super.set_active(enabled,pause_audio)
	if not enabled or pause_audio: stop_flame()

func _exit_tree()->void:
	stop_flame()
	if is_instance_valid(flame): flame.stream=null
	super._exit_tree()
