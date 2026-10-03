extends RefCounted
## Weapons assembled from bark, seed pods, vines, cones and thorns.
static func ring(world:Node3D,parent:Node3D,pos:Vector3,radius:float,color:Color)->void:
	var shape:=TorusMesh.new();shape.inner_radius=radius*.82;shape.outer_radius=radius;shape.rings=16;shape.ring_segments=6
	var node:MeshInstance3D=world.mesh(parent,shape,pos,Vector3.ONE,world.material(color));node.rotation.z=PI/2

static func build(world:Node3D,parent:Node3D)->Array:
	var acorn:=Node3D.new();parent.add_child(acorn)
	var barrel:MeshInstance3D=world.tube(acorn,Vector3(-.2,.01,0),Vector3(.58,.01,0),.21,Color("ac8660"));barrel.material_override=world.landmarks.bark
	world.ball(acorn,Vector3(.60,.01,0),Vector3(.025,.15,.15),Color("342d23"))
	ring(world,acorn,Vector3(.61,.01,0),.23,Color("937346"))
	world.tube(acorn,Vector3(-.17,-.08,0),Vector3(-.27,-.32,0),.075,Color("705536"))
	world.ball(acorn,Vector3(-.13,.26,0),Vector3(.22,.23,.18),Color("b7844e"))
	world.ball(acorn,Vector3(-.13,.40,0),Vector3(.235,.11,.20),Color("625239"))
	for x in [-.04,.32]:ring(world,acorn,Vector3(x,.01,0),.235,Color("66743f"))
	world.Scenery.leaf(world,acorn,Vector3(-.22,.23,.16),Vector3(-.51,.45,.15),.24,Color("708741"))
	var pine:=Node3D.new();parent.add_child(pine)
	world.ball(pine,Vector3(.03,.05,0),Vector3(.33,.20,.19),Color("79553a"))
	for row in range(4):
		for j in range(6):
			var a:float=j*TAU/6+row*.5
			world.ball(pine,Vector3(-.18+row*.13,.05+cos(a)*.16,sin(a)*.16),Vector3(.10,.065,.075),Color("a58151") if j%2==0 else Color("88673d"))
	for i in range(3):
		world.tube(pine,Vector3(.23,(i-1)*.07,0),Vector3(.76,(i-1)*.07,0),.033,Color("72834a"))
		world.tube(pine,Vector3(-.21,.16,.08),Vector3(-.5+i*.10,.36+i*.03,.08),.014,Color("7f984f"))
	world.tube(pine,Vector3(-.15,-.05,0),Vector3(-.27,-.3,0),.055,Color("685332"))
	ring(world,pine,Vector3(.32,0,0),.13,Color("b39465"))
	var bramble:=Node3D.new();parent.add_child(bramble)
	world.ball(bramble,Vector3(.09,.025,0),Vector3(.36,.23,.22),Color("7d8b45"))
	for j in range(5):
		var a:float=j*TAU/5
		var start:=Vector3(-.18,cos(a)*.19,sin(a)*.19)
		var end:=Vector3(.53,cos(a+.55)*.19,sin(a+.55)*.19)
		world.tube(bramble,start,end,.045,Color("645038"))
		var thorn:=CylinderMesh.new();thorn.top_radius=0;thorn.bottom_radius=.045;thorn.height=.16;thorn.radial_segments=6
		var node:MeshInstance3D=world.mesh(bramble,thorn,Vector3(.18,cos(a)*.29,sin(a)*.29),Vector3.ONE,world.material(Color("d3bb82")));node.rotation.x=a-PI/2
	world.ball(bramble,Vector3(.53,0,0),Vector3(.035,.15,.15),Color("42382a"))
	ring(world,bramble,Vector3(.56,0,0),.19,Color("958453"))
	world.tube(bramble,Vector3(-.16,-.1,0),Vector3(-.24,-.33,0),.07,Color("715836"))
	world.Scenery.leaf(world,bramble,Vector3(-.13,.18,.12),Vector3(-.4,.37,.12),.23,Color("72813d"))
	var dragonpod:=Node3D.new();parent.add_child(dragonpod)
	world.ball(dragonpod,Vector3(-.02,.04,0),Vector3(.36,.26,.25),Color("bc793b"))
	for j in range(7):
		var a:float=j*TAU/7
		world.tube(dragonpod,Vector3(-.29,cos(a)*.14,sin(a)*.14),Vector3(.21,cos(a)*.23,sin(a)*.23),.026,Color("e1b35c"))
	world.tube(dragonpod,Vector3(.20,.04,0),Vector3(.73,.04,0),.10,Color("687640"))
	for x in [.30,.45,.60]:ring(world,dragonpod,Vector3(x,.04,0),.115,Color("9e9657"))
	world.ball(dragonpod,Vector3(.735,.04,0),Vector3(.012,.065,.065),Color("e9a441"))
	world.tube(dragonpod,Vector3(-.22,-.06,0),Vector3(-.30,-.32,0),.07,Color("68583a"))
	world.Scenery.leaf(world,dragonpod,Vector3(-.28,.18,.14),Vector3(-.48,.48,.14),.28,Color("8d9446"))
	# Split reed rails and a luminous crystal chamber give the precision gun a long silhouette.
	var rail:=Node3D.new();parent.add_child(rail)
	world.ball(rail,Vector3(-.24,.01,0),Vector3(.29,.17,.18),Color("455d56"))
	for side in [-1,1]:
		world.tube(rail,Vector3(-.12,side*.14,0),Vector3(1.15,side*.14,0),.045,Color("75a291"))
		for x in [.04,.40,.77]:ring(world,rail,Vector3(x,side*.14,0),.064,Color("b2d7a3"))
		world.Scenery.leaf(world,rail,Vector3(-.30,side*.09,.06),Vector3(-.65,side*.24,.06),.16,Color("566579"))
	var crystal:=PrismMesh.new();crystal.size=Vector3(.43,.31,.22)
	var energy:=StandardMaterial3D.new();energy.albedo_color=Color("84f3dc");energy.emission_enabled=true;energy.emission=Color("42c6cd");energy.emission_energy_multiplier=2
	world.mesh(rail,crystal,Vector3(-.08,.03,.07),Vector3.ONE,energy)
	world.tube(rail,Vector3(.22,0,.015),Vector3(1.06,0,.015),.021,Color("c7fff1"))
	world.tube(rail,Vector3(-.20,-.10,0),Vector3(-.36,-.36,0),.065,Color("445449"))
	world.ball(rail,Vector3(-.22,.28,0),Vector3(.17,.09,.09),Color("405449"))
	world.ball(rail,Vector3(-.045,.28,0),Vector3(.014,.055,.055),Color("87f5e4"))
	# A round spore drum and flared mushroom muzzle make the lobber visibly heavy.
	var grenade:=Node3D.new();parent.add_child(grenade)
	world.ball(grenade,Vector3(-.12,0,0),Vector3(.36,.33,.30),Color("9560a0"))
	for i in range(6):
		var a:float=i*TAU/6
		world.ball(grenade,Vector3(-.19,cos(a)*.25,sin(a)*.25),Vector3(.12,.12,.12),Color("d6bf7d"))
	world.tube(grenade,Vector3(.04,.03,0),Vector3(.64,.03,0),.24,Color("887345"))
	ring(world,grenade,Vector3(.66,.03,0),.31,Color("bb886d"))
	world.ball(grenade,Vector3(.665,.03,0),Vector3(.025,.235,.235),Color("372c37"))
	world.tube(grenade,Vector3(-.24,-.12,0),Vector3(-.36,-.4,0),.085,Color("665344"))
	world.Scenery.leaf(world,grenade,Vector3(-.25,.25,.10),Vector3(-.5,.55,.10),.28,Color("789547"))
	acorn.scale=Vector3(1.0,1.22,1.12)
	pine.scale=Vector3(1.18,.84,.90)
	bramble.scale=Vector3(.92,1.20,1.15)
	var burr:=burr_model(world,parent)
	for model in [acorn,pine,bramble,dragonpod,rail,grenade,burr]:world.Scenery.batch_static(model)
	return [acorn,pine,bramble,dragonpod,rail,grenade,burr]

