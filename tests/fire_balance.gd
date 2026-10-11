extends SceneTree
const Sim=preload("res://src/simulation.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh()->RefCounted:
	var s:=Sim.new([{},{},{}]);s.countdown=0;s.platforms=[];s.crates=[];s.pickups=[];s.pickup_timer=100
	for i in range(3):s.frogs[i].pos=Vector2(-10+i*10,9);s.frogs[i].invincible=0
	return s
func shot_damage(distance:float)->float:
	var s:=fresh();var p:Dictionary=s.frogs[0];p.pos=Vector2(0,9);p.aim=Vector2.RIGHT;p.weapon="flame";p.ammo=70
	var travel:float=distance/18
	s.frogs[1].pos=p.pos+Vector2(.35+distance,Sim.FlameStyle.rise(travel).y);s.frogs[2].pos=Vector2(20,20)
	s.fire(p)
	for i in range(34):s.update_shots(1.0/120)
	return 100-s.frogs[1].hp
func _initialize()->void:call_deferred("run")
func run()->void:
	var close:float=shot_damage(1.2);var far:float=shot_damage(4.2)
	check(close>7 and far>0 and close>far*1.6,"Actual flame projectiles hit much harder near the nozzle")
	var s:=fresh();var p:Dictionary=s.frogs[1]
	s.hurt(p,7.5,Vector2.ZERO,"flame",1)
	check(p.burn==1.6,"Direct flame ignites a 1.6-second burn")
	var hp:float=p.hp;s.update_burning(.5)
	check(is_equal_approx(hp-p.hp,6.0) and p.burn>1,"Damage continues after the stream stops")
	check(s.hitstop==0 and s.gore.is_empty(),"Burn ticks add no hit pause or blood stream")
	p.invincible=0;s.hurt(p,7.5,Vector2.ZERO,"flame",2)
	check(p.burn==1.6,"Another hit refreshes duration without stacking burns")
	hp=p.hp;s.update_burning(2.0)
	check(is_equal_approx(hp-p.hp,19.2) and p.burn==0,"Burn only deals damage for its remaining duration")
	hp=p.hp;s.update_burning(1);check(p.hp==hp,"Expired fire deals no more damage")
	p.burn=1;p.in_water=true;hp=p.hp;s.update_burning(.1)
	check(p.burn==0 and p.hp==hp,"Water extinguishes fire immediately")
	p.in_water=false;p.hp=1;p.burn=.5;var lives:int=p.lives;s.update_burning(.1)
	check(p.lives==lives-1 and p.respawn>0 and p.burn==0,"Afterburn can finish a frog once and clears on knockout")
	s=fresh();p=s.frogs[1];p.invincible=2;s.hurt(p,7.5,Vector2.ZERO,"flame")
	check(p.burn==0 and p.hp==100,"Spawn protection prevents ignition")
	p.invincible=0;p.burn=1;hp=p.hp;s.hitstop=.5;s.step(.1,[{},{},{}])
	check(p.burn==1 and p.hp==hp,"Hit pauses freeze damage and burn lifetime together")
	s.hitstop=0;s.countdown=.5;s.step(.1,[{},{},{}])
	check(p.burn==1 and p.hp==hp,"Ready countdown does not advance burns")
	s.countdown=0;s.over=true;s.update_burning(.1)
	check(p.hp==hp,"A declared winner takes no afterburn damage")
	s=fresh();p=s.frogs[1];s.damage=2;p.burn=1;hp=p.hp;s.update_burning(.25)
	check(is_equal_approx(hp-p.hp,6.0),"Burn honors the live damage multiplier")
	s.spawn_enemy("bird",Vector2(0,9));var enemy:Dictionary=s.enemies.back()
	s.hurt_enemy(enemy,1,Vector2.ZERO,"flame");hp=enemy.hp;s.update_burning(.5)
	check(enemy.burn>1 and is_equal_approx(hp-enemy.hp,12.0),"Survival enemies also catch fire and take afterburn")
	print("Frog Fighter fire balance: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
