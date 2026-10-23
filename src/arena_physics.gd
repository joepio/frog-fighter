extends RefCounted
## Small deterministic rigid-body solver shared by headless simulation and 3D rendering.
## Positive Y is up. Rope joints only pull; loose boxes exchange linear/angular momentum.
const SUBSTEPS=3
const ITERATIONS=7

static func dynamic(body:Dictionary)->bool:return body.get("inv_mass",0.0)>0 and body.get("active",true)

static func prepare(body:Dictionary,mass:float,height:float)->void:
	body["height"]=height;body["inv_mass"]=1.0/mass
	body["inv_inertia"]=12.0/(mass*(body.width*body.width+height*height))
	body["omega"]=0.0;body["ropes"]=[]

static func velocity(body:Dictionary,point:Vector2)->Vector2:
	var r:Vector2=point-body.pos
	return body.vel+Vector2(-r.y,r.x)*body.get("omega",0.0)

static func impulse(body:Dictionary,force:Vector2,point:Vector2,wake:bool=true)->void:
	if not dynamic(body):return
	if wake and force.length_squared()>.0001:body["sleeping"]=false;body["rest_time"]=0.0
	body.vel=(body.vel+force*body.inv_mass).limit_length(25)
	body.omega=clampf(body.omega+(point-body.pos).cross(force)*body.inv_inertia,-12,12)

static func half(body:Dictionary)->Vector2:return Vector2(body.width*.5,body.get("height",.4)*.5)

static func ray(body:Dictionary,a:Vector2,b:Vector2)->Dictionary:
	# Slab intersection catches the sides of a tumbling block as well as its crown.
	var origin:Vector2=(a-body.pos).rotated(-body.angle)
	var delta:Vector2=(b-a).rotated(-body.angle)
	var extent:=half(body);var enter:=0.0;var leave:=1.0;var normal:=Vector2.ZERO
	for axis in range(2):
		if absf(delta[axis])<.00001:
			if absf(origin[axis])>extent[axis]:return {}
			continue
		var first:float=(-extent[axis]-origin[axis])/delta[axis]
		var last:float=(extent[axis]-origin[axis])/delta[axis]
		var sign_normal:float=-signf(delta[axis])
		if first>last:var swap:=first;first=last;last=swap
		if first>enter:
			enter=first;normal=Vector2.ZERO;normal[axis]=sign_normal
		leave=minf(leave,last)
		if enter>leave:return {}
	if enter<0 or enter>1:return {}
	if normal==Vector2.ZERO:normal=-delta.normalized()
	return {"point":a+(b-a)*enter,"normal":normal.rotated(body.angle)}

