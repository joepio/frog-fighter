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
	for id in Sim.Arenas.CLASSIC_IDS:
		var s:=Sim.new([{}],"versus",17,id);s.countdown=0;s.crates=[];s.pickups=[];s.pickup_timer=999
		var p:Dictionary=s.frogs[0]
		# Low speed and hard falls must both float, rather than respawn or tunnel.
		for speed in [-1.0,-30.0]:
			p.pos=Vector2(6,.65);p.vel=Vector2(0,speed);p.ground=-1;p.anchor={};p.jump_prev=false
			for i in range(120):s.update_frog(p,{},1.0/120)
			check(p.in_water and p.lives==3 and p.hp==100 and p.respawn==0,id+" water is safe at fall speed "+str(speed))
			check(absf(p.pos.y-Sim.Terrain.WATER_LEVEL)<Sim.RADIUS*.3,id+" floats partly submerged at the visible waterline")
		p.weapon="seed";p.ammo=10;s.update_frog(p,{"fire":true,"aim":Vector2.RIGHT},1.0/120)
		check(s.shots.size()==1 and p.in_water,id+" can shoot while floating")
		var at:float=p.pos.x
		for i in range(18):s.update_frog(p,{"move":Vector2.RIGHT},1.0/120)
		check(p.pos.x>at+.25 and p.in_water,id+" can steer on water")
		s.update_frog(p,{"jump":true},1.0/120)
		check(not p.in_water and p.vel.y>20 and p.pos.y>Sim.Terrain.WATER_LEVEL+.1,id+" can jump straight out of water")
		var anchor:Dictionary=s.cast_tongue(Vector2(6,.5),s.platforms[1].pos+Vector2(0,.2)-Vector2(6,.5))
		check(not anchor.is_empty() and s.platforms[anchor.platform].kind!="water",id+" can grapple from the water")
		check(s.cast_tongue(Vector2(6,1.5),Vector2(0,-1)).is_empty(),id+" tongue cannot stick to liquid")
		for side in [-1.0,1.0]:
			var rock:Dictionary=s.platforms.filter(func(a):return a.kind=="rock" and absf(a.pos.x-side*4.1)<.01).front()
			p.pos=rock.pos+Vector2(0,.9);p.vel=Vector2(0,-3);p.ground=-1;p.jump_prev=false;p.anchor={}
			for i in range(60):s.update_frog(p,{},1.0/120)
			check(p.ground>=0 and s.platforms[p.ground]==rock and not p.in_water,id+" lands on exposed rock on side "+str(side))
			check(absf(p.pos.y-rock.pos.y-.2-Sim.RADIUS)<.01,id+" feet rest on the visible rock crown")
			s.update_frog(p,{"jump":true},1.0/120);check(p.vel.y>20,id+" jumps from rocks")
	# Actual renderer: matching terrain, pond immersion, shadow/ripple state.
	var s:=Sim.new([{}],"versus",17,"vineway");s.crates=[];s.pickups=[]
	var p:Dictionary=s.frogs[0];p.pos=Vector2(6,-1);p.vel=Vector2(0,-20)
	s.update_frog(p,{},1.0/60)
	var world:=World.new();root.add_child(world);world.build(s)
	check(world.swim_rings[0].visible and not world.contact_shadows[0].visible,"Floating frog shows a ripple instead of a ground shadow")
	s.update_frog(p,{"jump":true},1.0/60);world.update()
	check(not world.swim_rings[0].visible,"Water ripple clears on jumping out")
	world.free()
	print("Frog Fighter terrain: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
