# Frog Fighter

A native Godot 4.5.2 party brawler for GameNight. Cheerful clay frogs in a little
terrarium, with deliberately excessive cartoon gore when combat begins.
The playable build uses original procedural 3D meshes with AI-generated wood,
bark, and stone material textures (`art/materials/`), layered over an AI-generated
distant garden plate (`art/garden.png`). Worn beveled planks, moss, curved leaves
with raised veins, clay frog poses, contact shadows, water lilies, and a glass
pond rim bring the foreground closer to the concept. The pond uses an animated
distorted garden reflection, rather than real-time scene reflections. Nearer
plants and rocks are rendered in a separate 3D viewport with soft lens blur;
the frogs and physical platforms remain sharp. The detailed distant scenery
is a baked image, not reconstructed 3D geometry.
The side walls are full 3D landmarks: a grooved tree trunk with roots, knots,
and collidable shelf fungi on the left, and a mossy stone cliff with two
animated waterfall curtains and spray on the right. Waterfall animation freezes
with gameplay during pause, as does the pond. Their climbable inner edges use simple collision
surfaces to keep tongue movement and wall grips predictable.
The expanded arenas add original procedural reeds, cracked timber, stone ruins,
and blue/violet mushroom platforms. Three distant environment plates were made
with the built-in image generator: `art/ruins-background.png`,
`art/autumn-background.png`, and `art/grotto-background.png`. The full prompt set
is in `art/arena-art-prompts.json`. These pictures provide distant scenery;
platforms, side geometry, moving pieces, and tongue grips are real 3D meshes.
The AI concept in `art/concept.png` is an art reference, not a gameplay capture
or a source of finished 3D assets.

## Play

Open `FrogFighter.exe` in the portable Windows build, or open `project.godot` in
Godot 4.5.2 and press F5. The game is fully local and works offline.

One start screen contains mode, 1–4 human players, bot count, 1/3/5 lives,
level, and window/fullscreen options. Sound effects are removed for now. Press **Play** or controller
Start to play. Up/down selects a row; left/right immediately cycles its value.
The stick, D-pad, and arrow keys all work. The active row is bright lime.
A/Enter is only needed for Play, Resume, or New match; Start is a shortcut.
F2 cycles player count; F3/controller Y switches mode. F11 toggles fullscreen.
Start, Escape, or Back opens this same settings menu during a match.
Resume (or Start/Escape/Back again) continues the paused match. New match applies
the selected mode, player/bot counts, lives, and level. Display changes apply immediately.
Versus requires at least two frogs; survival uses only the selected human team.

### Levels

Choose **Level** in the same menu with left/right:

- **Terrarium:** the original seesaw, timber shelves, and hanging platforms.
- **Vineway:** a wide open middle, three swinging perches, and five hanging vine grips for crossing long gaps.
- **Canopy:** staggered treetop ledges and a rising central platform, with routes to a high crown perch.
- **Floodplain:** broad water gaps, two travelling ferries, and a suspended upper crossing.
- **Reed Delta:** a 42×22 river arena with reed beds, ferries, high swing routes, and safe water. Repeaters near the lower spawns, bramble blasters upstairs, a railgun on the high central island and grenades on the low crossing.
- **Sky Ruins:** a 36×25 ruined garden above a lethal chasm, with open sides and no ceiling. Acorn cannons near the lower spawns reward knockback; the high central railgun and mid-height grenade launcher are contested prizes.
- **Deadfall:** a 34×21 autumn ravine with open sides and a lethal drop. The cracked five-section bridge collapses in a chain. Bramble blasters start near lower spawns, acorn cannons near upper ones; the grenade launcher sits on the unstable bridge, and the flamethrower sits on a timber stack above a destructible support.
- **Glow Grotto:** a 32×24 mushroom cave with safe water. Blue caps are permanent; cracked violet caps fall. Bramble blasters suit the lower paths, repeaters start higher, the central flamethrower controls nearby crossings and the railgun rewards a climb to the crown.
- **Beaver Dam:** timber gates, a roof that collapses when both posts break, destructible crossing routes and safe water.
- **Shatter Spire:** a stone tower whose supports can be shot out, permanent outer ledges and a lethal chasm.
- **Tour:** rotate through all ten arenas after each match (not between survival waves).

Every arena supports versus and survival and has four permanent spawn perches
with nearby weapon pickups. The original four keep their safe ponds and walls;
new arenas declare their own size, walls, ceiling, and bottom hazard. Movement
speed, frog size, jump height, and tongue reach stay the same. The camera fits
each arena. Open sides allow ring-outs; falling into a chasm costs one life.
Hazard rules appear in the level description and during the round countdown.

