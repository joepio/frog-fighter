extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var s:=Sim.new([{"slot":0}],"survival",17);s.countdown=0
	s.spawn_wave()
	check(s.wave==1 and s.enemies.size()==8,"First wave has eight bees")
	check(s.enemies.all(func(e):return e.kind=="bee"),"First wave introduces bees alone")
	s.enemies=[];s.spawn_wave()
	check(s.enemies.size()==10 and s.enemies.any(func(e):return e.kind=="mosquito"),"Wave two adds mosquitoes and more enemies")
	s.enemies=[];s.spawn_wave()
	check(s.enemies.any(func(e):return e.kind=="bird"),"Small birds join from wave three")
	s.enemies=[];s.wave=4;s.spawn_wave()
	var bosses:Array=s.enemies.filter(func(e):return e.kind=="boss")
	check(bosses.size()==1 and bosses[0].max_hp==450,"Wave five introduces one substantial bird boss")
	check(s.enemies.any(func(e):return e.kind=="bird") and s.enemies.any(func(e):return e.kind=="mosquito"),"Boss wave keeps a mixed escort")
	var boss:Dictionary=bosses[0];s.hurt_enemy(boss,100,Vector2.RIGHT*8,"rail")
	check(boss.hp==350 and boss.flash>0,"Rail hurts and flashes the boss without instantly deleting it")
	s.enemies=[boss];boss.hp=200;boss.summon=0;s.update_survival(.01)
	check(boss.enraged and s.enemies.size()==3,"Wounded boss summons a pair of bees")
	s.hurt_enemy(boss,999,Vector2.RIGHT,"rail");s.update_survival(.01)
	check(not s.enemies.has(boss) and s.pickups.any(func(p):return p.kind=="rail"),"Defeated boss is removed and drops weapons")
	s.enemies=[];s.wave=9;s.spawn_wave()
	check(s.enemies.filter(func(e):return e.kind=="boss")[0].max_hp>450,"Later fifth-wave bosses scale up")
	s.enemies=[];s.wave=98;s.spawn_wave();check(s.enemies.size()==26,"Regular waves stay bounded at 26 enemies")
	s.platforms=[];s.crates=[];s.enemies=[]
	var p:Dictionary=s.frogs[0];p.pos=Vector2(0,5);p.vel=Vector2.ZERO;p.invincible=0;p.hp=100;p.enemy_guard=0
	var bee:Dictionary=s.spawn_enemy("bee",p.pos+Vector2(.2,0));bee.cooldown=0
	var bee2:Dictionary=s.spawn_enemy("bee",p.pos+Vector2(-.2,0));bee2.cooldown=0
	s.update_survival(.01)
	check(p.hp==91 and p.enemy_guard>0,"Crowded enemies cannot stack contact hits in one frame")
	for kind in ["mosquito","bird","boss"]:
		s.enemies=[];p.pos=Vector2(0,5)
		var enemy:Dictionary=s.spawn_enemy(kind,Vector2(0,9));enemy.timer=0
		s.update_survival(.01);check(enemy.state=="windup","%s telegraphs before attacking"%kind)
		for frame in range(110):s.clock+=.01;s.update_survival(.01)
		check(enemy.state in ["strike","recover"] and enemy.pos.y<9,"%s commits to a diving attack"%kind)
	s.enemies=[]
	for kind in ["bee","mosquito","bird","boss"]:s.spawn_enemy(kind,Vector2(-6+s.enemies.size()*4,8))
	var world:=World.new();root.add_child(world);world.build(s);world.update()
	check(world.enemy_visuals.visuals.size()==4,"Every enemy type has its own persistent character model")
	for enemy in s.enemies:
		var visual:Dictionary=world.enemy_visuals.visuals[enemy.id]
		check(visual.eyes.size()==2 and visual.pupils.size()==2 and visual.wings.size()==2,"%s has expressive eyes and animated wings"%enemy.kind)
	var first:Dictionary=s.enemies[0];var visual:Dictionary=world.enemy_visuals.visuals[first.id]
	var instance_id:int=visual.root.get_instance_id();first.flash=.14;world.update()
	check(visual.lids[0].visible and not visual.eyes[0].visible,"Enemy blinks when hit")
	s.clock+=.1;world.update();check(visual.root.get_instance_id()==instance_id,"Enemy visuals are reused across animation frames")
	s.enemies=[];world.update();check(world.enemy_visuals.visuals.is_empty(),"Clearing enemies cleans up character models")
	world.free()
	print("Frog Fighter survival roster: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
