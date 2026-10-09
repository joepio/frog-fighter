extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=Sim.new([{"slot":0},{"slot":1}],"versus",17);s.countdown=0;s.pickup_timer=999
	check(s.frogs.all(func(p):return p.weapon.is_empty()),"Every frog spawns unarmed")
	var p:Dictionary=s.frogs[0]
	s.add_pickup(p.pos,"seed");s.update_frog(p,{},.0083)
	check(p.weapon=="seed","Walking onto a weapon automatically equips it")
	s.add_pickup(p.pos,"acorn");s.update_frog(p,{},.0083);check(p.weapon=="seed","Walking over a weapon keeps the current gun")
	s.platforms=[s.platform(Vector2(0,3),24,"fixed")];s.crates=[];s.pickups=[]
	p.pos=Vector2(0,(3.2+Sim.RADIUS));p.vel=Vector2.ZERO;p.ground=0;p.jump_prev=false
	var apex:=0.0;var height:=0.0;var landed:=0.0
	for frame in range(140):
		s.update_frog(p,{"jump":true},1.0/120)
		height=maxf(height,p.pos.y-(3.2+Sim.RADIUS))
		if p.vel.y<=0 and apex==0:apex=(frame+1)/120.0
		if p.ground>=0:landed=(frame+1)/120.0;break
	print("JUMP apex=%.3fs airtime=%.3fs height=%.2f"%[apex,landed,height])
	check(apex>.42 and apex<.50 and landed>.94 and landed<1.07,"Jump keeps its quick rise with a gentler descent")
	check(height>4.8 and height<5.2,"Jump reaches roughly five units")
	p.pos=Vector2(0,(3.2+Sim.RADIUS));p.vel=Vector2.ZERO;p.ground=0;p.jump_prev=false
	s.update_frog(p,{"jump":true},1.0/120);s.update_frog(p,{},1.0/120)
	check(p.vel.y<11,"Releasing jump produces a short hop")
	for direction in [-1.0,1.0]:
		var air:=Sim.new([{}]);air.platforms=[];air.pickups=[]
		var falling:Dictionary=air.frogs[0]
		falling.pos=Vector2(0,12);falling.vel=Vector2(-direction*Sim.RUN_SPEED,-1);falling.ground=-1
		for frame in range(48):air.update_frog(falling,{"move":Vector2(direction,0)},1.0/120)
		check(falling.vel.x*direction>8.5 and falling.vel.y<0 and falling.ground<0,"A falling frog can reverse full running momentum in 0.4 seconds toward %s"%direction)
	var world:=World.new();root.add_child(world);world.build(s)
	p.pos=Vector2(0,(3.2+Sim.RADIUS));p.vel=Vector2(6,0);p.ground=0;p.walk=1;p.stride=PI/2;world.update()
	check(world.frogs[0].root.scale.is_equal_approx(Vector3.ONE*.5),"Frog and held weapon are half size")
	var left:Vector3=world.frogs[0].feet[0].position;var right:Vector3=world.frogs[0].feet[1].position
	check(left.y>right.y+.1,"Walking lifts one foot clear of the platform")
	p.stride+=PI;world.update()
	check(world.frogs[0].feet[1].position.y>world.frogs[0].feet[0].position.y+.1,"Foot lift alternates on the next step")
	p.flash=0;p.shot_age=10;p.anchor={}
	s.update_frog(p,{"tongue":true},1.0/120);world.update()
	check(world.frogs[0].open_mouth.visible and not world.frogs[0].closed_mouth.visible,"Tongue input opens mouth even before attaching")
	s.update_frog(p,{"fire":true},1.0/120);world.update()
	check(world.frogs[0].brows[0].visible and world.frogs[0].brows[1].visible,"Holding trigger shows angry brows")
	check(world.frogs[0].open_mouth.visible,"An empty-air tongue keeps the mouth open while it snaps back")
	p.tongue_miss=0;world.update()
	check(not world.frogs[0].open_mouth.visible,"Releasing tongue closes mouth once it is back")
	s.update_frog(p,{},1.0/120);p.shot_age=10;world.update()
	check(not world.frogs[0].brows[0].visible,"Releasing trigger returns to neutral expression")
	p.pos=Vector2(0,3.2+Sim.RADIUS);p.vel=Vector2.ZERO;p.ground=0;p.anchor={};p.jump_prev=false
	for frame in range(36):s.update_frog(p,{"move":Vector2.RIGHT},1.0/120)
	check(p.vel.x>11.9 and p.vel.x<=12.0,"Run reaches 12 units per second promptly")
	check(is_equal_approx(p.pos.y,3.2+Sim.RADIUS),"Smaller collision body rests directly on original platform")
	p.anchor={"platform":-1,"offset":Vector2(9,12)};world.update()
	var tip:Node3D=world.frogs[0].tongue.get_children().back()
	check(Vector2(tip.global_position.x,tip.global_position.y).distance_to(Vector2(9,12))<.001,"Half-size tongue still reaches full world-space anchor")
	world.free()
	s.platforms=[];s.crates=[];s.pickups=[]
	for side in [-1.0,1.0]:
		p.pos=Vector2(side*(Sim.WALL_LIMIT-.01),6);p.vel=Vector2(side*4,-6);p.ground=-1;p.stuck=false;p.wall_release=0;p.jump_prev=false
		s.update_frog(p,{},1.0/120)
		check(p.stuck and p.vel==Vector2.ZERO,"Wall contact catches a falling frog without a button on side %s"%side)
		var height_at_wall:float=p.pos.y
		for frame in range(60):s.update_frog(p,{},1.0/120)
		check(p.stuck and is_equal_approx(p.pos.y,height_at_wall),"Idle frog stays attached on side %s"%side)
		s.update_frog(p,{"move":Vector2(0,1)},1.0/120)
		check(p.stuck and p.pos.y>height_at_wall,"Stick up climbs automatically on side %s"%side)
		s.update_frog(p,{"move":Vector2(-side,0)},1.0/120)
		check(not p.stuck and p.vel.x*side<0,"Moving away releases wall on side %s"%side)
		p.pos=Vector2(side*(Sim.WALL_LIMIT-.01),6);p.vel=Vector2.ZERO;p.wall_release=0
		s.update_frog(p,{},1.0/120);s.update_frog(p,{"jump":true},1.0/120)
		check(not p.stuck and p.vel.x*side< -5 and p.vel.y>16,"Jump pushes away from automatic wall grip on side %s"%side)
		for frame in range(12):s.update_frog(p,{"move":Vector2(side,0),"jump":true},1.0/120)
		check(not p.stuck and absf(p.pos.x)<Sim.WALL_CONTACT-.03,"Holding toward wall cannot immediately cancel wall jump on side %s"%side)
	for seed_value in [17,23,31]:
		s=Sim.new([{"slot":0},{"slot":1},{"slot":2},{"slot":3}],"versus",seed_value);s.countdown=0
		var kills:=0;var shots_fired:=0;var previous_lives:Array=[3,3,3,3]
		for frame in range(10800):
			var input:Array=[]
			for frog in s.frogs:input.append(s.bot(frog))
			s.step(1.0/120,input)
			for event in s.events:
				if event.begins_with("fire_"):shots_fired+=1
			for i in range(4):
				if s.frogs[i].lives<previous_lives[i] and s.frogs[i].hp<=0:kills+=1
				previous_lives[i]=s.frogs[i].lives
			if s.over:break
		print("BOTS seed=%d weapon_kills=%d fire_events=%d elapsed=%.1f winner=%s"%[seed_value,kills,shots_fired,s.clock,s.winner])
		check(kills>=2,"Bots secure multiple weapon kills in seeded match %d"%seed_value)
	print("Frog Fighter movement/AI: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
