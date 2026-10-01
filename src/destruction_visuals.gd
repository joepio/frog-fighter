extends RefCounted
# Each platform owns its crack layers and material, so damage persists as it falls.
static func build(host:Node3D,root:Node3D,shelf:Dictionary)->void:
	var wood:bool=shelf.material=="wood"
	var width:float=shelf.width;var height:float=shelf.height
	var mat:StandardMaterial3D=(host.landmarks.bark if wood else host.landmarks.stone).duplicate()
	var base:=Color("c19b69") if wood else Color("bec6b4")
	mat.albedo_color=base
	host.mesh(root,host.Scenery.rounded_box(Vector3(width,height,1.2),minf(.07,height*.15)),Vector3.ZERO,Vector3.ONE,mat)
	var vertical:bool=height>width
	var length:float=height if vertical else width
	# Cut ends distinguish breakable timber; masonry has shallow block joints.
	if wood:
		for side in [-1,1]:
			var size:=Vector3(width*.88,.045,1.05) if vertical else Vector3(.045,height*.84,1.05)
			var pos:=Vector3(0,side*(height*.5-.02),0) if vertical else Vector3(side*(width*.5-.02),0,0)
			host.block(root,pos,size,Color("e3c28b"))
		for i in range(3):
			var offset:float=(i-1)*.21
			var a:=Vector3(offset*width,-height*.43,.61) if vertical else Vector3(-width*.43,offset*height,.61)
			var b:=Vector3(offset*width+.02,height*.43,.61) if vertical else Vector3(width*.43,offset*height+.018,.61)
			host.tube(root,a,b,.009,Color("87603c"))
		for side in [-1,1]:
			var pos:=Vector3(0,side*height*.32,0) if vertical else Vector3(side*width*.32,0,0)
			var size:=Vector3(width+.025,.07,1.235) if vertical else Vector3(.07,height+.025,1.235)
			host.block(root,pos,size,Color("99884e"))
	else:
		for i in range(1,int(length/1.1)+1):
			var at:float=-length*.5+i*length/(int(length/1.1)+1)
			var a:=Vector3(-width*.46,at,.611) if vertical else Vector3(at,-height*.4,.611)
			var b:=Vector3(width*.46,at,.611) if vertical else Vector3(at,height*.4,.611)
			host.tube(root,a,b,.012,Color("83927e"))
	var layers:Array=[]
	for tier in range(3):
		var layer:=Node3D.new();root.add_child(layer);layer.visible=false;layers.append(layer)
		for branch in range(2+tier):
			var along:float=sin((tier*5+branch)*2.71)*length*.37
			var last:=Vector3(along,-height*.43,.626) if not vertical else Vector3(-width*.43,along,.626)
			for j in range(1,6):
				var zig:float=sin(j*2.1+branch*3+tier)*(.08+tier*.025)
				var next:=Vector3(along+zig,lerpf(-height*.43,height*.43,j/5.0),.626)
				if vertical:next=Vector3(lerpf(-width*.43,width*.43,j/5.0),along+zig,.626)
				host.tube(layer,last,next,.015+tier*.009,Color("493428") if wood else Color("3e453d"))
				if j==3:
					var fork:Vector3=next+Vector3(.16,.11,0) if not vertical else next+Vector3(.11,.2,0)
					host.tube(layer,next,fork,.013,Color("493428") if wood else Color("3e453d"))
				last=next
		# Thin pale exposed splinters/chips catch the light beside deeper cracks.
		for side in [-1,1]:
			var pos:=Vector3(side*width*.28,height*.48,.3)
			host.block(layer,pos,Vector3(.11,.065,.35),Color("e1bb81") if wood else Color("ddd6bd"))
	root.set_meta("destruction",{"layers":layers,"mat":mat,"base":base})

static func update(root:Node3D,shelf:Dictionary,clock:float)->void:
	if not root.has_meta("destruction"):return
	var visual:Dictionary=root.get_meta("destruction")
	var damage:float=1.0-shelf.hp/shelf.max_hp
	for i in range(3):visual.layers[i].visible=damage>[.015,.34,.66][i]
	visual.mat.albedo_color=visual.base.darkened(damage*.30)
	if shelf.get("support_warning",0)>0 and not shelf.get("structural_fall",false):
		root.rotation.z+=sin(clock*48)*.018*shelf.support_warning/.32