Cracked structures shake for about a second after being stepped on or grappled,
then drop and rotate. Gunfire accelerates their failure; rail shots and nearby
grenade explosions can bring them down immediately. Adjacent bridge sections
fail in a staggered chain. Disappeared sections stop blocking shots, landings,
and tongues, then recover eight seconds after falling out of view. Spawn ledges
are permanent. Bots avoid falling sections and jump away from warning cracks.
The new maps each start with nine deliberately placed pickups, including all
seven weapon types; empty supply sites replenish, and broken sites wait to recover.
Aim your tongue at the pale green curls on hanging vines to attach and swing;
reel in with up, then jump to release. Upper perches offer alternative routes
across the open middle. The level choice is saved with the other settings.
For a direct source launch, add `-- --arena=vineway` (or `canopy`, `floodplain`, `cycle`).

### Controls

| Action | Controller | Keyboard / mouse P1 |
|---|---|---|
| Move / steer a swing | Left stick | A / D |
| Jump (hold for height) | LB (A also works) | Space |
| Aim weapon and tongue | Right stick | Mouse |
| Shoot | RT / RB | Left click / F |
| Tongue grapple, hold to stay attached | LT | Right click / Q |
| Reel tongue in / out | Left stick up / down | W / S |
| Stick to walls | Automatic on contact | Automatic on contact |
| Climb wall | Left stick up / down | W / S |
| Cling to a platform underside | Hold B | Hold Shift |
| Pick up a weapon when unarmed | Automatic | Automatic |
| Throw held weapon | X | E |
| Settings menu / resume | Start / Back | Escape |
| GameNight lobby (managed play) | Back | — |

Frogs spawn unarmed and automatically pick up nearby weapons. Equipped weapons
are kept until empty or thrown with X/E. Throws follow your aim, preserve remaining
ammo, and can be caught by another frog. A brief owner lockout prevents instant
re-pickup. A jump releases a tongue or wall
grip. There is no air jump: use tongue anchors to reach the hanging shelves.
Platforms can be jumped through from underneath. Tongues attach to platform
tops, curled vine grips, the overhead branch, or the terrarium's side walls and follow moving
anchors. Walls hold you automatically; jump or move away to release.
B/Shift still holds to platform undersides. Wall jumps have a short outward push
and extra air steering: hold toward the wall to land back on it higher up, then
release and press jump again to keep climbing.

Connected controllers are assigned once at the start of a local match. A
disconnected controller becomes neutral; the other players keep their devices.
Players without controllers use these separate keyboard layouts:

| Player | Movement and aim | Jump | Tongue | Shoot | Throw | Grip |
|---|---|---|---|---|---|---|
| P2 | Arrow keys | Ctrl | N | M | Comma | Period |
| P3 | I J K L | U | Y | O | H | P |
| P4 | Numpad 8 4 5 6 | Numpad 0 | Numpad 7 | Numpad 9 | Numpad 1 | Numpad 3 |

Keyboard guests aim in their movement direction and retain their last aim
when released. Controllers provide independent aiming for every player.

## Rules

- **Versus:** selectable 1, 3, or 5 lives per frog (default 3). Losing all health
  costs one life. The pond is safe: frogs float and can move, fire, grapple, or
  jump out. Foreground rocks have solid landing crowns and support jumps. Surviving frogs win after the other players are eliminated.
- **Survival:** starts with eight bees in solo play, with larger groups for extra
  players. Mosquitoes arrive in wave 2 and small birds in wave 3. Every fifth wave
  brings Baron Beak, a large bird boss with an escort, a visible dive wind-up, and
  bee reinforcements below half health. Defeating him drops a railgun and lobber.
  Regular swarms grow to 26 enemies. Mosquitoes dart, birds swoop, and bees pursue
  in a fluttering swarm. Enemies have tracking eyes, wing animation, and hit blinks.
  Contact hits have a brief shared recovery window to avoid stacked swarm damage.
  Selected lives and no friendly fire still apply; the best wave is saved locally.
- **Weapons:** Acorn Cannon (heavy knockback), Pine Repeater (rapid needles),
  Bramble Blaster (five-thorn spread), Dragonpod (short-range flamethrower),
  Lightning Reed (three high-power piercing rail shots with heavy recoil), and
  Puffball Lobber (six bouncing, fused grenades with blast damage and knockback),
  and Burr Bomb (three hand-thrown pods that detonate on first impact).
  Rail shots stop at solid cover. Grenades can hurt their owner; survival teammates
  remain protected. The railgun and lobber start on interior perches in each arena.
  Ammo/fuel is limited. New pickups drop regularly; all seven types spawn initially.
