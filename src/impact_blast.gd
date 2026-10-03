extends Node3D
const FlameStyle=preload("res://src/flame_style.gd")
## Four reusable layered bursts. Visual time continues through the impact pause.
var pool:Array=[]
func build(host:Node3D)->void:
	var quad:=QuadMesh.new();quad.size=Vector2(2,2)
	var chip:=PrismMesh.new();chip.size=Vector3(.16,.10,.06)
	var spark_shape:=QuadMesh.new();spark_shape.size=Vector2(2,2)
	for i in range(4):
		var root:=Node3D.new();add_child(root)
		var fires:Array=[];var smoke:Array=[];var sparks:Array=[];var chips:Array=[];var spark_mats:Array=[];var chip_mats:Array=[]
		for j in range(6):
			var mat:=ShaderMaterial.new();mat.shader=preload("res://src/blast_fire.gdshader");mat.set_shader_parameter("heat_ramp",FlameStyle.heat_ramp())
			var node:MeshInstance3D=host.mesh(root,quad,Vector3.ZERO,Vector3.ONE,mat);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fires.append({"node":node,"mat":mat})
			var soot:=ShaderMaterial.new();soot.shader=preload("res://src/blast_smoke.gdshader")
			var cloud:MeshInstance3D=host.mesh(root,quad,Vector3.ZERO,Vector3.ONE,soot);cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			smoke.append({"node":cloud,"mat":soot})
		var ring_mat:=ShaderMaterial.new();ring_mat.shader=preload("res://src/blast_fire.gdshader");ring_mat.set_shader_parameter("shockwave",true)
		var ring:MeshInstance3D=host.mesh(root,quad,Vector3(0,0,1.25),Vector3(5,5,1),ring_mat);ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var chip_mat:=StandardMaterial3D.new();chip_mat.albedo_color=Color("92713b");chip_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		for j in range(24):
			var spark_mat:=ShaderMaterial.new();spark_mat.shader=preload("res://src/blast_spark.gdshader");spark_mats.append(spark_mat)
			var spark:MeshInstance3D=host.mesh(root,spark_shape,Vector3.ZERO,Vector3.ONE,spark_mat);spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;sparks.append(spark)
		for j in range(10):
			var material:StandardMaterial3D=chip_mat.duplicate();chip_mats.append(material)
			var fragment:MeshInstance3D=host.mesh(root,chip,Vector3.ZERO,Vector3.ONE,material);fragment.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;chips.append(fragment)
		var light:=OmniLight3D.new();root.add_child(light);light.position=Vector3(0,0,2);light.omni_range=12;light.light_color=Color("ffab50")
		root.visible=false
		pool.append({"root":root,"fires":fires,"smoke":smoke,"sparks":sparks,"chips":chips,"ring":ring,"ring_mat":ring_mat,"spark_mats":spark_mats,"chip_mats":chip_mats,"light":light,"key":-1,"spark_data":[],"chip_data":[],"plume_data":[]})
func seed_burst(b:Dictionary,key:int)->void:
	# Separate cosmetic randomness: replayable per explosion, without touching gameplay RNG.
	var random:=RandomNumberGenerator.new();random.seed=key
	b.key=key;b.spark_data.clear();b.chip_data.clear();b.plume_data.clear()
	var fans:Array=[]
	for i in range(4):fans.append(random.randf_range(0,TAU))
	for i in range(b.sparks.size()):
		var angle:float=fans[random.randi_range(0,3)]+random.randf_range(-.48,.48)
		var direction:=Vector2(cos(angle),sin(angle))
		b.spark_data.append({"velocity":direction*lerpf(1.5,14,pow(random.randf(),1.5))+Vector2(0,random.randf_range(.3,2.5)),
			"origin":direction*random.randf_range(.03,.45),"delay":random.randf_range(0,.07),"life":random.randf_range(.20,.85),
			"drag":random.randf_range(.8,3.2),"gravity":random.randf_range(2,10),"width":random.randf_range(.010,.028),
			"length":random.randf_range(.025,.095),"brightness":random.randf_range(.45,1.0),"z":random.randf_range(1.35,1.8),
			"curl":random.randf_range(-.22,.22),"phase":random.randf_range(0,TAU)})
	for i in range(b.chips.size()):
		var angle:float=random.randf_range(0,TAU)
		var scale_value:float=random.randf_range(.45,1.6)
		b.chip_data.append({"velocity":Vector2(cos(angle),sin(angle))*random.randf_range(.8,8.5)+Vector2(0,random.randf_range(1,4)),
			"origin":Vector2(random.randf_range(-.25,.25),random.randf_range(-.15,.25)),
			"delay":random.randf_range(0,.06),"life":random.randf_range(.5,1.5),"drag":random.randf_range(.25,1.2),
			"gravity":random.randf_range(9,20),"z":random.randf_range(.9,1.65),
			"scale":Vector3(scale_value,scale_value*random.randf_range(.45,1.1),scale_value),
			"spin":Vector3(random.randf_range(-13,13),random.randf_range(-13,13),random.randf_range(-15,15)),
			"rotation":Vector3(random.randf_range(0,TAU),random.randf_range(0,TAU),random.randf_range(0,TAU)),
			"color":Color("8d6938").lightened(random.randf_range(-.22,.22))})
	for i in range(b.fires.size()):
		var angle:float=random.randf_range(0,TAU)
		b.plume_data.append({"radial":Vector2(cos(angle),sin(angle)),"reach":random.randf_range(.65,1.85),
			"scale":random.randf_range(.75,1.25),"loft":random.randf_range(1.3,2.5),"seed":random.randf_range(0,200)})

