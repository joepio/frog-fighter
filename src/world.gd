extends Node3D
const ForestWeapons=preload("res://src/forest_weapons.gd")
const OrganShapes=preload("res://src/organ_shapes.gd")
const Burning=preload("res://src/burning.gd")
const FlameStyle=preload("res://src/flame_style.gd")
const CombatFX=preload("res://src/combat_fx.gd")
const ArenaScenery=preload("res://src/arena_scenery.gd")
const Scenery=preload("res://src/scenery.gd")
const Backdrop=preload("res://src/background.gd")
const EnemyVisuals=preload("res://src/enemy_visuals.gd")
const Landmarks=preload("res://src/landmarks.gd")
var combat:Node3D
var sim:RefCounted
var camera:Camera3D
var frogs:Array=[]
var shelves:Array=[]
var boxes:Array=[]
var effects:Node3D
var enemy_visuals:Node3D
var water:MeshInstance3D
var rope_nodes:Array=[]
var mats:Dictionary={}
var blood_mesh:MultiMeshInstance3D
var stain_mesh:MultiMeshInstance3D
var limb_mesh:MultiMeshInstance3D
var cut_mesh:MultiMeshInstance3D
var organ_meshes:Array=[]
var particle_mesh:MultiMeshInstance3D
var clay_normal:NoiseTexture2D
var wood_texture:Texture2D
var contact_shadows:Array=[]
var swim_rings:Array=[]
var pickup_models:Array=[]
var landmarks:Node3D

func material(color:Color,wood:bool=false)->Material:
	var key:=color.to_html()+str(wood)
	if mats.has(key):return mats[key]
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.86
	mat.metallic_specular=.28
	if clay_normal==null:
		var noise:=FastNoiseLite.new();noise.frequency=.07
		clay_normal=NoiseTexture2D.new();clay_normal.width=128;clay_normal.height=128
		clay_normal.noise=noise;clay_normal.as_normal_map=true;clay_normal.bump_strength=.4;clay_normal.seamless=true
	mat.normal_enabled=true;mat.normal_texture=clay_normal;mat.normal_scale=.15
	if wood:
		if wood_texture==null:wood_texture=load("res://art/materials/wood.png")
		mat.albedo_texture=wood_texture;mat.uv1_scale=Vector3(1,.38,1)
		mat.normal_scale=.3;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mats[key]=mat;return mat

func mesh(parent:Node3D,shape:Mesh,pos:Vector3,scale_value:Vector3,mat:Material)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=shape;node.position=pos;node.scale=scale_value
	node.material_override=mat;parent.add_child(node);return node

func ball(parent:Node3D,pos:Vector3,size_value:Vector3,color:Color)->MeshInstance3D:
	var s:=SphereMesh.new();s.radius=1;s.height=2;s.radial_segments=20;s.rings=12
	return mesh(parent,s,pos,size_value,material(color))

func block(parent:Node3D,pos:Vector3,size_value:Vector3,color:Color,wood:bool=false)->MeshInstance3D:
	var s:=BoxMesh.new();s.size=size_value
	return mesh(parent,s,pos,Vector3.ONE,material(color,wood))

func tube(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color)->MeshInstance3D:
	var s:=CylinderMesh.new();s.top_radius=radius;s.bottom_radius=radius;s.height=1;s.radial_segments=10
	var node:=mesh(parent,s,(a+b)*.5,Vector3(1,maxf(.001,a.distance_to(b)),1),material(color))
	var direction:Vector3=(b-a).normalized()
	if direction.length()>.001:
		var ref:=Vector3.RIGHT if absf(direction.dot(Vector3.UP))>.98 else Vector3.UP
		var x:=ref.cross(direction).normalized()
		node.basis=Basis(x,direction,x.cross(direction))*Basis.from_scale(Vector3(1,maxf(.001,a.distance_to(b)),1))
	return node

