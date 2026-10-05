# Validation 0.27.0

2026-10-05, Godot 4.4.1 Linux headless: all 26 GDScript test groups pass with exit 0. Includes the 15 AGENTS-required groups plus controls22, driving22, tree22, model23, assists23, street23, driving24, graphics24, graphics25, local26 and terrain27.

- Official DGM start climb within 2.2–3.7m by 100m. Identical road-profile/contact heights at eight stations through 12km; terrain within 10cm of road profile at these probes.
- 210 indexed terrain tiles, at most 1089 vertices each. Bounded detail generation: 580132 indexed vertices in close facade-detail batches. Construction SurfaceTools released.
- Grade gravity integrated at fixed ticks: opposing 5% gradients produce slower uphill coasting than downhill.
- 40 geographically distinct real wall-ray probes from both sides at raised foundation height. All above-ground building collision bodies retained; underground courtyard open.
- Recovery checks current road height. Earlier tests retain coverage of controls, tyres, fixed-tick invariance, acceleration, braking, suspension and model imports.
- Python MV integrity passes: 451 original edges, four anchors, 2137 footprints, 3438m modeled unpaved / 1842m explicitly tagged. Stored Großräschen route check passes: 16010m closed loop, exact start/finish, no >400m gaps. Full independent Großräschen source-XML comparison was not rerun.
- Godot import and git diff --check pass. Android Preview export and apksigner verify pass. Package com.ghostrally.racer.preview27 uses a new debug certificate; installs alongside older previews, without automatic save transfer. Production signing unchanged.

Actual in-game Vulkan/llvmpipe captures checked; physical Android FPS, thermal behavior, touch/sensor response and memory unmeasured. Architecture is interpreted procedural detailing, not surveyed 1:1 facades or full photorealism. Official heights are resampled to 16m for runtime efficiency, with road-centre interpolation every 5m.
