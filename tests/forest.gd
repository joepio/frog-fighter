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
	var s:=Sim.new([{"slot":0},{"slot":1}],"versus",1);s.countdown=0;s.pickups=[];s.crates=[]
	var original_platforms:Array=s.platforms.duplicate(true)
	var p:Dictionary=s.frogs[1];p.invincible=0;p.pos=Vector2(2,8)
	s.hurt(p,9,Vector2.RIGHT*3.4,"seed",1,p.pos+Vector2(-.28,.21)*s.FROG_SCALE)
	check(p.wounds.size()==1 and p.wounds[0].offset.distance_to(Vector2(-.28,.21))<.001,"Blood mark records actual local contact point")
	check(s.gore.size()==2 and s.gore.all(func(g):return g.radius<=.043),"Ordinary hit emits only two tiny contact droplets")
	check(s.fx.any(func(f):return f.kind=="mist"),"Hit creates dispersing blood mist")
	s.update_feedback(.05)
	check(s.gore.size()==4,"Pine hit emits four small droplets in total")
	var world:=World.new();root.add_child(world);world.build(s)
	var frog:Dictionary=world.frogs[1]
	check(frog.muzzles.size()==Sim.WEAPON_ORDER.size(),"All seven forest weapon models are present")
	p.flash=.19;world.update();check(frog.lids[0].visible and not frog.eyewhites[0].visible,"Eyes squeeze shut on impact")
	var always_visible:=true
	for frame in range(48):
		p.flash=maxf(0,.19-frame/120.0);p.invincible=2.0; s.clock=frame/120.0;world.update()
		always_visible=always_visible and frog.body.visible and frog.root.visible
	check(always_visible,"Frog stays visible through the entire hit reaction and invulnerability cycle")
	p.flash=0;world.update();check(frog.body.visible and not frog.lids[0].visible and frog.eyewhites[0].visible,"Frog and eyes return after blink")
	check(frog.wounds[0].visible,"Blood remains after the hit flash")
	var before:Vector3=frog.wounds[0].global_position;p.pos.x+=1;world.update()
	check(absf(frog.wounds[0].global_position.x-before.x-1)<.01,"Blood mark follows the moving frog")
	p.respawn=.001;s.update_frog(p,{},.01);check(p.wounds.is_empty(),"Respawn clears blood marks")
	p.invincible=0;p.hp=100;s.hitstop=0;s.gore=[];s.fx=[];s.delayed_gore=[];p.flash=0
	for i in range(10):
		p.invincible=0;s.hurt(p,3.5,Vector2.RIGHT*.65,"flame",10+i);s.update_feedback(.075)
	check(p.hp==65,"Continuous flame applies sustained damage")
	check(s.hitstop==0,"Nonlethal flame does not repeatedly freeze the arena")
	check(s.gore.is_empty(),"Sustained flame produces no blood-blob stream")
	check(p.wounds.size()<=6,"Persistent wound marks are bounded")
	world.update();check(p.burn>1 and frog.burning.visible,"Flame damage ignites visible body flames")
	var fire_before:Vector3=frog.burning.global_position;p.pos.x+=1;world.update()
	check(absf(frog.burning.global_position.x-fire_before.x-1)<.01,"Burning follows the moving victim")
	s.update_feedback(.6);world.update();check(frog.burning.visible and p.burn>0,"Fire remains after the flame stream leaves")
	s.update_feedback(.7);world.update();check(p.burn==0 and not frog.burning.visible,"Residual fire expires and hides its pooled effects")
	p.invincible=1;s.hurt(p,3.5,Vector2.RIGHT,"flame",90)
	check(p.burn==0,"Blocked flame damage cannot ignite a protected frog")
	p.burn=1;p.respawn=.001;s.update_frog(p,{},.01);world.update()
	check(p.burn==0 and not frog.burning.visible,"Respawning clears fire")
	var shooter:Dictionary=s.frogs[0];shooter.weapon="flame";shooter.ammo=70;s.shots=[];s.fire(shooter)
	check(shooter.ammo==69 and s.shots[0].life<=.28,"Dragonpod consumes fuel and has short projectile reach")
	s.enemies=[];s.platforms=[];s.crates=[];s.frogs[1].pos=Vector2(30,30)
	s.update_shots(.3);check(s.shots.is_empty(),"Flame cannot travel beyond its short lifetime")
	shooter.pos=Vector2(-1,9);shooter.aim=Vector2.RIGHT;shooter.vel=Vector2.ZERO;s.fx=[];s.fire(shooter)
	var flame_start:Vector2=s.shots[0].pos
	s.update_shots(.10)
	check(s.shots[0].pos.y>flame_start.y and s.shots[0].vel.y>0,"Flame jets accelerate upward in world space")
	var curved_pos:Vector2=s.shots[0].pos
	s.shots=[];shooter.vel=Vector2.ZERO;s.fire(shooter)
	for tick in range(10):s.update_shots(.01)
	check(s.shots[0].pos.distance_to(curved_pos)<.001,"Flame trajectory is independent of simulation step size")
	var connected:=true;var previous_length:=0.0
	for frame in range(36):
		if frame%9==0:s.fire(shooter)
		s.update_feedback(1.0/120);world.combat.update(s)
		var jet:Dictionary=world.combat.jets[0]
		connected=connected and jet.node.visible and jet.length>=previous_length
		previous_length=jet.length
	check(connected and previous_length>3.8,"Held flame remains one connected full-length plume across four fuel ticks")
	s.update_feedback(.25);world.combat.update(s)
	check(not world.combat.jets[0].node.visible,"Continuous jet fades out after firing stops")
	s.shots=[]
	shooter.pos=Vector2(-1,9);shooter.aim=Vector2.RIGHT;s.fx=[]
	s.crates=[{"pos":Vector2(.5,9),"vel":Vector2.ZERO,"angle":0.0}];s.fire(shooter);s.update_shots(.1)
	check(s.shots.is_empty() and s.fx.filter(func(f):return f.kind=="flame")[0].reach<1.5,"Flame visual is clipped at the first blocking collision")
	check(s.flame_reach(shooter,4.8)<1.0,"Connected plume stops at the nearest blocking crate")
	s.crates=[];p.pos=Vector2(2,9);p.invincible=0;p.respawn=0;p.alive=true
	var fire_contact:Dictionary=s.flame_contact(shooter,4.8)
	check(fire_contact.blocked and absf(fire_contact.point.distance_to(p.pos)-.46*s.FROG_SCALE)<.001,"Flame reaches the visible frog surface rather than the expanded damage hitbox")
	check(not s.flame_contact(shooter,.5).blocked,"A free flame tip still dissipates without an impact")
	s.gore=[];p.alive=true;p.respawn=0;p.pos=Vector2(0,8);p.vel=Vector2.ZERO;p.burn=1;s.knockout(p)
	check(p.burn==0,"Knockout clears attached flames")
	var organs:Array=s.gore.filter(func(g):return g.has("organ"))
	check(organs.size()==3 and organs[0].organ==0 and organs[1].organ==1 and organs[2].organ==2,"Knockout ejects exactly three distinct organs")
	check(s.gore.filter(func(g):return g.chunk and not g.has("organ")).size()==5,"Knockout retains the five existing limb pieces")
	s.platforms=original_platforms
	world.update()
	check(world.organ_meshes.all(func(m):return m.multimesh.visible_instance_count==1),"Each organ uses its own visible mesh pool")
	s.platforms=[s.platform(Vector2(0,6),12,"fixed")]
	organs[0].pos=Vector2(0,6.2+organs[0].radius+.05);organs[0].vel=Vector2(0,-6);s.update_gore(.02)
	check(organs[0].bounces==1 and organs[0].bounce_squash>0,"Organs bounce and squash when they land")
	var life:float=organs[0].life;s.update_gore(.02);check(organs[0].life<life,"Organs expire with the other debris")
	world.free()
	print("Frog Fighter forest combat: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
