extends RefCounted
# New arenas use the existing textured 3D asset kit, with distinct silhouettes.
static func build(host:Node3D)->void:
	var sim:RefCounted=host.sim
	if sim.theme=="mushrooms":host.landmarks.stone.albedo_color=Color("b0b3c6")
	var stone:Color=Color("87998e") if sim.theme=="ruins" else Color("716c86")
	if sim.safe_water:
		var pond:=PlaneMesh.new();pond.size=Vector2(sim.half_width*2+3,10)
		var mat:=ShaderMaterial.new();mat.shader=load("res://src/pond.gdshader");mat.set_shader_parameter("garden",load("res://art/grotto-background.png" if sim.theme=="mushrooms" else "res://art/garden.png"))
		host.water=host.mesh(host,pond,Vector3(0,sim.Terrain.WATER_LEVEL,1),Vector3.ONE,mat)
		host.block(host,Vector3(0,-.1,1),Vector3(sim.half_width*2+3,.45,9),Color("4c5147"))
		for i in range(int(sim.half_width)):
			var x:float=-sim.half_width+1+i*2
			host.Scenery.lily(host,Vector3(x,.43,2.0+sin(i)*.6),.9,Color("758e55"))
	for shelf in sim.platforms:
		var root:=Node3D.new();host.add_child(root);host.shelves.append(root)
		if shelf.kind in ["water","fungus"]:continue
		if shelf.get("max_hp",0)>0:
			preload("res://src/destruction_visuals.gd").build(host,root,shelf);continue
		if shelf.kind=="loose":
			loose_piece(host,root,shelf);continue
		if sim.theme=="mushrooms":
			mushroom(host,root,shelf.width,shelf.kind=="crumble")
		elif sim.theme=="ruins":
			var mat:Material=host.landmarks.stone.duplicate();mat.albedo_color=stone if shelf.kind!="crumble" else Color("b5a383")
			host.mesh(root,host.Scenery.rounded_box(Vector3(shelf.width,.48,1.35),.16),Vector3(0,-.04,0),Vector3.ONE,mat)
			for i in range(3):host.ball(root,Vector3(-shelf.width*.3+i*shelf.width*.3,.20,-.25),Vector3(.3,.035,.26),Color("8e9e65"))
			if shelf.kind=="fixed":
				for side in [-1,1]:
					host.landmarks.rock(Vector3(shelf.pos.x+side*shelf.width*.28,shelf.pos.y-1.0,-.6),Vector3(.38,.85,.65))
		else:
			host.Scenery.plank(host,root,shelf.width)
			if shelf.kind=="fixed":host.landmarks.branch(Vector3(shelf.pos.x-1,shelf.pos.y-2,-.4),Vector3(shelf.pos.x+1,shelf.pos.y-.15,-.4),.22)
		if shelf.kind=="crumble":
			# Pale broken lashings and jagged dark cracks read before the first step.
			for side in [-1,1]:
				host.tube(root,Vector3(side*shelf.width*.32,-.38,.96),Vector3(side*shelf.width*.29,.19,.96),.048,Color("ead298"))
			var last:=Vector3(-.24,.225,.97)
			for i in range(5):
				var next:=Vector3(-.24+i*.13,.225-i*.13,.98)
				next.x+=.10 if i%2==0 else -.10
				host.tube(root,last,next,.025,Color("48312b"));last=next
		if shelf.kind=="fixed" and sim.theme=="reeds":
			for side in [-1,1]:reed(host,Vector3(shelf.pos.x+side*shelf.width*.42,shelf.pos.y,-1),1.5,side)
	for hook in sim.hooks:host.vine_grip(hook)
	if sim.roof:
		if sim.theme=="mushrooms":
			for i in range(int(sim.half_width)+1):host.landmarks.rock(Vector3(-sim.half_width+i*2,sim.ceiling+.8,-.25),Vector3(1.3,1.0,1.0))
		else:host.landmarks.branch(Vector3(-sim.half_width,sim.ceiling-.2,-.4),Vector3(sim.half_width,sim.ceiling-.2,-.4),.25)
	for side in [-1,1]:
		if sim.walls:
			if sim.theme=="mushrooms":
				for i in range(int(sim.ceiling/2)+1):host.landmarks.rock(Vector3(side*(sim.half_width+1.1),i*2,-.2),Vector3(1.25,1.3,1.3))
			else:
				host.landmarks.branch(Vector3(side*(sim.half_width+.6),-.1,-.2),Vector3(side*(sim.half_width+.6),sim.ceiling+.2,-.2),.9)
		if sim.theme=="reeds":
			for i in range(7):reed(host,Vector3(side*(sim.half_width-1+i*.35),.4,-1.6),4+i%3,side)
		elif sim.theme=="autumn":
			# Distant broken trunks leave the actual side exits visibly open.
			for i in range(6):
				var base:=Vector3(side*(sim.half_width+1),sim.ceiling-i*1.4,-2)
				host.landmarks.branch(base+Vector3(side, -1, -.5),base+Vector3(-side,0,0),.10)
				host.Scenery.leaf(host,host,base,base+Vector3(-side*2,-1,.1),1.1,Color("c8984c") if i%2==0 else Color("a85f37"))
		elif sim.theme=="mushrooms":
			for i in range(4):
				var decor:=Node3D.new();host.add_child(decor);decor.position=Vector3(side*(sim.half_width-.3),2+i*5,-1.9)
				mushroom(host,decor,2.2,false)
			var glow:=OmniLight3D.new();host.add_child(glow);glow.position=Vector3(side*10,8,2);glow.light_color=Color("b5a4df");glow.light_energy=.7;glow.omni_range=12

