extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh(id:String="beaver_dam")->RefCounted:
	var s:=Sim.new([{},{},{},{}],"versus",23,id);s.countdown=0;s.pickup_timer=1000
	return s
func hit(s:RefCounted,index:int,damage:float,kind:String="acorn")->void:
	var b:Dictionary=s.platforms[index];s.Destruction.damage(s,b,damage,b.pos,Vector2(5,2),kind)
func advance(s:RefCounted,seconds:float)->void:
	for i in range(int(seconds*60)):s.step(1.0/60,[{},{},{},{}])
func _initialize()->void:call_deferred("run")
func run()->void:
	for id in Sim.Arenas.DESTRUCTION_IDS:
		var s:=fresh(id)
		check(s.pickups.size()==9 and Sim.WEAPON_ORDER.all(func(k):return s.pickups.any(func(p):return p.kind==k)),id+" starts with all seven weapons in nine locations")
		check(s.frogs.all(func(p):return p.weapon.is_empty()),id+" frogs start unarmed")
		advance(s,2)
		check(s.frogs.all(func(p):return p.lives==3 and p.ground>=0 and s.platforms[p.ground].kind=="fixed"),id+" all four spawns settle safely on permanent terrain")
		check(s.pickups.size()==9 and s.pickups.all(func(p):return p.pos.y>0),id+" all supplies settle above the bottom")
		check(s.platforms.filter(func(b):return b.get("rubble",false)).all(func(b):return not b.active),id+" reserved debris never spawns itself")
		var connected:=true
		for a in range(4):
			for b in range(s.arena_platform_count):
				if s.bot_surface(s.platforms[b]) and s.bot_route(a,b)<0:connected=false;print(id," unreachable ",a," -> ",b)
		check(connected,id+" spawn perches have routes to starting platforms")
		var w:=World.new();root.add_child(w);w.build(s);w.update()
		check(w.shelves.size()==s.platforms.size(),id+" geometry and collision slots match")
		var index:int=5 if id=="beaver_dam" else 7
		var shelf:Dictionary=s.platforms[index];var visuals:Dictionary=w.shelves[index].get_meta("destruction")
		check(visuals.layers.all(func(n):return not n.visible),id+" undamaged structures have no damage cracks")
		hit(s,index,shelf.max_hp*.15);w.update()
		check(visuals.layers[0].visible and not visuals.layers[1].visible,id+" first hit reveals shallow cracks")
		hit(s,index,shelf.max_hp*.6);w.update()
		check(visuals.layers.all(func(n):return n.visible) and shelf.active,id+" heavy damage deepens cracks while retaining collision")
		hit(s,index,1000);w.update()
		check(not w.shelves[index].visible and not shelf.active,id+" broken geometry and collision disappear together")
		var rubble:Array=s.platforms.filter(func(b):return b.get("rubble",false) and b.active)
		check(rubble.size()>=2 and rubble.all(func(b):return s.Physics.dynamic(b)),id+" breakage emits physical fragments")
		var piece:Dictionary=rubble[0];var node:Node3D=w.shelves[s.platforms.find(piece)]
		check(is_equal_approx(node.scale.x,piece.width) and is_equal_approx(node.scale.y,piece.height/.4),id+" fragments render at their collision dimensions")
		w.free()
		s=fresh(id);var fires:=0;var grapples:=0
		for frame in range(1200):
			s.step(1.0/60,s.frogs.map(func(p):return s.bot(p)))
			for event in s.events:
				if event.begins_with("fire_"):fires+=1
				if event=="tongue":grapples+=1
		check(fires>3 and grapples>0,id+" bots pick up weapons, grapple and fight")
		print(id," shots=",fires," grapples=",grapples)
	var s:=fresh();var b:Dictionary=s.platforms[5];var p:Dictionary=s.frogs[0]
	check(not s.bot_clear_shot(Vector2(-5,4.5),Vector2(-1,4.5)),"An intact timber gate blocks weapon fire")
	p.pos=b.pos+Vector2(-.5,0);p.vel=Vector2(8,0);s.land(p,Sim.RADIUS,1.0/60)
	check(p.pos.x<=b.pos.x-b.width*.5-Sim.RADIUS+.001 and p.vel.x==0,"Tall gate blocks a running frog at its actual face")
	var anchor:Dictionary=s.cast_tongue(Vector2(-5,4.5),Vector2.RIGHT)
	check(anchor.get("platform",-1)==5,"Tongue can attach to the side of a destructible gate")
	p.anchor=anchor;p.ground=5
	for i in range(3):hit(s,5,24)
	check(b.active and b.hp==24,"Three acorn hits accumulate instead of resetting damage")
	hit(s,5,24)
	check(not b.active and p.anchor.is_empty() and p.ground==-1,"Final hit breaks timber and releases standing/grappling frogs")
	# Debris may briefly occupy the new opening; move it aside to inspect the gap itself.
	for piece in s.platforms:
		if piece.get("rubble",false):piece.active=false
	check(s.bot_clear_shot(Vector2(-5,4.5),Vector2(-1,4.5)),"Breaking the gate opens a real shooting route")
	advance(s,11)
	check(not b.active,"Destroyed terrain stays destroyed for the rest of the round")
	s=fresh();b=s.platforms[5]
	s.shots=[{"pos":Vector2(-5,4.5),"vel":Vector2(100,0),"life":1.0,"kind":"acorn","owner":0,"volley":1}]
	s.update_shots(.03)
	check(b.hp==72 and s.shots.is_empty(),"Actual projectile collision damages the near face once")
	var g:Dictionary={"pos":Vector2(-5,4.5),"vel":Vector2(60,0),"life":1.0,"kind":"grenade","owner":0,"volley":2}
	s.update_grenade(g,.03)
	check(g.vel.x<0 and g.pos.x<b.pos.x,"Lobber grenades bounce off tall static destructible walls")
	s=fresh();p=s.frogs[0];p.pos=Vector2(-5,4.5);p.aim=Vector2.RIGHT;p.weapon="rail";p.ammo=3;s.fire(p)
	check(not s.platforms[5].active,"Actual rail shot punches apart timber cover")
	s=fresh();b=s.platforms[5];s.explode_grenade({"pos":b.pos+Vector2(-.6,1.8),"kind":"burr","life":1.0,"owner":0,"volley":8})
	check(not b.active,"A Burr impact near the end of a tall gate destroys it using distance to its surface")
	s=fresh();hit(s,5,40,"flame");var wood_damage:float=s.platforms[5].max_hp-s.platforms[5].hp
	var stone:=fresh("shatter_spire");hit(stone,7,40,"flame")
	check(wood_damage>20 and stone.platforms[7].max_hp-stone.platforms[7].hp<3,"Timber burns while stone resists flames")
	s=fresh();hit(s,5,1000);advance(s,.6)
	check(not s.platforms[7].get("structural_fall",false),"One remaining dam post still carries its roof")
	hit(s,6,1000);s.Destruction.update(s,.1)
	check(s.platforms[7].support_warning>0 and not s.platforms[7].get("structural_fall",false),"Loss of both supports warns before collapse")
	advance(s,1)
	check(s.platforms[7].get("structural_fall",false) and s.platforms[7].pos.y<6.5,"Dam roof becomes a falling physical body")
	var count:int=s.pickups.size();s.place_supply([0,8,"burr"])
	check(s.pickups.size()==count,"Supply cannot reappear over a collapsed roof")
	s=fresh("shatter_spire");hit(s,7,1000);advance(s,.5)
	check(not s.platforms[9].get("structural_fall",false),"One stone pier still supports the tower")
	hit(s,8,1000);advance(s,.4)
	check([9,10,11,12,13].all(func(i):return s.platforms[i].get("structural_fall",false)),"Upper sections follow their falling supports without hanging in midair")
	advance(s,1.6)
	check([9,10,11,12,13].all(func(i):return s.platforms[i].get("structural_fall",false)),"Destroying both piers cascades through all five upper tower sections")
	check(s.platforms[13].pos.y<18.5,"The tower crown actually falls")
	check(s.frogs.all(func(f):return f.lives==3 and f.ground>=0 and s.platforms[f.ground].kind=="fixed"),"Tower collapse leaves every spawn safe")
	for shelf in s.platforms.duplicate():
		if shelf.get("max_hp",0)>0:s.Destruction.damage(s,shelf,1000,shelf.pos,Vector2.ZERO,"rail")
	check(s.platforms.filter(func(piece):return piece.get("rubble",false)).size()==16,"Repeated destruction has a fixed debris budget")
	advance(s,10)
	check(s.platforms.filter(func(piece):return piece.get("rubble",false)).all(func(piece):return not piece.active),"Fragments clean up without respawning")
	var reset:=fresh("shatter_spire")
	check(reset.platforms[7].active and reset.platforms[7].hp==reset.platforms[7].max_hp,"New matches restore the complete arena")
	print("Frog Fighter destruction: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