func build(state:RefCounted)->void:
	sim=state
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("35463b")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("e4ded3");env.environment.ambient_light_energy=.30
	env.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-28,0)
	sun.light_color=Color("fff1df");sun.light_energy=.66;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=70;sun.shadow_blur=2
	add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,145,0)
	fill.light_color=Color("c0d8d4");fill.light_energy=.20;add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=maxf(sim.ceiling+3.6,(sim.half_width*2+5)*9.0/16);camera.position=Vector3(0,sim.ceiling*.5+7.3,37)
	add_child(camera);camera.look_at(Vector3(0,sim.ceiling*.5-.3,0));camera.current=true
	var backdrop:=Backdrop.new();add_child(backdrop);backdrop.build(self)
	landmarks=Landmarks.new();add_child(landmarks);landmarks.build(self,sim.theme=="garden")
	if sim.theme!="garden":ArenaScenery.build(self)
	else:
		# The distant garden is soft; the physical rim and playfield stay sharp.
		mesh(self,Scenery.rounded_box(Vector3(30.5,.4,10),.14),Vector3(0,.05,1.3),Vector3.ONE,material(Color("615344"),true))
		Scenery.glass_rim(self)
		var water_mesh:=PlaneMesh.new();water_mesh.size=Vector2(30,10)
		var water_mat:=ShaderMaterial.new();water_mat.shader=load("res://src/pond.gdshader");water_mat.set_shader_parameter("garden",load("res://art/garden.png"))
		water=mesh(self,water_mesh,Vector3(0,sim.Terrain.WATER_LEVEL,1.1),Vector3.ONE,water_mat)
		# Handmade hanging branch across the roof.
		landmarks.branch(Vector3(-14.6,15.9,-.4),Vector3(14.0,15.8,-.4),.26)
		for s in sim.platforms:
			var shelf:=Node3D.new();add_child(shelf)
			if s.kind in ["fungus","rock","water"]:
				shelves.append(shelf)
				continue # Natural terrain is rendered by the landmarks and pond.
			if s.kind=="loose":ArenaScenery.loose_piece(self,shelf,s)
			else:Scenery.plank(self,shelf,s.width)
			if s.kind in ["lift","ferry"]:
				# Mossy end caps distinguish the travelling platforms.
				for side in [-1,1]:
					ball(shelf,Vector3(side*(s.width*.5-.12),.07,0),Vector3(.23,.28,.53),Color("839454"))
					Scenery.leaf(self,shelf,Vector3(side*s.width*.36,.1,.35),Vector3(side*(s.width*.36+.35),.65,.25),.4,Color("a5b461"))
			shelves.append(shelf)
			if s.kind=="fixed" and s.pos.y<10:
				landmarks.branch(Vector3(s.pos.x-1,s.pos.y-2,-.35),Vector3(s.pos.x+1,s.pos.y-.2,-.35),.21)
		if sim.arena_id=="terrarium":
			# Central log fulcrum and rocks.
			var pivot:=CylinderMesh.new();pivot.top_radius=.8;pivot.bottom_radius=.8;pivot.height=1.9
			var log_node:=mesh(self,pivot,Vector3(0,4.35,0),Vector3.ONE,landmarks.bark);log_node.rotation.x=PI/2
			ball(self,Vector3(0,4.35,1.0),Vector3(.65,.65,.055),Color("c39e65"))
			for radius in [.17,.29,.42,.55]:
				var ring:=TorusMesh.new();ring.inner_radius=radius-.007;ring.outer_radius=radius+.007;ring.rings=40;ring.ring_segments=6
				var circle:=mesh(self,ring,Vector3(0,4.35,1.057),Vector3.ONE,material(Color("8e6945")));circle.rotation.x=PI/2
			ball(self,Vector3(0,4.35,1.08),Vector3(.11,.11,.045),Color("72543c"))
		for hook in sim.hooks:vine_grip(hook)
		for side in [-1,1]:
			pot(Vector3(side*11.8,1.3,1.1),1.1) if sim.arena_id=="terrarium" else pot(Vector3(side*12.6,1.1,.5),.75)
			plant(Vector3(side*10,15.9,-.4),1.0,-side)
			for j in range(4):
				plant(Vector3(side*(9+j),.8+j*.2,-2.4),1.25,-side)
		for rock in sim.Terrain.rocks(sim.arena_id):landmarks.rock(rock.pos,rock.size,null,true)
		plant(Vector3(-1.7,.9,-.7),.8,-1)
		plant(Vector3(1.7,1.0,-.7),.7,1)
		for i in range(7):
			var ring:=TorusMesh.new();ring.inner_radius=.8+i*.025;ring.outer_radius=ring.inner_radius+.013;ring.rings=48;ring.ring_segments=4
			mesh(self,ring,Vector3(-11+i*3.6,.37,1.4+sin(i)*.8),Vector3(1,.20,.48),material(Color("71958c")))
		for i in range(11):
			var x:float=-12.5+i*2.4
			Scenery.lily(self,Vector3(x,.43,2.1+sin(i)*.65),.75,Color("708649") if i%2==0 else Color("8b9e53"))
			if i%3==0:flower(Vector3(x,.50,2.1+sin(i)*.65))

	Scenery.batch_static(self,[water])
	Scenery.batch_static(landmarks)
	for shelf in shelves:Scenery.batch_static(shelf)
	for p in sim.frogs:
		frogs.append(make_frog(Color(p.color)))
		var shadow_mat:=StandardMaterial3D.new();shadow_mat.albedo_color=Color(.08,.10,.06,.3);shadow_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var shadow:=ball(self,Vector3.ZERO,Vector3(.53*sim.FROG_SCALE,.012,.36*sim.FROG_SCALE),Color.WHITE);shadow.material_override=shadow_mat
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;contact_shadows.append(shadow)
		var ripple_shape:=TorusMesh.new();ripple_shape.inner_radius=.43;ripple_shape.outer_radius=.45;ripple_shape.rings=32;ripple_shape.ring_segments=4
		var ripple_mat:=StandardMaterial3D.new();ripple_mat.albedo_color=Color(.66,.85,.74,.6);ripple_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		var ripple:=mesh(self,ripple_shape,Vector3.ZERO,Vector3.ONE,ripple_mat);ripple.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;swim_rings.append(ripple)
	for box in sim.crates:
		var n:=Node3D.new();add_child(n)
		mesh(n,Scenery.rounded_box(Vector3(1.1,1.1,1.1),.055),Vector3.ZERO,Vector3.ONE,material(Color("e7d5b6"),true))
		var brace:=block(n,Vector3(0,0,.565),Vector3(.14,1.25,.07),Color("ede1cc"),true);brace.rotation.z=-.7
		for y in [-.46,.46]:block(n,Vector3(0,y,.57),Vector3(1,.1,.08),Color("d7c4a5"),true)
		boxes.append(n)
	enemy_visuals=EnemyVisuals.new();add_child(enemy_visuals);enemy_visuals.build(self)
	effects=Node3D.new();add_child(effects)

	for i in range(12):
		var root:=Node3D.new();add_child(root);root.scale=Vector3.ONE*.78*sim.FROG_SCALE*sim.WEAPON_SCALE
		pickup_models.append({"root":root,"models":ForestWeapons.build(self,root)})
	combat=CombatFX.new();add_child(combat);combat.build(self)
	blood_mesh=make_droplets(260,Color("c82337"))
	stain_mesh=make_droplets(150,Color("991e30"))
	limb_mesh=make_droplets(260,Color.WHITE,true)
	cut_mesh=make_droplets(260,Color("d94052"))
	for kind in range(3):
		var organ:=make_droplets(260,Color(["c94760","873e60","cb788f"][kind]))
		organ.multimesh.mesh=OrganShapes.make(kind)
		organ.material_override.roughness=.48;organ.material_override.metallic_specular=.4
		organ_meshes.append(organ)
	particle_mesh=make_droplets(180,Color.WHITE,true)
	update()

