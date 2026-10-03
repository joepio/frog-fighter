extends Node3D
## Full 3D side landmarks. Their inner silhouette follows the x=±14 grip walls.
var host:Node3D
var rng:=RandomNumberGenerator.new()
var falls:Array=[]
var spray:MultiMeshInstance3D
var bark:StandardMaterial3D
var stone:StandardMaterial3D
var moss:StandardMaterial3D

func build(world:Node3D,full_garden:bool=true)->void:
	host=world;rng.seed=83471
	bark=textured_material(Color("69503b"),Color("a7835a"),.055,Vector3(4,.35,1),1.6)
	stone=textured_material(Color("666e65"),Color("a5aa97"),.07,Vector3(2,2,1),.7)
	moss=textured_material(Color("3d5331"),Color("8c9b4e"),.1,Vector3(3,3,1),1.2)
	bark.albedo_texture=load("res://art/materials/bark.png");bark.uv1_scale=Vector3(2,1,1);bark.normal_scale=.2
	stone.albedo_texture=load("res://art/materials/stone.png");stone.uv1_scale=Vector3(1.2,1.2,1);stone.normal_scale=.18
	if full_garden:
		build_tree()
		build_cliff()

func textured_material(dark:Color,light:Color,frequency:float,uv_scale:Vector3,bump:float)->StandardMaterial3D:
	var noise:=FastNoiseLite.new();noise.frequency=frequency;noise.fractal_octaves=5
	var gradient:=Gradient.new();gradient.set_color(0,dark);gradient.set_color(1,light)
	var albedo:=NoiseTexture2D.new();albedo.width=256;albedo.height=512;albedo.noise=noise;albedo.color_ramp=gradient;albedo.seamless=true
	var normal:=NoiseTexture2D.new();normal.width=256;normal.height=512;normal.noise=noise;normal.as_normal_map=true;normal.bump_strength=bump;normal.seamless=true
	var mat:=StandardMaterial3D.new();mat.albedo_texture=albedo;mat.roughness=.94;mat.normal_enabled=true;mat.normal_texture=normal;mat.normal_scale=.55;mat.uv1_scale=uv_scale
	return mat

func bark_mesh(height:float,radius:float)->ArrayMesh:
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	var sides:=48;var rings:=70
	for j in range(rings+1):
		var t:float=float(j)/rings;var y:float=t*height
		for i in range(sides+1):
			var a:float=float(i)/sides*TAU
			var ridge:float=sin(a*9+y*.13)*.065+sin(a*21-y*.08)*.035
			var flare:float=pow(1-t,8)*.35
			var r:float=radius*(1-t*.24+ridge+flare)
			vertices.append(Vector3(cos(a)*r+sin(t*3.1)*.15,y,sin(a)*r))
			uv.append(Vector2(float(i)/sides,t*4))
	for j in range(rings):
		for i in range(sides):
			var a:int=j*(sides+1)+i;var b:int=a+sides+1
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=SurfaceTool.new();surface.create_from(mesh,0);surface.generate_normals()
	return surface.commit()

func rock(pos:Vector3,size_value:Vector3,mat:Material=null,playable:bool=false)->MeshInstance3D:
	if mat==null:mat=stone
	var sphere:=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=18;sphere.rings=12
	var arrays:=sphere.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var offset:=rng.randf_range(0,20)
	for i in range(vertices.size()):
		var v:Vector3=vertices[i]
		var n:float=sin(v.x*6+v.y*7+offset)*cos(v.z*8-v.y*3)*.14+sin(v.x*11+v.z*4)*.045
		vertices[i]=Vector3(signf(v.x)*pow(absf(v.x),.78),signf(v.y)*pow(absf(v.y),.78),signf(v.z)*pow(absf(v.z),.78))*(1+n*.65)
		if playable and v.y>.55:vertices[i].y=host.sim.Terrain.ROCK_TOP
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var raw:=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=SurfaceTool.new();surface.create_from(raw,0);surface.generate_normals()
	var node:MeshInstance3D=host.mesh(self,surface.commit(),pos,size_value,mat)
	if not playable:node.rotation=Vector3(rng.randf_range(-.2,.2),rng.randf_range(-.4,.4),rng.randf_range(-.15,.15))
	return node

func branch(a:Vector3,b:Vector3,radius:float)->void:
	var shape:=bark_mesh(a.distance_to(b),radius)
	var direction:Vector3=(b-a).normalized()
	var ref:=Vector3.RIGHT if absf(direction.y)>.97 else Vector3.UP
	var x:=ref.cross(direction).normalized()
	var node:MeshInstance3D=host.mesh(self,shape,a,Vector3.ONE,bark)
	node.basis=Basis(x,direction,x.cross(direction))

