extends RefCounted
const CLASSIC_IDS=["terrarium","vineway","canopy","floodplain"]
const EXPANSION_IDS=["reed_delta","sky_ruins","deadfall","grotto"]
const DESTRUCTION_IDS=["beaver_dam","shatter_spire"]
const IDS=CLASSIC_IDS+EXPANSION_IDS+DESTRUCTION_IDS
const NAMES={"terrarium":"Terrarium","vineway":"Vineway","canopy":"Canopy","floodplain":"Floodplain","cycle":"Tour","reed_delta":"Reed Delta","sky_ruins":"Sky Ruins","deadfall":"Deadfall","grotto":"Glow Grotto","beaver_dam":"Beaver Dam","shatter_spire":"Shatter Spire"}
const DESCRIPTIONS={"terrarium":"Tilting timber and familiar garden perches.","vineway":"Long swings across a wide, open middle.","canopy":"Climb the treetops using a rising platform.","floodplain":"Moving ferries above a wide stretch of water.","cycle":"A different arena after each match.","reed_delta":"Wide river, safe water, long crossing routes.","sky_ruins":"Open edges. The chasm below is lethal.","deadfall":"Open edges. Cracked bridges collapse. Lethal fall.","grotto":"Safe pond. Violet mushroom caps crumble.","beaver_dam":"Blast through timber gates. Break the dam roof supports. Safe water.","shatter_spire":"Crack the stone piers. Collapse the central tower. Lethal fall."}

static func rules(id:String)->Dictionary:
	match id:
		"beaver_dam":return {"width":34.0,"height":21.0,"walls":true,"roof":true,"bottom":"water","theme":"reeds"}
		"shatter_spire":return {"width":34.0,"height":24.0,"walls":false,"roof":false,"bottom":"chasm","theme":"ruins"}
		"reed_delta":return {"width":42.0,"height":22.0,"walls":true,"roof":true,"bottom":"water","theme":"reeds"}
		"sky_ruins":return {"width":36.0,"height":25.0,"walls":false,"roof":false,"bottom":"chasm","theme":"ruins"}
		"deadfall":return {"width":34.0,"height":21.0,"walls":false,"roof":false,"bottom":"chasm","theme":"autumn"}
		"grotto":return {"width":32.0,"height":24.0,"walls":true,"roof":true,"bottom":"water","theme":"mushrooms"}
	return {"width":28.0,"height":16.0,"walls":true,"roof":true,"bottom":"water","theme":"garden"}