- **Physics:** momentum, variable jumps, rope constraints, wall jumps, shifting
  suspended platforms, a weight-sensitive seesaw, movable crates, and projectile
  impulses. Falling limbs bounce and blood stains move with their platforms.
- **Scale and pace:** frogs, held weapons, and collision bodies are half their original size.
  Run speed is 12 units/second with quicker acceleration. Jump
  height, tongue range, damage, and knockback remain unchanged.
- **Movement:** a held jump rises about 4.95 units, peaks in 0.47 seconds, and
  lands in about 1.0 second. Falling gravity is softer (36 units/s²); air steering
  accelerates at 52 units/s² for responsive left/right corrections and reversals.
  Releasing early makes a short hop. Feet lift, swing, and
  plant alternately with a movement-driven stride, body bob, and arm swing.
- **Bot difficulty:** 0.65-second target acquisition delay, slower sampled aim,
  imperfect movement prediction, and short firing bursts separated by pauses.
- **Bots:** seek and automatically collect weapons, route between platforms,
  grapple to higher shelves, lead moving targets, respect weapon range, and
  avoid shooting directly into scenery. New weapons replenish on reachable shelves.
- Rounds restart after a six-second results screen. Each new round varies the
  Terrarium upper platform placement and moving platform phases. Settings and the survival record persist
  in Godot's `user://pond.cfg` (Windows: `%APPDATA%/Godot/app_userdata/Frog Fighter`).

The garden uses a 1280×720 background render with a dense Gaussian blur instead
of a sparse offset grid. Frog smiles are continuous curves fitted to the face.

## Weapon feedback

| Weapon | Shot spacing | Damage | Hit-stop | Feel |
|---|---:|---:|---:|---|
| Acorn Cannon | 580 ms | 24 | 55 ms | Bark barrel, heavy acorn, vine bindings |
| Pine Repeater | 120 ms | 9 | 18 ms | Pine-cone chamber, rapid needles |
| Bramble Blaster | 820 ms | 10 × 5 thorns | 45 ms | Briar-wrapped pod, wide thorn blast |
| Dragonpod | 75 ms | 3.5 | None on normal hits | Sap pod, reed nozzle, continuous flame and warm light |
| Burr Bomb | 1150 ms (160 ms windup) | Up to 145 | 85 ms | Hand-thrown thorn pod, contact detonation, 4.4-unit blast |

Impact feedback runs on a separate presentation clock: a local cream flash and
squash pose land first. Frogs briefly squeeze their eyes when hit; their bodies
remain visible throughout hit reactions and spawn protection.
Small blood marks remain at the impact location, follow the body, and clear on
respawn. Ordinary projectile hits emit 4–6 tiny droplets plus a soft, rapidly
dispersing mist. A knockout uses a 95 ms freeze, five limb pieces and three
squishy organ shapes (heart-like, bean-shaped, and curled), a broader mist,
and a small secondary spray at 75 ms. Short
shared-screen freezes do not stack; jumps and throw presses are buffered.
All thorns in one bramble volley can register, with one hit sound/flash per victim.
The Dragonpod carries 70 fuel units and reaches roughly five world units. Its
continuous damage does not emit blood blobs or repeated hit-stop; hit flashes
are throttled. Hits ignite body-attached flames, rising embers, soft smoke, and
flickering orange light. This visual burn fades over 1.25 seconds after the last
hit, follows the moving frog, and clears on knockout or respawn. It has no
lingering damage after the flame has passed.
Jet and body fire use the same turbulent shader, heat/alpha ramp, and upward
acceleration. Fire blends additively with soft transparent edges; dense overlaps
become white-hot. Separate darker smoke expands and rises around the plume.
The jet's damage trajectory curves upward with the visual effect. Flame hits
retain a small flinch without repeatedly whitening the whole frog.
The weapon draws one continuous, subdivided plume per shooter, attached to the
nozzle. Turbulence flows through it independently of fuel/damage ticks. It grows
on ignition, clips along its curved path at obstacles, and fades when released.
At impact, the stream reaches the visible body surface and widens against it;
the early tip fade is reserved for fire traveling through open air.
Debris keeps moving through the results screen. GameNight and local pause freeze
both clocks. Muzzle effects, projectiles, blood, body parts, and impact particles
use bounded pools. Distinct synthesized sounds feed a master limiter.