func vine_grip(hook:Vector2)->void:
	var tip:=Vector3(hook.x,hook.y,.05)
	var top:=Vector3(hook.x+.35*sin(hook.x),sim.ceiling-.2,-.25)
	if not sim.roof:
		var best:=INF
		for shelf in sim.platforms:
			if shelf.kind!="fixed" or shelf.pos.y<hook.y+.4:continue
			var distance:float=shelf.pos.distance_to(hook)
			if distance<best:best=distance;top=Vector3(shelf.pos.x,shelf.pos.y,-.25)
	var last:Vector3=top
	for i in range(1,13):
		var t:float=i/12.0
		var point:Vector3=top.lerp(tip,t)+Vector3(sin(t*PI)*.32,0,sin(t*TAU)*.08)
		tube(self,last,point,.045,Color("647841"));last=point
	# A chunky curled stem is the exact tongue attachment point.
	var curl:=TorusMesh.new();curl.inner_radius=.17;curl.outer_radius=.30;curl.rings=20;curl.ring_segments=8
	var ring:=mesh(self,curl,tip,Vector3.ONE,material(Color("bad17b")))
	ring.rotation.x=PI/2
	ball(self,tip,Vector3(.17,.19,.16),Color("708e45"))
	for side in [-1,1]:
		Scenery.leaf(self,self,tip+Vector3(side*.1,.17,0),tip+Vector3(side*.55,.52,-.04),.32,Color("a8bd62"))

func make_droplets(count:int,color:Color,colored:bool=false)->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new();var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	var shape:=SphereMesh.new();shape.radius=1;shape.height=2;shape.radial_segments=8;shape.rings=4
	mm.mesh=shape;mm.use_colors=colored;mm.instance_count=count;mm.visible_instance_count=0;node.multimesh=mm
	var mat:StandardMaterial3D=material(color).duplicate();mat.vertex_color_use_as_albedo=colored
	node.material_override=mat;add_child(node);return node