static func step(sim:RefCounted,dt:float)->void:
	var loose:Array=sim.platforms.filter(func(b):return b.kind=="loose" and dynamic(b))
	var moving_support:=false
	for support in sim.platforms:
		if not support.get("active",true) or not (support.kind in ["ferry","lift","swing"] or support.get("falling",false)):continue
		for b in loose:
			if absf(b.pos.x-support.pos.x)<(b.width+support.width)*.5+.2 and absf(b.pos.y-support.pos.y)<b.height*.5+.8:moving_support=true
	if moving_support or loose.any(func(b):return not b.get("sleeping",false)):
		for b in loose:b["sleeping"]=false
	if moving_support:
		for b in loose:b["rest_time"]=0.0
	var moving:Array=sim.platforms.filter(func(b):return dynamic(b) and not b.get("sleeping",false))
	var solids:Array=sim.platforms.filter(func(b):return b.get("active",true) and b.kind!="water" and not b.get("falling",false))
	var sub:float=dt/SUBSTEPS
	for tick in range(SUBSTEPS):
		for b in moving:
			b.vel.y-=22*sub;b.vel*=exp(-.12*sub);b.omega*=exp(-.35*sub)
			b.pos+=b.vel*sub;b.angle=wrapf(b.angle+b.omega*sub,-PI,PI)
		var pairs:Array=[]
		var bounds:Array=[];var order:Array=[]
		for b in solids:
			var bh:=half(b);var c:float=absf(cos(b.angle));var s:float=absf(sin(b.angle))
			bounds.append(Vector2(c*bh.x+s*bh.y,s*bh.x+c*bh.y)+Vector2(.15,.15))
			order.append(moving.find(b) if dynamic(b) and not b.get("sleeping",false) else -1)
		for i in range(moving.size()):
			var a:Dictionary=moving[i]
			var ah:=half(a);var c:float=absf(cos(a.angle));var s:float=absf(sin(a.angle))
			var bounds_a:=Vector2(c*ah.x+s*ah.y,s*ah.x+c*ah.y)
			for k in range(solids.size()):
				if order[k]>=0 and order[k]<=i:continue
				var b:Dictionary=solids[k]
				var distance:Vector2=(a.pos-b.pos).abs()
				if distance.x<bounds_a.x+bounds[k].x and distance.y<bounds_a.y+bounds[k].y:pairs.append([a,b])
		# Contact geometry (SAT and clipping) is the expensive part; build it once
		# per substep and let the iterations only exchange impulses.
		var manifolds:Array=[]
		for pair in pairs:manifolds.append(contact_manifold(pair[0],pair[1]))
		for iteration in range(ITERATIONS):
			for b in moving:
				for rope in b.ropes:solve_rope(b,rope,sub)
			for k in range(pairs.size()):
				if not manifolds[k].is_empty():solve_manifold(pairs[k][0],pairs[k][1],manifolds[k])
		for b in moving:
			if sim.walls:
				var extent:float=absf(cos(b.angle))*b.width*.5+absf(sin(b.angle))*b.height*.5
				if absf(b.pos.x)+extent>sim.half_width:
					var side:float=signf(b.pos.x);b.pos.x=side*(sim.half_width-extent)
					if b.vel.x*side>0:b.vel.x*=-.35
			if sim.safe_water and b.kind=="loose":
				var depth:float=sim.Terrain.WATER_LEVEL+b.height*.22-b.pos.y
				if depth>0:
					b.vel.y+=minf(65,depth*65)*sub;b.vel*=exp(-2.5*sub);b.omega*=exp(-3*sub)
	for b in moving:
		if b.kind=="loose" and (b.pos.y<sim.kill_y-5 or absf(b.pos.x)>sim.half_width+5):
			b.active=false;b.restore=10.0
	# Stacks jitter a little forever, so judge rest by net movement since the
	# body last moved, not only by instantaneous speed; otherwise a standing
	# tower never sleeps and keeps the solver busy all round.
	var resting:=true
	for b in loose:
		var anchor:Vector3=b.get("rest_anchor",Vector3(b.pos.x,b.pos.y,b.angle))
		if b.vel.length()>.5 or absf(b.omega)>.4 or Vector2(anchor.x,anchor.y).distance_to(b.pos)>.04 or absf(anchor.z-b.angle)>.03:
			anchor=Vector3(b.pos.x,b.pos.y,b.angle);resting=false
		b["rest_anchor"]=anchor
	for b in loose:
		b["rest_time"]=b.get("rest_time",0.0)+dt if resting else 0.0
		if b.rest_time>.8:b["sleeping"]=true;b.vel=Vector2.ZERO;b.omega=0.0
	# Lost pieces return only to a clear home; never materialize inside a player or stack.
	for b in sim.platforms:
		if b.kind!="loose" or b.active or b.get("permanent",false):continue
		b.restore-=dt
		if b.restore>0:continue
		var blocked:bool=sim.frogs.any(func(p):return p.alive and p.pos.distance_to(b.base)<b.width+1)
		var home:Dictionary=b.duplicate();home.pos=b.base;home.angle=0.0
		for other in sim.platforms:
			if is_same(other,b) or not other.get("active",true) or other.kind=="water":continue
			if intersects(home,other):blocked=true
		if blocked:b.restore=1.0;continue
		b.active=true;b.pos=b.base;b.vel=Vector2.ZERO;b.angle=0.0;b.omega=0.0;b["sleeping"]=false;b["rest_time"]=0.0

