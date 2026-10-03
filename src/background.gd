extends Node3D
## Real 3D scenery rendered behind the sharp playfield, with a separate lens blur.
var viewport:SubViewport
var source:Node3D
var host:Node3D
var rng:=RandomNumberGenerator.new()
var frames:=0
var image_plane:MeshInstance3D
var image_quad:QuadMesh

func build(world:Node3D)->void:
	host=world;rng.seed=826
	viewport=SubViewport.new();viewport.size=Vector2i(1280,720)
	viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X;add_child(viewport)
	source=Node3D.new();viewport.add_child(source)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=19.6
	camera.position=Vector3(0,15.3,37);source.add_child(camera);camera.look_at(Vector3(0,7.7,0));camera.current=true
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("9d9a77")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d9d6b6");env.environment.ambient_light_energy=.45
	source.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-30,0)
	sun.light_energy=.8;sun.light_color=Color("ffdfae");sun.shadow_enabled=true;sun.shadow_blur=3
	source.add_child(sun)
	# Generated distant garden plate; layered geometry provides the nearer depth.
	var plate_shape:=QuadMesh.new();plate_shape.size=Vector2(34.8445,19.6)
	var plate_mat:=StandardMaterial3D.new();plate_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	plate_mat.albedo_texture=load({"ruins":"res://art/ruins-background.png","autumn":"res://art/autumn-background.png","mushrooms":"res://art/grotto-background.png"}.get(host.sim.theme,"res://art/garden.png"))
	plate_mat.albedo_color=Color("d7e7b7") if host.sim.theme=="reeds" else Color.WHITE
	plate_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var plate_direction:Vector3=(Vector3(0,7.7,0)-camera.position).normalized()
	var plate:MeshInstance3D=host.mesh(source,plate_shape,camera.position+plate_direction*70,Vector3.ONE,plate_mat)
	plate.rotation=camera.rotation
	plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if host.sim.theme in ["ruins","autumn","mushrooms"]:
		build_theme_depth(host.sim.theme)
	for side in [-1,1]:
		if host.sim.theme in ["ruins","autumn","mushrooms"]:continue
		for i in range(5):
			var x:float=side*rng.randf_range(13.8,18)
			var z:float=rng.randf_range(-12,-3)
			var size_value:=Vector3(rng.randf_range(.6,1.2),rng.randf_range(.6,1.5),rng.randf_range(.8,1.7))
			rock(Vector3(x,size_value.y*.6,z),size_value,Color("78806b").lightened(rng.randf_range(0,.16)))
		for i in range(3):
			var base:=Vector3(side*rng.randf_range(15,19),rng.randf_range(.3,2),rng.randf_range(-19,-5))
			fern(base,rng.randf_range(4,10),side)
		# A mossy bank of small leafy plants surrounds the large stones.
		for i in range(4):
			var base:=Vector3(side*rng.randf_range(14,18),rng.randf_range(.5,1.8),rng.randf_range(-15,-3))
			fern(base,rng.randf_range(1,3),-side)
	image_quad=QuadMesh.new()
	var blur:=ShaderMaterial.new();blur.shader=load("res://src/background_blur.gdshader")
	blur.set_shader_parameter("backdrop",viewport.get_texture())
	image_plane=MeshInstance3D.new();image_plane.mesh=image_quad;image_plane.material_override=blur
	image_plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(image_plane)
	fit_camera()

func build_theme_depth(theme:String)->void:
	# Near foliage and stones provide actual 3D depth over the distant art plate.
	for side in [-1,1]:
		for i in range(3):
			var base:=Vector3(side*(16+i*.9),1+i*2,-5-i*2)
			if theme=="ruins":
				rock(base,Vector3(.7,1.0,.8),Color("83917b"))
				fern(base+Vector3(0,.8,0),2.4,-side)
			elif theme=="autumn":
				var tip:Vector3=base+Vector3(-side*.4,15,0)
				host.tube(source,base,tip,.38,Color("71553d"))
				for j in range(3):
					var leaf_base:Vector3=base.lerp(tip,.6+j*.12)
					host.Scenery.leaf(host,source,leaf_base,leaf_base+Vector3(-side*1.5,.6,.2),.9,Color("ab7f45"))
			else:
				rock(base,Vector3(.6,1.1,.8),Color("655f72"))
				host.ball(source,base+Vector3(-side*.5,1,0),Vector3(.12,.65,.12),Color("afb4a9"))
				host.ball(source,base+Vector3(-side*.5,1.6,0),Vector3(.7,.18,.5),Color("7796ac"))

func rock(pos:Vector3,size_value:Vector3,color:Color)->void:
	var sphere:=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=18;sphere.rings=12
	var arrays:=sphere.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		var v:Vector3=vertices[i]
		vertices[i]=v*(1+sin(v.x*8+v.y*5)*cos(v.z*9-v.y*4)*.13)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var shape:=ArrayMesh.new();shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node:MeshInstance3D=host.mesh(source,shape,pos,size_value,host.material(color))
	node.rotation.y=rng.randf_range(0,TAU)
	# Smaller moss clumps soften the stone edges.
	for i in range(3):host.ball(source,pos+Vector3(rng.randf_range(-.5,.5),size_value.y*.8,0),Vector3(.45,.15,.35),Color("667c43"))

func fern(base:Vector3,height:float,side:int)->void:
	var tip:=base+Vector3(side*height*.25,height,0)
	host.tube(source,base,tip,.025+height*.006,Color("637143"))
	for i in range(7):
		var t:float=.18+i*.11
		var center:Vector3=base.lerp(tip,t)
		for leaf_side in [-1,1]:
			var spread:float=(1-t)*height*.22
			var leaf:MeshInstance3D=host.ball(source,center+Vector3(leaf_side*spread,.12,0),Vector3(spread*.95,height*.06,.10+height*.015),Color("637f48").lightened(rng.randf_range(0,.17)))
			leaf.rotation.z=leaf_side*.35+side*.12

func pot(pos:Vector3,radius:float)->void:
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius*.7;shape.height=radius*1.5
	host.mesh(source,shape,pos,Vector3.ONE,host.material(Color("ac7959")))
	var rim:=TorusMesh.new();rim.inner_radius=radius*.86;rim.outer_radius=radius*1.1
	host.mesh(source,rim,pos+Vector3(0,radius*.75,0),Vector3.ONE,host.material(Color("b88a67")))
	fern(pos+Vector3(0,radius*.8,0),6,1)

func fit_camera()->void:
	# This is a composited distant backdrop. Keep it covering the current view,
	# including camera pans, zoom changes, aspect changes and impact offsets.
	var camera:Camera3D=host.camera
	var extent:Vector2=camera.get_viewport().get_visible_rect().size
	var aspect:float=extent.x/maxf(1,extent.y)
	var size_value:=Vector2(camera.size*aspect,camera.size) if camera.keep_aspect==Camera3D.KEEP_HEIGHT else Vector2(camera.size,camera.size/aspect)
	image_quad.size=size_value*1.02
	image_plane.global_transform=camera.get_camera_transform()*Transform3D(Basis.IDENTITY,Vector3(0,0,-46))

func _process(_dt:float)->void:
	fit_camera()
	frames+=1
	# Let procedural textures settle; the distant world is static, so bake it once.
	if frames==90:viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
