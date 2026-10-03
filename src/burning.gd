extends Node3D
const FlameStyle=preload("res://src/flame_style.gd")
## Fixed per-frog flame, smoke and ember pools. Animation follows the simulation clock.
var tongues:Array=[]
var smoke:Array=[]
var embers:Array=[]
var smoke_material:ShaderMaterial
var light:OmniLight3D

func build(world:Node3D)->void:
	var quad:=QuadMesh.new();quad.size=Vector2.ONE
	smoke_material=FlameStyle.material(true)
	# Back flames outline the head; front flames hug the feet and sides, leaving the eyes readable.
	var anchors:=[Vector3(-.38,-.36,.42),Vector3(.40,-.34,.40),Vector3(-.44,.02,.22),Vector3(.46,.05,.20),Vector3(-.27,.30,-.28),Vector3(.26,.32,-.28),Vector3(.02,-.36,.49)]
	for i in range(anchors.size()):
		var mat:=FlameStyle.material();mat.set_shader_parameter("seed",i*3.71)
		var node:MeshInstance3D=world.mesh(self,quad,anchors[i],Vector3.ONE,mat)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tongues.append({"node":node,"anchor":anchors[i],"mat":mat})
	for i in range(3):
		var mat:ShaderMaterial=smoke_material.duplicate();mat.set_shader_parameter("seed",i*4.1)
		var node:MeshInstance3D=world.mesh(self,quad,Vector3.ZERO,Vector3.ONE,mat)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;smoke.append(node)
	var ember_mat:=StandardMaterial3D.new();ember_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.albedo_color=FlameStyle.color(.85)
	for i in range(12):
		var node:MeshInstance3D=world.mesh(self,quad,Vector3.ZERO,Vector3(.035,.08,1),ember_mat)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;embers.append(node)
	light=OmniLight3D.new();add_child(light);light.position=Vector3(0,.15,1)
	light.light_color=FlameStyle.color(.65);light.omni_range=2.8;light.shadow_enabled=false
	visible=false

func update(p:Dictionary,time:float)->void:
	visible=p.burn>0 and p.alive and p.respawn<=0
	if not visible:return
	var strength:float=clampf(p.burn/.55,0,1)
	smoke_material.set_shader_parameter("clock",time)
	smoke_material.set_shader_parameter("strength",strength)
	light.light_energy=strength*(.80+sin(time*31)*.12)
	for i in range(tongues.size()):
		var item:Dictionary=tongues[i]
		var age:float=fposmod(time*1.7+i*.143,1)
		var lift:Vector2=FlameStyle.motion(Vector2(-p.vel.x*.10,1.1),age*.30)
		item.mat.set_shader_parameter("clock",time);item.mat.set_shader_parameter("phase",age)
		item.mat.set_shader_parameter("strength",strength)
		item.node.scale=Vector3(1.25+age*.55,1.0+age*.3,1)*(.65+.35*strength)
		item.node.position=item.anchor+Vector3(lift.x,.22+lift.y,0)
		item.node.rotation.z=PI/2+clampf(p.vel.x*.035,-.35,.35)+sin(time*7+i)*.12
	for i in range(smoke.size()):
		var age:float=fposmod(time*.7+i/3.0,1)
		smoke[i].material_override.set_shader_parameter("phase",age)
		smoke[i].material_override.set_shader_parameter("clock",time)
		smoke[i].material_override.set_shader_parameter("strength",strength)
		smoke[i].position=Vector3(sin(i*4+time)*.23-p.vel.x*age*.025,.6+age*1.65,-.32)
		smoke[i].scale=Vector3.ONE*(.75+age*1.1)
	for i in range(embers.size()):
		var age:float=fposmod(time*(.7+i*.026)+i*.173,1)
		embers[i].position=Vector3(sin(i*7.3)*.46+sin(time*4+i)*age*.20-p.vel.x*age*.035,-.2+age*2.25,.5)
		embers[i].scale=Vector3(.028,.065,1)*strength*(1-age)
		embers[i].rotation.z=sin(time*8+i)*.6
