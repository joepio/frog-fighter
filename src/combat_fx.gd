extends Node3D
const FlameStyle=preload("res://src/flame_style.gd")
## Bounded visual pools: no per-frame mesh/material allocation for combat flashes or trails.
var host:Node3D
var bursts:Array=[]
var bullets:Array=[]
var star:Mesh
var ring:Mesh
var jets:Array=[]
var previous_time:=0.0
var impact_blast:Node3D

func glow(color:Color)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=color;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.no_depth_test=false
	return mat

func build(world:Node3D)->void:
	host=world
	impact_blast=preload("res://src/impact_blast.gd").new();add_child(impact_blast);impact_blast.build(world)
	for i in range(world.sim.frogs.size()):
		var mat:=FlameStyle.material();mat.set_shader_parameter("jet",true)
		mat.set_shader_parameter("phase",.3);mat.set_shader_parameter("seed",i*3.71)
		mat.set_shader_parameter("buoyancy",FlameStyle.BUOYANCY)
		var quad:=QuadMesh.new();quad.size=Vector2.ONE;quad.subdivide_width=32
		var node:MeshInstance3D=world.mesh(self,quad,Vector3.ZERO,Vector3.ONE,mat)
		node.custom_aabb=AABB(Vector3(-6,-6,-1),Vector3(12,12,2))
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visible=false
		jets.append({"node":node,"mat":mat,"age":0.0,"strength":0.0,"length":0.0})
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a:float=i*TAU/16;var b:float=(i+1)*TAU/16
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(cos(a),sin(a),0)*(1.0 if i%2==0 else .28))
		st.add_vertex(Vector3(cos(b),sin(b),0)*(1.0 if i%2==1 else .28))
	star=st.commit()
	var torus:=TorusMesh.new();torus.inner_radius=.96;torus.outer_radius=1.0;torus.rings=32;torus.ring_segments=6;ring=torus
	for i in range(64):
		var root:=Node3D.new();add_child(root)
		var mat:=glow(Color.WHITE)
		var flash:MeshInstance3D=host.mesh(root,star,Vector3.ZERO,Vector3.ONE,mat)
		var halo:MeshInstance3D=host.mesh(root,ring,Vector3.ZERO,Vector3.ONE,mat);halo.rotation.x=PI/2
		var smoke:MeshInstance3D=host.ball(root,Vector3.ZERO,Vector3.ONE,Color.WHITE);smoke.material_override=mat
		var mist_mat:=ShaderMaterial.new();mist_mat.shader=load("res://src/blood_mist.gdshader")
		var quad:=QuadMesh.new();quad.size=Vector2(2,2)
		var clouds:Array=[]
		for j in range(3):
			var cloud:MeshInstance3D=host.mesh(root,quad,Vector3(j*.08,(j-1)*.1,.04+j*.025),Vector3.ONE,mist_mat)
			cloud.rotation.z=j*1.7;cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;clouds.append(cloud)
		var flame_mat:=FlameStyle.material()
		var fire:MeshInstance3D=host.mesh(root,quad,Vector3.ZERO,Vector3.ONE,flame_mat);fire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var soot_mat:=FlameStyle.material(true)
		var soot:MeshInstance3D=host.mesh(root,quad,Vector3.ZERO,Vector3.ONE,soot_mat);soot.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for node in [flash,halo,smoke]:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.visible=false;bursts.append({"root":root,"flash":flash,"halo":halo,"smoke":smoke,"mat":mat,"clouds":clouds,"mist_mat":mist_mat,"fire":fire,"flame_mat":flame_mat,"soot":soot,"soot_mat":soot_mat})
	var trail_mat:=glow(Color(1,.79,.35,.65))
	for i in range(128):
		var root:=Node3D.new();add_child(root)
		var seed:MeshInstance3D=host.ball(root,Vector3.ZERO,Vector3(.25,.023,.023),Color("c2cc77"))
		var thorn:=CylinderMesh.new();thorn.top_radius=0;thorn.bottom_radius=.065;thorn.height=.29;thorn.radial_segments=6
		var bramble:MeshInstance3D=host.mesh(root,thorn,Vector3.ZERO,Vector3.ONE,host.material(Color("c0a477")));bramble.rotation.z=-PI/2
		var cup:MeshInstance3D=host.ball(root,Vector3.ZERO,Vector3(.18,.12,.12),Color("b88c50"))
		var stem:MeshInstance3D=host.ball(root,Vector3(-.12,0,0),Vector3(.08,.145,.145),Color("6f603a"))
		var trail:MeshInstance3D=host.ball(root,Vector3(-.36,0,-.02),Vector3(.38,.023,.023),Color.WHITE);trail.material_override=trail_mat
		var grenade:MeshInstance3D=host.ball(root,Vector3.ZERO,Vector3(.15,.15,.15),Color("b18abd"))
		var fuse:MeshInstance3D=host.ball(root,Vector3(0,.17,.02),Vector3(.055,.055,.055),Color("ffe7a0"))
		fuse.material_override=glow(Color("ffe7a0"))
		for node in [seed,bramble,cup,stem,trail,grenade,fuse]:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var burr:Node3D=host.ForestWeapons.burr_model(host,root);burr.scale=Vector3.ONE*.55;host.Scenery.batch_static(burr)
		root.visible=false;bullets.append({"burr":burr,"root":root,"seed":seed,"bramble":bramble,"cup":cup,"stem":stem,"trail":trail,"grenade":grenade,"fuse":fuse})

