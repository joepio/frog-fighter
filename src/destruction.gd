extends RefCounted
const TYPES={"timber":96.0,"barricade":96.0,"masonry":180.0,"pier":200.0}
const DEBRIS_LIMIT=16
static func configure(shelf:Dictionary)->void:
	if not TYPES.has(shelf.kind):return
	shelf["max_hp"]=TYPES[shelf.kind];shelf["hp"]=shelf.max_hp
	shelf["material"]="stone" if shelf.kind in ["masonry","pier"] else "wood"
	shelf["height"]=shelf.get("height",.4)
	shelf["permanent"]=true;shelf["supports"]=shelf.get("supports",[]);shelf["support_warning"]=0.0

static func initialize(sim:RefCounted)->void:
	# A few optional old-map perches also gain destructible surfaces.
	var upgrades:Array={"reed_delta":[[9,"timber"]],"sky_ruins":[[10,"masonry"]],"deadfall":[[11,"timber"]]}.get(sim.arena_id,[])
	for item in upgrades:sim.platforms[item[0]].kind=item[1];configure(sim.platforms[item[0]])
	if not sim.platforms.any(func(s):return s.get("max_hp",0)>0):return
	for i in range(DEBRIS_LIMIT):
		var body:Dictionary=sim.platform(Vector2(0,-100),1,"loose")
		sim.Physics.prepare(body,1.5,.4)
		body.merge({"active":false,"rubble":true,"permanent":true,"debris_life":0.0,"material":"stone" if sim.theme=="ruins" else "wood"},true)
		sim.platforms.append(body)

static func damage(sim:RefCounted,shelf:Dictionary,amount:float,_point:Vector2,force:Vector2,weapon:String)->void:
	if not sim.usable(shelf) or shelf.get("max_hp",0)<=0:return
	# Timber scorches under flame; masonry requires solid hits or explosives.
	if weapon=="flame":amount*=.8 if shelf.material=="wood" else .06
	shelf.hp=maxf(0,shelf.hp-amount)
	if shelf.hp>0:return
	shelf.active=false;shelf["destroyed"]=true;shelf["permanent"]=true
	for frog in sim.frogs:
		if frog.ground==sim.platforms.find(shelf):frog.ground=-1;frog.coyote=.10
		if not frog.anchor.is_empty() and frog.anchor.platform==sim.platforms.find(shelf):frog.anchor={}
	var vertical:bool=shelf.height>shelf.width
	var count:int=clampi(int(ceil(maxf(shelf.width,shelf.height)/1.5)),2,4)
	for i in range(count):
		var offset:float=((i+.5)/count-.5)*(shelf.height if vertical else shelf.width)
		var pos:Vector2=shelf.pos+(Vector2(0,offset) if vertical else Vector2(offset,0)).rotated(shelf.angle)
		var available:Array=sim.platforms.filter(func(b):return b.get("rubble",false) and not b.active)
		if not available.is_empty():
			var body:Dictionary=available[0]
			body.width=shelf.width*.82 if vertical else shelf.width/count*.82
			var height:float=shelf.height/count*.75 if vertical else shelf.height*.8
			sim.Physics.prepare(body,1.4 if shelf.material=="wood" else 2.2,height)
			body.pos=pos;body.base=pos;body.active=true;body.angle=shelf.angle+sim.rng.randf_range(-.22,.22)
			body.vel=shelf.vel+force*.08+Vector2(sim.rng.randf_range(-3,3),sim.rng.randf_range(1,4));body.omega=sim.rng.randf_range(-5,5)
			body["sleeping"]=false;body["rest_time"]=0.0;body.debris_life=8.0
			sim.add_fx("terrain_dust",pos,Vector2(sim.rng.randf_range(-1,1),.4),.85,shelf.material)
	# Wake resting stacks even when every fragment slot is occupied.
	for body in sim.platforms:
		if body.kind=="loose" and body.active:body["sleeping"]=false;body["rest_time"]=0.0
	sim.trauma=maxf(sim.trauma,.25);sim.events.append("structure_broken")

static func update(sim:RefCounted,dt:float)->void:
	for shelf in sim.platforms:
		if not sim.usable(shelf):continue
		if shelf.get("rubble",false):
			shelf.debris_life-=dt
			if shelf.debris_life<=0:shelf.active=false
			continue
		if shelf.get("max_hp",0)<=0 or shelf.get("structural_fall",false):continue
		var supports:Array=shelf.get("supports",[])
		if supports.is_empty():continue
		var unsupported:bool=supports.all(func(i):return not sim.usable(sim.platforms[i]) or sim.platforms[i].get("structural_fall",false))
		if not unsupported:shelf.support_warning=0.0;continue
		# A support already in free fall cannot suspend its children for another warning.
		var carried_down:bool=supports.any(func(i):return sim.platforms[i].get("structural_fall",false))
		shelf.support_warning=.32 if carried_down else shelf.support_warning+dt
		if shelf.support_warning<.32:continue
		# Unsupported sections become real falling bodies, preserving their damage.
		shelf["structural_fall"]=true;shelf.kind="loose"
		sim.Physics.prepare(shelf,5.0 if shelf.material=="wood" else 8.0,shelf.height)
		shelf.vel=Vector2(sim.rng.randf_range(-.7,.7),-.5);shelf.omega=sim.rng.randf_range(-.15,.15)
		sim.events.append("support_collapse")
