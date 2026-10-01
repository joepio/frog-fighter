extends RefCounted
## Handmade foreground geometry shared by the arena and distant garden.
static func rounded_box(size_value:Vector3,bevel:float)->ArrayMesh:
	var box:=BoxMesh.new();box.size=size_value
	box.subdivide_width=20;box.subdivide_height=4;box.subdivide_depth=6
	var arrays:=box.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var inner:Vector3=size_value*.5-Vector3.ONE*bevel
	for i in range(vertices.size()):
		var v:Vector3=vertices[i];var nearest:=v.clamp(-inner,inner)
		v=nearest+(v-nearest).normalized()*bevel
		v.y+=sin(v.x*4.3+v.z*2.7)*.012
		v.z+=sin(v.x*3.6+v.y*5.1)*.017
		vertices[i]=v
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var raw:=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=SurfaceTool.new();surface.create_from(raw,0);surface.generate_normals();surface.generate_tangents()
	return surface.commit()

static func leaf(world:Node3D,parent:Node3D,base:Vector3,tip:Vector3,width:float,color:Color)->void:
	var axis:Vector3=tip-base;var across:=Vector3(axis.y,-axis.x,0).normalized()
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	for j in range(13):
		var t:float=j/12.0
		var center:Vector3=base+axis*t+Vector3(0,0,sin(t*PI)*width*.32)
		var spread:float=pow(sin(t*PI),.75)*width*.5
		for k in range(5):
			var s:float=(k-2)/2.0
			vertices.append(center+across*spread*s+Vector3(0,0,-absf(s)*width*.13*sin(t*PI)))
			uv.append(Vector2(k/4.0,t))
	for j in range(12):
		for k in range(4):
			var a:int=j*5+k
			indices.append_array(PackedInt32Array([a,a+5,a+1,a+1,a+5,a+6]))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var raw:=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var st:=SurfaceTool.new();st.create_from(raw,0);st.generate_normals()
	var key:String="leaf"+color.to_html()
	if not world.mats.has(key):
		var leaf_mat:StandardMaterial3D=world.material(color).duplicate()
		leaf_mat.cull_mode=BaseMaterial3D.CULL_DISABLED;leaf_mat.roughness=.65
		world.mats[key]=leaf_mat
	var mat:StandardMaterial3D=world.mats[key]
	world.mesh(parent,st.commit(),Vector3.ZERO,Vector3.ONE,mat)
	for j in range(5):
		var t:float=j/5.0;var u:float=(j+1)/5.0
		var a:Vector3=base+axis*t+Vector3(0,0,sin(t*PI)*width*.32+.012)
		var b:Vector3=base+axis*u+Vector3(0,0,sin(u*PI)*width*.32+.012)
		world.tube(parent,a,b,.008,color.lightened(.22))

static func plank(world:Node3D,parent:Node3D,width:float)->void:
	world.mesh(parent,rounded_box(Vector3(width,.65,1.8),.11),Vector3(0,-.125,0),Vector3.ONE,world.material(Color("eee2ca"),true))
	for side in [-1,1]:
		for j in range(3):
			var x:float=side*width*.5;var y:float=-.33+j*.16
			world.tube(parent,Vector3(x-side*.07,y,.913),Vector3(x-side*(.35+j*.13),y+.025,.927),.009,Color("5a4432"))
		world.ball(parent,Vector3(side*width*.37,-.08,.905),Vector3(.09,.09,.025),Color("70604a"))
		world.ball(parent,Vector3(side*width*.37,-.08,.932),Vector3(.025,.022,.012),Color("3c362b"))
	for i in range(int(width*2)):
		var x:float=-width*.48+i*.49
		if sin(i*3.7+width)>.05:
			world.ball(parent,Vector3(x,.21,-.60),Vector3(.24,.07,.24),Color("657b3b"))
			world.ball(parent,Vector3(x+.1,.23,-.49),Vector3(.12,.055,.14),Color("88994b"))

static func glass_rim(world:Node3D)->void:
	var glass:=StandardMaterial3D.new();glass.albedo_color=Color(.64,.83,.81,.24)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.roughness=.12;glass.metallic_specular=.85
	var previous:=Vector3(-15.2,.44,1.2)
	for i in range(1,49):
		var a:float=PI-float(i)/48*PI
		var point:=Vector3(cos(a)*15.2,.44,1.2+sin(a)*5.1)
		var tube:MeshInstance3D=world.tube(world,previous,point,.13,Color("8fa89f"));tube.material_override=glass
		world.tube(world,previous+Vector3(0,.08,0),point+Vector3(0,.08,0),.017,Color("c8d5c3"))
		previous=point

static func batch_static(parent:Node3D,excluded:Array=[])->void:
	# Merge static meshes by material; animated nodes and shaders retain ownership.
	var batches:Dictionary={}
	for child in parent.get_children():
		if not child is MeshInstance3D or child in excluded:continue
		var mat:Material=child.material_override
		if not mat is StandardMaterial3D or mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
		var key:int=mat.get_instance_id()
		if not batches.has(key):batches[key]={"surface":SurfaceTool.new(),"material":mat,"nodes":[]}
		batches[key].surface.append_from(child.mesh,0,child.transform)
		batches[key].nodes.append(child)
	for group in batches.values():
		if group.nodes.size()<2:continue
		var node:=MeshInstance3D.new();node.mesh=group.surface.commit();node.material_override=group.material
		parent.add_child(node)
		for old in group.nodes:old.free()

static func lily(world:Node3D,pos:Vector3,radius:float,color:Color)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(39):
		var a:float=.16+i*(TAU-.32)/39.0;var b:float=.16+(i+1)*(TAU-.32)/39.0
		for v in [Vector3.ZERO,Vector3(cos(b)*radius,0,sin(b)*radius*.75),Vector3(cos(a)*radius,0,sin(a)*radius*.75)]:
			st.set_normal(Vector3.UP);st.add_vertex(v)
	var key:String="lily"+color.to_html()
	if not world.mats.has(key):
		var mat:StandardMaterial3D=world.material(color).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		world.mats[key]=mat
	world.mesh(world,st.commit(),pos,Vector3.ONE,world.mats[key])
	for j in range(7):
		var a:float=.3+j*(TAU-.6)/7
		world.tube(world,pos+Vector3(0,.008,0),pos+Vector3(cos(a)*radius*.9,.008,sin(a)*radius*.65),.007,color.lightened(.1))