func update(sim:RefCounted)->void:
	impact_blast.update(sim)
	var dt:float=maxf(0,sim.fx_clock-previous_time);previous_time=sim.fx_clock
	for i in range(sim.frogs.size()):
		var j:Dictionary=jets[i];var p:Dictionary=sim.frogs[i]
		var active:bool=p.alive and p.respawn<=0 and p.last_weapon=="flame" and p.shot_age<.10
		if active:
			j.age+=dt;j.strength=1.0
		else:
			j.strength=maxf(0,j.strength-dt*10)
			if j.strength<=0:j.age=0.0
		j.node.visible=j.strength>0 and p.alive and p.respawn<=0
		if not j.node.visible:continue
		var frog:Dictionary=host.frogs[i]
		var offset:Vector3=frog.gun.to_global(Vector3(.745,.04,0))-frog.root.global_position
		var nozzle:Vector3=Vector3(p.pos.x,p.pos.y,.35)+offset
		var origin:=Vector2(nozzle.x,nozzle.y)
		var maximum:float=maxf(.12,5.5-(origin-p.pos).dot(p.aim))
		var contact:Dictionary=sim.flame_contact(p,minf(maximum,maxf(.12,j.age*18)),origin)
		j.length=contact.distance
		j.mat.set_shader_parameter("jet_contact",contact.blocked)
		j.node.position=nozzle+Vector3(0,0,.025);j.node.rotation.z=p.aim.angle()
		j.mat.set_shader_parameter("jet_length",j.length)
		j.mat.set_shader_parameter("jet_up",Vector2(p.aim.y,p.aim.x))
		j.mat.set_shader_parameter("clock",sim.fx_clock);j.mat.set_shader_parameter("strength",j.strength)
	for i in range(bursts.size()):
		var b:Dictionary=bursts[i];b.root.visible=i<sim.fx.size()
		if not b.root.visible:continue
		var effect:Dictionary=sim.fx[i];var t:float=effect.age/effect.life
		if effect.kind=="impact_blast":b.root.visible=false;continue
		var is_smoke:bool=effect.kind=="smoke"
		var is_mist:bool=effect.kind in ["mist","mist_ko"]
		var is_flame:bool=effect.kind=="flame"
		var is_dust:bool=effect.kind=="terrain_dust"
		var is_soot:bool=effect.kind=="flame_smoke" or is_dust
		var reach:float=effect.get("reach",4.8)
		var flame_length:float=minf(2.0+t*3.2,reach)
		for cloud in b.clouds:cloud.visible=is_mist
		b.fire.visible=false # The persistent jet replaces per-shot flame billboards.
		b.soot.visible=is_soot
		b.soot_mat.set_shader_parameter("phase",t)
		b.soot_mat.set_shader_parameter("clock",sim.fx_clock)
		b.soot_mat.set_shader_parameter("seed",effect.get("volley",i)*3.71)
		b.mist_mat.set_shader_parameter("phase",t)
		b.mist_mat.set_shader_parameter("opacity",.72 if effect.kind=="mist" else .88)
		b.flame_mat.set_shader_parameter("phase",t)
		b.flame_mat.set_shader_parameter("clock",sim.fx_clock)
		b.flame_mat.set_shader_parameter("seed",effect.get("volley",i)*3.71)
		var is_muzzle:bool=effect.kind=="muzzle"
		var is_ko:bool=effect.kind=="ko"
		var color:=Color("ffe9a9")
		if effect.weapon=="bramble":color=Color("f6cce6")
		if effect.weapon=="rail":color=Color("aefff1")
		if effect.weapon=="grenade":color=Color("ffc75d")
		if is_ko:color=Color("e5434c") if t>.16 else Color("fff3d2")
		if effect.kind=="wood":color=Color("d7b27a")
		if is_smoke:color=Color("c2bba1") if effect.weapon!="bramble" else Color("c9acc9")
		color.a=pow(1-t,2)*(.24 if is_smoke else 1.0);b.mat.albedo_color=color
		var pos:Vector2=effect.pos
		if is_smoke:pos+=effect.dir*t*.6+Vector2(0,t*.4)
		if is_mist:pos+=effect.dir*t*(.8 if effect.kind=="mist" else 1.2)+Vector2(0,t*.25)
		if (is_flame or is_soot) and not is_dust:
			var displacement:Vector2=FlameStyle.motion(effect.get("velocity",effect.dir*18),effect.age)
			var travel:float=clampf(displacement.dot(effect.dir),flame_length*.5,maxf(flame_length*.5,reach-flame_length*.5))
			# Keep the collision limit along the jet, while buoyancy bends the plume upward.
			var side:Vector2=displacement-effect.dir*displacement.dot(effect.dir)
			pos+=effect.dir*travel+side
		b.root.position=Vector3(pos.x,pos.y,1.05 if is_soot else 1.45);b.root.rotation.z=effect.dir.angle()
		if is_dust:
			b.root.position+=Vector3(effect.dir.x*effect.age*.6,effect.age*.8,0);b.root.rotation.z=0
		if is_flame:
			var tangent:Vector2=effect.get("velocity",effect.dir*18)+Vector2(0,FlameStyle.BUOYANCY*effect.age)
			b.root.rotation.z=tangent.angle()
		b.flash.visible=not is_mist and not is_flame and not is_soot and not is_smoke and (is_muzzle or t<.42)
		b.halo.visible=not is_mist and not is_flame and not is_soot and not is_smoke and not is_muzzle
		b.smoke.visible=is_smoke
		var size_value:float=(.72 if effect.weapon=="bramble" else .45) if is_muzzle else (.85 if is_ko else .36)
		b.flash.scale=Vector3(size_value*(1-t*.65),size_value*(.6 if is_muzzle else 1.0)*(1-t*.6),1)
		b.halo.scale=Vector3.ONE*size_value*(.22+t*1.15)
		b.smoke.scale=Vector3(.25+t*.65,.17+t*.4,.08)
		var cloud_size:float=(.22+t*.8)*(1.7 if effect.kind=="mist_ko" else 1.0)
		for j in range(3):b.clouds[j].scale=Vector3(cloud_size*(1+j*.15),cloud_size*.65,1)
		b.fire.scale=Vector3(flame_length*.5,(.40+t*.90)*minf(1,reach/.5),1)
		b.soot.scale=Vector3(.40+t*.95,.4+t*1.05,1)
		b.mat.blend_mode=BaseMaterial3D.BLEND_MODE_MIX
		if effect.kind=="rail":
			var length:float=effect.get("length",1.0)
			b.flash.visible=false;b.halo.visible=false;b.smoke.visible=true
			b.root.position+=Vector3(effect.dir.x,effect.dir.y,0)*length*.5
			b.smoke.scale=Vector3(length*.5,.025+.055*(1-t),.025)
			b.mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
		if effect.kind=="explosion":
			b.flash.scale=Vector3.ONE*(.7+t*2.8)
			b.halo.scale=Vector3.ONE*(.3+t*2.8)
			b.mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	for i in range(bullets.size()):
		var b:Dictionary=bullets[i];b.root.visible=i<sim.shots.size() and sim.shots[i].kind!="flame"
		if not b.root.visible:continue
		var shot:Dictionary=sim.shots[i]
		b.root.position=Vector3(shot.pos.x,shot.pos.y,.8);b.root.rotation.z=shot.vel.angle()
		b.burr.visible=shot.kind=="burr"
		if b.burr.visible:b.root.rotation.z=shot.get("age",0.0)*shot.get("spin",-11.0)
		b.grenade.visible=shot.kind=="grenade";b.fuse.visible=b.grenade.visible
		b.fuse.scale=Vector3.ONE*(.04+.025*(.5+.5*sin(sim.fx_clock*(20 if shot.life>.5 else 50))))
		b.seed.visible=shot.kind=="seed";b.bramble.visible=shot.kind=="bramble"
		b.cup.visible=shot.kind=="acorn";b.stem.visible=b.cup.visible
		b.trail.scale.x=1.4 if shot.kind=="seed" else .75
		b.trail.visible=shot.kind not in ["acorn","grenade","burr"]
