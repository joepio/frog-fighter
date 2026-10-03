extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh()->RefCounted:
	var s:=Sim.new([{"slot":0},{"slot":1},{"slot":2}],"versus",17)
	s.platforms=[];s.crates=[];s.pickups=[];s.countdown=0
	for p in s.frogs:p.invincible=0;p.pos=Vector2(-9+p.slot*6,8);p.vel=Vector2.ZERO
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=fresh();var p:Dictionary=s.frogs[0]
	for side in [-1.0,1.0]:
		p.pos=Vector2(side*(Sim.WALL_LIMIT-.01),3);p.vel=Vector2.ZERO;p.stuck=false;p.wall_release=0;p.wall_air=0;p.jump_prev=false
		s.update_frog(p,{},1.0/120)
		for cycle in range(2):
			var height:float=p.pos.y
			s.update_frog(p,{"jump":true,"move":Vector2(side,0)},1.0/120)
			check(not p.stuck and p.vel.x*side<0,"Wall jump initially pushes outward")
			for frame in range(70):
				s.update_frog(p,{"jump":true,"move":Vector2(side,0)},1.0/120)
				if p.stuck:break
			check(p.stuck and p.pos.y>height+2,"Steering back reattaches higher on the same wall")
			s.update_frog(p,{},1.0/120)
	s=fresh();p=s.frogs[0];p.pos=Vector2(-4,8);p.weapon="rail";p.ammo=3;p.aim=Vector2.RIGHT
	s.frogs[1].pos=Vector2(0,8);s.frogs[2].pos=Vector2(3,8);s.fire(p)
	check(s.frogs[1].hp<=0 and s.frogs[2].hp<=0,"Rail instantly penetrates aligned frogs with lethal direct hits")
	check(p.ammo==2 and p.cooldown==1.6 and p.vel.x< -6,"Rail spends one round with long recovery and heavy recoil")
	check(s.fx.any(func(e):return e.kind=="rail" and e.get("length",0)>10),"Rail creates a full beam afterimage")
	s=fresh();p=s.frogs[0];p.pos=Vector2(-4,8);p.weapon="rail";p.ammo=3;p.aim=Vector2.RIGHT
	s.crates=[{"pos":Vector2(-1,8),"vel":Vector2.ZERO,"angle":0.0}];s.frogs[1].pos=Vector2(1,8);s.fire(p)
	check(s.frogs[1].hp==100 and s.crates[0].vel.x>0,"Solid cover blocks rail and receives its impulse")
	s=fresh();p=s.frogs[0];p.weapon="grenade";p.ammo=6;p.aim=Vector2.RIGHT;s.fire(p)
	check(s.shots.size()==1 and s.shots[0].kind=="grenade" and s.shots[0].vel.y>0,"Lobber fires a rising grenade")
	var shot:Dictionary=s.shots[0];shot.pos=Vector2(0,4.36);shot.vel=Vector2(3,-8)
	s.platforms=[s.platform(Vector2(0,4),6,"fixed")];s.update_shots(.02)
	check(shot.life>0 and shot.vel.y>0,"Grenade bounces off a platform without exploding")
	s.platforms=[];s.frogs[1].pos=Vector2(.6,8);s.frogs[2].pos=Vector2(1.9,8);shot.pos=Vector2(0,8);shot.vel=Vector2.ZERO;shot.life=.005
	s.update_shots(.01)
	check(s.shots.is_empty() and s.fx.any(func(e):return e.kind=="explosion"),"Fuse detonates and removes grenade exactly once")
	check(s.frogs[1].hp<s.frogs[2].hp and s.frogs[2].hp<100,"Blast damages multiple frogs with distance falloff")
	check(s.frogs[1].vel.x>0 and s.frogs[2].vel.x>0,"Blast throws nearby frogs outward")
	s=fresh();s.mode="survival";s.frogs[0].pos=Vector2(-.6,8);s.frogs[1].pos=Vector2(.6,8)
	s.explode_grenade({"pos":Vector2(0,8),"owner":0,"volley":1,"life":1.0})
	check(s.frogs[1].hp==100 and s.frogs[0].hp<100,"Grenades preserve co-op protection but can hurt their owner")
	s=Sim.new([{"slot":0},{"slot":1}],"versus",17)
	check(s.pickups.any(func(i):return i.kind=="rail") and s.pickups.any(func(i):return i.kind=="grenade"),"Both new weapons are available at round start")
	var world:=World.new();root.add_child(world);world.build(s)
	for side in [-1.0,1.0]:
		p=s.frogs[0];p.pos=Vector2(side*Sim.WALL_LIMIT,7);p.stuck=true;p.ground=-1;p.vel=Vector2.ZERO;p.aim=Vector2.RIGHT;p.weapon="rail";p.shot_age=10
		world.update()
		check(is_equal_approx(world.frogs[0].body.rotation.z,side*PI*.5),"Wall pose puts feet toward the wall and head inward")
		var gun:Node3D=world.frogs[0].gun
		check(absf(gun.global_basis.x.normalized().y)<.03,"Gun keeps aiming horizontally while body clings sideways")
	check(world.frogs[0].muzzles.size()==Sim.WEAPON_ORDER.size() and world.frogs[0].gun.scale.x>1.6,"Seven weapon silhouettes render at the larger scale")
	world.free()
	print("Frog Fighter wall/arsenal: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
