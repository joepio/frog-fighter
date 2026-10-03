extends RefCounted
## Shared heat/opacity ramp and buoyancy for jet flames, body fire, and their lighting.
const BUOYANCY:=18.0
static var ramp:GradientTexture1D

static func heat_ramp()->GradientTexture1D:
	if ramp==null:
		ramp=GradientTexture1D.new();ramp.width=128;ramp.gradient=Gradient.new()
		ramp.gradient.offsets=PackedFloat32Array([0,.25,.70,.92,1])
		ramp.gradient.colors=PackedColorArray([Color(1,.26,.018,0),Color(1,.28,.022,.12),Color(1,.32,.030,.52),Color(1,.48,.075,.82),Color(1,.94,.78,.96)])
	return ramp

static func material(smoke:bool=false)->ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://src/fire_smoke.gdshader") if smoke else preload("res://src/flame.gdshader")
	if not smoke:mat.set_shader_parameter("heat_ramp",heat_ramp())
	return mat

static func color(heat:float)->Color:
	return heat_ramp().gradient.sample(clampf(heat,0,1))

static func rise(age:float)->Vector2:
	return Vector2(0,.5*BUOYANCY*age*age)

static func motion(velocity:Vector2,age:float)->Vector2:
	return velocity*age+rise(age)