static func solve_rope(body:Dictionary,rope:Dictionary,_dt:float)->void:
	var arm:Vector2=rope.local.rotated(body.angle)
	var point:Vector2=body.pos+arm
	var delta:Vector2=point-rope.anchor;var length:float=delta.length()
	if length<.001 or length<rope.length-.002:return
	var normal:Vector2=delta/length
	var inverse:float=body.inv_mass+pow(arm.cross(normal),2)*body.inv_inertia
	var outward:float=velocity(body,point).dot(normal)
	var force:float=maxf(0,outward/inverse)
	impulse(body,-normal*force,point,false)
	var correction:float=maxf(0,length-rope.length-.001)*.65/inverse
	body.pos-=normal*correction*body.inv_mass
	body.angle-=arm.cross(normal)*correction*body.inv_inertia

static func corners(body:Dictionary)->Array:
	var h:=half(body);var out:Array=[]
	for v in [Vector2(-h.x,-h.y),Vector2(h.x,-h.y),Vector2(h.x,h.y),Vector2(-h.x,h.y)]:out.append(body.pos+v.rotated(body.angle))
	return out

static func solve_contact(a:Dictionary,b:Dictionary)->void:
	var m:=contact_manifold(a,b)
	if not m.is_empty():solve_manifold(a,b,m)

static func contact_manifold(a:Dictionary,b:Dictionary)->Dictionary:
	var av:=corners(a);var bv:=corners(b)
	var normal:=Vector2.ZERO;var overlap:=INF
	for angle in [a.angle,b.angle]:
		for axis in [Vector2.RIGHT.rotated(angle),Vector2.UP.rotated(angle)]:
			var amin:=INF;var amax:=-INF;var bmin:=INF;var bmax:=-INF
			for v in av:amin=minf(amin,v.dot(axis));amax=maxf(amax,v.dot(axis))
			for v in bv:bmin=minf(bmin,v.dot(axis));bmax=maxf(bmax,v.dot(axis))
			var depth:float=minf(amax,bmax)-maxf(amin,bmin)
			if depth<=0:return {}
			if depth<overlap:overlap=depth;normal=axis if (b.pos-a.pos).dot(axis)>0 else -axis
	if b.get("sleeping",false):b.sleeping=false;b.rest_time=0.0
	var ia:float=a.get("inv_mass",0.0);var ib:float=b.get("inv_mass",0.0)
	if ia+ib<=0:return {}
	# Clip the two convex rectangles to obtain a two-point contact manifold.
	var polygon:Array=av
	for edge in range(4):
		var start:Vector2=bv[edge];var end:Vector2=bv[(edge+1)%4]
		var output:Array=[]
		if polygon.is_empty():break
		var previous:Vector2=polygon.back();var prior:float=(end-start).cross(previous-start)
		for current in polygon:
			var distance:float=(end-start).cross(current-start)
			if (distance>=0)!=(prior>=0):output.append(previous+(current-previous)*(prior/(prior-distance)))
			if distance>=0:output.append(current)
			previous=current;prior=distance
		polygon=output
	if polygon.is_empty():return {}
	var tangent:=Vector2(-normal.y,normal.x)
	var low:Vector2=polygon[0];var high:Vector2=polygon[0]
	for v in polygon:
		if v.dot(tangent)<low.dot(tangent):low=v
		if v.dot(tangent)>high.dot(tangent):high=v
	# Arms and effective masses barely change within one substep: cache them.
	var ja:float=a.get("inv_inertia",0.0);var jb:float=b.get("inv_inertia",0.0)
	var contacts:Array=[]
	for point in [low,high]:
		var ra:Vector2=point-a.pos;var rb:Vector2=point-b.pos
		var normal_mass:float=1.0/(ia+ib+pow(ra.cross(normal),2)*ja+pow(rb.cross(normal),2)*jb)
		var tangent_mass:float=1.0/(ia+ib+pow(ra.cross(tangent),2)*ja+pow(rb.cross(tangent),2)*jb)
		contacts.append([ra,rb,normal_mass,tangent_mass])
	return {"normal":normal,"overlap":overlap,"contacts":contacts,"ia":ia,"ib":ib,"ja":ja,"jb":jb}

