extends RefCounted
## One declaration is shared by the host, assistant and gameplay validation.
var SPECS = [
  {
    "key": "mode",
    "label": "Mode (next round)",
    "kind": "choice",
    "default": "versus",
    "options": [
      "versus",
      "survival"
    ]
  },
  {
    "key": "arena",
    "label": "Arena (next round)",
    "kind": "choice",
    "default": "terrarium",
    "options": preload("res://src/arenas.gd").IDS + ["cycle"]
  },
  {
    "key": "lives",
    "label": "Lives (next round)",
    "kind": "number",
    "default": 3,
    "min": 1,
    "max": 9
  },
  {
    "key": "run_speed",
    "label": "Running speed % (live)",
    "kind": "number",
    "default": 100,
    "min": 50,
    "max": 150
  },
  {
    "key": "jump_height",
    "label": "Jump impulse % (next jump)",
    "kind": "number",
    "default": 100,
    "min": 50,
    "max": 125
  },
  {
    "key": "gravity",
    "label": "Frog gravity % (live)",
    "kind": "number",
    "default": 100,
    "min": 25,
    "max": 175
  },
  {
    "key": "damage",
    "label": "Combat damage % (next hit)",
    "kind": "number",
    "default": 100,
    "min": 50,
    "max": 200
  },
  {
    "key": "pickup_seconds",
    "label": "Supply interval, s (next supply)",
    "kind": "number",
    "default": 4,
    "min": 1,
    "max": 12
  },
  {
    "key": "bot_reaction",
    "label": "Bot reaction delay % (next aim)",
    "kind": "number",
    "default": 100,
    "min": 50,
    "max": 200
  }
]
var values: Dictionary = {}

func _init() -> void:
	for spec in SPECS: values[spec.key] = spec.default

func change(key: String, value: Variant) -> bool:
	for spec in SPECS:
		if spec.key != key: continue
		match spec.kind:
			"number":
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT]: return false
				if not is_finite(float(value)) or float(value) != floor(float(value)): return false
				if value < spec.min or value > spec.max: return false
				value = int(value)
			"choice":
				if not value is String or value not in spec.options: return false
			"toggle":
				if not value is bool: return false
		values[key] = value
		write_probe()
		return true
	return false

func apply_live(sim: RefCounted) -> void:
	for key in ["run_speed", "jump_height", "gravity", "damage", "bot_reaction"]:
		sim.set(key, values[key] / 100.0)
	sim.pickup_seconds = values.pickup_seconds


func write_probe() -> void:
	# Opt-in observation for real-host integration tests. No player data.
	var path := OS.get_environment("GAMENIGHT_SETTINGS_PROBE")
	if path.is_empty(): return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"settings": values}))
