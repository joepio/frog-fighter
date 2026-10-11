extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh()->RefCounted:
	var s:=Sim.new([{}],"versus",23,"sky_ruins");s.countdown=0;s.platforms=[];s.hooks=[];s.crates=[];s.pickups=[];s.pickup_timer=100
	return s
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=fresh();s.platforms=[s.platform(Vector2(4,3),2,"fixed")]
	var anchor:Dictionary=s.cast_tongue(Vector2(0,2),Vector2.RIGHT)
	check(not anchor.is_empty() and s.anchor_point(anchor).is_equal_approx(Vector2(3,3.2)),"Aiming below a shelf snaps to its nearby edge without a ray hit")
	s.platforms.append(s.platform(Vector2(9,4),2,"fixed"))
	anchor=s.cast_tongue(Vector2(0,2),Vector2.RIGHT)
	check(anchor.platform==0,"Nearer reachable edge wins over a distant one")
	s.platforms[0].active=false;anchor=s.cast_tongue(Vector2(0,2),Vector2.RIGHT)
	check(anchor.platform==1,"Missing terrain is skipped for the next available edge")
	s.platforms=[s.platform(Vector2(-4,2),2,"fixed")]
	check(s.cast_tongue(Vector2(0,2),Vector2.RIGHT).is_empty(),"No surprise attachment behind the player")
	s.platforms=[s.platform(Vector2(15,2),2,"fixed")]
	check(s.cast_tongue(Vector2(0,2),Vector2.RIGHT).is_empty(),"Edges beyond tongue reach are not attached")
	s.platforms=[];s.hooks=[Vector2(5,3)]
	anchor=s.cast_tongue(Vector2(0,2),Vector2.RIGHT)
	check(not anchor.is_empty() and s.anchor_point(anchor)==s.hooks[0],"Nearby vine hooks also accept imprecise aim")
	s.hooks=[];var box:Dictionary=s.platform(Vector2(4,3),2,"loose");s.Physics.prepare(box,3,2);box.angle=.25;s.platforms=[box]
	anchor=s.cast_tongue(Vector2(0,3),Vector2.RIGHT)
	check(not anchor.is_empty() and anchor.platform==0,"Rotated physical box edges can be selected")
	var offset:Vector2=anchor.offset;box.pos+=Vector2(1,2);box.angle+=.3
	check(s.anchor_point(anchor).is_equal_approx(box.pos+offset.rotated(box.angle)),"Selected edge follows box motion and rotation")
	s=fresh();var obstruction:Dictionary=s.platform(Vector2(3,3),1,"loose");s.Physics.prepare(obstruction,3,4)
	s.platforms=[obstruction,s.platform(Vector2(7,3),3,"fixed")];anchor=s.cast_tongue(Vector2(0,3),Vector2.RIGHT)
	check(not anchor.is_empty() and anchor.platform==0 and s.anchor_point(anchor).x<3,"Tongue catches the visible face rather than passing through cover")
	s=fresh();var p:Dictionary=s.frogs[0];p.pos=Vector2(0,8);p.vel=Vector2.ZERO;p.aim=Vector2.RIGHT
	s.update_frog(p,{"tongue":true,"move":Vector2(0,1)},1.0/120)
	check(p.anchor.is_empty() and p.tongue_miss>0,"An empty-air shot starts an unanchored tongue animation")
	check(is_equal_approx(p.vel.y,-s.FALL_GRAVITY/120.0),"A missed tongue never suspends or reels the player")
	# Use real presentation objects to verify the empty-air tongue is actually drawn.
	var view_sim:=Sim.new([{}]);var w:=World.new();root.add_child(w);w.build(view_sim)
	var frog:Dictionary=view_sim.frogs[0];frog.tongue_miss=Sim.TONGUE_MISS_DURATION*.5;frog.tongue_direction=Vector2.RIGHT
	w.update()
	check(w.frogs[0].tongue.get_child_count()==2 and w.frogs[0].open_mouth.visible,"Miss draws a tongue and tip with an open mouth")
	view_sim.update_feedback(.5);w.update()
	check(w.frogs[0].tongue.get_child_count()==0 and not w.frogs[0].open_mouth.visible,"Miss retracts and clears without an anchor")
	w.free()
	print("Frog Fighter tongue targeting: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
