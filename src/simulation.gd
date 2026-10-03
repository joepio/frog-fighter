extends RefCounted
var run_speed := 1.0
var jump_height := 1.0
var gravity := 1.0
var damage := 1.0
var pickup_seconds := 4.0
var bot_reaction := 1.0
const Destruction=preload("res://src/destruction.gd")
const Physics=preload("res://src/arena_physics.gd")
const Terrain=preload("res://src/terrain.gd")
const Arenas=preload("res://src/arenas.gd")
const FlameStyle=preload("res://src/flame_style.gd")
## Fixed-step 2D gameplay, rendered as 3D. Positive Y is up.
const FROG_SCALE:=0.5
const RADIUS:=0.53*FROG_SCALE
const WALL_LIMIT:=13.98-RADIUS
const WALL_CONTACT:=WALL_LIMIT-.10
const RUN_SPEED:=12.0
const WEAPON_ORDER=["acorn","seed","bramble","flame","rail","grenade","burr"]
const WEAPON_SCALE:=1.65
const JUMP_SPEED:=22.0
const RISE_GRAVITY:=48.0
const FALL_GRAVITY:=36.0
const AIR_ACCELERATION:=52.0
const COLORS := ["87b957", "68b8d4", "ed8067", "ecc36d"]
const SPAWNS := [Vector2(-10,3.8),Vector2(10,3.8),Vector2(-7,9),Vector2(7,9)]
var frogs: Array = []
var platforms: Array = []
var arena_id:="terrarium"
var spawns:Array=[]
var hooks:Array=[]
var arena_platform_count:=0
var half_width:=14.0
var ceiling:=16.0
var wall_limit:=WALL_LIMIT
var wall_contact:=WALL_CONTACT
var walls:=true
var roof:=true
var safe_water:=true
var theme:="garden"
var kill_y:=-2.0
var supply_count:=6
var supply_sites:Array=[]
var crates: Array = []
var pickups: Array = []
var shots: Array = []
var enemies: Array = []
var particles: Array = []
var events: Array = []
var gore: Array = []
var stains: Array = []
const WEAPON_NAMES={"acorn":"Acorn Cannon","seed":"Pine Repeater","bramble":"Bramble Blaster","flame":"Dragonpod","rail":"Lightning Reed","grenade":"Puffball Lobber","burr":"Burr Bomb"}
const WEAPONS={
 "acorn":{"interval":.58,"speed":23.0,"damage":24.0,"impulse":11.0,"recoil":2.3,"stop":.055},
 "seed":{"interval":.12,"speed":34.0,"damage":9.0,"impulse":3.4,"recoil":.6,"stop":.018},
 "flame":{"interval":.075,"speed":18.0,"damage":3.5,"impulse":.65,"recoil":.12,"stop":0.0},
 "rail":{"interval":1.6,"speed":180.0,"damage":100.0,"impulse":19.0,"recoil":7.0,"stop":.075},
 "burr":{"interval":1.15,"speed":15.0,"damage":145.0,"impulse":22.0,"recoil":0.0,"stop":.085},
 "grenade":{"interval":.9,"speed":13.0,"damage":80.0,"impulse":14.0,"recoil":3.4,"stop":.06},
 "bramble":{"interval":.82,"speed":26.0,"damage":10.0,"impulse":4.5,"recoil":4.6,"stop":.045}}
var fx:Array=[]
var delayed_gore:Array=[]
var fx_clock:=0.0
var hitstop:=0.0
var stop_guard:=0.0
var volley_id:=0
var buffered_inputs:Array=[]
var trauma := 0.0
var clock := 0.0
var countdown := 2.5
var over := false
var winner := ""
var mode := "versus"
var round_number := 1
var enemy_serial:=0
const ENEMY_STATS={
 "bee":{"hp":18.0,"radius":.29,"speed":2.25,"damage":9.0,"color":"e8b94e"},
 "mosquito":{"hp":9.0,"radius":.22,"speed":2.8,"damage":7.0,"color":"ba839b"},
 "bird":{"hp":35.0,"radius":.38,"speed":3.0,"damage":13.0,"color":"d08c58"},
 "boss":{"hp":450.0,"radius":1.0,"speed":2.4,"damage":22.0,"color":"589fbd"}}
var wave := 0
var wave_delay := 2.0
var pickup_timer := 0.0
var rng := RandomNumberGenerator.new()

func _init(roster: Array = [], game_mode: String = "versus", seed_value: int = 1, arena: String = "terrarium") -> void:
	mode = game_mode
	rng.seed = seed_value
	round_number = seed_value
	arena_id=arena if arena in Arenas.IDS else "terrarium"
	var layout:Dictionary=Arenas.layout(arena_id)
	var rules:Dictionary=Arenas.rules(arena_id)
	half_width=rules.width*.5;ceiling=rules.height;walls=rules.walls;roof=rules.roof;safe_water=rules.bottom=="water";theme=rules.theme
	wall_limit=half_width-.02-RADIUS;wall_contact=wall_limit-.10
	spawns=layout.spawns;hooks=layout.hooks
	for item in layout.platforms:
		var shelf:=platform(Vector2(item[0],item[1]),item[2],item[3])
		if item.size()>4:shelf.merge(item[4].duplicate(true),true)
		Destruction.configure(shelf);platforms.append(shelf)
	arena_platform_count=platforms.size()
	for i in range(platforms.size()):
		if platforms[i].kind in ["swing","ferry","lift"]:platforms[i].phase=rng.randf_range(0,TAU)
	if arena_id=="terrarium":
		for i in range(3,7):
			platforms[i].base.x+=rng.randf_range(-.45,.45);platforms[i].pos=platforms[i].base
	if arena_id!="terrarium":
		for shelf in platforms:
			if not usable(shelf):continue
			if shelf.kind in ["ferry","lift"]:
				shelf.pos=shelf.base+(Vector2(2.5,0) if shelf.kind=="ferry" else Vector2(0,2.1))*sin(shelf.phase)
	for shelf in platforms:
		if shelf.kind!="swing":continue
		Physics.prepare(shelf,3.5,.4)
		var length:float=ceiling-.2-shelf.base.y
		var lean:float=sin(shelf.phase)*.045
		shelf.pos=shelf.base+Vector2(sin(lean)*length,(1-cos(lean))*length)
		for side in [-1,1]:
			var local:=Vector2(side*shelf.width*.38,0)
			shelf.ropes.append({"local":local,"anchor":shelf.base+local+Vector2(0,length),"length":length})
	# Optional physics toys sit off the permanent spawn and traversal routes.
	for stack in Arenas.stacks(arena_id):
		for item in stack.pieces:
			var piece:=platform(Vector2(stack.x+item[0],stack.y+item[1]),item[2],"loose")
			piece["material"]=stack.material
			Physics.prepare(piece,2.3 if stack.material=="wood" else 3.5,item[3])
			platforms.append(piece)
	# Shelf fungi belong to the tree landmark and are genuine footholds/anchors.
	if theme=="garden":
		for i in range(7):platforms.append(platform(Vector2(-14.05+(i%2)*.12,2.12+i*2.05),1.1,"fungus"))
	if theme=="mushrooms":
		for side in [-1,1]:
			for i in range(4):platforms.append(platform(Vector2(side*(half_width-.3),2+i*5),2.2,"fungus"))
	for rock in Terrain.rocks(arena_id):
		platforms.append(platform(Vector2(rock.pos.x,rock.pos.y+rock.size.y*Terrain.ROCK_TOP-.2),rock.size.x*Terrain.ROCK_WIDTH,"rock"))
	if safe_water:platforms.append(platform(Vector2(0,Terrain.WATER_LEVEL-.2),half_width*2,"water"))
	Destruction.initialize(self)
	for i in range(roster.size()):
		var p: Dictionary = roster[i].duplicate(true)
		p.merge({"pos":spawns[i%4],"spawn":spawns[i%4],"vel":Vector2.ZERO,"aim":Vector2.RIGHT,
			"hp":100.0,"lives":3,"alive":true,"respawn":0.0,"invincible":2.0,
			"ground":-1,"in_water":false,"coyote":0.0,"wall_release":0.0,"wall_air":0.0,"jump_buffer":0.0,"jump_prev":false,"tongue_prev":false,
			"throw_prev":false,"pending_burr":{},"pickup_delay":0.0,"enemy_guard":0.0,"anchor":{},"rope":0.0,"weapon":"","ammo":0,
			"tongue_active":false,"trigger_held":false,"stride":0.0,"walk":0.0,"wounds":[],"burn":0.0,"shot_age":10.0,"last_weapon":"","last_volley":-1,"hit_dir":Vector2.RIGHT,"cooldown":0.0,"stuck":false,"facing":1.0,"flash":0.0,
			"name":"Frog %d"%(i+1),"color":COLORS[i%4],"slot":i,"bot":false},false)
		frogs.append(p)
	for pos in layout.crates: crates.append({"pos":pos,"vel":Vector2.ZERO,"angle":0.0})
	supply_sites=layout.get("weapons",[]).duplicate(true)
	if not supply_sites.is_empty():supply_sites.append(Arenas.burr_site(arena_id))
	if not supply_sites.is_empty():
		supply_count=supply_sites.size()
		for site in supply_sites:place_supply(site)
	else:
		supply_count=7
		place_supply(Arenas.burr_site(arena_id))
		for i in range(4):add_pickup(spawns[i]+Vector2((2.0 if arena_id=="terrarium" else 1.15)*(1 if i%2==0 else -1),.2),["acorn","seed","bramble","flame"][i])
		for i in range(layout.bonus.size()):
			var position:Vector2=layout.bonus[i]
			for shelf in platforms:
				if not usable(shelf):continue
				if absf(position.x-shelf.base.x)<shelf.width*.5 and position.y>shelf.base.y and position.y-shelf.base.y<1.5:
					position+=shelf.pos-shelf.base;break
			add_pickup(position,["rail","grenade"][i])
	pickup_timer=pickup_seconds