static func reed(host:Node3D,base:Vector3,height:float,side:int)->void:
	for i in range(3):
		var tip:Vector3=base+Vector3((i-1)*.25+side*.3,height*(.8+i*.1),0)
		host.tube(host,base,tip,.035,Color("8c9d57"))
		host.ball(host,tip,Vector3(.11,.4,.11),Color("80573a"))
		host.Scenery.leaf(host,host,base+Vector3(0,height*.3,0),base+Vector3(side*(.7+i*.15),height*.65,.08),.3,Color("8baf66"))

static func mushroom(host:Node3D,root:Node3D,width:float,fragile:bool)->void:
	var cap:Color=Color("ae7fae") if fragile else Color("669baf")
	host.ball(root,Vector3(0,-1.35,-.15),Vector3(.26,1.05,.27),Color("d1ccb5"))
	host.ball(root,Vector3(0,-.30,0),Vector3(width*.58,.22,.78),cap)
	# Broad flat crown shares the exact y=.2 landing surface.
	var crown:=CylinderMesh.new();crown.top_radius=1;crown.bottom_radius=1.15;crown.height=.50;crown.radial_segments=32
	host.mesh(root,crown,Vector3(0,-.05,0),Vector3(width*.5,1,.66),host.material(cap.lightened(.1)))
	for i in range(7):
		var a:float=i*2.399
		host.ball(root,Vector3(cos(a)*width*.33,.205,sin(a)*.38),Vector3(.11,.015,.09),Color("dedfb9"))

static func loose_piece(host:Node3D,root:Node3D,piece:Dictionary)->void:
	var size:=Vector3(piece.width,piece.height,.9)
	var wood:bool=piece.material=="wood"
	var mat:Material=(host.landmarks.bark if wood else host.landmarks.stone).duplicate()
	mat.albedo_color=Color("bc9466") if wood else Color("a2b4af")
	host.mesh(root,host.Scenery.rounded_box(size,.07),Vector3.ZERO,Vector3.ONE,mat)
	if wood:
		# Pale sawn end grain and bark edges make the loose timber read separately.
		for side in [-1,1]:
			host.block(root,Vector3(side*(piece.width*.5-.025),0,0),Vector3(.055,piece.height*.84,.78),Color("d4b77d"))
		for i in range(3):
			var y:float=(i-1)*piece.height*.22
			host.tube(root,Vector3(-piece.width*.40,y,.459),Vector3(piece.width*.39,y+.025,.459),.012,Color("7b553a"))
		host.ball(root,Vector3(piece.width*.13,0,.465),Vector3(.12,.065,.014),Color("765338"))
	else:
		for side in [-1,1]:
			host.ball(root,Vector3(side*piece.width*.28,piece.height*.5,.03),Vector3(piece.width*.17,.035,.21),Color("8caa76"))
		# A chipped mineral seam rotates with the actual collision body.
		host.tube(root,Vector3(-piece.width*.3,-piece.height*.3,.458),Vector3(piece.width*.25,piece.height*.32,.458),.018,Color("d3d8bd"))
