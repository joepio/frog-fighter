extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func game(id:String="deadfall")->RefCounted:
	var s:=Sim.new([{}],"versus",23,id);s.countdown=0;s.crates=[];s.pickups=[];s.pickup_timer=1000
	return s
func advance(s:RefCounted,seconds:float,input:Dictionary={})->void:
	for i in range(int(seconds*60)):s.step(1.0/60,[input])
func _initialize()->void:
	for id in Sim.Arenas.EXPANSION_IDS:
		var s:=game(id);advance(s,3)
		var pieces:Array=s.platforms.filter(func(b):return b.kind=="loose" and not b.get("rubble",false))
		check(pieces.size()>=4,id+" has a real stack of separate bodies")
		check(pieces.all(func(b):return b.pos.distance_to(b.base)<.12 and absf(b.angle)<.06),id+" stack rests stably without spontaneous collapse")
		check(pieces.all(func(b):return b.get("sleeping",false)),id+" settled stacks sleep")
		check(s.frogs[0].ground>=0 and s.platforms[s.frogs[0].ground].kind=="fixed",id+" spawn remains clear")
		var bottom:Dictionary=pieces[0]
		s.Physics.impulse(bottom,Vector2(-42,4),bottom.pos+Vector2(0,.3));advance(s,.8)
		check(bottom.pos.distance_to(bottom.base)>.4,id+" support can be knocked out")
		check(pieces[2].pos.distance_to(pieces[2].base)>.15 or absf(pieces[2].angle)>.1,id+" removing a support destabilizes the crosspiece")
		check(pieces.all(func(b):return b.pos.is_finite() and b.vel.is_finite() and absf(b.omega)<=12),id+" tumbling remains bounded")
	var s:=game("vineway");var index:=4;var plank:Dictionary=s.platforms[index]
	var idle:=game("vineway")
	var p:Dictionary=s.frogs[0]
	p.pos=plank.pos+Vector2(-.8,Sim.RADIUS+.21);p.vel=Vector2(10,-8);p.ground=index
	advance(s,.4)
	advance(idle,.4)
	check(plank.pos.distance_to(idle.platforms[index].pos)>.1,"Landing momentum changes a hanging platform's swing")
	check(plank.ropes.all(func(r):return (plank.pos+r.local.rotated(plank.angle)).distance_to(r.anchor)<=r.length+.025),"Ropes keep their physical length after a landing")
	s=game("vineway");plank=s.platforms[index];p=s.frogs[0]
	var start:Vector2=plank.pos
	p.pos=plank.pos+Vector2(3,-2);p.vel=Vector2.ZERO;p.ground=-1;p.tongue_prev=true
	p.anchor={"platform":index,"offset":Vector2(.9,0)};p.rope=p.pos.distance_to(s.anchor_point(p.anchor))
	advance(s,.65,{"tongue":true,"move":Vector2(0,1)})
	check(plank.pos.x>start.x+.18,"Reeling a tongue pulls the hanging platform toward the frog")
	check(not p.anchor.is_empty() and p.pos.distance_to(s.anchor_point(p.anchor))<=p.rope+.12,"Tongue remains attached to its moving local contact")
	s=game("vineway");plank=s.platforms[index];p=s.frogs[0]
	p.pos=plank.pos+Vector2(0,Sim.RADIUS+.2);p.ground=index;plank.vel=Vector2(4,0)
	s.update_frog(p,{"jump":true},1.0/60)
	check(p.vel.x>1.5 and p.vel.y>20,"Jump inherits sideways platform momentum")
	check(plank.vel.y<-.5,"Jump pushes back on the hanging platform")
	s=game();advance(s,2)
	var pieces:Array=s.platforms.filter(func(b):return b.kind=="loose" and not b.get("rubble",false))
	var top:Dictionary=pieces.back();p=s.frogs[0]
	p.pos=top.pos+Vector2(0,top.height*.5+Sim.RADIUS+.03);p.vel=Vector2.ZERO;p.ground=-1
	advance(s,1)
	check(p.ground==s.platforms.find(top) and p.lives==3,"Frog can stand on the top of a stacked body")
	s=game();advance(s,2);pieces=s.platforms.filter(func(b):return b.kind=="loose" and not b.get("rubble",false));top=pieces.back();p=s.frogs[0]
	p.pos=top.pos+Vector2(-3,.1);p.aim=Vector2.RIGHT;p.weapon="rail";p.ammo=3
	s.fire(p)
	check(top.vel.x>5 and absf(top.omega)>.2,"Rail shot hits the side and adds spin to a stone or log")
	check(not top.get("sleeping",false),"Weapon impact wakes resting props")
	var anchor:Dictionary=s.cast_tongue(top.pos+Vector2(3,0),Vector2.LEFT)
	check(anchor.get("platform",-1)==s.platforms.find(top),"Tongue can grab the side of a loose block")
	check(not s.bot_clear_shot(top.pos+Vector2(-2,0),top.pos+Vector2(2,0)),"Loose blocks provide real weapon cover")
	s=game();advance(s,2);pieces=s.platforms.filter(func(b):return b.kind=="loose" and not b.get("rubble",false))
	s.explode_grenade({"pos":Vector2(-1.4,17),"life":1.0,"owner":0,"volley":17})
	check(pieces.filter(func(b):return b.vel.length()>2).size()>=3,"Explosion scatters multiple pieces of a stack")
	advance(s,1)
	check(pieces.any(func(b):return absf(b.angle)>.25),"Explosion produces visible tumbling")
	# Test body-body momentum independently of level geometry and actors.
	s=game();s.platforms=[]
	var a:Dictionary=s.platform(Vector2(-.7,10),1,"loose");s.Physics.prepare(a,2,1)
	var b:Dictionary=s.platform(Vector2(.4,10),1,"loose");s.Physics.prepare(b,2,1)
	a.vel=Vector2(12,0);s.platforms=[a,b]
	for i in range(4):s.Physics.step(s,1.0/60)
	check(b.vel.x>3 and a.vel.x<10,"Loose bodies collide and transfer momentum to each other")
	# Lost pieces recover after ten seconds; they cannot pop into a frog.
	s=game();pieces=s.platforms.filter(func(body):return body.kind=="loose" and not body.get("rubble",false));top=pieces.back()
	top.pos=Vector2(0,-20);s.Physics.step(s,1.0/60)
	check(not top.active,"Fallen debris leaves the arena")
	top.restore=0;s.frogs[0].pos=top.base;s.Physics.step(s,1.0/60)
	check(not top.active,"Debris does not respawn inside a frog")
	s.frogs[0].pos=s.spawns[0];top.restore=0;s.Physics.step(s,1.0/60)
	check(top.active and top.pos.distance_to(top.base)<.05,"Lost debris returns to an unoccupied home")
	# Safe ponds float the physical pieces instead of deleting them.
	s=game("reed_delta");s.platforms=[]
	var floater:Dictionary=s.platform(Vector2(0,.5),1,"loose");s.Physics.prepare(floater,2,1);s.platforms=[floater]
	for i in range(240):s.Physics.step(s,1.0/60)
	check(floater.active and floater.pos.y>-.3 and floater.pos.y<.7,"Loose timber settles into safe water")
	# Resting debris must wake when its support collapses.
	s=game();s.platforms=[]
	var bridge:Dictionary=s.platform(Vector2(0,5),4,"crumble")
	var block:Dictionary=s.platform(Vector2(0,5.7),1,"loose");s.Physics.prepare(block,2,1)
	block["sleeping"]=true;block["rest_time"]=2.0;s.platforms=[bridge,block];bridge.stress=1
	s.update_crumble(bridge,1.0/60)
	for i in range(30):s.update_crumble(bridge,1.0/60);s.Physics.step(s,1.0/60)
	check(not block.get("sleeping",false) and block.pos.y<5,"Sleeping debris falls when its bridge support gives way")
	# Moving scenery can hurt a frog, but an ordinary landing must not.
	s=game();s.clock=1;s.platforms=[];p=s.frogs[0];p.invincible=0
	block=s.platform(Vector2(0,10),1,"loose");s.Physics.prepare(block,2,1);block.vel=Vector2(12,0);s.platforms=[block]
	p.pos=Vector2(.7,10);p.vel=Vector2.ZERO;s.land(p,Sim.RADIUS,1.0/60)
	check(p.hp<100 and p.vel.x>0,"Fast thrown timber knocks and hurts a frog")
	s=game();s.platforms=[];p=s.frogs[0];p.invincible=0
	block=s.platform(Vector2(0,10),1,"loose");s.Physics.prepare(block,2,1);s.platforms=[block]
	p.pos=Vector2(0,10.7);p.vel=Vector2(0,-15);s.land(p,Sim.RADIUS,1.0/60)
	check(p.hp==100,"Landing on stationary timber does not inflict impact damage")
	var grenade:Dictionary={"pos":Vector2(-1,10),"vel":Vector2(15,0),"life":1.0,"owner":0,"volley":10,"kind":"grenade"}
	s.update_grenade(grenade,.05)
	check(grenade.vel.x<0 and block.vel.x>0,"Grenade bounces off a block side and transfers momentum")
	print("Frog Fighter physical scenery: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