The staged `tests/impact_preview.gd` scene records the actual renderer and weapon
simulation for frame-by-frame inspection. It is excluded from playable exports.

## GameNight integration

The portable build includes a local `shelf.json` pointing to its executable.
The protocol ID is `frog-fighter`. Managed mode uses opaque host controller
tokens, handles stale input, hides and mutes during Prepare/Pause/Dispose,
ignores mismatched session IDs, exits on host loss, and continues rounds inside
the session. Back has a one-second release gate. Names, colors, and transparent
face portraits follow profiles by player ID. The `mode` and `arena` settings apply next
round; roster changes apply on the next prepared session (`instant_join=false`).

This local prototype has not been published to the online catalog. Real-pad
ownership, focus switching, and release certification still need hardware QA.

## Develop and verify

```sh
godot --headless --path games/frog-fighter --editor --import --quit
godot --headless --path games/frog-fighter --script res://tests/run.gd
godot --headless --path games/frog-fighter --script res://tests/menu.gd
godot --headless --path games/frog-fighter --script res://tests/combat.gd
godot --headless --path games/frog-fighter --script res://tests/forest.gd
python games/frog-fighter/tests/integration.py --godot /path/to/godot
```

The simulation tests exercise jumping, tongue constraints/reeling, moving
anchors, surface grip, pickups, knockback, damage ownership, gore bounds,
stock loss, victory, survival progression, and stale input. The integration
test starts the actual game against a synthetic host. Neither replaces a
physical controller playtest.

```sh
python games/frog-fighter/tools/package.py --godot /path/to/Godot.exe --output /path/to/fresh-build
```

The packaging script uses the pinned editor executable plus an exported PCK,
so no separately downloaded export templates are required. It includes Godot
and GameNight licenses. Runtime GL Compatibility graphics target desktop GPUs.

For a reproducible bot match or a real frame capture:

```sh
godot --path games/frog-fighter -- --demo --capture=/absolute/gameplay.png --capture-frame=600
godot --path games/frog-fighter -- --demo --survival
```

## Asset and code layout

- `src/simulation.gd`: deterministic fixed-step 2D physics and game rules.
- `src/world.gd`: 3D asset kit, scene, camera, character poses, and gore rendering.
- `src/landmarks.gd`: bark geometry, textured rocks, fungi, roots, and waterfalls.
- `src/scenery.gd`: beveled timber, curved leaves, lilies, glass rim, and static mesh batching.
- `src/combat_fx.gd`: pooled muzzle bursts, shock rings, smoke, and weapon projectiles.
- `src/enemy_visuals.gd`: persistent animated bee, mosquito, bird, and boss models.
- `src/forest_weapons.gd`: shared held/pickup models built from bark, cones, pods, and thorns.
- `src/organ_shapes.gd`: three soft organ silhouettes, with pooled tumbling and bounce squash.
- `src/burning.gd`: pooled body flames, embers, smoke, and light.
- `src/flame_style.gd`: shared heat/alpha ramp, light colors, and buoyant motion.
- `src/fire_field.gdshaderinc` and `src/fire_smoke.gdshader`: shared turbulence and rising smoke.
- `src/blood_mist.gdshader` and `src/flame.gdshader`: soft procedural mist and flame wisps.
- `src/background.gd`: blurred 3D scenery over the generated distant garden.
- `src/main.gd`: local and managed input, lifecycle, audio, saves, and match flow.
- `src/hud.gd`: menu, HUD, score screens, and profile portraits.
- `src/bridge.gd`: current GameNight protocol adapter over the vendored SDK.

Replace the meshes produced by `make_frog`, `pot`, and the platform builder with
cleaned generated GLB assets as the art evolves; gameplay coordinates and
collision rules are independent of those visual meshes.


### Physical scenery

- Hanging wooden platforms use two tension-only rope constraints. They swing under landing momentum, tongue pulls, gun recoil and projectile/explosion impulses; their ropes stay attached to the visible contact points. Jumping carries some of their velocity and kicks the platform back.
- Reed Delta has two timber stacks on the high side perches. Sky Ruins has two stone cairns below the railgun perch. Deadfall has a timber pile supporting the central Dragonpod pickup. Glow Grotto has two mossy stone stacks on the upper outer mushrooms. Spawn ledges remain permanent and clear.
- Every stack piece is a separate rotating physical body: push it, grapple it, climb it, shoot it or blast its supports away. Pieces collide with other pieces and platforms, block weapon fire and transfer momentum. Fast-moving pieces can hurt frogs. Stone is heavier than timber.
- Settled stacks sleep to save simulation time. Impacts wake them again. Pieces float in safe ponds; pieces lost beyond the arena return after ten seconds if their original space is clear.
- Ferries and lifts still follow their established routes. Fragile bridges retain their warning/collapse behavior; these are separate from the loose-body stacks.