static func layout(id:String)->Dictionary:
	match id:
		"beaver_dam":return {
			"platforms":[[-13,3,5,"fixed"],[13,3,5,"fixed"],[-12,12,4,"fixed"],[12,12,4,"fixed"],
			[0,2.2,8,"fixed"],[-3.3,4.5,.8,"barricade",{"height":4.2}],[3.3,4.5,.8,"barricade",{"height":4.2}],
			[0,6.8,7.4,"timber",{"supports":[5,6]}],[-8,6.4,3.4,"timber"],[8,6.4,3.4,"timber"],
			[-5,10.1,3.6,"timber"],[5,10.1,3.6,"timber"],[-5,15,4,"timber"],[5,15,4,"timber"],
			[0,18.3,5,"timber"],[-10,18.4,3,"fixed"],[10,18.4,3,"fixed"]],
			"spawns":[Vector2(-13,3.7),Vector2(13,3.7),Vector2(-12,12.7),Vector2(12,12.7)],
			"hooks":[Vector2(-8,10),Vector2(8,10),Vector2(-4,17.5),Vector2(4,17.5),Vector2(0,20)],
			"crates":[],"bonus":[],
			"weapons":[[-11.7,4,"seed"],[11.7,4,"seed"],[-10.8,13,"acorn"],[10.8,13,"acorn"],[-8,7.6,"bramble"],[8,7.6,"flame"],[0,3.4,"grenade"],[0,19.5,"rail"]]}
		"shatter_spire":return {
			"platforms":[[-13,4,5,"fixed"],[13,4,5,"fixed"],[-12,13,4,"fixed"],[12,13,4,"fixed"],
			[-3.2,4,3,"fixed"],[3.2,4,3,"fixed"],[0,3,3,"fixed"],
			[-3.2,6.8,1.15,"pier",{"height":4.8}],[3.2,6.8,1.15,"pier",{"height":4.8}],
			[0,9.4,8,"masonry",{"supports":[7,8]}],
			[0,12.1,1.15,"pier",{"height":5.0,"supports":[9]}],
			[0,14.8,7,"masonry",{"supports":[10]}],
			[0,17.2,1.0,"pier",{"height":4.4,"supports":[11]}],
			[0,19.6,5,"masonry",{"supports":[12]}],
			[-8,8.5,3,"fixed"],[8,8.5,3,"fixed"],[-7,20.5,3,"fixed"],[7,20.5,3,"fixed"]],
			"spawns":[Vector2(-13,4.7),Vector2(13,4.7),Vector2(-12,13.7),Vector2(12,13.7)],
			"hooks":[Vector2(-8,11.8),Vector2(8,11.8),Vector2(-7,17.8),Vector2(7,17.8)],
			"crates":[],"bonus":[],
			"weapons":[[-11.7,5,"acorn"],[11.7,5,"acorn"],[-10.8,14,"seed"],[10.8,14,"seed"],[8,9.7,"bramble"],[0,16,"flame"],[0,4.2,"grenade"],[0,20.8,"rail"]]}

		"reed_delta":return {
			"platforms":[[-17,3,6,"fixed"],[17,3,6,"fixed"],[-17,12,5,"fixed"],[17,12,5,"fixed"],[-8,6.5,4,"ferry"],[8,6.5,4,"ferry"],[0,5,4,"fixed"],[-8,13.5,4,"swing"],[8,13.5,4,"swing"],[0,14.5,4,"fixed"],[-14,18.5,4,"fixed"],[14,18.5,4,"fixed"],[0,20,5,"fixed"],[-4,9.5,2.8,"fixed"],[4,9.5,2.8,"fixed"]],
			"spawns":[Vector2(-17,3.7),Vector2(17,3.7),Vector2(-17,12.7),Vector2(17,12.7)],
			"hooks":[Vector2(-12,10),Vector2(12,10),Vector2(-4.5,11),Vector2(4.5,11),Vector2(-6,19),Vector2(6,19)],
			"crates":[Vector2(-18.8,4.4),Vector2(18.8,4.4)],"bonus":[],
			"weapons":[[-15.6,4,"seed"],[15.6,4,"seed"],[-15.7,13,"bramble"],[15.7,13,"bramble"],[-8,7.7,"acorn"],[8,7.7,"flame"],[0,15.7,"rail"],[0,6.2,"grenade"]]}
		"sky_ruins":return {
			"platforms":[[-14,5.5,5,"fixed"],[14,5.5,5,"fixed"],[-12,14.5,4,"fixed"],[12,14.5,4,"fixed"],[-7,8.5,3,"fixed"],[7,8.5,3,"fixed"],[0,5.8,3.5,"fixed"],[0,12.5,4,"fixed"],[-6,18,3,"fixed"],[6,18,3,"fixed"],[0,22.5,4,"fixed"],[-12,20.5,2.6,"crumble"],[12,20.5,2.6,"crumble"]],
			"spawns":[Vector2(-14,6.2),Vector2(14,6.2),Vector2(-12,15.2),Vector2(12,15.2)],
			"hooks":[Vector2(-10,11.8),Vector2(10,11.8),Vector2(-4,16),Vector2(4,16),Vector2(0,19.6)],
			"crates":[Vector2(-15.7,7),Vector2(15.7,7)],"bonus":[],
			"weapons":[[-12.6,6.5,"acorn"],[12.6,6.5,"acorn"],[-10.9,15.5,"seed"],[10.9,15.5,"seed"],[0,23.5,"rail"],[0,13.5,"grenade"],[-7,9.5,"bramble"],[7,9.5,"flame"]]}
		"deadfall":return {
			"platforms":[[-13,5,5,"fixed"],[13,5,5,"fixed"],[-12,13,4,"fixed"],[12,13,4,"fixed"],[-8,7,3.8,"crumble"],[-4,7,3.8,"crumble"],[0,7,3.8,"crumble"],[4,7,3.8,"crumble"],[8,7,3.8,"crumble"],[-6,11.5,3,"crumble"],[6,11.5,3,"crumble"],[0,16,4,"fixed"],[-7,18.5,3,"fixed"],[7,18.5,3,"fixed"]],
			"spawns":[Vector2(-13,5.7),Vector2(13,5.7),Vector2(-12,13.7),Vector2(12,13.7)],
			"hooks":[Vector2(-9,16),Vector2(9,16),Vector2(0,12),Vector2(-3.5,18),Vector2(3.5,18)],
			"crates":[Vector2(-14.6,6.4),Vector2(14.6,6.4)],"bonus":[],
			"weapons":[[-11.7,6,"bramble"],[11.7,6,"bramble"],[-10.9,14,"acorn"],[10.9,14,"acorn"],[0,8.1,"grenade"],[.28,18.6,"flame"],[-7,19.5,"rail"],[7,19.5,"seed"]]}
		"grotto":return {
			"platforms":[[-12,3,5,"fixed"],[12,3,5,"fixed"],[-11,12,4,"fixed"],[11,12,4,"fixed"],[-5,7,4,"crumble"],[5,7,4,"crumble"],[0,10.5,4,"fixed"],[-5,16,3.5,"crumble"],[5,16,3.5,"crumble"],[0,21.5,4,"fixed"],[-12,20,3.5,"fixed"],[12,20,3.5,"fixed"],[0,3.5,3,"ferry"]],
			"spawns":[Vector2(-12,3.7),Vector2(12,3.7),Vector2(-11,12.7),Vector2(11,12.7)],
			"hooks":[Vector2(-8,10),Vector2(8,10),Vector2(0,7),Vector2(-3,19),Vector2(3,19)],
			"crates":[],"bonus":[],
			"weapons":[[-10.7,4,"bramble"],[10.7,4,"bramble"],[-9.9,13,"seed"],[9.9,13,"seed"],[0,11.5,"flame"],[0,22.5,"rail"],[-5,8.2,"grenade"],[5,8.2,"acorn"]]}
		"vineway":return {
			"platforms":[[-11,2.5,4,"fixed"],[11,2.5,4,"fixed"],[-10,9.5,3.2,"fixed"],[10,9.5,3.2,"fixed"],[-4.5,5.5,3,"swing"],[4.5,5.5,3,"swing"],[0,11.8,3,"swing"],[-7,13.8,3,"fixed"],[7,13.8,3,"fixed"]],
			"spawns":[Vector2(-11,3.2),Vector2(11,3.2),Vector2(-10,10.2),Vector2(10,10.2)],
			"hooks":[Vector2(-6.8,9),Vector2(0,8.7),Vector2(6.8,9),Vector2(-3.8,13.5),Vector2(3.8,13.5)],
			"crates":[Vector2(-11.8,4),Vector2(11.8,4)],"bonus":[Vector2(-4.5,6.7),Vector2(4.5,6.7)]}
		"canopy":return {
			"platforms":[[-11,2.5,4,"fixed"],[11,2.5,4,"fixed"],[-9,7.1,3.8,"fixed"],[9,7.1,3.8,"fixed"],[-3.8,5.5,2.7,"swing"],[3.8,10.2,2.7,"swing"],[-7,12.3,3,"fixed"],[7,12.3,3,"fixed"],[0,14.4,4,"fixed"],[0,8,2.2,"lift"]],
			"spawns":[Vector2(-11,3.2),Vector2(11,3.2),Vector2(-9,7.8),Vector2(9,7.8)],
			"hooks":[Vector2(-11,11.5),Vector2(-3.2,11.8),Vector2(4.5,7.8),Vector2(11,11.5)],
			"crates":[Vector2(-9.7,8.4),Vector2(9.7,8.4)],"bonus":[Vector2(-3.8,6.6),Vector2(3.8,11.3)]}
		"floodplain":return {
			"platforms":[[-10.5,2.4,5,"fixed"],[10.5,2.4,5,"fixed"],[-9,10,3.2,"fixed"],[9,10,3.2,"fixed"],[-5.8,5.6,3.6,"ferry"],[5.8,7.7,3.6,"ferry"],[0,12.8,3.5,"swing"],[-6,14.1,2.5,"fixed"],[6,14.1,2.5,"fixed"]],
			"spawns":[Vector2(-10.5,3.1),Vector2(10.5,3.1),Vector2(-9,10.7),Vector2(9,10.7)],
			"hooks":[Vector2(-6.5,8.5),Vector2(0,9.5),Vector2(6.5,10.7)],
			"crates":[Vector2(-11.5,3.8),Vector2(11.5,3.8)],"bonus":[Vector2(-5.8,6.8),Vector2(5.8,8.9)]}
	return {
		"platforms":[[-10,2.3,6,"fixed"],[10,2.3,6,"fixed"],[0,4.7,9,"seesaw"],[-8,7.5,5,"fixed"],[8,7.5,5,"fixed"],[-5,11.3,4,"swing"],[5,11.3,4,"swing"],[0,14.7,7,"fixed"]],
		"spawns":[Vector2(-10,3.8),Vector2(10,3.8),Vector2(-7,9),Vector2(7,9)],"hooks":[],
		"crates":[Vector2(-3,6.5),Vector2(3,6.5)],"bonus":[Vector2(-2.4,5.8),Vector2(2.4,5.8)]}

