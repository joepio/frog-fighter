extends Node3D
## Keep each enemy model alive across frames; only wings, eyes and poses animate.
var host:Node3D
var visuals:Dictionary={}

func build(world:Node3D)->void:host=world

func make_enemy(kind:String)->Dictionary:
	var root:=Node3D.new();add_child(root)
	var body:=Node3D.new();root.add_child(body)
	var skin:=Node3D.new();body.add_child(skin)
	var bird:bool=kind in ["bird","boss"]
	var color:Color={"bee":Color("edbf55"),"mosquito":Color("bc88a4"),"bird":Color("c98c60"),"boss":Color("548fab")}[kind]
	var wings:Array=[];var eyes:Array=[];var pupils:Array=[];var lids:Array=[];var brows:Array=[]
	if bird:
		host.ball(skin,Vector3(0,-.07,0),Vector3(.34,.40,.27),color)
		host.ball(skin,Vector3(0,-.11,.21),Vector3(.25,.30,.09),Color("efcf96") if kind=="bird" else Color("f4dca6"))
		host.ball(skin,Vector3(0,.23,.025),Vector3(.32,.29,.27),color)
		for i in range(3):
			var tuft:MeshInstance3D=host.ball(skin,Vector3((i-1)*.10,.49+(.04 if i==1 else 0),-.02),Vector3(.063,.16,.065),color.darkened(.2));tuft.rotation.z=(i-1)*-.25
			var tail:MeshInstance3D=host.ball(skin,Vector3((i-1)*.11,-.39,-.18),Vector3(.07,.22,.07),color.darkened(.23));tail.rotation.z=(i-1)*-.24
		for side in [-1,1]:
			host.tube(skin,Vector3(side*.14,-.37,.02),Vector3(side*.17,-.48,.12),.028,Color("bf965a"))
			for toe in range(3):host.tube(skin,Vector3(side*.17,-.48,.12),Vector3(side*.17+(toe-1)*.065,-.49,.22),.018,Color("d6ac67"))
	else:
		host.ball(skin,Vector3(0,-.05,-.015),Vector3(.28,.32,.23) if kind=="bee" else Vector3(.17,.32,.18),color)
		host.ball(skin,Vector3(0,.22,.05),Vector3(.28,.24,.24),color)
		if kind=="bee":
			for y in [-.08,-.23]:host.ball(skin,Vector3(0,y,.02),Vector3(.265,.052,.225),Color("574736"))
		else:
			host.ball(skin,Vector3(0,-.30,-.02),Vector3(.11,.20,.12),Color("9a5d7c"))
		for side in [-1,1]:
			host.tube(skin,Vector3(side*.14,.39,.03),Vector3(side*.23,.60,.025),.018,Color("655048"))
			host.ball(skin,Vector3(side*.23,.60,.025),Vector3.ONE*.041,color.darkened(.28))
			for leg in range(3):
				var y:float=-.03-leg*.1
				host.tube(skin,Vector3(side*.17,y,0),Vector3(side*(.32+leg*.025),y-.15,.08),.014,Color("6f5457"))
	for side in [-1,1]:
		var wing:=Node3D.new();body.add_child(wing);wing.position=Vector3(side*.23,.04,-.10);wings.append(wing)
		if bird:
			host.ball(wing,Vector3(side*.24,0,0),Vector3(.31,.13,.11),color.darkened(.07))
			for feather in range(4):
				var part:MeshInstance3D=host.ball(wing,Vector3(side*(.24+feather*.10),-.08-feather*.03,.015),Vector3(.095,.20,.055),color.lightened(.06*feather));part.rotation.z=side*-.5
		else:
			for pair in range(2):
				var part:MeshInstance3D=host.ball(wing,Vector3(side*(.20+pair*.06),.10-pair*.16,0),Vector3(.32,.095,.055),Color("e2edce"));part.rotation.z=side*(.3-pair*.6)
		var eye:MeshInstance3D=host.ball(body,Vector3(side*.14,.27,.245),Vector3(.13,.16,.085),Color("fff2d6"));eyes.append(eye)
		var pupil:=Node3D.new();body.add_child(pupil);pupil.position=Vector3(side*.14,.27,.32);pupils.append(pupil)
		host.ball(pupil,Vector3.ZERO,Vector3(.057,.081,.022),Color("29342c"))
		host.ball(pupil,Vector3(.017,.034,.02),Vector3(.018,.021,.009),Color.WHITE)
		var lid:=Node3D.new();body.add_child(lid);lid.position=Vector3(side*.14,.27,.32);lids.append(lid)
		host.ball(lid,Vector3.ZERO,Vector3(.14,.045,.045),color)
		host.tube(lid,Vector3(-.085,0,.04),Vector3(.085,0,.04),.009,color.darkened(.45))
		var brow:=Node3D.new();body.add_child(brow);brow.position=Vector3(side*.14,.39,.31);brows.append(brow)
		host.ball(brow,Vector3.ZERO,Vector3(.145,.038,.045),color.darkened(.15));brow.rotation.z=side*.28
	var mouth:=Node3D.new();body.add_child(mouth);mouth.position=Vector3(0,.10,.27)
	if bird:
		var beak:=PrismMesh.new();beak.size=Vector3(.22,.14,.26)
		host.mesh(mouth,beak,Vector3(0,0,.085),Vector3.ONE,host.material(Color("e1a24d")))
		host.ball(mouth,Vector3(0,-.045,.06),Vector3(.10,.045,.11),Color("ac7038"))
	elif kind=="mosquito":
		host.tube(mouth,Vector3(0,0,0),Vector3(0,-.20,.19),.026,Color("72546c"))
		host.ball(mouth,Vector3(0,-.21,.20),Vector3(.041,.038,.036),Color("d58c9e"))
	else:
		host.tube(mouth,Vector3(-.07,0,.015),Vector3(0,-.022,.025),.009,Color("74523e"))
		host.tube(mouth,Vector3(0,-.022,.025),Vector3(.07,0,.015),.009,Color("74523e"))
	host.Scenery.batch_static(skin)
	var meshes:Array=[];host.collect_skin(body,meshes,null)
	var flash:=ShaderMaterial.new();flash.shader=load("res://src/hit_flash.gdshader");flash.set_shader_parameter("strength",0.0)
	var size:float={"bee":.80,"mosquito":.66,"bird":1.0,"boss":2.65}[kind]
	root.scale=Vector3.ONE*size
	var burning:=preload("res://src/burning.gd").new();root.add_child(burning);burning.build(host)
	return {"root":root,"body":body,"burning":burning,"wings":wings,"eyes":eyes,"pupils":pupils,"lids":lids,"brows":brows,"mouth":mouth,"flash":flash,"meshes":meshes,"flashing":false,"kind":kind}

