# GameNight settings

These options are declared over GameNight's typed settings protocol. The phone and lobby assistant discover the same keys, labels, ranges and current values. No game-specific model prompt is required.

| Key | Control and timing | Values | Default |
| --- | --- | --- | --- |
| `mode` | Mode (next round) | versus, survival | `"versus"` |
| `arena` | Arena (next round) | terrarium, vineway, canopy, floodplain, reed_delta, sky_ruins, deadfall, grotto, beaver_dam, shatter_spire, cycle | `"terrarium"` |
| `lives` | Lives (next round) | 1 to 9 | `3` |
| `run_speed` | Running speed % (live) | 50 to 150 | `100` |
| `jump_height` | Jump impulse % (next jump) | 50 to 125 | `100` |
| `gravity` | Frog gravity % (live) | 25 to 175 | `100` |
| `damage` | Combat damage % (next hit) | 50 to 200 | `100` |
| `pickup_seconds` | Supply interval, s (next supply) | 1 to 12 | `4` |
| `bot_reaction` | Bot reaction delay % (next aim) | 50 to 200 | `100` |

Gravity affects frogs, including rope movement, not thrown items or enemies. Jump impulse applies to subsequent standing and wall jumps. Damage scales hits on frogs and survival enemies; lethal falls remain lethal. Supply interval starts with the next supply timer reset. Bot reaction delay changes target acquisition and aim resampling, not movement speed. Lives never reset in the middle of a round.

All numeric inputs are integers. Invalid types, unknown keys and values outside the declared range leave the previous value intact. Live options update without restarting; structural options wait for the boundary named in the label. Party choices use GameNight's existing saved configurations and Undo/Keep flow.

The lobby owns seats and controller bindings. These options cannot add human players, remap controllers or write arbitrary engine variables. Renderer/debug internals are not exposed as gameplay controls.

## Verification

The headless settings tests exercise validation and gameplay effects. The public `scripts/test-godot-settings.py` in the GameNight repo also runs the actual game against a real daemon and checks typed updates and Undo. These source checks do not certify older downloaded binaries.

Run `godot --headless --path . --script res://tests/settings.gd`.
