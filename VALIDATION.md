# Local validation — 29 September 2026

Godot 4.5.2 stable, native Windows, OpenGL Compatibility renderer.

- `tests/run.gd`: **41 checks passed**, including repeated 60-second bot
  simulations, jumping, platform collision, grappling and reeling, wall jumps,
  underside grip, projectile collision, friendly-fire rules, gore bounds,
  respawns, versus victory, survival waves, and stale controller input.
- `tests/menu.gd`: **23 checks passed** for standalone mode selection, team
  size, pause/resume, new rounds, selected bot counts and lives, camera orientation,
  settings persistence, visible player controls, and LB jump without tongue input.
  Start/Escape open the full settings menu, key repeat cannot toggle it repeatedly,
  Resume preserves the match, New match applies settings, and no audio players exist.
- `tests/movement.gd`: **23 checks passed** for unarmed spawns, deliberate pickup,
  faster full jumps and short hops, alternating foot lift, and actual bot weapon kills.
  Measured held jump: 0.367 s to apex, 0.667 s total, 3.05 units high. Three seeded
  four-bot matches produced 10, 11, and 10 weapon kills in 86.0, 37.5, and 33.3 s.
  Both walls catch falling frogs automatically, hold while idle, allow climbing,
  release on away input or jump, and resist immediate reattachment after jumping.
- `tests/combat.gd`: **20 checks passed** for complete bramble volleys, one impact
  per volley, bounded hit-stop, buffered jumps, delayed spray, immediate lethal
  damage, post-round debris, nearest-hit ownership, and final-ammo animation.
- `tests/forest.gd`: **37 checks passed** for impact-local blood marks, bounded
  droplets, mist emission, eye squeeze and continuous body visibility, marks following animation,
  clean respawns, all four weapon models, and sustained flame damage, fuel,
  range, no blood-blob stream, no repeated hit-stop, and collision-clipped VFX.
  Knockouts retain five limb pieces and add three distinct rendered organs,
  with bounce squash and finite lifetimes.
  Burning checks cover ignition, following movement, lingering visuals, expiry,
  immunity, and cleanup on respawn and knockout. Flame trajectory checks cover
  upward acceleration and matching results across different simulation step sizes.
  Continuous-plume checks cover uninterrupted growth across fuel ticks, release
  fade-out, and clipping against the nearest crate. Contact checks distinguish
  visible body surfaces from enlarged damage hitboxes and preserve free-tip fading.
- `tests/integration.py`: **passed against both source and packaged executable**.
  Checks include authentication, prepared readiness, sparse seats with reversed
  controller-frame order, session guards, pause/resume, player profile ownership,
  one Back request per held press, disposal, reprepare, and clean exit on host loss.
- Actual GPU captures were inspected for the menu and live four-frog match.
  The v11 pause menu was captured after injecting a controller Start event through
  the native viewport; Resume, New match, and all five settings rows are visible.
  The playability revision also has a six-second native walking/jumping preview;
  foot lift, the continuous mouth curve, the cleaner garden blur, and all six
  setting rows on the single start screen were visually inspected.
  The final packaged menu also rendered without script or shader errors.
  `art/gameplay.png` is an actual running-game frame showing the revised terrarium, materials, foliage, and pond.
- A 750-frame four-player combat capture at 1280×720 on an RTX 5070 Ti reported
  **12.50 ms median / 16.67 ms p95** after the first 60 frames (120 FPS cap)
  in the playability revision, with the new bots and higher-resolution background.
- Recorded a sixteen-second, 60 FPS staged preview of the four forest weapons
  and a knockout with the actual simulation and renderer. Inspected impact marks,
  continuous frog visibility, fine mist, the Dragonpod flame stream, burning
  victims after leaving the stream, and all three flying organ shapes.
  This is a staged test scene.
- The shared-fire revision adds an eight-second native preview of an unobstructed
  continuous jet followed by a burning frog. Both use one additive fire shader and heat/alpha
  ramp, with world-up buoyancy and a separate smoke pass. Godot's particle material
  documentation informed the ramp and acceleration design:
  https://docs.godotengine.org/en/4.5/tutorials/3d/particles/process_material_properties.html

The graphics revision includes generated wood, bark, and stone albedo textures
with mipmaps, beveled platforms, cupped leaves, contact shadows, water lilies,
and a glass rim. Static meshes are batched by material. During iteration this
reduced the measured rendering cost from about 21 ms median to under 12 ms in
subsequent live matches. Pond and waterfall motion use the simulation clock.
Combat flashes and recoil use a separate feedback clock during hit-stop. The
final combat pass pools projectile FX, particles, and body parts; the final
capture and preview completed without script, shader, or shutdown errors.

The portable build contains `FrogFighter.exe`, its PCK, licenses, README,
SHA-256 sums, a screenshot, a local GameNight shelf, and a ZIP archive.

Physical controllers and manual GameNight window/focus switching have not been
tested. This is a local playable prototype, with no online-catalog certification.
The source includes a CI workflow for the same automated checks; no remote CI
run is claimed here.

## Current direct-play iteration

Frogs and their collision bodies now use 50% scale, with run speed raised from
8.5 to 12 units/second and acceleration from 42 to 60. Jump physics and tongue
range are unchanged. `tests/movement.gd`: 31 checks passed, including full-length
tongue endpoints after scaling, platform contact, wall release, and faster running.
Held jump remains 4.95 units, 0.467 s to apex, 0.850 s total. Three bot matches
scored 9, 9, and 11 weapon kills. Native rendering was inspected and the source
project was launched directly for user testing; no portable build was produced.

## Wall jumps and expanded arsenal

`tests/arsenal.gd`: 24 checks passed for repeated same-wall ascent on either side,
wall pose and independent aiming, larger six-weapon models, lethal piercing rail
shots, solid cover, ammo/recoil, grenade launch arc, terrain bounce, fuse expiry,
blast falloff and knockback, self-damage and survival team protection.
`tests/movement.gd`: 31 checks passed; seeded bot matches scored 9, 11, and 11
weapon kills. `tests/forest.gd`: 37 checks passed, including retained fire/gore
behavior. Native weapon and wall-pose captures were inspected.

## Expanded survival roster

`tests/survival.gd`: 26 checks passed for larger mixed waves, species unlocks,
fifth-wave bosses and later scaling, rail damage against boss health, reinforcements,
boss rewards, bounded counts, contact-hit recovery, telegraphed dives, expressive
character meshes, hit blinks, and persistent visual ownership/cleanup.
`tests/arsenal.gd`: 24 checks passed; `tests/run.gd`: 41 checks passed, including
long survival simulations. Native roster and fifth-wave screenshots were inspected.
The game was launched from source with Survival selected.
