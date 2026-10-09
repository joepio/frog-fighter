extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh(kind:String="fixed",angle:float=0.0)->RefCounted:
	var s:=Sim.new([{}],"survival",12);s.countdown=0;s.platforms=[];s.crates=[];s.pickups=[]
	var top:Dictionary=s.platform(Vector2(0,6),8,kind);top.angle=angle
	s.platforms=[top,s.platform(Vector2(0,3),8,"fixed")]
	var p:Dictionary=s.frogs[0];p.pos=top.pos+Vector2(-sin(angle),cos(angle))*(s.RADIUS+.2)
	p.vel=Vector2.ZERO;p.ground=0;p.invincible=0
	return s
func run()->void:
	for kind in ["fixed","swing","ferry","lift","seesaw","crumble","fungus","timber","masonry"]:
		var s:=fresh(kind);var p:Dictionary=s.frogs[0];var y:float=p.pos.y
		s.update_frog(p,{"move":Vector2(0,-1),"jump":true},1.0/120)
		check(p.ground==-1 and p.drop_platform==0 and p.pos.y<y and p.vel.y<0,"Down+jump drops through "+kind)
		for i in range(90):s.update_frog(p,{"move":Vector2(0,-1),"jump":true},1.0/120)
		check(p.ground==1 and p.drop_platform==-1,"Holding drop lands on the next shelf for "+kind)
		# Release and press again: each platform needs its own deliberate drop.
		s.update_frog(p,{},1.0/120);s.update_frog(p,{"move":Vector2(0,-1),"jump":true},1.0/120)
		check(p.ground==-1 and p.drop_platform==1,"A fresh press drops through the next shelf for "+kind)
	for angle in [-.3,.3]:
		var s:=fresh("seesaw",angle);var p:Dictionary=s.frogs[0]
		s.update_frog(p,{"move":Vector2(0,-1),"jump":true,"grip":true},1.0/120)
		check(p.ground==-1 and not p.stuck,"Drop releases angled platforms even while grip is held")
	var s:=fresh();var p:Dictionary=s.frogs[0]
	s.update_frog(p,{"move":Vector2(0,-1)},1.0/120)
	check(p.ground==0 and p.drop_platform==-1,"Down alone does not fall through the floor")
	s=fresh();p=s.frogs[0];s.update_frog(p,{"jump":true},1.0/120)
	check(p.vel.y>10 and p.drop_platform==-1,"Normal jump still launches upward")
	for kind in ["rock","water","loose","barricade","pier"]:
		s=fresh(kind);p=s.frogs[0];s.update_frog(p,{"move":Vector2(0,-1),"jump":true},1.0/120)
		check(p.drop_platform==-1 and p.vel.y>0,"Solid ground/props keep normal jump: "+kind)
	s=fresh();p=s.frogs[0];p.respawn=.001;p.drop_platform=0;p.drop_time=.4
	s.update_frog(p,{},1.0/120)
	check(p.drop_platform==-1 and p.drop_time==0,"Respawn clears ignored platform")
	print("Frog Fighter drop-through: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
func _initialize()->void:call_deferred("run")
