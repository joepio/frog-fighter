extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize()->void:
	for id in Sim.Arenas.CLASSIC_IDS:
		for mode in ["versus","survival"]:
			var s:=Sim.new([{}, {}, {}, {}],mode,23,id);s.countdown=0;s.wave_delay=100
			check(s.pickups.size()==7,id+" has all seven weapons")
			for i in range(120):s.step(1.0/60,[{},{},{},{}])
			check(s.frogs.all(func(p):return p.alive and p.lives==3 and p.ground>=0),id+" has safe spawn perches in "+mode)
		var s:=Sim.new([{}],"versus",23,id);s.countdown=0
		for hook in s.hooks:
			var origin:Vector2=hook+Vector2(-.75,-.8)
			var anchor:Dictionary=s.cast_tongue(origin,hook-origin)
			check(not anchor.is_empty() and s.anchor_point(anchor).distance_to(hook)<.01,id+" vine grip attaches at its visible curl")
			var frog:Dictionary=s.frogs[0];frog.pos=origin;frog.vel=Vector2.ZERO;frog.anchor=anchor;frog.rope=origin.distance_to(hook);frog.ground=-1;frog.tongue_prev=true
			for i in range(30):s.update_frog(frog,{"tongue":true,"move":Vector2.RIGHT},1.0/60)
			check(frog.pos.distance_to(hook)<=frog.rope+.08,id+" vine grip supports a swing")
		if id!="terrarium":
			var moving:Array=s.platforms.filter(func(a):return a.kind in ["lift","ferry","swing"])
			var initial:Array=moving.map(func(a):return a.pos)
			s.step(1.0/60,[{}])
			check(moving.all(func(a):return a.vel.length()<3),id+" moving perches start without a velocity spike")
			for i in range(90):s.step(1.0/60,[{}])
			check(moving[0].pos.distance_to(initial[0])>.1,id+" platforms travel")
			var connected:=true
			for a in range(s.arena_platform_count):
				for b in range(s.arena_platform_count):
					if s.bot_route(a,b)<0:connected=false
			check(connected,id+" has connected jump/grapple routes between every perch")
			var anchor:Dictionary={"platform":s.platforms.find(moving[0]),"offset":Vector2(.2,.2)}
			var before:Vector2=s.anchor_point(anchor)
			for i in range(30):s.step(1.0/60,[{}])
			check(s.anchor_point(anchor).distance_to(before)>.01,id+" moving tongue anchors follow their perch")
			for kind in ["ferry","lift"]:
				var ride:=Sim.new([{}],"versus",23,id);ride.countdown=0;ride.crates.clear();ride.pickups.clear();ride.pickup_timer=100
				var index:int=ride.platforms.find(ride.platforms.filter(func(a):return a.kind==kind).front()) if ride.platforms.any(func(a):return a.kind==kind) else -1
				if index<0:continue
				var frog:Dictionary=ride.frogs[0];frog.pos=ride.platforms[index].pos+Vector2(0,Sim.RADIUS+.2);frog.ground=index
				for i in range(180):ride.step(1.0/60,[{}])
				check(frog.lives==3 and absf(frog.pos.x-ride.platforms[index].pos.x)<.25 and absf(frog.pos.y-ride.platforms[index].pos.y-Sim.RADIUS-.2)<.15,id+" carries standing frogs on the "+kind)
			# Exercise routes with real bot inputs, not only the navigation graph.
			var combat:=Sim.new([{"bot":true},{"bot":true},{"bot":true},{"bot":true}],"versus",23,id);combat.countdown=0
			var fired:=0;var grapples:=0
			for i in range(1800):
				combat.step(1.0/60,combat.frogs.map(func(p):return combat.bot(p)))
				for event in combat.events:
					if event.begins_with("fire_"):fired+=1
					if event=="tongue":grapples+=1
			check(fired>3,id+" bots can find weapons and fight")
			check(grapples>0,id+" bots use tongue routes")
			print(id," bot play: shots=",fired," grapples=",grapples)
	print("Frog Fighter arenas: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