static func burr_model(world:Node3D,parent:Node3D)->Node3D:
	var root:=Node3D.new();parent.add_child(root)
	world.ball(root,Vector3.ZERO,Vector3(.27,.29,.25),Color("92713b"))
	var heat:=StandardMaterial3D.new();heat.albedo_color=Color("ffc05a");heat.emission_enabled=true;heat.emission=Color("ef721d");heat.emission_energy_multiplier=.8
	for i in range(7):
		var a:float=i*TAU/7
		world.tube(root,Vector3(cos(a)*.20,-.16,sin(a)*.18),Vector3(cos(a)*.24,.15,sin(a)*.21),.021,Color("e7ac4e")).material_override=heat
		var thorn:=CylinderMesh.new();thorn.top_radius=0;thorn.bottom_radius=.052;thorn.height=.16;thorn.radial_segments=5
		var n:MeshInstance3D=world.mesh(root,thorn,Vector3(cos(a)*.28,sin(a)*.29,.05),Vector3.ONE,world.material(Color("c1a15d")))
		n.rotation.z=a-PI*.5
	world.ball(root,Vector3(0,.25,0),Vector3(.16,.07,.16),Color("697441"))
	world.tube(root,Vector3(0,.28,0),Vector3(-.07,.43,.02),.038,Color("665039"))
	world.Scenery.leaf(world,root,Vector3(-.07,.37,.02),Vector3(.16,.49,.025),.14,Color("91aa55"))
	return root
