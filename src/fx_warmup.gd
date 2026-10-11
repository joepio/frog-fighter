extends Node
## Compatibility compiles on first draw. Render the actual FX resources in a
## separate tiny viewport, so hidden pools are ready before the first explosion.
func run(host:Node3D)->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(96,96)
	viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=12;camera.position.z=8;viewport.add_child(camera);camera.current=true
	var sun:=DirectionalLight3D.new();viewport.add_child(sun)
	var light:=OmniLight3D.new();light.position=Vector3(0,0,2);light.omni_range=20;viewport.add_child(light)
	var sources:Array=[]
	for branch in [host.combat.impact_blast.pool[0].root,host.combat.bursts[0].root,host.combat.bullets[0].root]:
		sources.append_array(branch.find_children("*","MeshInstance3D",true,false))
	# The two blend modes are distinct immutable materials during gameplay.
	var additive:MeshInstance3D=host.combat.bursts[0].flash.duplicate()
	additive.material_override=host.combat.bursts[0].additive;sources.append(additive)
	for i in range(sources.size()):
		var source:MeshInstance3D=sources[i]
		var sample:=MeshInstance3D.new();sample.mesh=source.mesh;sample.material_override=source.material_override
		sample.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sample.position=Vector3((i%10-4.5)*1.05,(floori(i/10.0)-3)*1.05,0)
		sample.scale=Vector3.ONE*.4;viewport.add_child(sample)
	additive.free()
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