func update(sim:RefCounted)->void:
	var effects:Array=sim.fx.filter(func(e):return e.kind=="impact_blast")
	for i in range(pool.size()):
		var b:Dictionary=pool[i];b.root.visible=i<effects.size()
		if not b.root.visible:continue
		var e:Dictionary=effects[effects.size()-1-i];var age:float=e.age
		var key:int=hash([e.get("seed",0),e.pos])
		if b.key!=key:seed_burst(b,key)
		b.root.position=Vector3(e.pos.x,e.pos.y,0)
		b.ring.visible=age<.28;b.ring_mat.set_shader_parameter("age",age);b.ring_mat.set_shader_parameter("seed",b.plume_data[0].seed)
		b.light.visible=age<.42;b.light.light_energy=5.5*pow(maxf(0,1-age/.42),2)
		for j in range(6):
			var plume:Dictionary=b.plume_data[j];var radial:Vector2=plume.radial
			var distance:float=0 if j==0 else (1-exp(-age*14))*plume.reach
			var offset:Vector2=radial*distance+Vector2(0,age*1.25)
			var f:Dictionary=b.fires[j];f.node.visible=age<.66
			f.node.position=Vector3(offset.x,offset.y,1.45+j*.01)
			var size_value:float=(.25+(1-exp(-age*24))*3.2) if j==0 else (.15+(1-exp(-age*13))*1.6)
			f.node.scale=Vector3(size_value*plume.scale,size_value,1);f.mat.set_shader_parameter("age",age);f.mat.set_shader_parameter("seed",plume.seed)
			var cloud:Dictionary=b.smoke[j]
			cloud.node.position=Vector3(radial.x*(.3+age*.85),radial.y*(.25+age*.5)+age*plume.loft,.80+j*.012)
			cloud.node.scale=Vector3.ONE*(.5+sqrt(age)*1.6)*plume.scale
			cloud.mat.set_shader_parameter("age",age);cloud.mat.set_shader_parameter("seed",plume.seed)
		for j in range(b.sparks.size()):
			var data:Dictionary=b.spark_data[j];var t:float=age-data.delay
			var spark:MeshInstance3D=b.sparks[j];spark.visible=t>=0 and t<data.life
			if not spark.visible:continue
			var damping:float=exp(-data.drag*t)
			var perpendicular:=Vector2(-data.velocity.y,data.velocity.x).normalized()
			var curl:Vector2=perpendicular*(sin(t*9+data.phase)-sin(data.phase))*data.curl*t
			var pos:Vector2=data.origin+data.velocity*(1-damping)/data.drag+Vector2(0,-.5*data.gravity*t*t)+curl
			var velocity:Vector2=data.velocity*damping+Vector2(0,-data.gravity*t)
			var life:float=t/data.life
			spark.position=Vector3(pos.x,pos.y,data.z);spark.rotation.z=velocity.angle()
			spark.scale=Vector3(data.length+velocity.length()*.004,data.width,1)
			b.spark_mats[j].set_shader_parameter("opacity",data.brightness*pow(1-life,1.6))
			b.spark_mats[j].set_shader_parameter("heat",1-smoothstep(.03,.65,life))
		for j in range(b.chips.size()):
			var data:Dictionary=b.chip_data[j];var t:float=age-data.delay
			var fragment:MeshInstance3D=b.chips[j];fragment.visible=t>=0 and t<data.life
			if not fragment.visible:continue
			var pos:Vector2=data.origin+data.velocity*(1-exp(-data.drag*t))/data.drag+Vector2(0,-.5*data.gravity*t*t)
			fragment.position=Vector3(pos.x,pos.y,data.z);fragment.rotation=data.rotation+data.spin*t;fragment.scale=data.scale
			var color:Color=data.color;color.a=1-smoothstep(.60,1,t/data.life);b.chip_mats[j].albedo_color=color