func platform(p:Vector2,width:float,kind:String)->Dictionary:
	return {"pos":p,"base":p,"width":width,"angle":0.0,"omega":0.0,"kind":kind,"phase":0.0,"vel":Vector2.ZERO,"active":true,"stress":0.0,"falling":false,"restore":0.0}

func place_supply(site:Array)->void:
	var position:=Vector2(site[0],site[1])
	for shelf in platforms:
		if shelf.get("rubble",false):continue
		var top:float=shelf.base.y+shelf.get("height",.4)*.5
		if absf(position.x-shelf.base.x)<shelf.width*.5 and position.y>top and position.y-top<1.4:
			if not usable(shelf) or shelf.get("falling",false) or shelf.get("structural_fall",false):return
			position+=shelf.pos-shelf.base;break
	add_pickup(position,site[2]);pickups.back()["site"]=supply_sites.find(site)

func usable(shelf:Dictionary)->bool:return shelf.get("active",true)

func stress_structure(shelf:Dictionary,amount:float)->void:
	if shelf.kind=="crumble" and usable(shelf) and not shelf.falling:
		shelf.stress=minf(1,shelf.stress+amount)

func update_crumble(shelf:Dictionary,dt:float)->void:
	if not shelf.active:
		shelf.restore-=dt
		if shelf.restore<=0:
			shelf.active=true;shelf.falling=false;shelf.stress=0.0;shelf.pos=shelf.base;shelf.vel=Vector2.ZERO;shelf.angle=0.0
		return
	if shelf.falling:
		shelf.vel.y-=18*dt;shelf.pos+=shelf.vel*dt;shelf.angle+=.55*dt*signf(shelf.base.x+.1)
		if shelf.pos.y<kill_y-3:shelf.active=false;shelf.restore=8.0
		return
	if shelf.stress<=0:return
	shelf.stress+=dt
	if shelf.stress>=1.0:
		shelf.falling=true;shelf.vel=Vector2(signf(shelf.base.x)*.4,-1)
		burst(shelf.pos,Color("b8996d"),12);events.append("collapse")
		# Adjacent cracked sections fail in a staggered chain.
		for neighbor in platforms:
			if neighbor==shelf or neighbor.kind!="crumble":continue
			if absf(neighbor.base.y-shelf.base.y)<.3 and absf(neighbor.base.x-shelf.base.x)<(neighbor.width+shelf.width)*.5+.35:stress_structure(neighbor,.45)

func add_pickup(p:Vector2,kind:String)->void:
	pickups.append({"pos":p,"vel":Vector2.ZERO,"kind":kind,"age":0.0})

func aim_frog(p:Dictionary,c:Dictionary)->void:
	var aim:Vector2=c.get("aim",Vector2.ZERO)
	if aim.length()>.18:p.aim=aim.normalized()
	if absf(p.aim.x)>.1:p.facing=signf(p.aim.x)
	p.trigger_held=c.get("fire",false)

func update_aim(inputs:Array)->void:
	# Aim is presentation input: it stays responsive while combat/physics wait.
	for i in range(mini(frogs.size(),inputs.size())):aim_frog(frogs[i],inputs[i])

func step(dt:float,inputs:Array)->void:
	update_aim(inputs)
	events.clear()
	update_feedback(dt)
	if over:hitstop=0.0
	if hitstop>0:
		while buffered_inputs.size()<frogs.size():buffered_inputs.append({})
		for i in range(mini(inputs.size(),frogs.size())):
			for action in ["jump","throw"]:
				buffered_inputs[i][action]=buffered_inputs[i].get(action,false) or inputs[i].get(action,false)
		hitstop=maxf(0,hitstop-dt)
		return
	if countdown>0:
		countdown=maxf(0,countdown-dt)
		return
	clock+=dt
	Destruction.update(self,dt)
	for s in platforms:
		if s.kind=="crumble":update_crumble(s,dt);continue
		var before:Vector2=s.pos
		if Physics.dynamic(s):continue
		if s.kind in ["ferry","lift"]:
			s.pos=s.base+(Vector2(2.5,0) if s.kind=="ferry" else Vector2(0,2.1))*sin(clock*.65+s.phase)
		elif s.kind=="seesaw":
			s.omega+=(-s.angle*3.5-s.omega*1.8)*dt
			s.angle=clampf(s.angle+s.omega*dt,-.32,.32)
			s.omega=clampf(s.omega,-.65,.65)
		s.vel=(s.pos-before)/dt
	Physics.step(self,dt)
	for i in range(frogs.size()):
		var c:Dictionary=inputs[i].duplicate() if i<inputs.size() else {}
		if i<buffered_inputs.size():
			for action in ["jump","throw"]:c[action]=c.get(action,false) or buffered_inputs[i].get(action,false)
		update_frog(frogs[i],c,dt)
	buffered_inputs.clear()
	for i in range(frogs.size()):
		for j in range(i+1,frogs.size()):
			var a:Dictionary=frogs[i]; var b:Dictionary=frogs[j]
			if not a.alive or not b.alive or a.respawn>0 or b.respawn>0: continue
			var d:Vector2=b.pos-a.pos
			if d.length()<RADIUS*2:
				var normal:Vector2=d.normalized() if d.length()>.01 else Vector2.RIGHT
				var shift:Vector2=normal*(RADIUS*2-d.length())*.5
				a.pos-=shift; b.pos+=shift
				var speed:float=(a.vel-b.vel).dot(normal)
				if speed>0:
					a.vel-=normal*speed*.7; b.vel+=normal*speed*.7
	for crate in crates:
		crate.vel.y-=22*dt
		crate.pos+=crate.vel*dt
		land(crate,.55,dt)
		crate.vel.x*=exp(-.6*dt)
		crate.angle+=crate.vel.x*dt*.3
		for p in frogs:
			if not p.alive or p.respawn>0: continue
			var d:Vector2=crate.pos-p.pos
			if d.length()<RADIUS+.55:
				var n:Vector2=d.normalized() if d.length()>.01 else Vector2.RIGHT
				if p.ground>=0 and n.y>.4:
					crate.pos+=n*(RADIUS+.55-d.length())
				else:
					crate.pos+=n*(RADIUS+.55-d.length())*.7
					p.pos-=n*(RADIUS+.55-d.length())*.3
				var impact:float=(p.vel-crate.vel).dot(n)
				if impact>0: crate.vel+=n*impact*.65; p.vel-=n*impact*.35
		if crate.pos.y<kill_y or absf(crate.pos.x)>half_width+3:crate.pos=spawns[rng.randi_range(0,3)]+Vector2(0,2);crate.vel=Vector2.ZERO
	for item in pickups:
		item.age+=dt; item.vel.y-=20*dt;item.pos+=item.vel*dt
		var on_ground:int=land(item,.35,dt)
		if item.has("spin"):
			item.angle+=item.spin*dt
			if on_ground>=0:item.spin*=exp(-8*dt);item.vel.x*=exp(-3*dt)
		if walls and absf(item.pos.x)>half_width-.5:item.pos.x=clampf(item.pos.x,-half_width+.5,half_width-.5);item.vel.x*=-.45
		if item.pos.y<kill_y or absf(item.pos.x)>half_width+3:item["lost"]=true
	pickups=pickups.filter(func(item):return not item.get("lost",false))
	pickup_timer-=dt
	if pickup_timer<=0 and pickups.size()<supply_count and not platforms.is_empty():
		pickup_timer=pickup_seconds
		if not supply_sites.is_empty():
			var site:Array=supply_sites[rng.randi_range(0,supply_sites.size()-1)]
			if not pickups.any(func(item):return item.get("site",-1)==supply_sites.find(site)):place_supply(site)
		else:
			var shelf:Dictionary=platforms[rng.randi_range(0,mini(arena_platform_count-1,platforms.size()-1))]
			if usable(shelf):add_pickup(shelf.pos+Vector2(rng.randf_range(-.3,.3)*shelf.width,1),WEAPON_ORDER[rng.randi_range(0,WEAPON_ORDER.size()-1)])
	update_shots(dt)
	if mode=="survival" and not over: update_survival(dt)
	update_debris(dt)
	if over:return # The declared result stays final while the winner plays.
	var living:Array=frogs.filter(func(p):return p.alive)
	if mode=="versus" and frogs.size()>1 and living.size()<=1:
		over=true;winner=living[0].name if living.size()==1 else "Draw"
	elif mode=="survival" and living.is_empty(): over=true;winner="Wave %d reached"%wave

