# Validation 0.29

Godot 4.4.1 final editor import and signed ARM64 Android Preview export passed. 28 headless regression groups passed after texture-format and brake-material corrections:

- dynamics: PASS: acceleration, braking, reverse, stable corner integration and locked VOC upgrades
- sim: PASS: 720 Hz at 30/60/120/144 Hz; MF/combined slip; braking grip; LSD; turbo lag; independent airborne/split-grip wheels
- start_area: PASS: shore relief, sealed-start grip, mapped buildings, colliders, batched details 21
- geo: PASS: 17 routes, map zoom, route projection
- realism: PASS: tree collision, buttons, minimap, crash response, onboard toggle, main-menu exit
- smoke: PASS: twelve cars, physical acceleration, braking, steering, ordered checkpoints; brake start z=-41.1495475769043
- progression: PASS: RC upgrades, prices, balance guard
- suspension: PASS: 240/360/720 Hz static support, acceleration/braking transfer, independent bump, damping, flight and landing
- suspension_integration: PASS: sealed start, matching road/contact heights, physical body pose, preset-specific best times
- upgrade14: PASS: three connected WPs, isolated times, recorded loop, smooth analog touch and spatial forest
- upgrade15: PASS: Lovo naming, pause input reset, timestamp/height replay and finish transition
- vegetation16: PASS: spatial oaks 299 and bounded dense grass 6771
- graphics19: PASS: outward loft normals, all twelve wheel models and four material batches per wheel
- maps20: PASS: 81 OSM footprints, world alignment, T-shaped hotel roofs and three IBA terrace cubes
- mv21: PASS: MV mixed surfaces and widths, 2137 world footprints; original Müritz preserved
- controls22: PASS: garage reuse, thumb signs, calibrated tilt, pause/settings, recovery, 40 real two-sided wall probes and local tree sweeps
- driving22: PASS: stock performance and low-speed left corner grip
- tree22: PASS: 400 sweeps equivalent; trees=1173; mean candidates=0.3275; reference=84900 us; indexed=824 us
- model23: PASS: actual GLB read, metre fit, four animated wheel nodes, native collider retained, over-budget fallback
- assists23: PASS: ABS stop 33.2602753271349 m vs 34.7729488853365 m; locked 0 vs 130; TC slip 0.40930857027876 vs 0.84328124311551; bounded high-speed steering
- street23: PASS: source highway classification, preserved roof outline, batched Street View reference details
- driving24: PASS: braking response, analogue modulation, Ackermann, rear handbrake, multi-touch joystick, safe stop/reverse
- graphics24: PASS: clipped concave roof ridges, finite normals, cached and bounded canopy geometry
- graphics25: PASS: shared material atlas, sky projection, leaf alpha, encoded shore blend; terrain heights preserved
- local26: PASS: finished number 17, open underground-garage courtyard, finite modern facades and OSM-aligned planted roundabout
- terrain27: PASS: DGM rise, wheel/road contact, indexed tiles, batched facade details, free PBR maps and fixed-tick slope force
- model28: PASS: shipped Lovo reference model, triangle budget, metre fit, native collider, four centred rotating/steering wheels, live brake lamps
- resources29: PASS: requested Terrain3D release, MAVS-derived camera invariance/reverse/recenter, bounded merged car, rounded 195/65R15 tyres

Both Python route-integrity checks passed: 451 original MV edges / 2,137 footprints and stored 16,010m closed Großräschen loop. The complete original Großräschen OSM snapshot is unavailable in this runtime, so source-edge revalidation of that stage was not repeated.

Actual Mobile/Vulkan software-rendered captures: garage front/rear, wheel detail, Rostock brake/chase and front, Großräschen roundabout. Visual review confirms closed body/glazing, rounded treaded tyres and recessed rims. These are development graphics, not a photorealistic or factory-measured model. No Android device FPS measurement was made.

Preview package com.ghostrally.racer.preview27; versionCode 29, versionName 0.29.0; certificate SHA-256 d53f7b22229e11c150364c495974d957a8cbc395caa6610f488716b9f4f986d1. Production signing unchanged.