func plant(pos:Vector3,size_value:float,side:int)->void:
	for i in range(7):
		var angle:float=-1.15+i*.35
		var tip:Vector3=pos+Vector3(sin(angle)*size_value*1.2+side*.3,cos(angle)*size_value*1.6,.15+sin(i*2.4)*.3)
		var base:Vector3=pos.lerp(tip,.23)
		tube(self,pos,base,.024,Color("61703b"))
		Scenery.leaf(self,self,base,tip,size_value*.72,Color("577533") if i%2==0 else Color("7e9346"))

func pot(pos:Vector3,radius:float)->void:
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius*.65;shape.height=radius*1.5;shape.radial_segments=24
	mesh(self,shape,pos,Vector3.ONE,material(Color("bc7958")))
	var ring:=TorusMesh.new();ring.inner_radius=radius*.8;ring.outer_radius=radius*1.12;ring.rings=24;ring.ring_segments=10
	mesh(self,ring,pos+Vector3(0,radius*.75,0),Vector3.ONE,material(Color("d08a60")))
	ball(self,pos+Vector3(0,radius*.72,0),Vector3(radius*.88,.08,radius*.88),Color("504735"))
	plant(pos+Vector3(0,radius*.85,0),radius,1)

func flower(pos:Vector3)->void:
	for layer in range(2):
		for i in range(7):
			var a:float=i*TAU/7+layer*.45
			var petal:=ball(self,pos+Vector3(cos(a)*(.22-layer*.09),layer*.09,sin(a)*(.22-layer*.09)),Vector3(.25-layer*.065,.055,.105),Color("eadfd0"))
			petal.rotation=Vector3(0,-a,.24+layer*.2)
	ball(self,pos+Vector3(0,.17,0),Vector3(.1,.065,.1),Color("d8ad53"))

