extends Control
var game:Node
var serif:SystemFont
var sans:SystemFont
var bold:SystemFont
var menu:Control
var status:=""
var menu_row:=0
var held_direction:=Vector2i.ZERO
var repeat_delay:=0.0
var portraits:Dictionary={}
const CREAM=Color("f6eedb")
const MUTED=Color("bcc5ac")

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	serif=SystemFont.new();serif.font_names=PackedStringArray(["Georgia","DejaVu Serif"]);serif.font_weight=700
	sans=SystemFont.new();sans.font_names=PackedStringArray(["Segoe UI","DejaVu Sans"])
	bold=SystemFont.new();bold.font_names=sans.font_names;bold.font_weight=700

func text(value:String,p:Vector2,size_value:int,color:Color=CREAM,font:Font=null)->void:
	draw_string(sans if font==null else font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func centered(value:String,p:Vector2,size_value:int,color:Color=CREAM,font:Font=null)->void:
	var f:Font=sans if font==null else font
	text(value,p-Vector2(f.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x*.5,0),size_value,color,f)

func panel(rect:Rect2,color:Color,radius:int=14)->void:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func _draw()->void:
	if game==null or game.sim==null:return
	var s:RefCounted=game.sim
	if game.in_menu:
		panel(Rect2(70,95,500,710),Color(.045,.09,.065,.96),22)
		text("Frog Fighter",Vector2(106,168),43,CREAM,serif)
		text("Paused" if game.paused_local else "Make yourself at home.",Vector2(109,204),17,MUTED)
		text(game.Simulation.Arenas.DESCRIPTIONS[game.selected_arena],Vector2(109,723),13,MUTED)
		text("↑ ↓  Select     ← →  Change",Vector2(109,754),17,CREAM)
		text("Start / Esc resume" if game.paused_local else "Start to play",Vector2(109,781),14,MUTED)
		return
	var count:int=s.frogs.size()
	for i in range(count):
		var p:Dictionary=s.frogs[i]
		var x:float=800-count*112+i*224
		var color:=Color(p.color)
		panel(Rect2(x,20,208,53),Color(.045,.09,.065,.72),10)
		draw_circle(Vector2(x+17,37),5,color)
		text(p.name.left(12),Vector2(x+29,42),14,CREAM,bold)
		for j in range(p.get("starting_lives",3)):draw_circle(Vector2(x+140+j*11,36),3,color if j<p.lives else Color("40523e"))
		draw_rect(Rect2(x+13,54,182,3),Color("40523e"))
		draw_rect(Rect2(x+13,54,182*clampf(p.hp/100,0,1),3),color)
		if not p.alive:text("OUT",Vector2(x+13,69),10,MUTED)
		elif p.respawn>0:text("%.1f"%p.respawn,Vector2(x+13,69),10,MUTED)
		elif not p.weapon.is_empty():text("%d"%p.ammo,Vector2(x+175,69),10,MUTED)
		if not p.bot and p.alive and p.respawn<=0:
			var aim:Vector2=game.world.screen_point(p.pos+p.aim*1.4)
			draw_arc(aim,4,0,TAU,16,color,1.2,true)

	if s.mode=="survival":
		centered("Wave %d · %d left"%[s.wave,s.enemies.size()],Vector2(800,97),13,MUTED)
		for enemy in s.enemies:
			if enemy.get("kind","")!="boss":continue
			centered("BARON BEAK",Vector2(800,126),13,CREAM,bold)
			panel(Rect2(660,136,280,5),Color("344638"),3)
			panel(Rect2(660,136,280*clampf(enemy.hp/enemy.max_hp,0,1),5),Color("e9b970"),3)
			break
	if s.countdown>0:
		centered(str(ceili(s.countdown)),Vector2(800,450),90,CREAM,serif)
		centered(s.Arenas.NAMES[s.arena_id],Vector2(800,493),23,CREAM,bold)
		centered(s.Arenas.DESCRIPTIONS[s.arena_id],Vector2(800,523),16,MUTED)
	if game.celebrating:
		centered(game.last_result,Vector2(800,166),36,CREAM,bold)

func row_enabled(row:int)->bool:
	return row!=2 or (game.selected_mode=="versus" and game.human_count<4)

func menu_move(direction:Vector2i)->void:
	if direction.y!=0:
		var count:int=8 if game.paused_local else 7
		menu_row=posmod(menu_row+direction.y,count)
		if not row_enabled(menu_row):menu_row=posmod(menu_row+direction.y,count)
		make_menu()
	elif direction.x!=0 and menu_row<6:cycle_value(direction.x)

func cycle_value(direction:int)->void:
	match menu_row:
		0:game.select_mode("survival" if game.selected_mode=="versus" else "versus")
		1:game.set_players(posmod(game.human_count-1+direction,4)+1)
		2:
			if not row_enabled(2):return
			var minimum:int=1 if game.human_count==1 else 0
			var count:int=5-game.human_count-minimum
			game.set_bots(minimum+posmod(game.bot_count-minimum+direction,count))
		3:game.set_lives([1,3,5][posmod([1,3,5].find(game.round_lives)+direction,3)])
		4:
			var arenas:Array=game.Simulation.Arenas.IDS+["cycle"]
			game.set_arena(arenas[posmod(arenas.find(game.selected_arena)+direction,arenas.size())])
		5:game.set_fullscreen(not game.fullscreen)

func activate_row(row:int)->void:
	menu_row=row
	if row<6:cycle_value(1)
	elif row==6 and game.paused_local:game.resume_local()
	else:game.start_local()

func menu_input(event:InputEvent)->bool:
	var direction:=Vector2i.ZERO
	var released:=false
	if event is InputEventKey:
		if event.keycode in [KEY_ENTER,KEY_SPACE]:
			if event.pressed and not event.echo and menu_row>=6:activate_row(menu_row)
			return true
		direction={KEY_UP:Vector2i.UP,KEY_DOWN:Vector2i.DOWN,KEY_LEFT:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT}.get(event.keycode,Vector2i.ZERO)
		if direction==Vector2i.ZERO:return false
		if event.echo:return true
		released=not event.pressed
	elif event is InputEventJoypadButton:
		if event.button_index==JOY_BUTTON_A:
			if event.pressed and menu_row>=6:activate_row(menu_row)
			return true
		direction={JOY_BUTTON_DPAD_UP:Vector2i.UP,JOY_BUTTON_DPAD_DOWN:Vector2i.DOWN,JOY_BUTTON_DPAD_LEFT:Vector2i.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2i.RIGHT}.get(event.button_index,Vector2i.ZERO)
		if direction==Vector2i.ZERO:return false
		released=not event.pressed
	elif event is InputEventJoypadMotion:
		if event.axis not in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:return false
		if absf(event.axis_value)<.30:
			if (event.axis==JOY_AXIS_LEFT_X and held_direction.x!=0) or (event.axis==JOY_AXIS_LEFT_Y and held_direction.y!=0):held_direction=Vector2i.ZERO
			return true
		if absf(event.axis_value)<.60:return true
		direction=Vector2i(int(signf(event.axis_value)),0) if event.axis==JOY_AXIS_LEFT_X else Vector2i(0,int(signf(event.axis_value)))
		if direction==held_direction:return true
	else:return false
	if released:
		if direction==held_direction:held_direction=Vector2i.ZERO
	else:
		held_direction=direction;repeat_delay=.36;menu_move(direction)
	return true

func _process(dt:float)->void:
	if not game.in_menu:held_direction=Vector2i.ZERO;return
	if held_direction==Vector2i.ZERO:return
	repeat_delay-=dt
	if repeat_delay<=0:repeat_delay=.14;menu_move(held_direction)

func make_menu()->void:
	if is_instance_valid(menu):remove_child(menu);menu.queue_free()
	menu=Control.new();menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);menu.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(menu)
	menu_row=clampi(menu_row,0,7 if game.paused_local else 6)
	if not row_enabled(menu_row):menu_row=3
	var labels:Array=["Mode","Players","Bots","Lives","Level","Display","Resume" if game.paused_local else "Play"]
	var values:Array=[game.selected_mode.capitalize(),str(game.human_count),str(game.bot_count) if game.selected_mode=="versus" else "—",str(game.round_lives),game.Simulation.Arenas.NAMES[game.selected_arena],"Full screen" if game.fullscreen else "Window",""]
	if game.paused_local:labels.append("New match");values.append("")
	for row in range(labels.size()):
		var selected:bool=row==menu_row
		var enabled:bool=row_enabled(row)
		var b:=Button.new();b.position=Vector2(105,239+row*58);b.size=Vector2(430,51);b.focus_mode=Control.FOCUS_NONE
		b.set_meta("menu_key",["mode","players","bots","lives","arena","display","start","restart"][row])
		b.disabled=not enabled
		for state in ["normal","hover","pressed","disabled"]:
			var style:=StyleBoxFlat.new();style.set_corner_radius_all(9)
			style.bg_color=Color("d5ee8e") if selected else Color("23372b")
			if state=="hover" and not selected:style.bg_color=Color("3b503a")
			if selected:style.border_color=Color("f5ffda");style.set_border_width_all(2)
			b.add_theme_stylebox_override(state,style)
		b.pressed.connect(func():activate_row(row));menu.add_child(b)
		var label:=Label.new();label.position=Vector2(18,14);label.text=labels[row];label.add_theme_font_override("font",bold);label.add_theme_font_size_override("font_size",19)
		label.add_theme_color_override("font_color",Color("20311c") if selected else (CREAM if enabled else Color("72816b")));label.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(label)
		var value:=Label.new();value.position=Vector2(190,14);value.size=Vector2(222,27);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		value.text=("‹  "+values[row]+"  ›") if row<6 and enabled else values[row]
		value.add_theme_font_override("font",bold);value.add_theme_font_size_override("font_size",19);value.add_theme_color_override("font_color",Color("20311c") if selected else (CREAM if enabled else Color("72816b")));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(value)
	queue_redraw()