func update_frog(p:Dictionary,c:Dictionary,dt:float)->void:
	aim_frog(p,c)
	if not p.alive: return
	if p.respawn>0:
		p.respawn-=dt
		if p.respawn<=0:
			p.pos=p.spawn;p.vel=Vector2.ZERO;p.hp=100.0;p.invincible=2.0;p.last_volley=-1;p.flash=0.0;p.burn=0.0;p.wounds.clear()
			p.stuck=false;p.in_water=false;p.ground=-1;p.wall_release=0.0;p.wall_air=0.0
		return
	if not p.pending_burr.is_empty():
		p.pending_burr.delay-=dt
		if p.pending_burr.delay<=0:release_burr(p)
	p.invincible=maxf(0,p.invincible-dt)
	p.cooldown=maxf(0,p.cooldown-dt);p.pickup_delay=maxf(0,p.pickup_delay-dt);p.enemy_guard=maxf(0,p.enemy_guard-dt)
	if p.ground>=0 and not usable(platforms[p.ground]):p.ground=-1
	if not p.anchor.is_empty() and p.anchor.platform>=0 and not usable(platforms[p.anchor.platform]):p.anchor={}
	var move:Vector2=c.get("move",Vector2.ZERO)
	var jump:bool=c.get("jump",false)
	var tongue:bool=c.get("tongue",false)
	p.tongue_active=tongue;p.trigger_held=c.get("fire",false)
	if jump and not p.jump_prev: p.jump_buffer=.14
	else: p.jump_buffer=maxf(0,p.jump_buffer-dt)
	if p.ground>=0: p.coyote=.12
	else: p.coyote=maxf(0,p.coyote-dt)
	var was_stuck:bool=p.stuck
	var grip_normal:=Vector2(-signf(p.pos.x),0)
	p.wall_release=maxf(0,p.wall_release-dt);p.wall_air=maxf(0,p.wall_air-dt)
	var at_wall:bool=walls and absf(p.pos.x)>wall_contact
	var leaving_wall:bool=move.dot(grip_normal)>.15
	if at_wall and was_stuck and leaving_wall:p.wall_release=.18
	p.stuck=false
	if at_wall:
		p.stuck=p.wall_release<=0 and not leaving_wall and p.vel.dot(grip_normal)<1.0
	elif c.get("grip",false):
		for shelf in platforms:
			if not usable(shelf):continue
			if shelf.kind=="water":continue
			var relative:Vector2=(p.pos-shelf.pos).rotated(-shelf.angle)
			if absf(relative.x)<shelf.width*.5+.15 and absf(relative.y)<RADIUS+.35:
				grip_normal=Vector2(0,signf(relative.y)).rotated(shelf.angle)
				p.stuck=true
				p.pos+=shelf.vel*dt
				break
	if p.stuck:
		p.vel=Vector2(0,move.y*5) if absf(grip_normal.x)>.8 else Vector2(move.x*4,0).rotated(grip_normal.angle()-PI*.5)
	elif not p.anchor.is_empty():
		p.vel.x+=move.x*26*dt
	else:
		p.vel.x=move_toward(p.vel.x,move.x*RUN_SPEED*run_speed,(60 if p.ground>=0 else (55 if p.wall_air>0 else AIR_ACCELERATION))*dt)
	if p.jump_buffer>0 and (p.coyote>0 or p.stuck or was_stuck or not p.anchor.is_empty()):
		var launch:=Vector2.ZERO
		if p.ground>=0 and Physics.dynamic(platforms[p.ground]):
			var support:Dictionary=platforms[p.ground]
			launch=Physics.velocity(support,p.pos)*.65
			Physics.impulse(support,Vector2(0,-5),p.pos)
		p.vel.y=JUMP_SPEED*jump_height;p.vel+=launch
		if p.stuck or was_stuck:
			p.vel=grip_normal*(5.5 if absf(grip_normal.x)>.8 else 9)+Vector2(0,JUMP_SPEED*jump_height if absf(grip_normal.x)>.8 else 5)
			p.pos+=grip_normal*.2
			p.wall_release=.10;p.wall_air=.40
		p.stuck=false;p.ground=-1;p.coyote=0.0;p.jump_buffer=0.0;p.anchor={}
		burst(p.pos,Color(p.color),5);events.append("jump")
	if not jump and p.jump_prev and p.vel.y>5: p.vel.y*=.48
	if tongue and not p.tongue_prev:
		p.anchor=cast_tongue(p.pos,p.aim)
		if not p.anchor.is_empty():
			p.rope=p.pos.distance_to(anchor_point(p.anchor));events.append("tongue")
	if not tongue: p.anchor={}
	if not p.stuck:p.vel.y-=(25.0 if not p.anchor.is_empty() else (RISE_GRAVITY if p.vel.y>0 else FALL_GRAVITY))*gravity*dt
	p.vel=p.vel.limit_length(30)
	p.pos+=p.vel*dt
	if not p.anchor.is_empty():
		var previous_length:float=p.rope
		p.rope=clampf(p.rope-move.y*5*dt,1.2,12)
		var reel_speed:float=(p.rope-previous_length)/dt
		# Alternate the tongue and suspension constraints. Neither endpoint is fixed
		# when the tongue catches a physical body, and positional drift adds no kick.
		for iteration in range(6):
			solve_tongue(p,reel_speed)
			if p.anchor.platform>=0:
				var support:Dictionary=platforms[p.anchor.platform]
				if Physics.dynamic(support):
					for rope in support.ropes:Physics.solve_rope(support,rope,dt)
	p.ground=land(p,RADIUS,dt)
	p.in_water=p.ground>=0 and platforms[p.ground].kind=="water"
	var walking:float=clampf(absf(p.vel.x)/5.5,0,1) if p.ground>=0 and not p.stuck and not p.in_water else 0.0
	p.walk=move_toward(p.walk,walking,dt*12)
	if walking>.02:p.stride+=absf(p.vel.x)*dt*TAU/1.4
	if walls and p.pos.x< -wall_limit:p.pos.x=-wall_limit;p.vel.x=maxf(0,p.vel.x)
	if walls and p.pos.x>wall_limit:p.pos.x=wall_limit;p.vel.x=minf(0,p.vel.x)
	if roof and p.pos.y>ceiling-.7:p.pos.y=ceiling-.7;p.vel.y=minf(0,p.vel.y)
	if c.get("throw",false) and not p.throw_prev:throw_weapon(p)
	if p.weapon.is_empty() and p.pickup_delay<=0 and p.pending_burr.is_empty():pickup(p)
	if c.get("fire",false) and p.cooldown<=0:fire(p)
	p.jump_prev=jump;p.tongue_prev=tongue;p.throw_prev=c.get("throw",false)
	if p.hp<=0 or (not safe_water and p.pos.y<kill_y) or (not walls and absf(p.pos.x)>half_width+2):knockout(p)

func solve_tongue(p:Dictionary,reel_speed:float=0.0)->void:
	if p.anchor.is_empty():return
	var anchor:Vector2=anchor_point(p.anchor)
	var delta:Vector2=p.pos-anchor
	var distance:float=delta.length()
	# A slack tongue cannot push, pull or continuously accelerate either endpoint.
	if distance<.001 or distance<p.rope-.001:return
	var normal:Vector2=delta/distance
	var support:Dictionary=platforms[p.anchor.platform] if p.anchor.platform>=0 else {}
	var moving:bool=not support.is_empty() and Physics.dynamic(support)
	var inverse_mass:float=support.inv_mass if moving else 0.0
	var inverse_inertia:float=support.inv_inertia if moving else 0.0
	var arm:Vector2=anchor-support.pos if not support.is_empty() else Vector2.ZERO
	var anchor_velocity:Vector2=Physics.velocity(support,anchor) if not support.is_empty() else Vector2.ZERO
	var effective:float=1.0+inverse_mass+pow(arm.cross(normal),2)*inverse_inertia
	var separating:float=(p.vel-anchor_velocity).dot(normal)-reel_speed
	var tension:float=maxf(0,separating)/effective
	# Equal and opposite impulses use velocity at the actual attachment point,
	# including platform rotation. Static scenery supplies the external reaction.
	p.vel-=normal*tension
	if moving:Physics.impulse(support,normal*tension,anchor)
	var correction:float=maxf(0,distance-p.rope)/effective
	p.pos-=normal*correction
	if moving:
		support.pos+=normal*correction*inverse_mass
		support.angle+=arm.cross(normal)*correction*inverse_inertia

func land(body:Dictionary,radius:float,dt:float)->int:
	var grounded:=-1
	for i in range(platforms.size()):
		var s:Dictionary=platforms[i]
		if not usable(s):continue
		if s.kind in ["loose","barricade","pier"]:
			var contact:Dictionary=Physics.circle(s,body.pos,radius)
			if contact.is_empty():continue
			var normal:Vector2=contact.normal
			body.pos+=normal*contact.depth
			var relative:Vector2=body.vel-Physics.velocity(s,contact.point)
			var speed:float=relative.dot(normal)
			if body.has("hp") and speed< -7 and Physics.velocity(s,contact.point).dot(normal)>7 and clock>s.get("hit_ready",0.0):
				s["hit_ready"]=clock+.4
				hurt(body,minf(28,-speed*1.4),normal*4,"contact",-1,contact.point)
			if speed<0:
				var force:float=-speed/(1+s.get("inv_mass",0.0)+pow((contact.point-s.pos).cross(normal),2)*s.get("inv_inertia",0.0))
				Physics.impulse(s,-normal*force,contact.point)
				body.vel-=normal*speed
			if normal.y>.55:
				grounded=i;body.pos+=Physics.velocity(s,contact.point)*dt
			continue
		if s.kind=="water":
			# Frogs float partly submerged; loose props float with them.
			var surface:float=Terrain.WATER_LEVEL+radius*(.15 if body.has("hp") else .6)
			if absf(body.pos.x)<=half_width and body.pos.y<surface and body.vel.y<=0:
				body.pos.y=surface;body.vel.y=0;grounded=i
			continue
		var normal:=Vector2(-sin(s.angle),cos(s.angle))
		var relative:Vector2=(body.pos-s.pos).rotated(-s.angle)
		var speed:float=(body.vel-s.vel).dot(normal)
		var surface:=radius+.2
		# One-way tops allow a frog to jump up through a shelf.
		if absf(relative.x)<s.width*.5+radius*.45 and relative.y<surface and relative.y>surface-maxf(.28,-speed*dt+.08) and speed<=.2:
			body.pos+=normal*(surface-relative.y)
			if Physics.dynamic(s):
				Physics.impulse(s,normal*minf(0,speed)*.7,body.pos-normal*radius)
				if body.has("hp"):
					var shove:float=(body.vel.x-s.vel.x)*(.35 if speed< -3 else dt*3.0)
					Physics.impulse(s,Vector2(shove,0),body.pos-normal*radius)
			body.vel-=normal*minf(0,speed)
			body.pos+=s.vel*dt
			body.vel.x*=exp(-.4*dt)
			grounded=i
			if body.has("hp") and s.get("stress",0)<=0:stress_structure(s,.01)
			if s.kind=="seesaw":s.omega-=relative.x*.085*dt
	return grounded