func make_frog(color:Color)->Dictionary:
	var root:=Node3D.new();add_child(root);root.scale=Vector3.ONE*sim.FROG_SCALE
	var body:=Node3D.new();root.add_child(body)
	ball(body,Vector3(0,-.04,0),Vector3(.52,.55,.39),color)
	ball(body,Vector3(0,-.12,.28),Vector3(.35,.38,.13),color.lerp(Color("e8d9a7"),.48))
	ball(body,Vector3(0,.27,.015),Vector3(.55,.3,.34),color)
	var pupils:Array=[];var eyewhites:Array=[];var lids:Array=[];var brows:Array=[]
	for side in [-1,1]:
		ball(body,Vector3(side*.28,.54,.12),Vector3(.2,.24,.2),color)
		eyewhites.append(ball(body,Vector3(side*.28,.56,.245),Vector3(.16,.18,.1),Color("fff2d6")))
		var lid:=Node3D.new();body.add_child(lid);lid.position=Vector3(side*.28,.56,.31);lid.visible=false
		ball(lid,Vector3.ZERO,Vector3(.17,.085,.085),color)
		tube(lid,Vector3(-.12,0,.074),Vector3(.12,0,.074),.012,color.darkened(.4));lids.append(lid)
		var pupil:=Node3D.new();body.add_child(pupil);pupil.position=Vector3(side*.28,.55,.335)
		ball(pupil,Vector3(.04,0,0),Vector3(.076,.11,.035),Color("29342c"))
		pupils.append(pupil)
		var brow:=Node3D.new();body.add_child(brow);brow.position=Vector3(side*.28,.65,.33);brow.visible=false
		ball(brow,Vector3.ZERO,Vector3(.18,.065,.06),color)
		brows.append(brow)
		ball(pupil,Vector3(.055,.05,.025),Vector3(.021,.025,.012),Color.WHITE)
		ball(body,Vector3(side*.38,.20,.29),Vector3(.13,.055,.09),color.lightened(.12))
		ball(body,Vector3(side*.12,.32,.342),Vector3(.023,.015,.014),color.darkened(.4))
	# One smooth line fitted to the cheek surface, without dotted beads or buried sections.
	var smile:=SurfaceTool.new();smile.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(24):
		for corner in [Vector2(0,-1),Vector2(1,-1),Vector2(1,1),Vector2(0,-1),Vector2(1,1),Vector2(0,1)]:
			var x:float=-.31+(i+corner.x)*.62/24
			var y:float=.135+.065*pow(x/.31,2)+corner.y*.009
			var head_z:float=.015+.34*sqrt(maxf(0,1-pow(x/.55,2)-pow((y-.27)/.3,2)))
			var torso_z:float=.39*sqrt(maxf(0,1-pow(x/.52,2)-pow((y+.04)/.55,2)))
			smile.add_vertex(Vector3(x,y,maxf(head_z,torso_z)+.01))
	smile.generate_normals()
	var mouth_material:=StandardMaterial3D.new();mouth_material.albedo_color=color.darkened(.55);mouth_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var closed_mouth:=mesh(body,smile.commit(),Vector3.ZERO,Vector3.ONE,mouth_material)
	var open_mouth:=Node3D.new();body.add_child(open_mouth);open_mouth.position=Vector3(0,.15,.39);open_mouth.visible=false
	ball(open_mouth,Vector3.ZERO,Vector3(.22,.15,.04),color.darkened(.25))
	ball(open_mouth,Vector3(0,0,.035),Vector3(.18,.115,.022),Color("39232c"))
	ball(open_mouth,Vector3(0,-.055,.058),Vector3(.10,.043,.012),Color("ed9da1"))
	var limbs:Array=[];var feet:Array=[]
	for side in [-1,1]:
		var leg:=Node3D.new();body.add_child(leg);leg.position=Vector3(side*.36,-.33,0)
		ball(leg,Vector3(side*.12,-.07,0),Vector3(.26,.21,.25),color)
		tube(leg,Vector3(side*.15,-.06,.03),Vector3(side*.23,-.24,.1),.085,color)
		var foot:=Node3D.new();leg.add_child(foot);feet.append(foot)
		ball(foot,Vector3(side*.23,-.22,.1),Vector3(.24,.09,.2),color)
		for digit in range(3):ball(foot,Vector3(side*(.15+digit*.1),-.24,.23),Vector3(.07,.065,.13),color)
		limbs.append(leg)
	var offhand:=Node3D.new();body.add_child(offhand);offhand.position=Vector3(-.38,.04,.13)
	tube(offhand,Vector3.ZERO,Vector3(-.2,-.22,.08),.09,color)
	ball(offhand,Vector3(-.23,-.25,.12),Vector3(.13,.1,.13),color)
	for i in range(3):ball(offhand,Vector3(-.36+i*.07,-.29,.17),Vector3(.055,.09,.06),color)
	for i in range(9):
		var a:float=i*2.4
		ball(body,Vector3(sin(a)*.43,-.13+cos(a)*.25,.28),Vector3(.028,.022,.016),color.darkened(.1))
	var arm:=Node3D.new();body.add_child(arm)
	ball(arm,Vector3(.52,0,.07),Vector3(.27,.12,.14),color)
	ball(arm,Vector3(.7,0,.07),Vector3(.13,.15,.15),color)
	var gun:=Node3D.new();arm.add_child(gun);gun.position=Vector3(.83,0,.08)
	var models:Array=ForestWeapons.build(self,gun)
	var fire_light:=OmniLight3D.new();gun.add_child(fire_light);fire_light.position=Vector3(.72,0,.2)
	fire_light.light_color=FlameStyle.color(.65);fire_light.omni_range=3;fire_light.light_energy=.9;fire_light.visible=false
	var flash:=ShaderMaterial.new();flash.shader=load("res://src/hit_flash.gdshader")
	var skin_meshes:Array=[]
	collect_skin(body,skin_meshes,gun)
	var wounds:Array=[]
	for i in range(6):
		var wound:=Node3D.new();body.add_child(wound);wound.visible=false
		ball(wound,Vector3.ZERO,Vector3(1,.70,.12),Color("872838"))
		ball(wound,Vector3(.10,-.20,.08),Vector3(.48,.44,.10),Color("b63845"))
		ball(wound,Vector3(.12,-.88,0),Vector3(.15,.62,.075),Color("a12c39"))
		wounds.append(wound)
	var tongue:=Node3D.new();root.add_child(tongue)
	var burning:=Burning.new();root.add_child(burning);burning.build(self)
	return {"root":root,"body":body,"closed_mouth":closed_mouth,"open_mouth":open_mouth,"brows":brows,"flash":flash,"skin_meshes":skin_meshes,"flashing":false,"pupils":pupils,"offhand":offhand,"limbs":limbs,"feet":feet,"arm":arm,"gun":gun,"tongue":tongue,"color":color,"muzzles":models,"wounds":wounds,"eyewhites":eyewhites,"lids":lids,"fire_light":fire_light,"burning":burning}

func collect_skin(node:Node3D,out:Array,gun:Node3D)->void:
	if node==gun:return
	if node is MeshInstance3D:out.append(node)
	for child in node.get_children():
		if child is Node3D:collect_skin(child,out,gun)

