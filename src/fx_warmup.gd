extends Node
## Compatibility compiles on first draw. Render the actual FX resources in a
## separate tiny viewport, so hidden pools are ready before the first explosion.
func run(host:Node3D)->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(96,96)
	viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=12;camera.position.z=8;viewport.add_child(camera);camera.current=true
	# Mirror the arena lights: shadowed sun, fill and an omni, so the same
	# lighting variants compile here instead of mid-round.
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-28,0);sun.shadow_enabled=true;viewport.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,145,0);viewport.add_child(fill)
	var light:=OmniLight3D.new();light.position=Vector3(0,0,2);light.omni_range=20;viewport.add_child(light)
	# Every material in the world, hidden pools included (flames, burning,
	# weapons, debris), plus the hit-flash overlay on frog skin.
	var samples:=collect(host)
	for frog in host.frogs:
		if not frog.skin_meshes.is_empty():
			samples.append([frog.skin_meshes[0].mesh,frog.skin_meshes[0].material_override,frog.flash]);break
	# The two blend modes are distinct immutable materials during gameplay.
	samples.append([host.combat.bursts[0].flash.mesh,host.combat.bursts[0].additive,null])
	for i in range(samples.size()):
		var sample:=MeshInstance3D.new();sample.mesh=samples[i][0];sample.material_override=samples[i][1];sample.material_overlay=samples[i][2]
		sample.position=Vector3((i%14-6.5)*.8,(floori(i/14.0)-5)*.8,0)
		sample.scale=Vector3.ONE*.3;viewport.add_child(sample)
	# Gore/debris use instancing, which is a different shader variant from meshes.
	var instanced:Array=[host.blood_mesh,host.stain_mesh,host.limb_mesh,host.cut_mesh,host.particle_mesh]+host.organ_meshes
	for i in range(instanced.size()):
		var source:MultiMeshInstance3D=instanced[i]
		var sample:=MultiMeshInstance3D.new();sample.material_override=source.material_override
		var instances:=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.use_colors=source.multimesh.use_colors;instances.mesh=source.multimesh.mesh;instances.instance_count=1
		instances.set_instance_transform(0,Transform3D(Basis.IDENTITY,Vector3.ZERO))
		if instances.use_colors:instances.set_instance_color(0,Color.WHITE)
		sample.multimesh=instances;sample.position=Vector3(i-3.5,4,0);sample.scale=Vector3.ONE*.4
		sample.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;viewport.add_child(sample)
	# Both frames really draw, including a driver upload/compile on the first.
	for i in range(2):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

## One sample per distinct mesh surface material found under root, visible or not.
static func collect(root:Node)->Array:
	var seen:Dictionary={};var out:Array=[]
	for node in root.find_children("*","MeshInstance3D",true,false):
		var item:MeshInstance3D=node
		if item.mesh==null:continue
		var materials:Array=[item.material_override] if item.material_override!=null else []
		if materials.is_empty():
			for surface in item.mesh.get_surface_count():
				var mat:Material=item.get_surface_override_material(surface)
				materials.append(mat if mat!=null else item.mesh.surface_get_material(surface))
		for mat in materials:
			var key:String=str(mat.get_instance_id() if mat!=null else 0)+"/"+str(item.material_overlay.get_instance_id() if item.material_overlay!=null else 0)
			if seen.has(key):continue
			seen[key]=true;out.append([item.mesh,mat,item.material_overlay])
	return out

## Draw a freshly prepared arena once off screen so its shaders compile while
## the current round is still playing, not on the first frame of the next one.
static func warm_stage(viewport:SubViewport)->void:
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	for i in range(2):
		await viewport.get_tree().process_frame
		await RenderingServer.frame_post_draw