func shelf_hit(shelf:Dictionary,a:Vector2,b:Vector2)->Dictionary:
	if shelf.get("inv_mass",0)>0 or shelf.get("max_hp",0)>0:return Physics.ray(shelf,a,b)
	var start:Vector2=shelf.pos+Vector2(-shelf.width*.5,.2).rotated(shelf.angle)
	var end:Vector2=shelf.pos+Vector2(shelf.width*.5,.2).rotated(shelf.angle)
	var contact:Variant=Geometry2D.segment_intersects_segment(a,b,start,end)
	return {} if contact==null else {"point":contact,"normal":Vector2(0,1).rotated(shelf.angle)}

func cast_tongue(origin:Vector2,direction:Vector2)->Dictionary:
	var end:Vector2=origin+direction.normalized()*12
	var nearest:=12.1
	var hit:Dictionary={}
	for i in range(platforms.size()+3):
		var a:Vector2;var b:Vector2
		if i<platforms.size():
			var s:Dictionary=platforms[i]
			if s.kind=="water" or not usable(s):continue
			if s.get("inv_mass",0)>0 or s.get("max_hp",0)>0:
				var contact:Dictionary=shelf_hit(s,origin,end)
				if not contact.is_empty():
					var distance:float=origin.distance_to(contact.point)
					if distance<nearest and distance>.6:
						nearest=distance;hit={"platform":i,"offset":(contact.point-s.pos).rotated(-s.angle)}
				continue
			a=s.pos+Vector2(-s.width*.5,.2).rotated(s.angle)
			b=s.pos+Vector2(s.width*.5,.2).rotated(s.angle)
		elif i==platforms.size():
			if not roof:continue
			a=Vector2(-half_width,ceiling-.2);b=Vector2(half_width,ceiling-.2)
		elif i==platforms.size()+1:
			if not walls:continue
			a=Vector2(-half_width,0);b=Vector2(-half_width,ceiling)
		else:
			if not walls:continue
			a=Vector2(half_width,0);b=Vector2(half_width,ceiling)
		var point:Variant=Geometry2D.segment_intersects_segment(origin,end,a,b)
		if point!=null and origin.distance_to(point)<nearest and origin.distance_to(point)>.6:
			nearest=origin.distance_to(point)
			hit={"platform":i if i<platforms.size() else -1,"offset":(point-platforms[i].pos).rotated(-platforms[i].angle) if i<platforms.size() else point}
	for hook in hooks:
		var entry:float=flame_circle_entry(origin,end,hook,.30)
		if entry<INF and origin.distance_to(hook)<nearest and origin.distance_to(hook)>.6:
			nearest=origin.distance_to(hook);hit={"platform":-1,"offset":hook}
	if not hit.is_empty() and hit.platform>=0:stress_structure(platforms[hit.platform],.01)
	return hit

func anchor_point(anchor:Dictionary)->Vector2:
	if anchor.platform<0:return anchor.offset
	var s:Dictionary=platforms[anchor.platform]
	return s.pos+anchor.offset.rotated(s.angle)

func pickup(p:Dictionary)->void:
	for i in range(pickups.size()):
		if p.pos.distance_to(pickups[i].pos)>.85:continue
		if pickups[i].get("thrown_by",-1)==p.slot and clock<pickups[i].get("owner_unlock",0.0):continue
		p.weapon=pickups[i].kind;p.ammo=pickups[i].get("ammo",{"flame":70,"seed":18,"rail":3,"grenade":6,"burr":3}.get(p.weapon,10))
		pickups.remove_at(i);events.append("pickup");return

func throw_weapon(p:Dictionary)->void:
	if p.weapon.is_empty() or not p.pending_burr.is_empty():return
	pickups.append({"pos":p.pos+p.aim*.6+Vector2(0,.12),"vel":p.vel*.5+p.aim*12+Vector2(0,4),
		"kind":p.weapon,"ammo":p.ammo,"age":0.0,"angle":p.aim.angle(),"spin":-p.facing*11,
		"thrown_by":p.slot,"owner_unlock":clock+.75})
	p.weapon="";p.ammo=0;p.shot_age=10;p.pickup_delay=.25

func fire(p:Dictionary)->void:
	if p.weapon.is_empty() or p.ammo<=0:return
	if not p.pending_burr.is_empty():return
	if p.weapon=="burr":
		p.pending_burr={"delay":.16,"aim":p.aim}
		p.cooldown=WEAPONS.burr.interval;p.ammo-=1;p.shot_age=0;p.last_weapon="burr"
		if p.ammo<=0:p.weapon=""
		return
	var kind:String=p.weapon;var spec:Dictionary=WEAPONS[kind]
	var count:=5 if kind=="bramble" else 1
	volley_id+=1
	if kind=="rail":fire_rail(p)
	for i in range(0 if kind=="rail" else count):
		var aim:Vector2=p.aim.rotated((i-2)*.10 if count>1 else 0)
		shots.append({"pos":p.pos+aim*.7*FROG_SCALE,"vel":aim*spec.speed+p.vel*.25+(Vector2(0,4) if kind=="grenade" else Vector2.ZERO),
			"owner":p.slot,"kind":kind,"volley":volley_id,"life":.28 if kind=="flame" else (1.65 if kind=="grenade" else (.62 if kind=="bramble" else 1.5))})
	p.vel-=p.aim*spec.recoil
	if p.ground>=0:Physics.impulse(platforms[p.ground],-p.aim*spec.recoil*.8,p.pos-Vector2(0,RADIUS))
	p.cooldown=spec.interval;p.ammo-=1;p.shot_age=0.0;p.last_weapon=kind
	if kind=="flame":
		add_fx("flame",shots.back().pos,p.aim,.30,kind)
		fx.back()["volley"]=volley_id;fx.back()["reach"]=4.8;fx.back()["velocity"]=shots.back().vel
		add_fx("flame_smoke",shots.back().pos,p.aim,.65,kind)
		fx.back()["volley"]=volley_id;fx.back()["reach"]=4.8;fx.back()["velocity"]=shots.back().vel*.48
	else:
		add_fx("muzzle",p.pos+p.aim*(.83+.61*WEAPON_SCALE)*FROG_SCALE,p.aim,.095 if kind!="bramble" else .15,kind)
		add_fx("smoke",p.pos+p.aim*(.83+.70*WEAPON_SCALE)*FROG_SCALE,p.aim,.32,kind)
	trauma=minf(.65,trauma+(.10 if kind=="bramble" else .035))
	if p.ammo<=0:p.weapon=""
	if kind!="flame" or volley_id%3==0:events.append("fire_"+kind)

func release_burr(p:Dictionary)->void:
	var aim:Vector2=p.pending_burr.aim
	p.pending_burr={};p.shot_age=0.0;p.last_weapon="burr"
	volley_id+=1
	# Start close to the hand and sweep outward: a point-blank wall must not be skipped.
	shots.append({"pos":p.pos+aim*.05+Vector2(0,.16),"vel":aim*WEAPONS.burr.speed+p.vel*.45+Vector2(0,5),
		"owner":p.slot,"kind":"burr","volley":volley_id,"life":6.0,"age":0.0,"spin":-p.facing*11})
	events.append("fire_burr")

