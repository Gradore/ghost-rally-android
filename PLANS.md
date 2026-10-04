# Execution plan: Android realism and reference graphics

## Current deliverable
Native Godot Android preview, geographically sourced Brandenburg start area, custom vehicle physics. Incorporate the user's October 2026 simulation brief without changing the existing game into an unrelated browser prototype.

## Milestones and acceptance
- [x] M0: ADR, architecture, SI/config schema and explicit assumptions. Preserve build/export.
- [x] M1: fixed 240/360 Hz mobile and 720 Hz desktop stepping, pure Magic Formula and combined-slip limits; rate-partition and braking tests.
- [x] M2: four individual wheel rotational states, load distribution, engine curves, turbo lag and limited-slip differential; airborne wheel and split-grip tests.
- [x] M3a: reduced vertical body heave/pitch/roll with four sprung/unsprung wheel paths, unilateral tyre contact, damping/stops and anti-roll coupling; bump/drop and scene adapter checks.
- [ ] M3: full 6-DOF chassis and four sprung/unsprung vertical bodies, terrain contact, suspension and anti-roll bars. Current small-angle vertical model plus planar translation/yaw remains an interim approximation; unrestricted orientation, slope force projection, chassis ground strikes and solid rear axle geometry remain open.
- [ ] M4: suspension/tyre/radiator/gearbox damage, thermal brakes, pressure/temperature calibration and per-wheel material queries.
- [ ] M5: sourced stage geometry, verified topography and landmarks; reference-quality PBR vehicles, vegetation LOD and terrain streaming.
- [ ] M6: de/en UI, controller calibration, co-driver/audio expansion, telemetry export and replay tests; FFB abstraction/optional native adapter.
- [ ] M7: device performance acceptance (60 fps target), signed production AAB, Play Console checks and store publication.

Native/C# core, gdUnit4 framework, full multibody suspension and device benchmarking remain open. Mobile/Vulkan, Jolt and Terrain3D adapter are now active.

## Risks and boundaries
720 Hz is a numerical update target, not proof of realism. Unknown coefficients are assumptions. Full survey data, realistic authored 3D car assets and device measurements remain necessary. Original-road curvature takes precedence over inventing bends to fit seven minutes. Actual start pavement and physics must agree. Debug previews are separate from production signing.

## Verification
Headless math/physics and game-flow checks; source-edge integrity for mapped routes; screenshots from actual Godot rendering. Tests pass before local commit. GitHub continuation is authorized on 2026-10-04; Play upload still requires production signing material.

## 0.14 continuation
- [x] Split Großräschen into three connected WPs, map each segment and isolate best times/ghosts.
- [x] Near spatial pines, actual Terrain3D grounding, photographed PBR gravel/forest floor, improved lighting.
- [x] Recorded CC0 engine base; RPM/throttle smoothing; no model-specific authenticity claim.
- [x] Analog wheel gesture, tilt/buttons options, critically damped input, sensitivity/auto-throttle.
- [ ] Complete reference-quality authored cars/vegetation, model-specific engine recordings and device visual/performance acceptance.
