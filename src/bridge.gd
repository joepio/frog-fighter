extends "res://addons/gamenight/gamenight.gd"
## The vendored SDK provides transport and the session lifecycle. This adapter
## adds host input by controller token and no focus-driven transitions.
var frames: Dictionary = {}
var frame_at := -10000
var connected_at := 0

func _ready() -> void:
	game_id = "frog-fighter"
	launched_by_daemon = OS.get_environment("GAMENIGHT") == "1"
	auto_reconnect = false
	connected_at = Time.get_ticks_msec()
	if launched_by_daemon:
		super._ready()

func _process(delta: float) -> void:
	if not launched_by_daemon:
		return
	super._process(delta)
	if _socket == null or (not _said_hello and Time.get_ticks_msec() - connected_at > 10000):
		get_tree().quit()

func _unhandled_input(_event: InputEvent) -> void:
	pass # Main owns a release-gated Back action, including authoritative host input.

func _handle(msg: Variant) -> void:
	if not msg is Dictionary:
		return
	var kind: String = msg.get("type", "")
	if kind == "welcome" and msg.get("protocol_version", 0) != 1:
		get_tree().quit(1)
		return
	if kind == "controller_frame":
		# Menus read controllers by token before a match runs, so keep every frame.
		frames.clear()
		frame_at = Time.get_ticks_msec()
		for frame in msg.get("controllers", []):
			var token: String = frame.get("controller", "")
			if not token.is_empty() and not frames.has(token):
				frames[token] = frame
	elif kind == "dispose" and not session.is_empty() and msg.get("session", "") == session:
		frames.clear()
	super._handle(msg)

func ready_for_session(value: String) -> void:
	if session != value or phase != "preparing":
		return
	_send({"type": "participation", "session": session, "instant_join": false})
	notify_ready(session)

func frame(token: String) -> Dictionary:
	if Time.get_ticks_msec() - frame_at >= 250:
		return {}
	return frames.get(token, {})

static func pressed(value: Dictionary, index: int) -> bool:
	return (int(value.get("buttons", 0)) & (1 << index)) != 0

static func axis(value: Dictionary, index: int) -> float:
	var axes: Array = value.get("axes", [])
	return clampf(float(axes[index]) / 32767, -1, 1) if axes.size() > index else 0.0

