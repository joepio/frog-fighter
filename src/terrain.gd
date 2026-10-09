extends RefCounted
# The same rock crowns drive the visible meshes and their landing surfaces.
const WATER_LEVEL:=.35
const ROCK_TOP:=.85
const ROCK_WIDTH:=1.3
static func rocks(arena:String)->Array:
	var out:Array=[]
	if arena not in preload("res://src/arenas.gd").CLASSIC_IDS:return out
	if arena=="terrarium":out.append({"pos":Vector3(0,2.2,-.15),"size":Vector3(1.9,1.7,1.3)})
	for side in [-1,1]:
		for i in range(5):
			out.append({"pos":Vector3(side*(9.8+i*.72),.8+(i%2)*.3,.0),"size":Vector3(.8,1.0+(i%2)*.4,.75)})
		for j in range(4):
			out.append({"pos":Vector3(side*(2+j*.7),.8+j*.07,0),"size":Vector3(.65,.8,.65)})
	return out
