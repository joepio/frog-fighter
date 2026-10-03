extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	for id in Sim.Arenas.EXPANSION_IDS:
		var s:=Sim.new([{},{},{},{}],"versus",23,id);s.countdown=0;s.crates=[]
		check(s.frogs.all(func(p):return p.weapon.is_empty()),id+" starts unarmed")
		check(s.pickups.size()==9 and Sim.WEAPON_ORDER.all(func(k):return s.pickups.any(func(p):return p.kind==k)),id+" supplies all seven weapon types at nine deliberate locations")
		for i in range(120):s.step(1.0/60,[{},{},{},{}])
		check(s.frogs.all(func(p):return p.lives==3 and p.ground>=0 and s.platforms[p.ground].kind=="fixed"),id+" all spawns settle on permanent perches")
		check(s.pickups.size()==9 and s.pickups.all(func(p):return p.pos.y>0),id+" weapons settle on their intended perches")
		var p:Dictionary=s.frogs[0];p.pos=Vector2(s.half_width+.2,10);p.vel=Vector2(5,0);p.ground=-1;p.stuck=false
		s.update_frog(p,{},1.0/60)
		check((p.pos.x<=s.wall_limit+.001 if s.walls else p.pos.x>s.half_width and not p.stuck),id+" uses its own side-wall rules")
		if not s.walls:
			check(s.cast_tongue(Vector2(s.half_width-1,11),Vector2.RIGHT).is_empty(),id+" has no invisible tongue wall")
			var shot:Dictionary={"pos":Vector2(s.half_width+.1,10),"vel":Vector2(10,0),"life":1.0,"kind":"grenade","owner":0,"volley":1}
			s.update_grenade(shot,.02);check(shot.vel.x>0,id+" grenade exits an open side without bouncing")
		p.pos=Vector2(0,-3);p.vel=Vector2(0,-20);p.stuck=false;p.ground=-1;s.update_frog(p,{},1.0/60)
		check((p.lives==3 and p.in_water if s.safe_water else p.lives==2 and p.respawn>0),id+" applies the advertised bottom hazard")
		s=Sim.new([{}],"survival",23,id);s.spawn_wave()
		check(s.enemies.all(func(e):return e.pos.y>s.ceiling-4 and absf(e.pos.x)<s.half_width),id+" waves spawn across the enlarged arena")
		var connected:=true
		for a in range(s.arena_platform_count):
			for b in range(s.arena_platform_count):
				if s.bot_route(a,b)<0:connected=false
		check(connected,id+" has jump and tongue routes between all starting perches")
		var world:=World.new();root.add_child(world);world.build(s)
		check(world.shelves.size()==s.platforms.size(),id+" all colliders have matching scenery slots")
		check(world.camera.size>=s.ceiling+3 and (world.water!=null)==s.safe_water,id+" camera fits the arena and lethal chasms have no pond")
		world.free()
		# Bots must still collect and use guns in the larger, hazardous layouts.
		s=Sim.new([{},{},{},{}],"versus",23,id);s.countdown=0
		var fires:=0;var grapples:=0
		for frame in range(1800):
			s.step(1.0/60,s.frogs.map(func(frog):return s.bot(frog)))
			for event in s.events:
				if event.begins_with("fire_"):fires+=1
				if event=="tongue":grapples+=1
		check(fires>3 and grapples>0,id+" bots can navigate and fight")
		print(id," bot shots=",fires," grapples=",grapples)
	var s:=Sim.new([{}],"versus",23,"deadfall");s.countdown=0;s.crates=[];s.pickups=[];s.pickup_timer=100
	var index:=6;var shelf:Dictionary=s.platforms[index];var p:Dictionary=s.frogs[0]
	p.pos=shelf.pos+Vector2(0,.2+Sim.RADIUS);p.ground=index
	for i in range(30):s.step(1.0/60,[{}])
	check(shelf.stress>.3 and not shelf.falling,"Cracked bridge warns before falling")
	for i in range(50):s.step(1.0/60,[{}])
	check(shelf.falling and shelf.pos.y<shelf.base.y,"Standing on the bridge makes the section fall")
	check(s.platforms[index-1].stress>0 and s.platforms[index+1].stress>0,"Failure spreads to connected bridge sections")
	var anchor:Dictionary={"platform":index,"offset":Vector2(0,.2)};p.anchor=anchor;p.rope=2;p.tongue_prev=true
	for i in range(300):s.update_crumble(shelf,1.0/60)
	check(not shelf.active,"Fallen section leaves a real gap")
	s.update_frog(p,{"tongue":true},1.0/60);check(p.anchor.is_empty(),"Tongue releases when its collapsed anchor disappears")
	check(s.cast_tongue(shelf.base+Vector2(0,1),Vector2(0,-1)).get("platform",-1)!=index,"Missing bridge cannot be grappled")
	for i in range(600):s.update_crumble(shelf,1.0/60)
	check(shelf.active and not shelf.falling and shelf.pos==shelf.base,"Bridge restores after a recovery interval")
	s.explode_grenade({"pos":shelf.pos+Vector2(0,.4),"owner":0,"volley":10,"life":1.0})
	s.update_crumble(shelf,1.0/60);check(shelf.falling,"Explosives bring down fragile structures")
	var before:int=s.pickups.size();shelf.active=false;shelf.falling=false
	s.place_supply([0,8.1,"grenade"])
	check(s.pickups.size()==before,"Supply does not respawn over a missing bridge section")
	var open:=Sim.new([{},{},{}],"versus",23,"sky_ruins");open.platforms=[];open.crates=[]
	var shooter:Dictionary=open.frogs[0];shooter.pos=Vector2(12,11);shooter.aim=Vector2.RIGHT;shooter.weapon="rail";shooter.ammo=3
	open.frogs[1].pos=Vector2(16,11);open.frogs[1].invincible=0;open.frogs[2].pos=Vector2(17,11);open.frogs[2].invincible=0
	open.fire(shooter)
	check(open.frogs[1].hp<=0 and open.frogs[2].hp<=0,"Rail shots cross the old arena boundary on larger maps")
	var closed:=Sim.new([{}],"versus",23,"reed_delta")
	var ceiling_grenade:Dictionary={"pos":Vector2(0,18),"vel":Vector2(0,8),"life":1.0,"kind":"grenade","owner":0,"volley":1}
	closed.update_grenade(ceiling_grenade,.02)
	check(ceiling_grenade.pos.y>18 and ceiling_grenade.vel.y>0,"Tall arenas have no invisible old ceiling for grenades")
	print("Frog Fighter expanded arenas: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