func update_burr(shot:Dictionary,dt:float)->void:
	var previous:Vector2=shot.pos
	shot.age+=dt;shot.life-=dt;shot.vel.y-=22*dt
	var end:Vector2=previous+shot.vel*dt
	var nearest:=INF;var normal:=Vector2.ZERO
	for victim in frogs:
		if victim.slot==shot.owner or mode=="survival" or not victim.alive or victim.respawn>0:continue
		var entry:float=flame_circle_entry(previous,end,victim.pos,RADIUS+.14)
		if entry<nearest:nearest=entry;normal=(previous.lerp(end,entry)-victim.pos).normalized()
	for bug in enemies:
		var entry:float=flame_circle_entry(previous,end,bug.pos,bug.get("radius",.4)+.14)
		if entry<nearest:nearest=entry;normal=(previous.lerp(end,entry)-bug.pos).normalized()
	for box in crates:
		var entry:float=flame_circle_entry(previous,end,box.pos,.69)
		if entry<nearest:nearest=entry;normal=(previous.lerp(end,entry)-box.pos).normalized()
	for shelf in platforms:
		if not usable(shelf) or shelf.kind=="water":continue
		var expanded:Dictionary=shelf.duplicate();expanded.width+=.28;expanded["height"]=shelf.get("height",.4)+.28
		var hit:Dictionary=Physics.ray(expanded,previous,end)
		if hit.is_empty():continue
		var entry:float=previous.distance_to(hit.point)/maxf(.00001,previous.distance_to(end))
		if entry<nearest:nearest=entry;normal=hit.normal
	# The first boundary hit wins, just like the nearest actor or piece of scenery.
	var edges:Array=[]
	if walls:
		edges.append([Vector2(-half_width+.14,-10),Vector2(-half_width+.14,ceiling+20),Vector2.RIGHT])
		edges.append([Vector2(half_width-.14,-10),Vector2(half_width-.14,ceiling+20),Vector2.LEFT])
	if roof:edges.append([Vector2(-half_width,ceiling-.34),Vector2(half_width,ceiling-.34),Vector2(0,-1)])
	if safe_water:edges.append([Vector2(-half_width,Terrain.WATER_LEVEL+.14),Vector2(half_width,Terrain.WATER_LEVEL+.14),Vector2(0,1)])
	for edge in edges:
		var point:Variant=Geometry2D.segment_intersects_segment(previous,end,edge[0],edge[1])
		if point!=null:
			var entry:float=previous.distance_to(point)/maxf(.00001,previous.distance_to(end))
			if entry<nearest:nearest=entry;normal=edge[2]
	if nearest<INF:
		shot.pos=previous.lerp(end,nearest)+normal*.025;explode_grenade(shot);return
	shot.pos=end
	if shot.pos.y<kill_y-4 or absf(shot.pos.x)>half_width+6:shot.life=0

func fire_rail(p:Dictionary)->void:
	var origin:Vector2=p.pos+p.aim*.36
	var end:Vector2=origin+p.aim*32
	var nearest:=32.0
	var blocking_box:Dictionary={}
	var blocking_shelf:Dictionary={}
	for shelf in platforms:
		if not usable(shelf):continue
		var contact:Dictionary=shelf_hit(shelf,origin,end)
		if not contact.is_empty() and origin.distance_to(contact.point)<nearest:nearest=origin.distance_to(contact.point);blocking_shelf=shelf
	for box in crates:
		var entry:float=flame_circle_entry(origin,end,box.pos,.55)
		if entry<INF and entry*32<nearest:
			nearest=entry*32;blocking_box=box;blocking_shelf={}
	if not blocking_box.is_empty():blocking_box.vel+=p.aim*12
	if walls and absf(p.aim.x)>.001:nearest=minf(nearest,maxf(0,((half_width if p.aim.x>0 else -half_width)-origin.x)/p.aim.x))
	if roof and p.aim.y>.001:nearest=minf(nearest,maxf(0,(ceiling-.2-origin.y)/p.aim.y))
	end=origin+p.aim*nearest
	if not blocking_shelf.is_empty():
		stress_structure(blocking_shelf,1.0)
		Physics.impulse(blocking_shelf,p.aim*32,end)
		Destruction.damage(self,blocking_shelf,WEAPONS.rail.damage,end,p.aim*32,"rail")
	for victim in frogs:
		if victim.slot==p.slot or mode=="survival" or not victim.alive or victim.respawn>0:continue
		if flame_circle_entry(origin,end,victim.pos,RADIUS+.10)<INF:
			hurt(victim,WEAPONS.rail.damage,p.aim*WEAPONS.rail.impulse,"rail",volley_id,victim.pos-p.aim*RADIUS)
	for bug in enemies:
		if flame_circle_entry(origin,end,bug.pos,bug.get("radius",.4))<INF:hurt_enemy(bug,WEAPONS.rail.damage,p.aim*8,"rail")
	add_fx("rail",origin,p.aim,.23,"rail");fx.back()["length"]=nearest
	add_fx("hit",end,-p.aim,.25,"rail");impact_stop(.06);trauma=maxf(trauma,.42)

func update_grenade(shot:Dictionary,dt:float)->void:
	var previous:Vector2=shot.pos
	shot.life-=dt;shot.vel.y-=18*dt;shot.pos+=shot.vel*dt
	if shot.life<=0 or shot.pos.y<(.25 if safe_water else kill_y):explode_grenade(shot);return
	for victim in frogs:
		if victim.slot==shot.owner or mode=="survival" or not victim.alive or victim.respawn>0:continue
		if flame_circle_entry(previous,shot.pos,victim.pos,RADIUS+.13)<INF:explode_grenade(shot);return
	for bug in enemies:
		if flame_circle_entry(previous,shot.pos,bug.pos,bug.get("radius",.4)+.12)<INF:explode_grenade(shot);return
	for shelf in platforms:
		if not usable(shelf):continue
		if Physics.dynamic(shelf) or shelf.get("max_hp",0)>0:
			var hit:Dictionary=Physics.ray(shelf,previous,shot.pos)
			if not hit.is_empty():
				var speed:float=(shot.vel-Physics.velocity(shelf,hit.point)).dot(hit.normal)
				if speed<0:
					Physics.impulse(shelf,hit.normal*speed*.22,hit.point)
					shot.pos=hit.point+hit.normal*.15;shot.vel-=hit.normal*speed*1.62
					break
			continue
		var normal:=Vector2(-sin(shelf.angle),cos(shelf.angle))
		var a:Vector2=shelf.pos+Vector2(-shelf.width*.5,.34).rotated(shelf.angle)
		var b:Vector2=shelf.pos+Vector2(shelf.width*.5,.34).rotated(shelf.angle)
		var contact:Variant=Geometry2D.segment_intersects_segment(previous,shot.pos,a,b)
		if contact!=null and shot.vel.dot(normal)<0:
			shot.pos=contact+normal*.015;shot.vel-=normal*shot.vel.dot(normal)*1.62;shot.vel.x*=.84
			burst(shot.pos,Color("dbb560"),3);break
	for box in crates:
		var delta:Vector2=shot.pos-box.pos
		if delta.length()<.70:
			var normal:Vector2=delta.normalized() if delta.length()>.001 else Vector2.UP
			shot.pos=box.pos+normal*.71
			if shot.vel.dot(normal)<0:shot.vel-=normal*shot.vel.dot(normal)*1.65;box.vel-=normal*2
	if walls and absf(shot.pos.x)>half_width-.2:shot.pos.x=clampf(shot.pos.x,-half_width+.2,half_width-.2);shot.vel.x*=-.65
	if roof and shot.pos.y>ceiling-.4:shot.pos.y=ceiling-.4;shot.vel.y=-absf(shot.vel.y)*.65

func explode_grenade(shot:Dictionary)->void:
	if shot.get("detonated",false):return
	shot["detonated"]=true;shot.life=0
	var big:bool=shot.get("kind","")=="burr"
	var weapon:String="burr" if big else "grenade"
	var radius:float=4.4 if big else 2.8
	var damage:float=WEAPONS[weapon].damage
	var impulse:float=WEAPONS[weapon].impulse
	for victim in frogs:
		if not victim.alive or victim.respawn>0 or (mode=="survival" and victim.slot!=shot.owner):continue
		var delta:Vector2=victim.pos-shot.pos
		if delta.length()>radius:continue
		var direction:Vector2=delta.normalized() if delta.length()>.01 else Vector2(0,1)
		if not bot_clear_shot(shot.pos+direction*.16,victim.pos):continue
		var force:float=1.0-clampf(delta.length()/radius,0,1)*.65
		hurt(victim,damage*force,direction*impulse*force+Vector2(0,4),weapon,shot.volley,shot.pos)
	for box in crates:
		var delta:Vector2=box.pos-shot.pos
		if delta.length()<radius+.5:box.vel+=delta.normalized()*(22 if big else 13)+Vector2(0,10 if big else 7)
	for bug in enemies:
		if bug.pos.distance_to(shot.pos)<radius+bug.get("radius",.4):hurt_enemy(bug,damage*(1-clampf(bug.pos.distance_to(shot.pos)/(radius+1),0,1)*.65),(bug.pos-shot.pos).normalized()*(17 if big else 10),weapon)
	for shelf in platforms:
		if not usable(shelf):continue
		var local:Vector2=(shot.pos-shelf.pos).rotated(-shelf.angle)
		var extent:Vector2=Physics.half(shelf)
		var contact:Vector2=shelf.pos+local.clamp(-extent,extent).rotated(shelf.angle)
		var distance:float=contact.distance_to(shot.pos)
		if distance<radius:
			stress_structure(shelf,1.0)
			var delta:Vector2=shelf.pos-shot.pos
			var force:float=maxf(.2,1-distance/radius)
			var push:Vector2=(delta.normalized()*(62 if big else 38)+Vector2(0,30 if big else 20))*force
			Physics.impulse(shelf,push,contact)
			Destruction.damage(self,shelf,damage*force,contact,push,weapon)
	if big:
		add_fx("impact_blast",shot.pos,Vector2.RIGHT,1.65,"burr");fx.back()["seed"]=shot.volley
		impact_stop(.085);trauma=maxf(trauma,.85)
	else:
		add_fx("explosion",shot.pos,Vector2.RIGHT,.45,"grenade")
		add_fx("smoke",shot.pos,Vector2(0,1),.85,"grenade")
		burst(shot.pos,Color("f1b04e"),24);impact_stop(.065);trauma=maxf(trauma,.6)

func flame_reach(p:Dictionary,maximum:float,from:Vector2=Vector2.INF)->float:
	return flame_contact(p,maximum,from).distance

