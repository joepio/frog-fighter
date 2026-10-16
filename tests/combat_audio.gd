extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var bank=load("res://src/game_audio.gd").new()
	root.add_child(bank)
	var frog:Dictionary={"alive":true,"respawn":0.,"last_weapon":"flame","shot_age":0.}
	for i in range(30):bank.update_flame([frog],1./60.)
	check(bank.flame.playing and bank.flame_level==1.,"Flamethrower sustains one continuous sound")
	var once:int=bank.serial
	var solo_db:float=bank.flame.volume_db
	for i in range(30):bank.update_flame([frog,frog,frog,frog],1./60.)
	check(bank.serial==once,"Held fire cannot retrigger ignition whooshes")
	check(bank.flame.volume_db==solo_db,"Four simultaneous flamethrowers do not multiply loudness")
	frog.shot_age=1.
	for i in range(30):bank.update_flame([frog],1./60.)
	check(not bank.flame.playing,"Releasing the trigger fades and stops the flame")
	frog.shot_age=0.
	bank.clock+=1.
	bank.update_flame([frog],.1)
	bank.set_active(false)
	check(not bank.flame.playing,"Returning to lobby stops the flame immediately")
	bank.set_active(true)
	bank.update_flame([frog],.1)
	bank.set_active(true,true)
	check(not bank.flame.playing,"Pause stops sustained weapon audio")
	bank.set_active(true)
	bank.clock+=1.
	bank.play_cue("hit")
	check(bank.voices[6].stream!=null or bank.voices[7].stream!=null,"Damage confirmation uses reserved voices")
	check(bank.cues.fire_seed[0]=="shot" and bank.cues.fire_seed[1]>-21,"Seed shots have a full attack and more presence than the old click")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(bank.BUS))==1,"Shared limiter protects busy combat from clipping")
	var stream:AudioStreamWAV=bank.flame.stream
	check(stream.mix_rate==44100 and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Flame loops at full sample rate")
	stream=null
	await create_timer(.25).timeout
	bank.queue_free()
	await process_frame
	await create_timer(.1).timeout
	print("COMBAT_AUDIO_TESTS %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