Run `godot --headless --path games/frog-fighter --script res://tests/physics.gd` for rope length, tongue force, jump momentum, stack stability, contact, blast, cover, recovery and flotation checks.

Tongue tension on physical objects uses equal and opposite impulses, relative attachment-point velocity and both bodies' mass/inertia. Rope stretch is corrected separately without injecting velocity. Reeling changes the relative closing speed; slack tongues exert no force. `tests/tongue_physics.gd` checks momentum/energy balance, off-center torque, slack/reeling behavior and neutral pendulum reversal/damping at 60 and 120 Hz.

### Burr Bomb — impact hand grenade

Pick up the thorny amber pod and press RT / left mouse / F to throw. Each pickup supplies three grenades. The frog winds up for 160 ms, then releases a spinning pod with an upward arc; recovery between throws is 1.15 seconds. X / E drops the remaining unarmed pack, following the normal weapon-drop control.

The first contact with a frog, enemy, crate, platform (including its side or underside), loose physics body, wall, ceiling or pond detonates it immediately. It uses swept collision to catch fast impacts. Open edges stay open. A 4.4-unit blast radius and 145 maximum damage make it larger than the Puffball Lobber, with distance falloff, cover protection, substantial physics impulses, self-damage and the existing co-op teammate protection.

The burst combines a white-hot flash, soft additive fire using the existing flame heat ramp, a fading shockwave, warm local light, rising shaded smoke, irregular fans of soft sparks and tumbling seed-shell pieces with independent speed, drag, size and lifetime. Four reusable visual pools bound the effect cost; visual timing continues during the short impact pause. Existing sound effects remain disabled.

A pack starts in every arena: the Terrarium seesaw, Vineway's central suspended perch, Canopy's crown, Floodplain's upper swing, Reed Delta's top central ledge, Sky Ruins' low central island, Deadfall's left bridge section and Glow Grotto's low ferry. These are arena pickups; frogs still spawn unarmed.

Run `godot --headless --path games/frog-fighter --script res://tests/burr.gd` for throw/release, contact, blast, self/co-op damage, cover and visual-pool checks.


### Destructible terrain

Breakable timber has pale cut ends and rope bands. Stone piers and masonry have block seams. Hits expose progressively deeper cracks and splinters; the surface darkens as damage accumulates. Timber has 96 HP, masonry 180 HP and structural piers 200 HP. All weapons can damage them; flame scorches timber effectively while stone strongly resists it. Explosions measure distance to the actual surface, including the ends of tall supports.

Destroyed sections leave real gaps in collision, shooting cover and tongue anchors. Removing every listed support gives a short shudder warning, then releases the section above as a rotating physical body; stacked supports cause a cascading collapse. Falling terrain can knock and hurt frogs. Fragments collide, tumble, float in safe water and clear after eight seconds, with a shared 16-body limit. Destroyed terrain and collapsed sections stay gone until the next match. The older loose toy stacks still use their existing recovery rules.

- **Beaver Dam**: safe pond, destructible timber routes, two gate posts carrying the lower roof. Blow open a gate to reach the protected Puffball pickup; remove both posts to drop the roof and its Burr Bomb perch. Seed guns start near the lower spawn ledges, Acorn guns above, with Bramble and Dragonpod on opposing routes and Lightning Reed at the crown.
- **Shatter Spire**: open sides and a lethal bottom, with permanent outer perches surrounding a supported stone tower. The two lower piers carry the upper levels; destroying both starts a collapse through the central column, balconies and railgun crown. Acorn and Seed guns start outside; the Burr Bomb sits on the left attack perch, Bramble on the right, with Puffball on the rescue island and Dragonpod on the upper tower.
- Reed Delta's central high perch, Sky Ruins' railgun perch and Deadfall's timber-stack support are also destructible. Spawn ledges remain permanent.

Both new levels are available in the single start/pause menu and in Tour. Start directly with `-- --arena=beaver_dam` or `-- --arena=shatter_spire`.

Run `godot --headless --path games/frog-fighter --script res://tests/destruction.gd` for accumulated damage, actual weapon impacts, collision/cover gaps, anchor release, support cascades, bounded debris, rendering, safe spawns, navigation and bot combat.
