extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func pair()->RefCounted:
	var s:=Sim.new([{}],"versus",23,"vineway");s.countdown=0;s.crates=[];s.pickups=[];s.pickup_timer=1000
	var b:Dictionary=s.platform(Vector2(0,12),3,"loose");s.Physics.prepare(b,3.5,.4);s.platforms=[b]
	var p:Dictionary=s.frogs[0];p.pos=Vector2(3,8);p.vel=Vector2.ZERO;p.anchor={"platform":0,"offset":Vector2.ZERO};p.rope=5;p.tongue_prev=true
	return s
func energy(s:RefCounted)->float:
	var b:Dictionary=s.platforms[0];var p:Dictionary=s.frogs[0]
	return .5*p.vel.length_squared()+.5*b.vel.length_squared()/b.inv_mass+.5*b.omega*b.omega/b.inv_inertia
func _initialize()->void:
	var s:=pair();var p:Dictionary=s.frogs[0];var b:Dictionary=s.platforms[0]
	p.vel=Vector2(6,-8)
	var momentum:Vector2=p.vel+b.vel/b.inv_mass;var initial:float=energy(s)
	s.solve_tongue(p)
	check((p.vel+b.vel/b.inv_mass).distance_to(momentum)<.0001,"Tongue conserves the combined linear momentum")
	check(energy(s)<=initial+.0001,"A taut tongue does not create kinetic energy")
	check(absf((p.vel-b.vel).dot((p.pos-b.pos).normalized()))<.0001,"Taut endpoints have equal radial velocity")
	for i in range(100):s.solve_tongue(p)
	check((p.vel+b.vel/b.inv_mass).distance_to(momentum)<.0001 and energy(s)<=initial+.0001,"Repeated solving adds no phantom force")
	s=pair();p=s.frogs[0];b=s.platforms[0];p.vel=Vector2(4,2);b.vel=p.vel
	s.solve_tongue(p)
	check(p.vel==Vector2(4,2) and b.vel==Vector2(4,2),"Common motion does not generate tongue tension")
	s=pair();p=s.frogs[0];b=s.platforms[0];p.rope=6;p.vel=Vector2(3,-4)
	s.solve_tongue(p)
	check(p.vel==Vector2(3,-4) and b.vel==Vector2.ZERO,"A slack tongue exerts no force")
	s=pair();p=s.frogs[0];b=s.platforms[0];p.vel=Vector2(-3,4)
	s.solve_tongue(p)
	check(p.vel==Vector2(-3,4) and b.vel==Vector2.ZERO,"An approaching frog does not push with its tongue")
	s=pair();p=s.frogs[0];b=s.platforms[0]
	p.rope=4.5
	var center:Vector2=(p.pos+b.pos/b.inv_mass)/(1+1/b.inv_mass)
	for i in range(8):s.solve_tongue(p)
	check(((p.pos+b.pos/b.inv_mass)/(1+1/b.inv_mass)).distance_to(center)<.0001,"Position correction preserves the center of mass")
	check(energy(s)<.0001,"Correcting rope stretch adds no velocity kick")
	s=pair();p=s.frogs[0];b=s.platforms[0];p.anchor.offset=Vector2(1,0);p.pos=Vector2(1,7);p.rope=5;p.vel=Vector2(0,-8)
	momentum=p.vel+b.vel/b.inv_mass;initial=energy(s)
	s.solve_tongue(p)
	check(absf(b.omega)>.1,"An off-center tongue applies torque")
	check((p.vel+b.vel/b.inv_mass).distance_to(momentum)<.0001 and energy(s)<=initial+.0001,"Off-center tension also balances force and energy")
	s=pair();p=s.frogs[0];b=s.platforms[0];s.solve_tongue(p,-5)
	check(absf((p.vel-b.vel).dot((p.pos-b.pos).normalized())+5)<.001,"Reeling imposes the requested relative closing speed")
	check((p.vel+b.vel/b.inv_mass).length()<.0001,"Reeling exchanges momentum rather than propelling both bodies")
	# Isolated coupled pendulum: a neutral frog hanging from a displaced platform.
	# No floors, steering, reeling, landing impulses or scenery contacts can drive it.
	for hz in [60,120]:
		s=pair();p=s.frogs[0];b=s.platforms[0];b.kind="swing"
		b.pos=Vector2(2,12+6-sqrt(32));b.base=Vector2(0,12)
		for side in [-1,1]:b.ropes.append({"local":Vector2(side,0),"anchor":Vector2(side,18),"length":6.0})
		p.anchor.offset=Vector2.ZERO;p.pos=b.pos+Vector2(0,-2);p.rope=2
		var peak:=2.0;var last_peak:=0.0;var minimum:=2.0;var rope_error:=0.0
		for frame in range(hz*12):
			s.step(1.0/hz,[{"tongue":true}])
			peak=maxf(peak,absf(b.pos.x));minimum=minf(minimum,b.pos.x)
			if frame>hz*9:last_peak=maxf(last_peak,absf(b.pos.x))
			rope_error=maxf(rope_error,p.pos.distance_to(s.anchor_point(p.anchor))-p.rope)
		check(minimum<-.6,"Neutral swing reverses through the center at %d Hz"%hz)
		check(peak<2.2 and last_peak<1.5,"Neutral swing damps instead of gaining sideways energy at %d Hz"%hz)
		check(rope_error<.035,"Coupled tongue/suspension remain constrained at %d Hz"%hz)
		print(hz," Hz pendulum: peak=",peak," last=",last_peak," minimum=",minimum," stretch=",rope_error)
	s=pair();p=s.frogs[0];b=s.platforms[0];b.kind="swing"
	for side in [-1,1]:b.ropes.append({"local":Vector2(side,0),"anchor":Vector2(side,18),"length":6.0})
	p.pos=b.pos+Vector2(0,-2);p.rope=2
	var drift:=0.0
	for i in range(720):
		s.step(1.0/120,[{"tongue":true}]);drift=maxf(drift,maxf(absf(p.pos.x),absf(b.pos.x)))
	check(drift<.01,"A motionless frog and hanging platform do not develop lateral drift")
	print("Frog Fighter tongue physics: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
