extends SceneTree
const Settings = preload("res://src/settings.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func validate(settings: RefCounted) -> void:
	for spec in settings.SPECS:
		var invalid: Array = [null, {}, []]
		if spec.kind == "number":
			check(settings.change(spec.key, float(spec.min)), "JSON integral numbers accepted")
			check(settings.change(spec.key, spec.max), "Upper boundary accepted")
			invalid += [true, "10", 1.5, INF, NAN, spec.min-1, spec.max+1]
		elif spec.kind == "choice":
			for option in spec.options: check(settings.change(spec.key,option),"Choice accepted")
			invalid += ["unknown", 1, false]
		else:
			check(settings.change(spec.key, not spec.default), "Toggle accepted")
			invalid += ["false", 0, 1]
		check(settings.change(spec.key, spec.default), "Reset accepted")
		for value in invalid:
			check(not settings.change(spec.key,value), "Invalid value rejected: "+spec.key)
			check(settings.values[spec.key] == spec.default, "Invalid update preserves value")
	check(not settings.change("controller_id", 1), "Roster cannot be changed via settings")
func finish(settings: RefCounted) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--settings-output="):
			var file = FileAccess.open(arg.trim_prefix("--settings-output="), FileAccess.WRITE)
			file.store_string(JSON.stringify(settings.SPECS))
	print("SETTINGS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

const Sim = preload("res://src/simulation.gd")
func run() -> void:
	var settings = Settings.new()
	validate(settings)
	var a=Sim.new([{"slot":0},{"slot":1}],"versus",17)
	var b=Sim.new([{"slot":0},{"slot":1}],"versus",17)
	a.countdown=0;b.countdown=0
	for i in 120:a.step(1./120,[{},{}]);b.step(1./120,[{},{}])
	settings.change("jump_height",125);settings.apply_live(b)
	a.step(1./120,[{"jump":true},{}]);b.step(1./120,[{"jump":true},{}])
	check(b.frogs[0].vel.y>a.frogs[0].vel.y,"Higher jump changes actual impulse")
	var p:Dictionary=b.frogs[1];p.invincible=0;p.hp=100
	settings.change("damage",150);settings.apply_live(b)
	b.hurt(p,20,Vector2.ZERO)
	check(p.hp==70,"Damage multiplier reaches combat")
	settings.change("lives",7);settings.apply_live(b)
	check(p.lives==3,"Lives are not reset mid-round")
	settings.change("gravity",25);settings.apply_live(b)
	a.frogs[0].vel=Vector2.ZERO;b.frogs[0].vel=Vector2.ZERO
	a.frogs[0].pos=Vector2(0,10);b.frogs[0].pos=Vector2(0,10)
	a.step(.01,[{},{}]);b.step(.01,[{},{}])
	check(b.frogs[0].vel.y>a.frogs[0].vel.y,"Reduced gravity changes fall")
	finish(settings)
