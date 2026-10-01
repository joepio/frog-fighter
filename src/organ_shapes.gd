extends RefCounted
## Three soft clay silhouettes, distinct from skin-colored limbs and droplets.
static func make(kind:int)->ArrayMesh:
	var sphere:=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=24;sphere.rings=16
	var arrays:=sphere.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		var v:Vector3=vertices[i]
		match kind:
			0: # Two rounded lobes and a tapered lower tip.
				v.x*=.84+.20*v.y
				v.y-=maxf(0,v.y)*.36*exp(-v.x*v.x*9)
				v.z*=.70
			1: # Broad, asymmetric bean shape.
				v.x+=.30*(1-v.y*v.y)
				v.y*=.72;v.z*=.65
			2: # Curled, lobulated pink gland.
				v.x*=1.20;v.y=v.y*.48+sin(v.x*2.8)*.26
				v.z*=.56+.08*cos(v.x*7)
		vertices[i]=v
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var raw:=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=SurfaceTool.new();surface.create_from(raw,0);surface.generate_normals();surface.generate_tangents()
	return surface.commit()