# Each toy stack has two supports and an offset crosspiece. Gaps invite tongue pulls.
static func stacks(id:String)->Array:
	var sites:Array=[]
	match id:
		"reed_delta":sites=[[-14,18.7,"wood"],[14,18.7,"wood"]]
		"sky_ruins":sites=[[-6,18.2,"stone"],[6,18.2,"stone"]]
		"deadfall":sites=[[0,16.2,"wood"]]
		"grotto":sites=[[-12,20.2,"stone"],[12,20.2,"stone"]]
	var result:Array=[]
	for site in sites:
		result.append({"x":site[0],"y":site[1],"material":site[2],"pieces":[[-.72,.43,.95,.85],[.72,.43,.95,.85],[0,1.10,2.45,.48],[.08,1.71,.85,.72]]})
	return result

static func burr_site(id:String)->Array:
	return {"terrarium":[0,5.8,"burr"],"vineway":[0,13,"burr"],"canopy":[0,15.6,"burr"],"floodplain":[0,14,"burr"],"reed_delta":[0,21.2,"burr"],"sky_ruins":[0,7,"burr"],"deadfall":[-4,8.2,"burr"],"grotto":[0,4.7,"burr"],"beaver_dam":[0,8,"burr"],"shatter_spire":[-8,9.7,"burr"]}.get(id,[0,5.8,"burr"])