static func solve_manifold(a:Dictionary,b:Dictionary,m:Dictionary)->void:
	var ia:float=m.ia;var ib:float=m.ib;var ja:float=m.ja;var jb:float=m.jb
	var sum:float=ia+ib
	var normal:Vector2=m.normal;var tangent:=Vector2(-normal.y,normal.x)
	var va:Vector2=a.vel;var wa:float=a.get("omega",0.0)
	var vb:Vector2=b.get("vel",Vector2.ZERO);var wb:float=b.get("omega",0.0)
	for c in m.contacts:
		var ra:Vector2=c[0];var rb:Vector2=c[1]
		var relative:Vector2=vb+Vector2(-rb.y,rb.x)*wb-va-Vector2(-ra.y,ra.x)*wa
		var speed:float=relative.dot(normal)
		if speed>=0:continue
		var j:float=-speed*(1.15 if speed< -2 else 1.0)*c[2]
		var push:Vector2=normal*j
		va-=push*ia;wa-=ra.cross(push)*ja;vb+=push*ib;wb+=rb.cross(push)*jb
		relative=vb+Vector2(-rb.y,rb.x)*wb-va-Vector2(-ra.y,ra.x)*wa
		var friction:float=clampf(-relative.dot(tangent)*c[3],-j*.65,j*.65)
		var slide:Vector2=tangent*friction
		va-=slide*ia;wa-=ra.cross(slide)*ja;vb+=slide*ib;wb+=rb.cross(slide)*jb
	if dynamic(a):a.vel=va.limit_length(25);a.omega=clampf(wa,-12,12)
	if dynamic(b):b.vel=vb.limit_length(25);b.omega=clampf(wb,-12,12)
	# Each pass removes 55% of the overlap that remains, as a fresh SAT would.
	var depth_push:float=maxf(0,m.overlap-.003)*.55
	m.overlap-=depth_push
	var correction:Vector2=normal*depth_push/sum
	a.pos-=correction*ia;b.pos+=correction*ib

static func circle(body:Dictionary,position:Vector2,radius:float)->Dictionary:
	var local:Vector2=(position-body.pos).rotated(-body.angle);var h:=half(body)
	var nearest:=local.clamp(-h,h);var delta:=local-nearest
	if delta.length_squared()>radius*radius:return {}
	var normal:Vector2;var depth:float
	if delta.length()>.0001:normal=delta.normalized();depth=radius-delta.length()
	else:
		var gap:=h-local.abs()
		if gap.x<gap.y:normal=Vector2(1 if local.x>=0 else -1,0);depth=radius+gap.x
		else:normal=Vector2(0,1 if local.y>=0 else -1);depth=radius+gap.y
	return {"normal":normal.rotated(body.angle),"depth":depth,"point":body.pos+nearest.rotated(body.angle)}

static func intersects(a:Dictionary,b:Dictionary)->bool:
	var av:=corners(a);var bv:=corners(b)
	for angle in [a.angle,b.angle]:
		for axis in [Vector2.RIGHT.rotated(angle),Vector2.UP.rotated(angle)]:
			var amin:=INF;var amax:=-INF;var bmin:=INF;var bmax:=-INF
			for v in av:amin=minf(amin,v.dot(axis));amax=maxf(amax,v.dot(axis))
			for v in bv:bmin=minf(bmin,v.dot(axis));bmax=maxf(bmax,v.dot(axis))
			if minf(amax,bmax)-maxf(amin,bmin)<.025:return false
	return true