func update(sim:RefCounted)->void:
	var living:Dictionary={}
	for i in range(sim.enemies.size()):
		var enemy:Dictionary=sim.enemies[i];var id:int=enemy.get("id",100000+i)
		living[id]=true
		if not visuals.has(id):visuals[id]=make_enemy(enemy.get("kind","bee"))
		var v:Dictionary=visuals[id];var kind:String=v.kind
		var phase:float=sim.clock+enemy.phase
		var velocity:Vector2=enemy.get("vel",Vector2.ZERO)
		var state:String=enemy.get("state","approach")
		var windup:bool=state=="windup";var striking:bool=state=="strike"
		var blink:bool=enemy.get("flash",0.0)>.06 or fposmod(phase,3.7)<.095
		v.root.position=Vector3(enemy.pos.x,enemy.pos.y,.43)
		v.burning.update({"burn":enemy.get("burn",0.0),"alive":enemy.hp>0,"respawn":0.0,"vel":velocity},sim.fx_clock)
		v.body.rotation.z=clampf(-velocity.x*.025,-.32,.32)
		v.body.rotation.y=enemy.get("look",Vector2.ZERO).x*.20
		v.body.scale=Vector3(1.10,.87,1.0) if windup else (Vector3(.91,1.10,1) if striking else Vector3.ONE)
		v.mouth.rotation.x=-.25 if windup else 0.0
		for side_index in range(2):
			var side:float=-1 if side_index==0 else 1
			var speed:float={"bee":42.0,"mosquito":55.0,"bird":17.0,"boss":8.5}[kind]
			v.wings[side_index].rotation.z=side*(.95 if windup else sin(phase*speed)*(.48 if kind in ["bee","mosquito"] else .85))
			v.eyes[side_index].visible=not blink;v.pupils[side_index].visible=not blink;v.lids[side_index].visible=blink
			v.brows[side_index].visible=(windup or striking or enemy.get("enraged",false)) and not blink
			var look:Vector2=enemy.get("look",Vector2.ZERO)
			v.pupils[side_index].position=Vector3(side*.14+look.x*.022,.27+look.y*.026,.32)
		var hit:bool=enemy.get("flash",0.0)>0
		if hit!=v.flashing:
			for part in v.meshes:part.material_overlay=v.flash if hit else null
			v.flashing=hit
		v.flash.set_shader_parameter("strength",clampf(enemy.get("flash",0.0)*5,0,.65))
	for id in visuals.keys():
		if not living.has(id):visuals[id].root.queue_free();visuals.erase(id)