func hide_menu()->void:
	if is_instance_valid(menu):remove_child(menu);menu.queue_free()
	menu=null;held_direction=Vector2i.ZERO

func portrait(p:Dictionary,center:Vector2,radius:float)->void:
	draw_circle(center,radius+2,Color(p.color))
	draw_circle(center,radius,Color.from_string(str(p.get("skin_color","")),Color("eac794")))
	var payload:Variant=p.get("avatar",{})
	var cache_key:=JSON.stringify(payload)
	var entry:Dictionary=portraits.get(p.slot,{})
	if entry.get("key","")!=cache_key:
		entry={"key":cache_key,"texture":null}
		if payload is String:payload=JSON.parse_string(payload)
		if payload is Dictionary:
			var w:int=int(payload.get("w",0));var h:int=int(payload.get("h",0))
			var pixels:Variant=payload.get("px",[])
			if w in [16,32,48] and h==w and pixels is Array and pixels.size()==w*h:
				var image:=Image.create(w,h,false,Image.FORMAT_RGBA8)
				for i in range(pixels.size()):
					if pixels[i] is String:image.set_pixel(i%w,i/w,Color.from_string(pixels[i],Color.TRANSPARENT))
				entry.texture=ImageTexture.create_from_image(image)
		portraits[p.slot]=entry
	var texture:Texture2D=entry.get("texture")
	if texture!=null:
		var origin:=Vector2(24,28)
		if texture.get_width()==32:origin=Vector2(10,13)
		elif texture.get_width()==16:origin=Vector2(2,5)
		var scale_value:=radius/12
		draw_texture_rect(texture,Rect2(center-origin*scale_value,texture.get_size()*scale_value),false)
	else:
		draw_circle(center+Vector2(-3,-2),1.5,Color("263429"));draw_circle(center+Vector2(3,-2),1.5,Color("263429"))
		draw_line(center+Vector2(-3,4),center+Vector2(3,4),Color("263429"),1)
