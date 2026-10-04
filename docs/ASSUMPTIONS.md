# Assumptions and accuracy boundaries

All config objects with `_assumption: true` contain provisional calibration. No RBR/NGP code or proprietary coefficients are used.

- Magic Formula longitudinal dry/wet/snow/ice shape constants follow the MathWorks typical-road table; lateral/gravel/grass coefficients, relaxation length, load sensitivity, rolling resistance and thermal/pressure response are assumptions. Sources: https://www.mathworks.com/help/sdl/ref/tireroadinteractionmagicformula.html
- Four wheel masses/inertias, suspension setup, centre of gravity, brake bias/torque and yaw inertia are assumptions. The chassis remains planar with algebraic longitudinal/lateral load transfer. Individual vertical multibody dynamics and airborne terrain contacts are still pending.
- Limited-slip diffs use a bounded angular-velocity damping/preload approximation, not a complete Salisbury clutch geometry solver. Generic front/rear/centre splits are assumptions.
- Turbo boost is a first-order spool/decay model. Arbitrary engine torque samples and generic engine drag are assumptions. Volvo is naturally aspirated, so turbo state cannot add power.
- Volvo 940 GL tune, year/engine, mass and VOC legality remain provisional. Upgrade lock is implemented; that does not establish regulation conformity.
- Kestrel is fictional; the supplied S1 E2 numerical targets inform a provisional config. Gear ratios, spring/damper constants, tyre size and front weight are explicitly assumed. Do not mix 1987 Pikes Peak power with the 1985 homologation tune.
- The 720 Hz internal integration does not guarantee cross-platform bit identity. `sin`/`atan` and floating point remain runtime-dependent. Recorded-state ghosts avoid input resimulation across devices.
- Lake shoreline positions and local buildings come from OSM; visual six-metre bank relief and facade details are photo interpretations, not surveyed heights. Gravel surfacing away from the paved start is a game variant.
- Target 60 fps requires physical-device benchmarking. No headless desktop render proves phone performance.

- 0.13 suspension: spring 32 kN/m, damper 3.2 kNs/m, tyre stiffness 180 kN/m, tyre damping 450 Ns/m, axle anti-roll 10 kN/m, body ride reference 0.55 m, provisional pitch/roll inertias and bump/rebound stops. All are assumed; vehicle JSON explicitly records this. Motion ratios, exact Volvo rear solid-axle geometry and suspension mounting points are unmeasured.
- Added gravel undulations are generated up to 3.5 cm and rendered/sampled consistently. These are not surveyed terrain elevations. Asphalt geometry and original route coordinates are retained.

- 0.14 recorded engine loop baseline 1,800 rpm is an approximate playback tuning point, not a measured source recording speed. One generic real recording is shared across the garage; cylinder-specific and Volvo B230 banks are still missing.
- Spatial pine shape is procedural, using only CC0 bark/needle photos from Poly Haven. It is not a surveyed reconstruction of Großräschen tree species/locations. Near mesh / far billboard distance thresholds are provisional until phone profiling.
- Großräschen WP boundaries divide the existing road into equal distances; they are game event boundaries, not real-world rally authorisations or official WP starts.

- 0.20: 81 Großräschen start-area footprints revalidated unchanged against OSM on 2026-10-04. Google Maps map/satellite view was visually checked for Seehotel, IBA-Studierhaus, Seesporthalle, curved pavilions and IBA-Terrassen. Footprints are OSM data, not a Google imagery extraction or survey. Untagged roof types, ridge heights, three terrace-cube subdivisions, facade/window detail and tree species/placement remain visual assumptions. Tree variants are authored procedural geometry; no Google imagery is shipped.
