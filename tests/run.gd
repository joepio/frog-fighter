extends SceneTree
const Sim=preload("res://src/simulation.gd")
const Bridge=preload("res://src/bridge.gd")
var checks:=0
var failures:=0

func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)

func game(mode:String="versus")->RefCounted:
	var s:=Sim.new([{"slot":0,"name":"A"},{"slot":1,"name":"B"}],mode,17)
	s.countdown=0
	return s

func _initialize()->void:call_deferred("run")

func run()->void:
	var s:=game()
	for i in range(120):s.step(1.0/120,[{},{}])
	check(s.frogs[0].ground==0,"Frog lands on spawn platform")
	check(absf(s.frogs[0].pos.y-(2.5+s.RADIUS))<.05,"Frog stands at collider height")
	s.step(1.0/120,[{"jump":true},{}])
	check(s.frogs[0].vel.y>11,"Jump provides upward impulse")
	for i in range(30):s.step(1.0/120,[{"jump":true},{}])
	check(s.frogs[0].pos.y>5,"Holding jump gains height")
	s.step(1.0/120,[{},{}])
	check(s.frogs[0].vel.y<5,"Releasing jump cuts upward velocity")
	var anchor:Dictionary=s.cast_tongue(Vector2(1,7),Vector2(0,1))
	check(not anchor.is_empty(),"Tongue ray finds an overhead platform")
	check(s.cast_tongue(Vector2(0,2),Vector2(0,-1)).is_empty(),"Tongue misses open water")
	s.frogs[0].pos=Vector2(1,7);s.frogs[0].vel=Vector2(9,0)
	s.step(1.0/120,[{"aim":Vector2(0,1),"tongue":true},{}])
	check(not s.frogs[0].anchor.is_empty(),"Tongue attaches on press")
	var original_length:float=s.frogs[0].rope
	for i in range(120):s.step(1.0/120,[{"tongue":true,"move":Vector2(.5,1)},{}])
	check(s.frogs[0].rope<original_length-3,"Up reels the tongue in")
	check(s.frogs[0].pos.distance_to(s.anchor_point(s.frogs[0].anchor))<=s.frogs[0].rope+.02,"Rope constraint holds under swing momentum")
	s.step(1.0/120,[{},{}]);check(s.frogs[0].anchor.is_empty(),"Releasing tongue detaches")
	s.frogs[0].pos=Vector2(s.WALL_LIMIT-.01,6);s.frogs[0].vel=Vector2.ZERO
	s.step(1.0/120,[{"move":Vector2.UP},{}])
	check(s.frogs[0].stuck,"Wall contact attaches automatically")
	s.step(1.0/120,[{"jump":true},{}])
	check(s.frogs[0].vel.x< -5 and s.frogs[0].vel.y>10,"Wall jump pushes away from surface")
	s.frogs[0].pos=s.platforms[3].pos+Vector2(0,-.48);s.frogs[0].vel=Vector2.ZERO
	s.step(1.0/120,[{"grip":true},{}])
	check(s.frogs[0].stuck and absf(s.frogs[0].vel.y)<.1,"Grip holds the underside of a platform")
	s=game();s.shots=[{"pos":s.platforms[4].pos+Vector2(0,-1),"vel":Vector2(0,24),"owner":0,"kind":"seed","life":1.0}]
	for i in range(12):s.step(1.0/120,[{},{}])
	check(s.shots.is_empty(),"Projectiles collide with arena platforms")
	s=game();s.crates=[];s.frogs[0].pos=s.platforms[2].pos+Vector2(-3,.2+s.RADIUS)
	for i in range(120):s.step(1.0/120,[{},{}])
	check(s.platforms[2].angle>.015,"Frog weight tilts seesaw")
	s.Physics.impulse(s.platforms[5],Vector2(12,0),s.platforms[5].pos)
	var before:Vector2=s.anchor_point({"platform":5,"offset":Vector2.ZERO})
	for i in range(120):s.step(1.0/120,[{},{}])
	check(before.distance_to(s.anchor_point({"platform":5,"offset":Vector2.ZERO}))>.1,"Tongue anchors follow moving platforms")
	s=game();s.pickups=[];s.add_pickup(s.frogs[0].pos,"acorn");s.pickup(s.frogs[0])
	check(s.frogs[0].weapon=="acorn" and s.frogs[0].ammo==10,"Weapon pickup equips ammo")
	s.platforms=[s.platform(Vector2(0,10-s.RADIUS-.2),9,"fixed")];s.crates=[]
	s.frogs[0].pos=Vector2(-2,10);s.frogs[1].pos=Vector2(2,10)
	s.frogs[1].invincible=0;s.fire(s.frogs[0])
	for i in range(24):s.step(1.0/120,[{},{}])
	check(s.frogs[1].hp<100,"Projectile damages another frog")
	check(s.frogs[0].hp==100,"Projectile cannot damage its owner")
	check(s.gore.size()>0,"Gun hits create blood spray")
	check(s.frogs[1].vel.x>0,"Projectile transfers knockback")
	s=game("survival");s.frogs[1].invincible=0
	s.frogs[0].pos=Vector2(-2,10);s.frogs[1].pos=Vector2(2,10);s.frogs[0].weapon="seed";s.frogs[0].ammo=10;s.fire(s.frogs[0])
	for i in range(24):s.step(1.0/120,[{},{}])
	check(s.frogs[1].hp==100,"Survival teammates do not receive friendly fire")
	s=game();s.frogs[0].hp=0;s.step(1.0/120,[{},{}])
	check(s.frogs[0].lives==2 and s.frogs[0].respawn>0,"Lethal damage costs one stock and schedules respawn")
	check(s.gore.size()>=20 and s.gore.size()<=30 and s.gore.any(func(p):return p.chunk),"Knockouts create body parts and a restrained directional spray")
	for i in range(210):s.step(1.0/120,[{},{}])
	check(s.frogs[0].respawn<=0 and s.frogs[0].hp==100,"Respawn restores health")
	s.frogs[0].lives=1;s.frogs[0].hp=0;s.step(1.0/120,[{},{}])
	check(s.over and s.winner=="B","Last survivor wins versus")
	var at:float=s.clock;s.step(1,[{},{"move":Vector2.RIGHT}])
	check(s.clock>at and s.over and s.winner=="B","Victory lap keeps simulation running without changing the result")
	check(s.frogs[0].lives==0,"Defeated player stays out during the victory lap")
	s=game("survival")
	for i in range(260):s.step(1.0/120,[{},{}])
	check(s.wave==1 and s.enemies.size()==10,"Survival spawns the first swarm")
	s.enemies=[]
	for i in range(440):s.step(1.0/120,[{},{}])
	check(s.wave==2,"Clearing a wave progresses survival")
	# Repeatable long simulation checks bounded effects and valid physics.
	for mode in ["versus","survival"]:
		for seed_value in range(1,5):
			s=Sim.new([{"slot":0},{"slot":1},{"slot":2},{"slot":3}],mode,seed_value);s.countdown=0
			for frame in range(7200):
				var input:Array=[]
				for p in s.frogs:input.append(s.bot(p))
				s.step(1.0/120,input)
				for p in s.frogs:
					if not p.pos.is_finite() or not p.vel.is_finite():check(false,"Finite simulation state");break
			check(s.gore.size()<=260 and s.stains.size()<=150,"Effects remain bounded during long rounds")
	var bridge:=Bridge.new()
	bridge.frames={"second-pad":{"axes":[16384,0,0,0,0,0],"buttons":1}}
	bridge.frame_at=Time.get_ticks_msec()
	check(Bridge.pressed(bridge.frame("second-pad"),0),"Host input follows opaque token")
	check(bridge.frame("other-pad").is_empty(),"Missing pad cannot borrow another player's input")
	bridge.frame_at-=251;check(bridge.frame("second-pad").is_empty(),"Stale host input becomes neutral")
	bridge.free()
	print("Frog Fighter: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
