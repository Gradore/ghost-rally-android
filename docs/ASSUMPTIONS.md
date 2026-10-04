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


## 0.21 Rostock–Mönchhagen

OSM positions and footprint polygons are source geometry. The four supplied short Plus Codes resolve within the Rostock region using the 9F6J prefix; each is snapped to the nearest eligible road segment (4.9 m start, 0.2 m Köster-Klickermann-Weg, 21.1 m Neuendorf village pin, 2.4 m Ibenweg finish). No invented connector crosses gardens or fields. Routing prefers unpaved tracks after Neuendorf but uses mapped asphalt connections where needed. Unknown track surfaces are modeled unpaved and marked surface_assumption; “gravel” contact includes earth/grass/compacted paths, not exclusively loose stone. Lane/track widths of 5.6/3.8 m are visual and gameplay assumptions where widths are untagged. Road rounding is inherited and can trim OSM junction corners by up to 11 m.

Building heights without height/levels tags, roof profiles without roof tags, colors, windows and materials are authored assumptions. No Google aerial imagery is distributed, and screenshot roof/facade appearance is not copied as an exact model. MV terrain remains flat with the existing small procedural road undulations, not surveyed elevation. Individual OSM tree coordinates and row/woodland geometry are retained; tree height, species and sampled crown spacing are assumptions. Woodland multipolygon relations are not yet imported; buildings with holes or multipolygon relations are not reconstructed from relations. There is no guarantee of complete current building coverage or device FPS.

Shadow opacity 0.78 and ambient energy 0.50 are an artistic approximation of indirect daylight for the mobile renderer.

## 0.22 driving and presentation

The user supplied the Lovo stock targets: 131 PS, 185 km/h and 10.5 seconds 0–100. The torque curve, drag coefficient (0.527 N/(m/s)^2), driveline efficiency (0.85) and other physical parameters remain provisional `_assumption` calibration, not an authenticated homologation. Calibration is on flat dry tarmac with stock upgrades and neutral setup. Low-speed contact stabilization fades from 5 to 12 m/s and requires grounded wheels; handbrake behavior keeps the tyre model. The garage is an original fictional workshop. Reduced vegetation and render scale are performance budgets; no phone FPS measurement is available. Gravity controls use Godot's display-rotation-corrected Android X axis, with neutral calibration, inversion and deadzone. Physical sensor response is unverified on hardware.


## 0.23 Street View, driving aids and imported appearance

On 2026-10-04, five representative panoramas were visually inspected: Riekdahler Weg and Rudolf-Tarnow-Straße (Google, July 2022), Neuendorf Hauptstraße (Google, September 2023), Mönchhagen Ibenweg (Google, July 2022), and IBA terraces/Seestraße (Paul Toto user panorama, November 2018). IDs, positions and observations are retained in streetview_reference.json. The historical Rostock construction site is not asserted as current. Gravel-field-path and full Großräschen coverage have not been verified in Street View. No panorama pixels, Google textures or reconstructed proprietary assets are shipped. Original OSM geometry stays authoritative. Small railing/shelter positions, heights, footpath widths, bollard/lamp dimensions and facade matching remain interpreted assumptions. Context footpath classification comes from the original two OSM snapshots. Complex pitched outlines still receive a simplified flat roof cap; collinear rectangle roofs can follow the source roof tag without shifting footprint/collision vertices.

ABS slip thresholds and pressure rates, traction intervention and steering lateral-acceleration limits are provisional gameplay assists, not measured Volvo control systems. ABS operates on service braking, not the handbrake. Raw model tests leave assists disabled unless explicitly requested. The reflective garage is a fictional workshop, with one static probe for render budget. Device FPS is not measured.

GLB import is appearance-only. The 4.87 m target length is provisional until the user's model/dimensions are supplied. Orientation, wheel node names, 100,000 triangle rejection budget, and texture/material optimization must be checked per asset; 100,000 is an upper rejection threshold, not a recommended phone budget. No user car is included yet. Imported appearance does not establish mass, torque, tyres or collision. The test GLB is generated locally and never exported as the user's vehicle.


## 0.24 handling and visual revisions

Virtual wheel lock 37°, rack speed 4.8 rad/s, brake capacity 15 m/s², service-braking relaxation lengths 0.12 m tarmac / 0.18 m other surfaces, rear handbrake torque 2,400 Nm, and ABS pressure rates are provisional simulation parameters, not measured Volvo specifications. Effective deceleration remains limited by tyre friction, thermal grip, individual loads and combined slip. Ackermann uses the existing wheelbase/track dimensions. Steering assistance blends at 18–32 m/s using total speed, not forward projection; it remains optional. Reverse is selected by a new brake press at near-rest after release, never merely by holding through a stop. Touch joystick axes and deadzone are gameplay settings.

Clipped complex pitched roofs retain original polygons and authored ridge/eave heights. Complex hip roofs use a gabled approximation along the longest edge, not surveyed hip/skeleton construction. Window/facade detail remains interpreted. PBR material, leaf shading and lighting revisions are original authoring; crop-row appearance is a procedural approximation, not current surveyed cultivation. Near/far canopy vertex budgets and geometry reuse control work but are not phone performance evidence. The Lovo still uses the authored mesh; no user Meshy asset has been supplied.

## 0.25 graphics assumptions

- Synthetic photo-style materials are interpreted surface categories, not site photographs or surveyed facade measurements. Atlas scales, macro variation, shore sand heights (-5.9..-4.8 m) and water-wave frequencies are authored artistic parameters. Shore control changes textures only, never the existing terrain height array.
- The sky is a synthetic LDR equirectangular panorama, not a measured HDR light probe; sun placement and lighting are approximate. Water uses analytic animated normals plus existing sky reflections; no screen-space reflection, refraction or measured water appearance is claimed.
- Lovo receives a sedan rear-lamp arrangement and adjusted roof/rear-window profile. Other cars use different hatch/coupe/sedan roof profiles. All are original approximate meshes, without manufacturer badges; no original car model is included.
- The 30 m CSV reference grid is computed from OSM centreline coordinates, not captured Street View. Coverage is explicitly unverified and photograph columns remain empty. Google images are not downloaded as game assets.

## 0.26 local reference details

- Current finished state of Rudolf-Tarnow-Straße 17 is supplied explicitly by the user, overriding the historical 2022 scaffold view. Four mapped apartment buildings use a shared approximate modern facade/balcony/setback style. The source address/footprint attribution is exact to the existing OSM dataset; dimensions and appearance are interpretations.
- Underground-tagged/layer-negative building references are kept in `footprint_reference` but not rendered as solid above-ground houses. Courtyard paving is decorative and not a surveyed parking map. Above-ground houses retain their original footprint colliders.
- Bus stop source node and local road segments remain geographic references; sidewalk offsets, orange bin, lamp spacing and shelter dimensions are assumptions.
- Großräschen roundabout decorative alignment now follows the existing source polyline centre. Island vegetation, planters and flower placement are artistic approximations; the original driving route is unchanged.