static func flame_circle_entry(a:Vector2,b:Vector2,center:Vector2,radius:float)->float:
	var delta:=b-a;var offset:=a-center
	var c:float=offset.length_squared()-radius*radius
	if c<=0:return 0.0
	var length_squared:float=delta.length_squared()
	if length_squared<.000001:return INF
	var along:float=offset.dot(delta)
	var discriminant:float=along*along-length_squared*c
	if discriminant<0:return INF
	var t:float=(-along-sqrt(discriminant))/length_squared
	return t if t>=0 and t<=1 else INF

func flame_contact(p:Dictionary,maximum:float,from:Vector2=Vector2.INF)->Dictionary:
	# Visual contact uses rendered surfaces, not the wider damage hitboxes.
	var origin:Vector2=from if from.is_finite() else p.pos+p.aim*.7*FROG_SCALE
	var previous:Vector2=origin
	for segment in range(1,17):
		var distance:float=maximum*segment/16.0
		var point:Vector2=origin+FlameStyle.motion(p.aim*18,distance/18)
		var nearest:=INF
		for victim in frogs:
			if mode=="survival" or victim.slot==p.slot or not victim.alive or victim.respawn>0 or victim.invincible>.1:continue
			nearest=minf(nearest,flame_circle_entry(previous,point,victim.pos,.46*FROG_SCALE))
		for group in [{"items":crates,"radius":.55},{"items":enemies,"radius":.40}]:
			for item in group.items:
				nearest=minf(nearest,flame_circle_entry(previous,point,item.pos,item.get("radius",group.radius)))
		for shelf in platforms:
			if not usable(shelf):continue
			var contact:Dictionary=shelf_hit(shelf,previous,point)
			if not contact.is_empty():nearest=minf(nearest,previous.distance_to(contact.point)/maxf(.001,previous.distance_to(point)))
		if nearest<INF:
			return {"distance":maxf(.06,maximum*((segment-1)+nearest)/16.0),"blocked":true,"point":previous.lerp(point,nearest)}
		previous=point
	return {"distance":maximum,"blocked":false,"point":previous}

func update_shots(dt:float)->void:
	for shot in shots:
		if shot.kind=="burr":
			update_burr(shot,dt);continue
		if shot.kind=="grenade":
			update_grenade(shot,dt);continue
		shot.life-=dt
		if shot.life<=0:continue
		var previous:Vector2=shot.pos
		if shot.kind=="flame":
			shot.pos+=FlameStyle.motion(shot.vel,dt);shot.vel.y+=FlameStyle.BUOYANCY*dt
		else:
			shot.pos+=shot.vel*dt;shot.vel.y-=4*dt
		# Resolve only the nearest collision: a spent round cannot hit scenery behind its victim.
		var nearest:=INF;var target:Dictionary={};var target_kind:="";var point:Vector2=shot.pos
		for p in frogs:
			var same_volley:bool=shot.get("volley",-1)>0 and p.last_volley==shot.get("volley",-1)
			if mode=="survival" or p.slot==shot.owner or not p.alive or p.respawn>0 or (p.invincible>0 and not same_volley):continue
			var contact:Vector2=Geometry2D.get_closest_point_to_segment(p.pos,previous,shot.pos)
			var distance:float=previous.distance_squared_to(contact)
			if contact.distance_to(p.pos)<RADIUS+.15 and distance<nearest:
				nearest=distance;target=p;target_kind="frog";point=contact
		for group in [{"items":enemies,"radius":.65,"kind":"bug"},{"items":crates,"radius":.75,"kind":"wood"}]:
			for body in group.items:
				if body.get("hp",1)<=0:continue
				var contact:Vector2=Geometry2D.get_closest_point_to_segment(body.pos,previous,shot.pos)
				var distance:float=previous.distance_squared_to(contact)
				if contact.distance_to(body.pos)<body.get("radius",group.radius)+(.10 if group.kind=="bug" else 0.0) and distance<nearest:
					nearest=distance;target=body;target_kind=group.kind;point=contact
		for shelf in platforms:
			if not usable(shelf):continue
			var contact:Dictionary=shelf_hit(shelf,previous,shot.pos)
			if not contact.is_empty() and previous.distance_squared_to(contact.point)<nearest:
				nearest=previous.distance_squared_to(contact.point);target=shelf;target_kind="shelf";point=contact.point
		if not target_kind.is_empty():
			var spec:Dictionary=WEAPONS[shot.kind];var direction:Vector2=shot.vel.normalized()
			if shot.kind=="flame":
				for effect in fx:
					if effect.kind in ["flame","flame_smoke"] and effect.get("volley",-1)==shot.get("volley",-2):
						effect.reach=maxf(.08,(point-effect.pos).dot(effect.dir))
			shot.life=0
			match target_kind:
				"frog":hurt(target,spec.damage,direction*spec.impulse,shot.kind,shot.get("volley",-1),point)
				"bug":
					hurt_enemy(target,spec.damage,direction*(spec.impulse*.35),shot.kind)
				"wood","shelf":
					if target_kind=="wood":target.vel+=shot.vel*.45
					elif Physics.dynamic(target):Physics.impulse(target,direction*spec.impulse*1.25,point)
					elif target.kind=="seesaw":target.omega+=shot.vel.y*(point.x-target.pos.x)*.002
					elif target.kind=="crumble":stress_structure(target,spec.damage/60.0)
					if target_kind=="shelf":Destruction.damage(self,target,spec.damage,point,direction*spec.impulse,shot.kind)
					burst(point,Color("c9a16c"),2 if shot.kind=="flame" else 8)
					if shot.kind!="flame":add_fx("wood",point,-direction,.17,shot.kind)
		elif shot.pos.y<kill_y or absf(shot.pos.x)>half_width+(0 if walls else 4):
			shot.life=0;add_fx("wood",shot.pos,-shot.vel.normalized(),.14,shot.kind)
	shots=shots.filter(func(s):return s.life>0)
	enemies=enemies.filter(func(e):return e.hp>0)

func hurt(p:Dictionary,damage:float,impulse:Vector2,kind:String="contact",volley:int=-1,contact:Vector2=Vector2.INF)->void:
	if over:return
	var continuation:bool=volley>0 and p.last_volley==volley
	var gentle:bool=kind=="flame"
	if not p.alive or p.respawn>0 or (p.invincible>0 and not continuation):return
	if gentle:p.burn=1.25
	p.hp-=damage*self.damage;p.vel+=impulse*(1+(100-p.hp)/75)*(.28 if continuation else 1.0)
	if not continuation and not gentle:p.vel.y+=3
	p.anchor={};p.invincible=.065;p.last_volley=volley;p.hit_dir=impulse.normalized()
	var offset:Vector2=(contact-p.pos)/FROG_SCALE if contact.is_finite() else -p.hit_dir*.34
	if offset.length()<.12:offset=-p.hit_dir*.30
	offset=Vector2(clampf(offset.x,-.38,.38),clampf(offset.y,-.32,.40))
	var impact:Vector2=p.pos+offset*FROG_SCALE
	if not continuation and (not gentle or p.flash<=0):
		var nearby:bool=p.wounds.any(func(w):return w.offset.distance_to(offset)<.10)
		if not nearby:p.wounds.append({"offset":offset,"size":.065 if kind in ["seed","flame"] else .10})
		while p.wounds.size()>6:p.wounds.pop_front()
		p.flash=.12 if gentle else .19
		add_fx("hit",impact,p.hit_dir,.14,kind)
		add_fx("mist",impact,p.hit_dir,.60,kind)
		blood(impact,impulse,0 if gentle else 2,Color(p.color),false)
		delayed_gore.append({"delay":.04,"pos":impact,"impulse":impulse,"count":0 if gentle else (4 if kind!="seed" else 2),"skin":Color(p.color)})
		if not gentle:impact_stop(WEAPONS[kind].stop if WEAPONS.has(kind) else .03)
		trauma=minf(1,trauma+(.35 if kind=="acorn" else .22));events.append("hit")
	if p.hp<=0:knockout(p)

func knockout(p:Dictionary)->void:
	if over:
		p.pos=p.spawn;p.vel=Vector2.ZERO;p.anchor={};p.ground=-1;p.stuck=false
		return
	if not p.alive or p.respawn>0:return
	var pos:Vector2=Vector2(p.pos.x,maxf(.65,p.pos.y)) if safe_water else p.pos
	blood(pos,p.vel*.5+Vector2(0,8),24,Color(p.color),true)
	for organ in range(3):
		gore.append({"pos":pos+Vector2((organ-1)*.14,.12),
			"vel":p.vel*.25+Vector2((organ-1)*5.5,10.0+organ*1.8),
			"life":4.0,"radius":(.26 if organ!=1 else .30)*FROG_SCALE,"chunk":true,"organ":organ,
			"skin":Color(p.color),"angle":rng.randf_range(0,TAU),"spin":rng.randf_range(-9,9),
			"ground":-1,"bounces":0,"bounce_squash":0.0})
	while gore.size()>260:gore.pop_front()
	delayed_gore.append({"delay":.075,"pos":pos,"impulse":p.vel*.4+Vector2(0,6),"count":10,"skin":Color(p.color)})
	add_fx("ko",pos,p.hit_dir,.26,"acorn")
	add_fx("mist_ko",pos,p.hit_dir,.85,"acorn")
	hitstop=maxf(hitstop,.095);stop_guard=.18
	trauma=1.0;events.append("splat")
	p.lives-=1;p.anchor={};p.weapon="";p.ammo=0;p.burn=0.0;p.pending_burr={}
	if p.lives<=0:p.alive=false
	else:p.respawn=1.5

