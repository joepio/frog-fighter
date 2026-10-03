extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh()->RefCounted:
	var s:=Sim.new([{},{},{}],"versus",23);s.countdown=0;s.platforms=[];s.crates=[];s.pickups=[];s.pickup_timer=1000
	for i in range(3):s.frogs[i].pos=Vector2(-10+i*10,14);s.frogs[i].invincible=0
	return s
func shot(pos:Vector2,vel:Vector2)->Dictionary:return {"pos":pos,"vel":vel,"owner":0,"kind":"burr","life":6.0,"age":0.0,"spin":-11.0,"volley":10}
func _initialize()->void:call_deferred("run")
func run()->void:
	for id in Sim.Arenas.IDS:
		var s:=Sim.new([{}],"versus",23,id)
		check(s.pickups.any(func(item):return item.kind=="burr"),id+" has a Burr Bomb at round start")
	var s:=fresh();var p:Dictionary=s.frogs[0];p.pos=Vector2(-3,8);s.add_pickup(p.pos,"burr");s.pickup(p)
	check(p.weapon=="burr" and p.ammo==3,"Burr pickup equips three hand grenades")
	p.aim=Vector2.RIGHT;s.fire(p)
	check(s.shots.is_empty() and not p.pending_burr.is_empty() and p.ammo==2,"Throw spends one grenade and starts a visible windup")
	for i in range(20):s.step(1.0/120,[{}])
	check(s.shots.size()==1 and s.shots[0].kind=="burr" and s.shots[0].vel.y>0 and p.pending_burr.is_empty(),"Windup releases one rising hand-thrown projectile")
	check(s.fx.all(func(e):return e.kind!="muzzle"),"Hand throw creates no gun muzzle flash")
	s=fresh();p=s.frogs[0];p.weapon="burr";p.ammo=1;s.fire(p);s.knockout(p)
	for i in range(25):s.step(1.0/120,[{}])
	check(s.shots.is_empty() and p.pending_burr.is_empty(),"A defeated frog cannot release a delayed ghost grenade")
	# Contact must explode on the first swept hit, never bounce or tunnel.
	for kind in ["fixed","loose","rock"]:
		s=fresh();var block:Dictionary=s.platform(Vector2(0,8),2,kind)
		if kind=="loose":s.Physics.prepare(block,2,1)
		s.platforms=[block];var g:=shot(Vector2(-3,8),Vector2(120,0));s.shots=[g];s.update_shots(.05)
		check(s.shots.is_empty() and g.get("detonated",false) and g.pos.x<-.8,"Fast grenade detonates on the near face of "+kind)
		var count:int=s.fx.size();s.explode_grenade(g);check(s.fx.size()==count,kind+" impact detonates exactly once")
	s=fresh();var g:=shot(Vector2(0,9),Vector2(0,-80));s.platforms=[s.platform(Vector2(0,8),5,"fixed")];s.shots=[g];s.update_shots(.03)
	check(g.get("detonated",false) and g.pos.y>8,"Downward throw explodes on a platform crown")
	s=fresh();g=shot(Vector2(0,7),Vector2(0,80));s.platforms=[s.platform(Vector2(0,8),5,"fixed")];s.shots=[g];s.update_shots(.03)
	check(g.get("detonated",false) and g.pos.y<8,"Upward throw explodes against an underside")
	s=fresh();g=shot(Vector2(s.half_width-.5,8),Vector2(30,0));s.shots=[g];s.update_shots(.05)
	check(g.get("detonated",false) and g.pos.x<s.half_width,"Side wall detonates the hand grenade")
	s=fresh();g=shot(Vector2(0,1),Vector2(0,-30));s.shots=[g];s.update_shots(.03)
	check(g.get("detonated",false) and g.pos.y>Sim.Terrain.WATER_LEVEL,"Water contact detonates above the surface")
	s=fresh();s.walls=false;g=shot(Vector2(s.half_width-.2,8),Vector2(30,0));s.shots=[g];s.update_shots(.05)
	check(not g.get("detonated",false) and g.pos.x>s.half_width,"Open arena sides have no invisible impact wall")
	s=fresh();p=s.frogs[0];p.pos=Vector2(s.wall_limit,8);p.pending_burr={"aim":Vector2.RIGHT};s.release_burr(p);g=s.shots[0];s.update_shots(.02)
	check(g.get("detonated",false),"A point-blank throw while wall-clinging cannot spawn through the wall")
	s=fresh();p=s.frogs[0];p.pos=Vector2(0,Sim.Terrain.WATER_LEVEL+Sim.RADIUS*.15);p.pending_burr={"aim":Vector2.RIGHT};s.release_burr(p);g=s.shots[0];s.update_shots(.02)
	check(not g.get("detonated",false) and g.pos.y>Sim.Terrain.WATER_LEVEL,"A floating frog can throw clear of the pond surface")
	s=fresh();g=shot(Vector2(0,s.ceiling-.6),Vector2(0,30));s.shots=[g];s.update_shots(.02)
	check(g.get("detonated",false) and g.pos.y<s.ceiling,"Ceiling contact detonates inward from the roof")
	s=fresh();s.spawn_enemy("bee",Vector2(0,8));g=shot(Vector2(-3,8),Vector2(120,0));s.shots=[g];s.update_shots(.05)
	check(g.get("detonated",false) and s.enemies.is_empty(),"Swarm enemy contact detonates and deals blast damage")
	s=fresh();s.frogs[1].pos=Vector2(0,8);g=shot(Vector2(-3,8),Vector2(120,0));s.shots=[g];s.update_shots(.05)
	check(g.get("detonated",false) and g.pos.x<0 and s.frogs[1].hp<=0,"Direct frog contact detonates at the body and is lethal")
	s=fresh();s.crates=[{"pos":Vector2(0,8),"vel":Vector2.ZERO,"angle":0.0}];g=shot(Vector2(-3,8),Vector2(120,0));s.shots=[g];s.update_shots(.05)
	check(g.get("detonated",false) and s.crates[0].vel.length()>10,"Crate impact explodes and launches the crate")
	s=fresh();s.frogs[0].pos=Vector2(-1,8);s.frogs[1].pos=Vector2(.8,8);s.frogs[2].pos=Vector2(3.6,8)
	g=shot(Vector2(0,8),Vector2.ZERO);s.explode_grenade(g)
	check(s.frogs[0].hp<100 and s.frogs[1].hp<s.frogs[2].hp and s.frogs[2].hp<100,"Large blast damages the thrower and has distance falloff beyond lobber range")
	check(s.fx.any(func(e):return e.kind=="impact_blast" and e.life>1.5) and s.trauma>=.8,"Big blast has its own long-lived layered effect and camera impact")
	s=fresh();s.mode="survival";s.frogs[0].pos=Vector2(-1,8);s.frogs[1].pos=Vector2(1,8);s.explode_grenade(shot(Vector2(0,8),Vector2.ZERO))
	check(s.frogs[0].hp<100 and s.frogs[1].hp==100,"Burr preserves co-op teammate protection and self-damage")
	s=fresh();s.frogs[1].pos=Vector2(2,8);var cover:Dictionary=s.platform(Vector2(1,8),.5,"loose");s.Physics.prepare(cover,4,3);s.platforms=[cover];s.explode_grenade(shot(Vector2(0,8),Vector2.ZERO))
	check(s.frogs[1].hp==100 and cover.vel.x>0,"Physical cover shields a frog while taking the blast impulse")
	s=Sim.new([{}],"versus",23,"deadfall");s.countdown=0
	for i in range(120):s.step(1.0/60,[{}])
	var pieces:Array=s.platforms.filter(func(b):return b.kind=="loose")
	s.explode_grenade(shot(Vector2(-1.4,17),Vector2.ZERO))
	check(pieces.filter(func(b):return b.vel.length()>3).size()>=3,"Burr blast scatters multiple stack pieces")
	var world:=World.new();root.add_child(world);world.build(s)
	check(world.frogs[0].muzzles.size()==7,"Hand grenade model is included in the held-weapon set")
	var blast:Node3D=world.combat.impact_blast
	for i in range(180):s.update_feedback(1.0/120);world.update()
	check(blast.pool.size()==4 and blast.pool[0].fires.size()==6 and blast.pool[0].chips.size()==10,"Explosion renderer uses bounded reusable fire, smoke and fragment pools")
	world.free()
	print("Frog Fighter Burr Bomb: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
