extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=Sim.new([{"slot":0},{"slot":1}],"versus",17);s.platforms=[];s.crates=[];s.pickups=[];s.countdown=0;s.pickup_timer=999
	var p:Dictionary=s.frogs[0];var q:Dictionary=s.frogs[1]
	p.pos=Vector2(0,8);q.pos=Vector2(8,8);p.invincible=0;q.invincible=0
	s.add_pickup(p.pos,"rail");s.update_frog(p,{},1.0/120)
	check(p.weapon=="rail" and p.ammo==3 and s.pickups.is_empty(),"Nearby weapon equips without a button")
	p.ammo=2;p.aim=Vector2.RIGHT;s.add_pickup(p.pos,"seed");s.update_frog(p,{},1.0/120)
	check(p.weapon=="rail" and p.ammo==2,"Auto pickup never replaces an equipped weapon")
	s.update_frog(p,{"throw":true},1.0/120)
	var thrown:Dictionary=s.pickups.filter(func(item):return item.kind=="rail")[0]
	check(p.weapon.is_empty() and p.ammo==0,"Throw immediately clears held gun")
	check(thrown.ammo==2 and thrown.vel.x>10 and thrown.vel.y>0,"Thrown gun arcs forward and retains remaining ammo")
	check(p.pickup_delay>0 and p.shot_age>=10,"Throw suppresses same-frame re-pickup and old weapon rendering")
	s.pickups=[thrown];p.pickup_delay=0;p.pos=thrown.pos;p.vel=Vector2.ZERO;s.update_frog(p,{},1.0/120)
	check(p.weapon.is_empty(),"Thrower cannot immediately recatch their own gun")
	q.pos=thrown.pos;q.vel=Vector2.ZERO;s.update_frog(q,{},1.0/120)
	check(q.weapon=="rail" and q.ammo==2,"Another frog can catch the thrown weapon without refilling it")
	s.add_pickup(p.pos,"acorn");s.update_frog(p,{"throw":true},1.0/120);s.update_frog(p,{"throw":true},1.0/120)
	check(p.weapon=="acorn","Holding X does not repeatedly throw newly collected weapons")
	s.update_frog(p,{},1.0/120);s.hitstop=.025;s.step(.01,[{"throw":true},{}])
	for i in range(4):s.step(.01,[{},{}])
	check(p.weapon.is_empty() and s.pickups.any(func(item):return item.kind=="acorn"),"Throw taps survive impact freeze")
	p.pos=Vector2(-4,8);q.pos=Vector2(3,8);p.weapon="seed";p.ammo=18;p.anchor={};p.ground=-1;p.vel=Vector2.ZERO;q.vel=Vector2(2,0)
	s.pickups=[];s.clock=0
	var early_shots:=0;var firing_ticks:=0;var noisy_aim:=false
	for frame in range(360):
		s.clock=frame/120.0
		var c:Dictionary=s.bot(p)
		if frame<72 and c.fire:early_shots+=1
		if c.fire:firing_ticks+=1
		if absf(c.aim.angle())>.015:noisy_aim=true
	check(early_shots==0,"Bot allows time to react after acquiring target")
	check(firing_ticks>0 and firing_ticks<140,"Bot leaves clear pauses between attack bursts")
	check(noisy_aim,"Bot aim has error instead of perfect tracking")
	print("Frog Fighter pickup/throw/easier AI: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
