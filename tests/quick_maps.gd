extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	for id in Sim.Arenas.QUICK_IDS:
		var s:=Sim.new([{},{},{},{}],"versus",23,id);s.countdown=0
		check(s.half_width*2<=20 and s.hooks.size()>0,id+" is compact and has tongue routes")
		check(s.frogs.all(func(p):return p.weapon.is_empty()),id+" starts unarmed")
		check(s.pickups.size()==s.supply_sites.size(),id+" supplies the designed weapon selection")
		var starting:Array=s.frogs.map(func(p):return p.lives)
		for i in range(90):s.step(1.0/60,[{},{},{},{}])
		check(s.frogs.all(func(p):return p.lives==3 and p.ground>=0),id+" spawns land safely")
		var connected:=true
		for p in s.frogs:
			for other in s.frogs:
				if s.bot_route(p.ground,other.ground)<0:connected=false
		check(connected,id+" has routes between all four starting seats")
		check(s.pickups.all(func(p):return p.pos.y>s.kill_y),id+" pickups stay reachable")
		var w:=World.new();root.add_child(w);w.build(s)
		check(w.shelves.size()==s.platforms.size() and (w.water!=null)==s.safe_water,id+" graphics match collision and water rules")
		w.free()
		var combat:=Sim.new([{},{},{},{}],"versus",23,id);combat.countdown=0
		var fired:=0
		for frame in range(900):
			combat.step(1.0/60,combat.frogs.map(func(p):return combat.bot(p)))
			for event in combat.events:
				if event.begins_with("fire_"):fired+=1
		check(fired>3,id+" bots can collect weapons and fight")
		print(id," shots=",fired)
	var s:=Sim.new([{},{},{},{}],"versus",23,"box_pillars");s.countdown=0
	var boxes:Array=s.platforms.filter(func(p):return p.get("crate",false))
	check(boxes.size()==10 and boxes.all(func(p):return s.Physics.dynamic(p)),"Two towers contain ten independently moving boxes")
	var target:Dictionary=boxes[2];var before:Vector2=target.pos
	var shooter:Dictionary=s.frogs[0];shooter.pos=target.pos+Vector2(-3,0);shooter.aim=Vector2.RIGHT;shooter.weapon="acorn";shooter.ammo=10
	s.fire(shooter)
	for i in range(30):s.update_shots(1.0/120);s.Physics.step(s,1.0/120)
	check(target.pos.distance_to(before)>.1,"Shooting a box moves it out of the tower")
	var anchor:Dictionary=s.cast_tongue(boxes[7].pos+Vector2(-2,0),Vector2.RIGHT)
	check(not anchor.is_empty() and anchor.platform>=0 and s.platforms[anchor.platform].get("crate",false),"Tongue attaches to the physical boxes")
	print("Frog Fighter quick maps: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
