extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(condition:bool,label:String)->void:
	checks+=1
	if not condition:failures+=1;push_error(label)
func game()->RefCounted:
	var s:=Sim.new([{"slot":0},{"slot":1}],"versus",9);s.countdown=0;s.pickups=[];s.crates=[]
	for p in s.frogs:p.invincible=0;p.pos=Vector2(-2 if p.slot==0 else 2,9);p.vel=Vector2.ZERO
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=game();var shooter:Dictionary=s.frogs[0];var victim:Dictionary=s.frogs[1]
	shooter.weapon="bramble";shooter.ammo=2;s.fire(shooter)
	check(s.shots.size()==5 and shooter.ammo==1,"Bramble emits five pellets for one ammo")
	# Same volley can register across adjacent physics ticks, without five hit pauses.
	for i in range(5):
		s.hurt(victim,10,Vector2.RIGHT*4.5,"bramble",1)
	check(victim.hp==50,"All five bramble pellets can damage one target")
	check(s.fx.filter(func(f):return f.kind=="hit").size()==1,"One impact flash per bramble volley")
	check(s.events.count("hit")==1,"One impact sound per bramble volley")
	check(s.hitstop<=.0451,"Bramble pellets do not stack hit-stop")
	s.hurt(victim,10,Vector2.RIGHT,"seed",2)
	check(victim.hp==50,"Different volley respects brief damage invulnerability")
	var time:float=s.clock;var position:Vector2=victim.pos
	s.step(1.0/120,[{},{}])
	check(s.clock==time and victim.pos==position,"Hit-stop freezes world motion")
	check(s.fx[0].age>0,"Impact animation advances during hit-stop")
	for i in range(12):s.step(1.0/120,[{},{}])
	check(s.clock>time and victim.pos!=position,"Physics resumes after short hit-stop")
	check(s.delayed_gore.is_empty() and s.gore.size()>2 and s.gore.size()<=6,"Delayed spray follows the contact burst")
	s=game();s.frogs[0].pos=Vector2(-.75,9);s.frogs[1].pos=Vector2(.75,9)
	s.frogs[0].weapon="bramble";s.frogs[0].ammo=2;s.fire(s.frogs[0])
	for i in range(30):s.step(1.0/120,[{},{}])
	check(s.frogs[1].hp==50,"A close-range fired bramble volley delivers all five pellet hits")
	s=game();s.frogs[0].pos=Vector2(-10,3.03);s.frogs[0].ground=0;s.hitstop=.04
	s.step(1.0/120,[{"jump":true},{}])
	for i in range(7):s.step(1.0/120,[{},{}])
	check(s.frogs[0].vel.y>0,"A jump tapped during hit-stop is buffered")
	s=game();victim=s.frogs[1];victim.lives=1
	s.hurt(victim,100,Vector2(10,3),"acorn",1)
	check(not victim.alive and victim.lives==0,"Lethal damage resolves knockout on impact frame")
	check(s.hitstop>=.09 and s.hitstop<.11,"Knockout freeze stays below 110 ms")
	s.knockout(victim);check(victim.lives==0,"Repeated knockout cannot consume another stock")
	for i in range(16):s.step(1.0/120,[{},{}])
	check(s.over,"Last knockout ends versus")
	var debris:Vector2=s.gore[0].pos;time=s.clock
	for i in range(10):s.step(1.0/120,[])
	check(s.clock>time and s.gore[0].pos!=debris,"Debris and winner simulation continue during the victory lap")
	check(s.over and not victim.alive and victim.lives==0,"The victory lap preserves the result and defeated player")
	s=game();s.frogs[1].pos=Vector2(0,9);s.crates=[{"pos":Vector2(1,9),"vel":Vector2.ZERO,"angle":0.0}]
	s.shots=[{"pos":Vector2(-1,9),"vel":Vector2(300,0),"owner":0,"kind":"seed","volley":1,"life":1.0}]
	s.update_shots(.01)
	check(s.frogs[1].hp<100 and s.crates[0].vel==Vector2.ZERO,"A spent round cannot also hit a crate behind its victim")
	s=game();shooter=s.frogs[0];shooter.weapon="acorn";shooter.ammo=1;s.fire(shooter)
	check(shooter.weapon.is_empty() and shooter.last_weapon=="acorn" and shooter.shot_age==0,"Final ammo preserves the weapon firing pose")
	for i in range(200):s.add_fx("hit",Vector2.ZERO,Vector2.RIGHT,.2,"seed")
	check(s.fx.size()<=64,"Combat visual pool remains bounded")
	print("Frog Fighter combat: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