func update()->void:
	landmarks.update(sim.clock)
	if water!=null:water.material_override.set_shader_parameter("flow_time",sim.clock)
	camera.h_offset=sin(sim.fx_clock*63)*sim.trauma*sim.trauma*.16
	camera.v_offset=cos(sim.fx_clock*71)*sim.trauma*sim.trauma*.11
	for i in range(shelves.size()):
		var s:Dictionary=sim.platforms[i];shelves[i].position=Vector3(s.pos.x,s.pos.y,0);shelves[i].rotation.z=s.angle
		shelves[i].visible=sim.usable(s)
		if s.get("max_hp",0)>0:preload("res://src/destruction_visuals.gd").update(shelves[i],s,sim.clock)
		if s.get("rubble",false):shelves[i].scale=Vector3(s.width,s.height/.4,1)*minf(1,maxf(.01,s.debris_life/.35))
		if s.kind=="crumble" and s.stress>0 and not s.falling:shelves[i].rotation.z+=sin(sim.clock*55)*.025*minf(s.stress*2,1)
	for rope in rope_nodes:rope.free()
	rope_nodes.clear()
	for s in sim.platforms:
		if s.kind=="swing":
			for rope in s.ropes:
				var bottom:Vector2=s.pos+rope.local.rotated(s.angle)
				var top:Vector2=rope.anchor
				var sag:float=maxf(0,rope.length-top.distance_to(bottom))*.55
				var middle:Vector2=(top+bottom)*.5+Vector2(0,-sag)
				rope_nodes.append(tube(self,Vector3(top.x,top.y,-.45),Vector3(middle.x,middle.y,-.45),.043,Color("b3a17c")))
				rope_nodes.append(tube(self,Vector3(middle.x,middle.y,-.45),Vector3(bottom.x,bottom.y,-.45),.043,Color("b3a17c")))
		elif s.kind in ["ferry","lift"]:
			for side in [-1,1]:
				var bottom:Vector2=s.pos+Vector2(side*s.width*.38,0).rotated(s.angle)
				rope_nodes.append(tube(self,Vector3(s.base.x+side*s.width*.38,sim.ceiling-.2,-.45),Vector3(bottom.x,bottom.y,-.45),.043,Color("b3a17c")))
	for i in range(frogs.size()):
		var p:Dictionary=sim.frogs[i];var f:Dictionary=frogs[i]
		f.root.visible=p.alive and p.respawn<=0
		f.root.position=Vector3(p.pos.x,p.pos.y,.35)
		f.burning.update(p,sim.fx_clock)
		swim_rings[i].visible=f.root.visible and p.in_water
		swim_rings[i].position=Vector3(p.pos.x,sim.Terrain.WATER_LEVEL+.025,.35)
		swim_rings[i].scale=Vector3(1,.25,.7)*(1+fposmod(sim.fx_clock*1.5+p.slot*.25,1)*.6)
		contact_shadows[i].visible=f.root.visible and p.ground>=0 and not p.in_water
		if p.ground>=0:
			var platform:Dictionary=sim.platforms[p.ground]
			contact_shadows[i].position=Vector3(p.pos.x,platform.pos.y+sin(platform.angle)*(p.pos.x-platform.pos.x)+.215,.35)
			contact_shadows[i].rotation.z=platform.angle
			if platform.kind=="loose":contact_shadows[i].position.y=p.pos.y-sim.RADIUS+.012
		var stretch:float=clampf(p.vel.y*.014,-.15,.18)
		var recovery:float={"rail":6.0,"grenade":8.0,"bramble":9.0,"seed":18.0}.get(p.last_weapon,12.0)
		var recoil:float=(1-exp(-p.shot_age*180))*exp(-p.shot_age*recovery) if p.shot_age<.45 else 0.0
		var weight:float=2.2 if p.last_weapon=="rail" else 1.35 if p.last_weapon in ["bramble","grenade"] else (.65 if p.last_weapon=="seed" else 1.0)
		if p.last_weapon=="flame":weight=.20
		if p.last_weapon=="burr":weight=0.0
		f.fire_light.visible=p.last_weapon=="flame" and p.shot_age<.11
		f.fire_light.light_energy=.8+sin(sim.fx_clock*38)*.18
		var hit:float=clampf(p.flash/.19,0,1)
		f.body.scale=Vector3((1-stretch*.6)*(1+hit*.22),(1+stretch)*(1-hit*.18),1)
		var walk:float=p.walk if p.ground>=0 else 0.0
		var bob:float=absf(sin(p.stride))*.065*walk
		f.body.position=Vector3(-p.aim.x*recoil*.10*weight,bob,0)
		f.body.rotation.z=clampf(-p.vel.x*.017,-.2,.2) if not p.stuck else signf(p.pos.x)*PI*.5
		f.body.rotation.z+=-p.hit_dir.x*hit*.28
		f.body.rotation.y=p.aim.x*.22+sin(sim.clock*2+p.slot)*.035
		for pupil in f.pupils:pupil.position.z=.335;pupil.rotation.y=p.aim.x*.14
		f.offhand.rotation.z=sin(p.stride)*.38*walk+sin(sim.clock*5+p.slot)*.06 if p.ground>=0 else -.8-p.vel.y*.025
		for j in range(2):
			var side:float=-1 if j==0 else 1
			var phase:float=p.stride+j*PI
			var lift:float=maxf(0,sin(phase))*walk
			var swing:float=cos(phase)*walk*signf(p.vel.x)
			f.limbs[j].position=Vector3(side*.36+swing*.16,-.33+lift*.14-bob,0)
			f.limbs[j].rotation.z=swing*.18 if p.ground>=0 else side*clampf(p.vel.y*.045,-.55,.55)
			f.limbs[j].scale.y=1.0 if p.ground>=0 else (.80 if p.vel.y>0 else 1.12)
			f.feet[j].position=Vector3(swing*.12,lift*.15,lift*.06)
			f.feet[j].rotation.z=-swing*.27
		f.arm.rotation.z=p.aim.angle()-f.body.rotation.z-p.facing*recoil*.22*weight
		f.gun.position.x=.83-recoil*.22*weight
		f.gun.scale=Vector3(1-recoil*.18*weight,1+recoil*.12*weight,1)*sim.WEAPON_SCALE
		f.offhand.rotation.z+=recoil*.45*weight
		f.gun.visible=not p.weapon.is_empty() or p.shot_age<.28
		var displayed_weapon:String=p.weapon if not p.weapon.is_empty() else p.last_weapon
		if not p.pending_burr.is_empty():displayed_weapon="burr"
		for j in range(sim.WEAPON_ORDER.size()):f.muzzles[j].visible=displayed_weapon==sim.WEAPON_ORDER[j]
		if displayed_weapon=="burr":
			f.gun.position.x=.69
			if not p.pending_burr.is_empty():
				var windup:float=1.0-p.pending_burr.delay/.16
				f.arm.rotation.z+=p.facing*(.55+sin(windup*PI)*1.15)
				f.gun.visible=true
			elif p.last_weapon=="burr" and p.shot_age<.32:
				f.arm.rotation.z-=p.facing*.75*sin(p.shot_age/.32*PI)
				f.gun.visible=false # The pod has left the hand; recover before showing the next one.

		# Keep the silhouette readable throughout hits and spawn protection.
		# Eye squeeze, color flash and squash convey damage without hiding the frog.
		f.body.visible=true
		var speaking:bool=p.tongue_active or not p.anchor.is_empty()
		var angry:bool=p.trigger_held or p.shot_age<.18
		f.closed_mouth.visible=not speaking;f.open_mouth.visible=speaking
		for j in range(2):
			var side:float=-1 if j==0 else 1
			f.brows[j].visible=angry and p.flash<=.105
			f.brows[j].rotation.z=side*.30
			f.eyewhites[j].scale.y=.18*(.82 if angry else 1.0)
			f.pupils[j].scale.y=.85 if angry else 1.0
		for j in range(2):
			f.lids[j].visible=p.flash>.105;f.eyewhites[j].visible=p.flash<=.105;f.pupils[j].visible=p.flash<=.105
		for j in range(6):
			f.wounds[j].visible=j<p.wounds.size()
			if j>=p.wounds.size():continue
			var wound:Dictionary=p.wounds[j];var point:Vector2=wound.offset
			# Project the mark onto the front of the rounded clay torso.
			var z:float=.30*sqrt(maxf(.14,1-pow(point.x/.56,2)-pow((point.y+.03)/.66,2)))+.095
			f.wounds[j].position=Vector3(point.x,point.y,z);f.wounds[j].scale=Vector3.ONE*wound.size
		var flashing:bool=p.flash>.12
		if flashing!=f.flashing:
			for skin in f.skin_meshes:skin.material_overlay=f.flash if flashing else null
			f.flashing=flashing
		f.flash.set_shader_parameter("strength",clampf((p.flash-.12)/.04,0,.88))
		for child in f.tongue.get_children():child.free()
		if not p.anchor.is_empty():
			var point:Vector2=(sim.anchor_point(p.anchor)-p.pos)/sim.FROG_SCALE
			tube(f.tongue,f.body.transform*Vector3(0,.15,.46),Vector3(point.x,point.y,.2),.055,Color("ed9da1"))
			ball(f.tongue,Vector3(point.x,point.y,.2),Vector3(.13,.08,.13),Color("e88e99"))
	for i in range(boxes.size()):
		boxes[i].position=Vector3(sim.crates[i].pos.x,sim.crates[i].pos.y,.15)
		boxes[i].rotation.z=sim.crates[i].angle
	for i in range(pickup_models.size()):
		var visual:Dictionary=pickup_models[i];visual.root.visible=i<sim.pickups.size()
		if not visual.root.visible:continue
		var item:Dictionary=sim.pickups[i]
		visual.root.position=Vector3(item.pos.x,item.pos.y+.12+sin(sim.clock*3+item.age)*.12,.6)
		visual.root.rotation.z=item.get("angle",0.0)
		for j in range(sim.WEAPON_ORDER.size()):visual.models[j].visible=item.kind==sim.WEAPON_ORDER[j]

	enemy_visuals.update(sim)
	particle_mesh.multimesh.visible_instance_count=mini(sim.particles.size(),180)
	for i in range(mini(sim.particles.size(),180)):
		var bramble:Dictionary=sim.particles[i]
		particle_mesh.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.065),Vector3(bramble.pos.x,bramble.pos.y,.9)))
		particle_mesh.multimesh.set_instance_color(i,bramble.color)
	var chunk_index:=0
	var organ_counts:Array[int]=[0,0,0]
	blood_mesh.multimesh.visible_instance_count=mini(sim.gore.size(),260)
	for i in range(mini(sim.gore.size(),260)):
		var part:Dictionary=sim.gore[i]
		var pos:=Vector3(part.pos.x,part.pos.y,.5+sin(i)*.28)
		blood_mesh.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.BACK,part.vel.angle()-PI*.5).scaled(Vector3(part.radius,part.radius*(1+minf(part.vel.length()*.08,1.4)),part.radius)),pos))
		if part.chunk:
			blood_mesh.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),pos))
			if part.has("organ"):
				var kind:int=part.organ
				var squash:float=part.get("bounce_squash",0.0)
				var wobble:float=sin(sim.clock*12+i)*.045
				var size_value:Vector3=Vector3(1+squash*.3+wobble,1-squash*.3-wobble,1)*part.radius
				var rotation_basis:=Basis.from_euler(Vector3(part.angle*.55,part.angle*.32,part.angle))
				organ_meshes[kind].multimesh.set_instance_transform(organ_counts[kind],Transform3D(rotation_basis*Basis.from_scale(size_value),pos+Vector3(0,0,.15)))
				organ_counts[kind]+=1
				continue
			var basis:=Basis(Vector3.BACK,part.angle)
			limb_mesh.multimesh.set_instance_transform(chunk_index,Transform3D(basis*Basis.from_scale(Vector3(part.radius,part.radius*1.9,part.radius)),pos))
			limb_mesh.multimesh.set_instance_color(chunk_index,part.skin)
			var cut:Vector3=pos+Vector3(-sin(part.angle),cos(part.angle),.2)*part.radius*1.4
			cut_mesh.multimesh.set_instance_transform(chunk_index,Transform3D(basis*Basis.from_scale(Vector3(part.radius*.83,part.radius*.4,part.radius*.84)),cut))
			chunk_index+=1
	limb_mesh.multimesh.visible_instance_count=chunk_index;cut_mesh.multimesh.visible_instance_count=chunk_index
	for kind in range(3):organ_meshes[kind].multimesh.visible_instance_count=organ_counts[kind]
	stain_mesh.multimesh.visible_instance_count=mini(sim.stains.size(),150)
	for i in range(mini(sim.stains.size(),150)):
		var stain:Dictionary=sim.stains[i];var p:=Vector2(stain.offset,.48);var angle:=0.0
		if stain.platform>=0:
			var shelf:Dictionary=sim.platforms[stain.platform]
			p=shelf.pos+Vector2(stain.offset,.22).rotated(shelf.angle);angle=shelf.angle
		stain_mesh.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.BACK,angle).scaled(Vector3(stain.size,.025,stain.size*.7)),Vector3(p.x,p.y,.7)))

	combat.update(sim)

func screen_point(p:Vector2)->Vector2:
	return camera.unproject_position(Vector3(p.x,p.y,.35))