func impact_stop(seconds:float)->void:
	# Do not stack a four-player stream of hits into a long shared-screen freeze.
	if stop_guard>0:return
	hitstop=maxf(hitstop,seconds);stop_guard=.10

func add_fx(kind:String,pos:Vector2,direction:Vector2,life:float,weapon:String)->void:
	fx.append({"kind":kind,"pos":pos,"dir":direction,"life":life,"age":0.0,"weapon":weapon})
	while fx.size()>64:fx.pop_front()

func update_feedback(dt:float)->void:
	fx_clock+=dt;stop_guard=maxf(0,stop_guard-dt);trauma=maxf(0,trauma-dt*2.8)
	for p in frogs:p.shot_age+=dt;p.flash=maxf(0,p.flash-dt);p.burn=maxf(0,p.burn-dt)
	for effect in fx:effect.age+=dt
	fx=fx.filter(func(effect):return effect.age<effect.life)
	for spray in delayed_gore:
		spray.delay-=dt
		if spray.delay<=0:blood(spray.pos,spray.impulse,spray.count,spray.skin,false)
	delayed_gore=delayed_gore.filter(func(spray):return spray.delay>0)

func update_debris(dt:float)->void:
	for bramble in particles:
		bramble.life-=dt;bramble.pos+=bramble.vel*dt;bramble.vel.y-=5*dt
	particles=particles.filter(func(p):return p.life>0)
	update_gore(dt)

func blood(pos:Vector2,impulse:Vector2,count:int,skin:Color,dismember:bool)->void:
	# Bright clay gore, intentionally excessive against the toy-like environment.
	for i in range(count):
		var chunk:bool=dismember and i<5
		gore.append({"pos":pos+impulse.normalized()*rng.randf_range(0,.3),"vel":impulse.normalized().rotated(rng.randf_range(-.65,.65))*rng.randf_range(4,15)+Vector2(rng.randf_range(-3,3),rng.randf_range(2,9)),
			"life":rng.randf_range(.6,1.2) if not chunk else rng.randf_range(2.0,3.5),"radius":rng.randf_range(.015,.043) if not chunk else rng.randf_range(.13,.22)*FROG_SCALE,
			"chunk":chunk,"skin":skin,"angle":rng.randf_range(0,TAU),"spin":rng.randf_range(-12,12),"ground":-1,"bounces":0})
	while gore.size()>260:gore.pop_front()

func update_gore(dt:float)->void:
	for part in gore:
		part.bounce_squash=maxf(0,part.get("bounce_squash",0.0)-dt*7)
		part.life-=dt;part.vel.y-=24*dt;part.pos+=part.vel*dt;part.angle+=part.spin*dt
		var landed:int=land(part,part.radius,dt)
		if landed>=0:
			if part.ground<0:
				var shelf:Dictionary=platforms[landed]
				stains.append({"platform":landed,"offset":(part.pos-shelf.pos).rotated(-shelf.angle).x,"size":rng.randf_range(.045,.13),"life":18.0})
			part.ground=landed;part.vel.x*=exp(-5*dt);part.spin*=exp(-7*dt)
			if part.chunk and part.get("bounces",0)<2:
				part.bounce_squash=1.0
				part.vel.y=4.0/(part.get("bounces",0)+1);part.bounces=part.get("bounces",0)+1;part.ground=-1
			if not part.chunk:part.life=0
		if part.pos.y<(.42 if safe_water else kill_y):
			if safe_water:stains.append({"platform":-1,"offset":part.pos.x,"size":rng.randf_range(.06,.18),"life":18.0})
			part.life=0
		if walls and absf(part.pos.x)>half_width-.3:part.pos.x=clampf(part.pos.x,-half_width+.3,half_width-.3);part.vel.x*=-.25
	gore=gore.filter(func(p):return p.life>0)
	for stain in stains:stain.life-=dt
	stains=stains.filter(func(p):return p.life>0)
	while stains.size()>150:stains.pop_front()

func burst(p:Vector2,color:Color,count:int)->void:
	for i in range(count):
		particles.append({"pos":p,"vel":Vector2(rng.randf_range(-5,5),rng.randf_range(1,7)),"color":color,"life":rng.randf_range(.25,.65)})

	while particles.size()>180:particles.pop_front()

func spawn_enemy(kind:String,pos:Vector2)->Dictionary:
	var spec:Dictionary=ENEMY_STATS[kind]
	enemy_serial+=1
	var health:float=spec.hp
	if kind=="boss":health*=1.0+maxi(0,wave/5-1)*.25+maxi(0,frogs.size()-1)*.35
	var enemy:Dictionary={"id":enemy_serial,"kind":kind,"pos":pos,"vel":Vector2.ZERO,"hp":health,"max_hp":health,
		"radius":spec.radius,"phase":rng.randf_range(0,TAU),"cooldown":1.0,"state":"approach",
		"timer":rng.randf_range(.6,1.6),"dash":Vector2.ZERO,"look":Vector2.DOWN,"flash":0.0,"summon":8.0,"enraged":false}
	enemies.append(enemy);return enemy

func spawn_wave()->void:
	wave+=1;wave_delay=3.5
	var count:int=mini(6+wave*2+maxi(0,frogs.size()-1)*2,26)
	var boss_wave:bool=wave%5==0
	if boss_wave:count=mini(6+wave/2,14)
	for i in range(count):
		var kind:="bee"
		if wave>=2 and i%3==1:kind="mosquito"
		if wave>=3 and i%4==2:kind="bird"
		spawn_enemy(kind,Vector2(-half_width+2+(half_width*2-4)*(i+.5)/count,rng.randf_range(ceiling-3.5,ceiling-1)))
	if boss_wave:spawn_enemy("boss",Vector2(0,ceiling-1.5))

func hurt_enemy(enemy:Dictionary,damage:float,impulse:Vector2,weapon:String)->void:
	if enemy.hp<=0:return
	enemy.hp-=damage*self.damage;enemy["flash"]=.14
	enemy["vel"]=enemy.get("vel",Vector2.ZERO)+impulse*(.2 if enemy.get("kind","")=="boss" else 1.0)
	var color:=Color(ENEMY_STATS.get(enemy.get("kind","bee"),ENEMY_STATS.bee).color)
	burst(enemy.pos,color,2 if weapon=="flame" else 5)
	if weapon!="flame":add_fx("hit",enemy.pos,impulse.normalized(),.16,weapon);impact_stop(.012)
	if enemy.hp<=0:
		burst(enemy.pos,color,24 if enemy.get("kind","")=="boss" else 12)
		if enemy.get("kind","")=="boss":
			add_fx("explosion",enemy.pos,Vector2.RIGHT,.45,"rail");trauma=maxf(trauma,.45)
			add_pickup(enemy.pos+Vector2(-.8,.2),"rail");add_pickup(enemy.pos+Vector2(.8,.2),"grenade")

func update_survival(dt:float)->void:
	enemies=enemies.filter(func(e):return e.hp>0)
	if enemies.is_empty():
		wave_delay-=dt
		if wave_delay<=0:spawn_wave()
	var available:Array=frogs.filter(func(p):return p.alive and p.respawn<=0)
	if available.is_empty():return
	var reinforcements:Array=[]
	for enemy in enemies:
		var kind:String=enemy.get("kind","bee");var spec:Dictionary=ENEMY_STATS[kind]
		enemy.merge({"vel":Vector2.ZERO,"flash":0.0,"state":"approach","timer":1.0,"dash":Vector2.ZERO,"radius":spec.radius},false)
		var target:Dictionary=available[0]
		for p in available:
			if p.pos.distance_squared_to(enemy.pos)<target.pos.distance_squared_to(enemy.pos):target=p
		var delta:Vector2=target.pos-enemy.pos
		enemy["look"]=delta.normalized();enemy.cooldown=maxf(0,enemy.cooldown-dt);enemy.flash=maxf(0,enemy.flash-dt);enemy.timer-=dt
		var desired:=Vector2.ZERO
		if kind=="bee":
			desired=delta.normalized()*spec.speed+Vector2(sin(clock*4+enemy.phase),cos(clock*3+enemy.phase))*.85
		else:
			match enemy.state:
				"approach":
					var perch:Vector2=target.pos+Vector2(sin(enemy.phase)*2.8,2.0 if kind=="mosquito" else 3.6)
					desired=(perch-enemy.pos).limit_length(1)*spec.speed
					if enemy.timer<=0 and delta.length()< (11 if kind=="boss" else 8):
						enemy.state="windup";enemy.timer=.85 if kind=="boss" else (.45 if kind=="mosquito" else .65)
				"windup":
					desired=-delta.normalized()*.55
					if enemy.timer<=0:
						enemy.state="strike";enemy.timer=.72 if kind=="boss" else (.30 if kind=="mosquito" else .55)
						enemy.dash=(target.pos+target.vel*.08-enemy.pos).normalized()*(10 if kind=="boss" else (8.5 if kind=="mosquito" else 9.5))
				"strike":
					desired=enemy.dash
					if enemy.timer<=0:enemy.state="recover";enemy.timer=1.7 if kind=="boss" else 1.2
				"recover":
					desired=Vector2(-signf(delta.x)*1.2,2.2)
					if enemy.timer<=0:enemy.state="approach";enemy.timer=.8
		if kind=="boss":
			enemy.enraged=enemy.hp<enemy.max_hp*.5;enemy.summon-=dt
			if enemy.enraged and enemy.summon<=0 and enemies.size()+reinforcements.size()<24:
				enemy.summon=8.0
				for side in [-1,1]:reinforcements.append(enemy.pos+Vector2(side*1.4,.4))
		enemy.vel=enemy.vel.lerp(desired,1-exp(-dt*(15 if enemy.state=="strike" else 4)))
		var before:Vector2=enemy.pos
		enemy.pos+=enemy.vel*dt
		enemy.pos=Vector2(clampf(enemy.pos.x,-half_width+.8,half_width-.8),clampf(enemy.pos.y,.8,ceiling-.9))
		for p in available:
			var near:Vector2=Geometry2D.get_closest_point_to_segment(p.pos,before,enemy.pos)
			if near.distance_to(p.pos)>enemy.radius+RADIUS or enemy.cooldown>0 or p.enemy_guard>0:continue
			var direction:Vector2=(p.pos-enemy.pos).normalized()
			var health:float=p.hp
			hurt(p,spec.damage,direction*(10 if kind=="boss" else 5)+Vector2(0,2))
			if p.hp<health:p.enemy_guard=.5
			enemy.cooldown=1.25;enemy.vel=-direction*3
			if kind!="bee":enemy.state="recover";enemy.timer=1.4
	for pos in reinforcements:spawn_enemy("bee",pos)