func build_tree()->void:
	host.mesh(self,bark_mesh(17.5,1.38),Vector3(-15.35,-.35,-.6),Vector3.ONE,bark)
	# Large knots and curling roots break the outline; grooves are real geometry.
	for y in [3.2,7.8,12.7]:
		var knot:MeshInstance3D=host.ball(self,Vector3(-15.1,y,.75),Vector3(.4,.7,.13),Color("8a6947"))
		knot.material_override=bark
		var ring:=TorusMesh.new();ring.inner_radius=.20;ring.outer_radius=.29;ring.rings=24;ring.ring_segments=8
		var scar:MeshInstance3D=host.mesh(self,ring,Vector3(-15.1,y,.86),Vector3(1,1.6,1),host.material(Color("4c392d")))
		scar.rotation.x=PI/2
	for i in range(7):
		var a:float=-.4+i*.5
		var start:=Vector3(-15.3,.5,-.6)
		var end:=start+Vector3(cos(a)*2.1,-.4,sin(a)*1.8)
		branch(start,end,.33)
	branch(Vector3(-15.5,13.5,-1),Vector3(-11.7,16.1,-1.3),.52)
	branch(Vector3(-15.6,9,-1.2),Vector3(-17.5,12,-1.8),.4)
	# Shelf fungi: rust-colored caps with a pale underside and speckled tops.
	for i in range(7):
		var y:float=2.0+i*2.05
		var pos:=Vector3(-14.05+(i%2)*.12,y,.45)
		host.tube(self,pos-Vector3(.3,.25,0),pos,.07,Color("dfc3a0"))
		host.ball(self,pos,Vector3(.55,.10,.4),Color("e1ceb0"))
		host.ball(self,pos+Vector3(0,.11,0),Vector3(.55,.21,.4),Color("b9764e"))
		for j in range(6):
			var a:float=j*TAU/6
			host.ball(self,pos+Vector3(cos(a)*.28,.26,sin(a)*.22),Vector3(.045,.022,.045),Color("e7d7b7"))
	for i in range(15):
		var y:=rng.randf_range(.5,17);var x:=rng.randf_range(-16.7,-14.4)
		rock(Vector3(x,y,.65),Vector3(.25,.15,.16),moss)
	for side in [-1,1]:
		for i in range(8):
			var x:float=side*(9+i*.48);var base:=Vector3(x,15.95,-.1)
			var tip:Vector3=base+Vector3(side*.4,-.8-sin(i)*.4,.3)
			host.Scenery.leaf(host,self,base,tip,.72,Color("6d833d"))
	fern(Vector3(-15.5,1,1.1),1.8,1)
	fern(Vector3(-16.2,9.7,.3),1.2,-1)

func build_cliff()->void:
	# Interlocking stone courses create a continuous climbable silhouette.
	for j in range(9):
		var y:float=.65+j*1.8
		rock(Vector3(15.45+sin(j*2.4)*.18,y,-.7),Vector3(1.36,1.1+(j%3)*.14,1.25),stone)
		rock(Vector3(16.5,y+.55,-1.1),Vector3(1.0,.85,.95),stone)
		rock(Vector3(14.9,y+.9,.15),Vector3(.52,.16,.48),moss)
	for i in range(10):
		var p:=Vector3(rng.randf_range(14.3,16.8),rng.randf_range(1,15),.3)
		rock(p,Vector3(.27,.2,.25),moss)
		if i%3==0:fern(p,1.3,-1)
	# Two curved curtains of water spill over stone ledges, not a painted wall.
	waterfall(Vector3(15.55,16.4,.4),Vector3(15.15,9.5,1.1),1.1)
	rock(Vector3(15.2,9.4,.6),Vector3(1.3,.35,1.1),stone)
	waterfall(Vector3(15.25,9.35,1.1),Vector3(15.65,.55,1.25),1.35)
	for i in range(6):
		var a:float=i*TAU/6
		rock(Vector3(15.2+cos(a)*1.7,.45,1.1+sin(a)*.8),Vector3(.7,.5,.65),stone)
	var drops:=SphereMesh.new();drops.radius=.05;drops.height=.1;drops.radial_segments=6;drops.rings=4
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=drops;mm.instance_count=35
	spray=MultiMeshInstance3D.new();spray.multimesh=mm;spray.material_override=host.material(Color("cfefdf"));add_child(spray)

func waterfall(top:Vector3,bottom:Vector3,width:float)->void:
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	var count:=36
	for j in range(count+1):
		var t:float=float(j)/count
		var p:Vector3=top.lerp(bottom,t)+Vector3(sin(t*7)*.06,0,sin(t*PI)*.35)
		for side in [-1,1]:vertices.append(p+Vector3(side*width*.5,0,0));uv.append(Vector2((side+1)*.5,t))
	for j in range(count):indices.append_array(PackedInt32Array([j*2,j*2+1,j*2+2,j*2+1,j*2+3,j*2+2]))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var raw:=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=SurfaceTool.new();surface.create_from(raw,0);surface.generate_normals()
	var mat:=ShaderMaterial.new();mat.shader=load("res://src/waterfall.gdshader")
	host.mesh(self,surface.commit(),Vector3.ZERO,Vector3.ONE,mat);falls.append(mat)

func fern(base:Vector3,height:float,side:int)->void:
	var tip:Vector3=base+Vector3(side*height*.5,height,0)
	host.tube(self,base,tip,.025,Color("70804c"))
	for i in range(5):
		var t:float=.2+i*.16
		for sign_value in [-1,1]:
			var p:Vector3=base.lerp(tip,t)
			var end:Vector3=p+Vector3(sign_value*(1-t)*height*.55,height*.11,.08)
			host.Scenery.leaf(host,self,p,end,(1-t)*height*.20,Color("738b44"))

func update(clock:float)->void:
	for mat in falls:mat.set_shader_parameter("flow_time",clock)
	if spray==null:return
	for i in range(35):
		var t:float=fmod(clock*.85+i*.137,1)
		var a:float=i*2.399
		var p:=Vector3(15.6+cos(a)*t*.9,.5+sin(t*PI)*.8,1.25+sin(a)*t*.7)
		spray.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(1,1+t,1)),p))
