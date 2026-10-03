extends SceneTree
const Sim=preload("res://src/simulation.gd")
const World=preload("res://src/world.gd")
var failures:=0
var checks:=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var config_path:="user://pond.cfg"
 var saved_config:String=FileAccess.get_file_as_string(config_path) if FileAccess.file_exists(config_path) else ""
 var roster:Array=[{"slot":0,"name":"Moss"},{"slot":1,"name":"Ripple"}]
 var s:=Sim.new(roster)
 var p:Dictionary=s.frogs[0];var origin:Vector2=p.pos
 p.weapon="rail";p.ammo=3
 for direction in [Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2.RIGHT]:
  s.step(.05,[{"aim":direction,"move":Vector2.RIGHT,"jump":true,"fire":true,"tongue":true,"throw":true},{}])
  check(p.aim==direction,"Countdown keeps aiming responsive "+str(direction))
 check(p.pos==origin and p.ammo==3 and s.shots.is_empty() and p.anchor.is_empty(),"Ready countdown still holds movement and attacks")
 check(s.clock==0 and s.countdown>0,"Aiming does not start the match early")
 s.step(.01,[{"aim":Vector2(.01,.02)},{}]);check(p.aim==Vector2.RIGHT,"Stick deadzone retains last aim")
 s.countdown=0;s.hitstop=.2
 s.step(.01,[{"aim":Vector2.LEFT},{}]);check(p.aim==Vector2.LEFT and p.pos==origin,"Aiming remains responsive through hitstop")
 s.hitstop=0;p.respawn=.5
 s.step(.01,[{"aim":Vector2.UP},{}]);check(p.aim==Vector2.UP,"Respawn countdown accepts aim")
 s.over=true;s.step(.01,[{"aim":Vector2.DOWN},{}]);check(p.aim==Vector2.DOWN,"Round-end state accepts aim before handoff")
 # Reusing a world must restore damage, hide every old FX pool and keep actors.
 s=Sim.new(roster,"versus",31,"beaver_dam");s.countdown=0
 var w:=World.new();root.add_child(w);w.build(s)
 var actor:Node=w.frogs[0].root;var fx:Node=w.combat;var stage:Node=w.stage
 var shelf:Dictionary=s.platforms[5]
 s.Destruction.damage(s,shelf,200,shelf.pos,Vector2.RIGHT*20,"burr");w.update()
 check(not w.shelves[5].visible,"Fixture breaks a timber support")
 w.combat.jets[0].strength=1.0;w.combat.jets[0].length=4.0
 var fresh:=Sim.new(roster,"versus",32,"beaver_dam");w.reset(fresh)
 check(w.frogs[0].root==actor and w.combat==fx and w.stage==stage,"Same arena reuses scenery, frogs and combat pools")
 check(w.shelves[5].visible and fresh.platforms[5].hp==fresh.platforms[5].max_hp,"New round restores broken terrain")
 var damage:Dictionary=w.shelves[5].get_meta("destruction")
 check(damage.layers.all(func(layer):return not layer.visible),"New round removes damage cracks")
 check(w.blood_mesh.multimesh.visible_instance_count==0 and w.combat.jets[0].strength==0,"Blood and flame pools reset without leaking last round's effects")
 for arena in Sim.Arenas.IDS:
  fresh=Sim.new(roster,"versus",33,arena);w.reset(fresh)
  check(w.frogs[0].root==actor and w.combat==fx,"Keeps actors and combat pools for "+arena)
  check(w.shelves.size()==fresh.platforms.size() and w.boxes.size()==fresh.crates.size(),"Scenery matches collision and crates for "+arena)
  check(w.camera.get_parent()==w.stage and w.camera.current,"Arena camera remains current for "+arena)
  await process_frame
 check(w.can_reuse(Sim.new([{"slot":0}])) ,"Smaller rosters reuse existing actor pools")
 w.reset(Sim.new([{"slot":0}],"survival",34,fresh.arena_id))
 check(not w.frogs[1].root.visible and not w.contact_shadows[1].visible and not w.combat.jets[1].node.visible,"Unused actor and flame pools stay hidden")
 w.queue_free();await process_frame
 # Verify the actual main-loop handoff and managed stick routing, not just a timer.
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 game.running=true;game.in_menu=false;game.roster=roster;game.selected_mode="versus";game.new_round()
 game.bridge.launched_by_daemon=true
 game.sim.frogs[0].controller="pad-one"
 game.bridge.frames={"pad-one":{"axes":[0,0,-32767,-32767,0,0],"buttons":0}}
 game.bridge.frame_at=Time.get_ticks_msec()
 game._physics_process(1.0/120)
 check(game.sim.frogs[0].aim.is_equal_approx(Vector2(-1,1).normalized()),"Managed right stick reaches the player during the ready countdown")
 game.bridge.launched_by_daemon=false
 var previous:RefCounted=game.sim;var world:Node=game.world
 game.sim.over=true;game.sim.winner="Moss"
 game.sim.countdown=0;game.sim.frogs[1].alive=false
 game.sim.frogs[0].pos=Vector2(0,3);game.sim.frogs[0].vel=Vector2.ZERO
 game.bridge.launched_by_daemon=true;game.bridge.set_process(false)
 game.bridge.frames["pad-one"].axes=[32767,0,32767,0,0,0]
 game.bridge.frame_at=Time.get_ticks_msec()
 game._physics_process(1.0/120)
 check(game.sim==previous and game.sim.over and game.celebrating,"Winner stays in the original arena")
 check(game.world==world and game.last_result=="Moss wins","Winner is clearly announced while still playable")
 var victory_origin:Vector2=game.sim.frogs[0].pos
 for i in range(100):
  game.bridge.frame_at=Time.get_ticks_msec();game._physics_process(1.0/120)
 check(game.sim==previous and game.sim.frogs[0].pos.x>victory_origin.x+.5,"Managed left stick moves the winner during the victory lap")
 check(game.sim.frogs[0].aim==Vector2.RIGHT,"Managed right stick aims during the victory lap")
 var hp:float=game.sim.frogs[0].hp
 game.sim.hurt(game.sim.frogs[0],1000,Vector2.LEFT*20)
 check(game.sim.frogs[0].hp==hp and game.sim.winner=="Moss","Result stays final and the winner cannot be killed by leftover attacks")
 game.sim.knockout(game.sim.frogs[0])
 check(game.sim.frogs[0].alive,"Falling during the victory lap does not eliminate the winner")
 game.selected_arena="beaver_dam" if game.sim.arena_id!="beaver_dam" else "grotto"
 var old_stage:Node=world.stage;var old_camera:Node=world.camera
 game.prepare_next_round()
 var frames:=0
 while game.preparing and frames<300:
  await process_frame;frames+=1
 check(frames>1 and game.pending_world!=null,"Next arena prepares incrementally across frames")
 check(game.sim==previous and world.stage==old_stage and world.camera==old_camera and old_camera.current,"Preparing the next arena leaves the current stage and camera active")
 var staged:Node=game.pending_world.stage
 game.victory_time=1.99;game._physics_process(.02)
 check(game.sim!=previous and not game.sim.over and game.sim.countdown<=.8,"After two seconds a fresh round starts with a brief ready countdown")
 check(game.world==world and world.stage==staged and world.camera.current,"Handoff adopts the prepared scenery and keeps actor pools")
 check(not game.celebrating,"Victory banner clears on the next round")
 # Starting with fewer players must keep the menu's prebuilt actor/FX pools.
 game.bridge.launched_by_daemon=false;game.show_menu()
 var menu_world:Node=game.world;var menu_combat:Node=game.world.combat
 game.selected_mode="survival";game.human_count=1;game.start_local()
 check(game.world==menu_world and game.world.combat==menu_combat and game.sim.frogs.size()==1,"Starting a solo map reuses the menu's models and effect pools")
 check(game.sim.countdown<=.8,"First map has the same short ready countdown")
 # In-flight preparation must not survive dispose/reprepare or replace the new session.
 game.selected_arena="grotto" if game.sim.arena_id!="grotto" else "terrarium"
 game.prepare_next_round();game.dispose_managed("")
 while game.preparing:await process_frame
 check(game.pending_world==null and game.pending_sim==null,"Disposal cancels pending arena adoption")
 game.queue_free();await process_frame
 if saved_config.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))
 else:
  var config:=FileAccess.open(config_path,FileAccess.WRITE);config.store_string(saved_config);config.close()
 print("Frog Fighter transitions: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