func bot(p:Dictionary)->Dictionary:
	if not p.alive or p.respawn>0:return {}
	var target:=Vector2(0,5.5);var target_velocity:=Vector2.ZERO;var best:=INF;var target_id:=-1
	var armed:bool=not p.weapon.is_empty() and p.ammo>0
	var choices:Array=(enemies if mode=="survival" else frogs) if armed else pickups
	for candidate in choices:
		if candidate==p or not candidate.get("alive",true) or candidate.get("respawn",0)>0:continue
		var score:float=p.pos.distance_to(candidate.pos)
		if armed and not bot_clear_shot(p.pos,candidate.pos):score+=8
		if score<best:best=score;target=candidate.pos;target_velocity=candidate.get("vel",Vector2.ZERO);target_id=choices.find(candidate)
	var delta:Vector2=target-p.pos
	var distance:float=delta.length()
	var travel:float=clampf(distance/(WEAPONS[p.weapon].speed if armed else 24.0),0,.45)
	var prediction:Vector2=target+target_velocity*travel*.45
	if armed:prediction.y+=(-FlameStyle.rise(travel).y if p.weapon=="flame" else (11*travel*travel-5*travel if p.weapon=="burr" else (9*travel*travel-4*travel if p.weapon=="grenade" else (0.0 if p.weapon=="rail" else 2*travel*travel))))
	var aim:Vector2=(prediction-p.pos).normalized()
	var range_limit:float={"flame":4.9,"bramble":11.0,"acorn":23.0,"seed":27.0,"rail":30.0,"grenade":13.0,"burr":12.0}.get(p.weapon,0)
	var can_fire:bool=armed and best<INF and distance<range_limit and bot_clear_shot(p.pos+aim*.7*FROG_SCALE,prediction)
	if p.weapon=="burr" and distance<5.0:can_fire=false
	if target_id!=p.get("bot_target",-2) or not armed:
		p["bot_target"]=target_id;p["bot_ready"]=clock+.65*bot_reaction;p["bot_aim_at"]=0.0
	if not can_fire:p["bot_ready"]=clock+.45*bot_reaction
	var desired:float={"flame":2.7,"bramble":4.2,"acorn":7.0,"seed":7.5,"rail":9.0,"grenade":6.0,"burr":7.0}.get(p.weapon,.3)
	var move:=Vector2(signf(delta.x) if absf(delta.x)>desired else 0,0)
	var jump:bool=p.jump_prev and p.ground<0 and p.vel.y>0
	var tongue:=false
	if not p.anchor.is_empty():
		# Reel onto the next perch, then jump free to land on its top.
		tongue=true;move.y=1
		var anchor:Vector2=anchor_point(p.anchor)
		move.x=clampf((anchor.x-p.pos.x)*.6,-1,1)
		if p.rope<1.65 or p.pos.y>anchor.y-.6:jump=not p.jump_prev;tongue=false
	elif not can_fire or distance>desired+1.5:
		var source:int=p.ground if p.ground>=0 else bot_platform(p.pos)
		var destination:int=bot_platform(target)
		if clock>=p.get("route_until",-1.0) or p.get("route_source",-2)!=source or p.get("route_destination",-2)!=destination:
			p["route_next"]=bot_route(source,destination);p["route_until"]=clock+.25
			p["route_source"]=source;p["route_destination"]=destination
		var next:int=p.get("route_next",-1)
		if next>=0 and next!=source:
			var shelf:Dictionary=platforms[next]
			var landing_x:float=clampf(p.pos.x,shelf.pos.x-shelf.width*.5+.5,shelf.pos.x+shelf.width*.5-.5)
			var elevation:float=shelf.pos.y-(platforms[source].pos.y if source>=0 else p.pos.y-RADIUS-.2)
			move.x=signf(landing_x-p.pos.x) if absf(landing_x-p.pos.x)>.2 else 0
			if elevation>2.8:
				aim=(Vector2(landing_x,shelf.pos.y+.2)-p.pos).normalized()
				tongue=not p.tongue_prev;move.y=1;can_fire=false
			elif p.ground>=0:
				var current:Dictionary=platforms[source]
				var direction:float=signf(shelf.pos.x-p.pos.x)
				if direction==0:direction=1
				var edge:float=current.pos.x+direction*(current.width*.5-.35)
				if elevation<-.8:
					move.x=direction
				else:
					jump=not p.jump_prev and (absf(edge-p.pos.x)<1.0 or absf(landing_x-p.pos.x)<1.2)
					if not jump:move.x=direction
	if p.ground>=0 and platforms[p.ground].kind=="crumble" and platforms[p.ground].stress>.35:
		jump=not p.jump_prev
	if p.pos.y<2 and p.vel.y<0 and p.anchor.is_empty():
		aim=Vector2(-p.pos.x*.08,1).normalized();tongue=not p.tongue_prev;move.y=1;can_fire=false
	if p.stuck and walls and absf(p.pos.x)>wall_contact and not can_fire:
		# A wall catch is a perch to jump from, not a dead end in the platform route.
		move.x=-signf(p.pos.x);jump=not p.jump_prev;tongue=false
	if can_fire and not tongue:
		# Aim is sampled slowly, with imperfect lead and a small persistent error.
		if clock>=p.get("bot_aim_at",0.0):
			p["bot_aim"]=aim.rotated(rng.randf_range(-.09,.09));p["bot_aim_at"]=clock+rng.randf_range(.24,.36)*bot_reaction
		aim=p.get("bot_aim",aim)
	var firing:bool=can_fire and clock>=p.get("bot_ready",clock+.65*bot_reaction) and fposmod(clock+p.slot*.31,1.35)<.50
	return {"move":move,"aim":aim,"jump":jump,"tongue":tongue,"fire":firing}

func bot_surface(shelf:Dictionary)->bool:
	return usable(shelf) and not shelf.get("falling",false) and not shelf.get("structural_fall",false) and not shelf.get("rubble",false) and shelf.kind not in ["pier","barricade"]

func bot_platform(pos:Vector2)->int:
	var result:=-1;var best:=INF
	for i in range(platforms.size()):
		var shelf:Dictionary=platforms[i]
		if not bot_surface(shelf):continue
		if shelf.pos.y>pos.y+.2:continue
		var score:float=absf(pos.y-shelf.pos.y-RADIUS-.2)+maxf(0,absf(pos.x-shelf.pos.x)-shelf.width*.5)*3
		if score<best:best=score;result=i
	return result

func bot_route(source:int,destination:int)->int:
	if source<0 or destination<0 or source==destination:return destination
	var costs:Array=[];var previous:Array=[];var visited:Array=[]
	costs.resize(platforms.size());costs.fill(INF);previous.resize(platforms.size());previous.fill(-1);visited.resize(platforms.size());visited.fill(false)
	costs[source]=0.0
	for iteration in range(platforms.size()):
		var current:=-1
		for i in range(platforms.size()):
			if bot_surface(platforms[i]) and not visited[i] and (current<0 or costs[i]<costs[current]):current=i
		if current<0 or costs[current]==INF:break
		if current==destination:break
		visited[current]=true
		for next in range(platforms.size()):
			if next==current or not bot_surface(platforms[next]):continue
			var a:Dictionary=platforms[current];var b:Dictionary=platforms[next]
			var rise:float=b.pos.y-a.pos.y
			var gap:float=maxf(0,absf(b.pos.x-a.pos.x)-(a.width+b.width)*.5)
			var grapple:bool=rise>2.8
			if rise< -9 or rise>9 or (grapple and a.pos.distance_to(b.pos)>11) or (not grapple and gap>4):continue
			var cost:float=costs[current]+a.pos.distance_to(b.pos)+(4 if grapple else 0)+(3 if b.kind=="crumble" else 0)
			if cost<costs[next]:costs[next]=cost;previous[next]=current
	if previous[destination]<0:return -1
	var next:int=destination
	while previous[next]!=source and previous[next]>=0:next=previous[next]
	return next

func bot_clear_shot(from:Vector2,to:Vector2)->bool:
	for shelf in platforms:
		if not usable(shelf):continue
		if not shelf_hit(shelf,from,to).is_empty():return false
	for box in crates:
		if flame_circle_entry(from,to,box.pos,.55)<INF:return false
	return true
