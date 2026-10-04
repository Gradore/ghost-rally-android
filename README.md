# GHOST RALLY — Android simulation alpha 0.21.0

Native Godot 4.4.1 project, Mobile/Vulkan renderer, Jolt and Terrain3D. Recovered from the public 0.10.0 source release and developed through locally verified milestones.

## Changes in 0.21

- Add Rostock → Köster-Klickermann-Weg → Neuendorf/Broderstorf → Mönchhagen as a seventeenth stage. All 451 edges follow OSM ways, including anchor projections onto the original road segments. The 15.6 km route includes 3.44 km modeled field/earth/gravel paths, with 1.84 km explicitly tagged unpaved; missing track surfaces are assumptions. Urban connecting sections remain asphalt.
- Preserve the original Müritz stage, all existing record keys and the three Großräschen WPs. MV selects the new stage by default and offers a Müritz/Rostock switch.
- Render 2,137 original building outlines without moving or replacing them with bounding boxes. Tagged heights/levels inform building heights; facade finishes and untagged roofs/heights remain interpretations. Batch facade/window/roof geometry in 200 m cells, cull distant detail and index building plots spatially for vegetation clearance.
- Use mapped field/woodland/water polygons, 217 mapped individual trees, 189 tree rows, 39 waterway lines and 13 railway polylines. Sample broadleaf crowns along rows and inside woodland rather than filling the whole route with procedural pine scenery.
- Generate terrain/context-road tangents for normal maps, skip empty detail batches, and lift shadow fill so town and tree shadows retain visible ground detail.
- Asphalt and unpaved segments now drive both appearance and tire contact. Add independent OSM source-edge/footprint verification and world-space/surface regressions. This is a geographically based alpha, not a photogrammetric or surveyed reproduction.

## Changes in 0.20

- Replace uniform horizontal pine tiers with irregular branches and three tree variants. Nearby and distant trees now share matching 3D silhouettes at different mesh detail levels. Broadleaf crowns have softer cutouts and rounded lighting normals; start-area tree cards become spatial crowns.
- All 81 stored Großräschen start-area building footprints match a fresh OSM snapshot. Google Maps map/satellite view was checked for landmark layout. Preserve coordinates/orientation while correcting the hotel T-shaped roof, flat sports hall and curved pavilion roofs, and the three IBA terrace cubes within their mapped footprint. Window details now face outward. Correct local-axis scaling for batched rotated facade parts, rails and piers; their original size and orientation are preserved.
- Add footprint provenance and a regression for world-coordinate alignment and roof containment. Fourteen groups and stored route integrity pass; actual north-up inspection and race captures accompany Android preview 0.20. Device FPS is unmeasured.

## Changes in 0.19

- Rounded tyre sidewalls, procedural tread grooves, recessed eight-spoke rally rims, metal brake discs and five bolt details. Wheel detail is batched into four material meshes per articulated wheel.
- Correct all inward loft side/cap normals, including glass. Glossier sky-reflecting windows and a ground-colored lower sky hemisphere improve material shading. Reflection radiance is limited to 128 pixels.
- Larger irregular mineral patches reduce gravel repetition. Gear has its own HUD label so first gear at rest no longer reads like “1 000 KM/H”; start/finish captions have darker contrast.
- Thirteen checks pass including outward-normal and twelve-car wheel-batching regression. Android preview 0.19 exports with the existing signer; Mobile/Vulkan screenshots are from the actual game. Device FPS is unmeasured.

## Changes in 0.18

- Broadleaf crowns use smaller irregular leaf clusters with gaps instead of large circular cards. Pines use alpha-to-coverage with the existing 2x MSAA to soften cutout edges. Sky includes a directional sun disc and warm haze tied to the scene light.
- Correct outward rear-cap normals, sampled curved wheel openings, four-segment VOC-inspired lamps, reduced badge size and lower idle/braking emissive intensity. Static body mesh surfaces are batched by shared material; articulated wheels, labels and collision shapes remain separate.
- Actual close three-quarter vehicle capture complements the start, lake, chase and three-WP views. Twelve groups and stored route integrity pass; phone frame rate remains unmeasured.

## Changes in 0.17

- Closer, lower chase camera gives the vehicle more screen presence while retaining the existing terrain clearance guard.
- Procedural metallic paint and lower-panel grime, clearcoat/roughness variation, subtler rear glass heating wires, authored plate lettering and braking-responsive rear lamps. Roof retains the plain paint material to avoid applying local-space lower-panel grime there.
- Stronger gravel tyre tracks and normal detail, darker/greener lake terrain tint, lower warm sun, spatial fern fronds and faceted irregular stone meshes instead of round placeholder rocks. Decorative foliage does not add colliders or consume the collision-placement RNG.
- Twelve test groups passed; the map regression was rerun after correcting the paint shader's clearcoat property. Graphics captured with Mobile/Vulkan; physical phone FPS remains unmeasured.

## Changes in 0.16

- Spatial broadleaf trunks, branches and textured crown clusters replace nearby full-tree cards. Pines have fuller branch/needle geometry. Both distant tree species are now chunked: their LOD distance follows local terrain cells instead of the world origin.
- 22 bent blades per grass clump, subtle wind, root/tip tint and spatial color variation. Dense roadside grass is rendered in 32 m cells with an 85 m visibility budget instead of drawing the entire stage's grass. Density and range are visual choices; phone FPS remains unmeasured.
- Textured irregular road shoulders blend gravel into forest soil, removing straight dark boundary bands. ACES tonemapping, tuned sun/ambient balance, sharper car body shading, painted A/C pillars and less mirror-like glass.
- A separate visual RNG preserves all 0.15 tree collider positions. The WP1 collider hash is identical to the previous source; existing progression, mapped WPs and physics keys remain intact.

## Changes in 0.15

- Fictional Lovo 940 VOC in the garage and rear badge; vertical grille without manufacturer diagonal. Config renamed while retaining car index 10, best-time keys and existing progression.
- Textured gravel shader with gently wandering tyre tracks, blended margins, normal mapping and larger-scale variation. Road meshes now include tangent vectors; bend patches follow the road relief. Warmer lower sun, reduced ambient wash, glossy windows, grounded chase camera and corrected near/far pine overlap. Keep 2x MSAA: 4x crashes this software Vulkan renderer.
- Broader rear-wheel dust emitter with explicit visibility bounds and reduced particle count.
- Finish transition exits the race update before touching removed HUD nodes; completion rewards are idempotent.
- Ghosts interpolate actual timestamps across time penalties and record vertical height; old eight-field recordings remain supported. Reject malformed/nonfinite/nonmonotonic replay data.
- Pause/focus loss clears touch anchors and pedals; saved track indices and dictionary containers are checked. Audio fills the complete generator buffer and mutes road/skid noise outside racing.

## Changes in 0.14

- Großräschen: three connected ~5.3 km WPs from the existing ~16 km mapped lake loop, separate north-up maps, records and ghosts. WP3 ends at the original start pin, 51.5753876, 14.0098543. Original mapped alignments are preserved; gravel surface conversion is a game adaptation. Seven minutes remains a driving target, not an enforced duration.
- Near pines now have spatial trunks and needle clusters, batched into visibility chunks. Tree placement queries actual Terrain3D height; roots are slightly buried. Photographed CC0 gravel and forest-floor PBR maps, mipmaps, anisotropic road filtering, retuned sun/haze. Far pines and broadleaf trees retain billboards.
- A real recorded CC0 engine loop follows RPM and throttle smoothly; gravel, skid and mechanical layers remain procedural. This is a generic recording, not an authenticated Volvo 940/B230 or Audi sample.
- Analog virtual wheel, tilt calibration and buttons options, steering sensitivity and optional automatic throttle. A critically damped input filter makes release/reversal continuous. Input is inspired by familiar mobile racers; RR3-identical handling is not claimed.

## Simulation status

Custom framework-independent GDScript modules integrate at 240/360 Hz on mobile and 720 Hz on desktop. Magic Formula/combined slip, four wheel rotational states, engine torque/turbo/differential models and reduced heave/pitch/roll suspension are implemented and tested. Planar translation/yaw and small-angle vertical motion remain approximations; full 6-DOF dynamics, validated tyre data, damage and telemetry calibration remain open. See PLANS.md and docs/ASSUMPTIONS.md.

The fictional Lovo 940 VOC uses game-authored procedural geometry and a VOC-inspired naturally aspirated RWD configuration. Its 116 PS, 1350 kg and other undocumented values are assumptions. Engine/grip upgrades are disabled. This is not a validated VOC homologation claim. Other cars remain fictional.

## Build and checks

Use official Godot 4.4.1, matching export templates, OpenJDK 17 and Android SDK. Configure SDK paths in Godot Editor Settings.

```bash
godot --headless --editor --import
godot --headless --script tools/sim_test.gd
godot --headless --script tools/suspension_test.gd
godot --headless --script tools/realism_test.gd
godot --headless --script tools/upgrade14_test.gd
godot --headless --export-debug "Android Preview" ../outputs/GhostRally-0.14.0-preview.apk
```

AGENTS.md lists the complete test suite. docs/VALIDATION-0.14.md records acceptance, limitations and the Dummy-audio shutdown warning. Captures come from actual Mobile/Vulkan rendering with desktop software rendering; they are not phone benchmarks.

Preview package: com.ghostrally.racer.preview, versionCode 18. It retains the previous debug signer and can update the previous preview. Production signing material is absent; do not replace it. No production AAB or Play Store submission is claimed.

## Remaining work and credits

Current graphics remain below the supplied reference. Authored vehicle models/interiors, richer surroundings, model-specific recorded audio, full dynamics calibration and Android device acceptance remain necessary.

Map data © OpenStreetMap contributors, ODbL, https://www.openstreetmap.org/copyright . State boundaries © GeoBasis-DE/BKG (2025). Mapped stages are game environments, not driving directions. CREDITS.md lists audio and texture sources/licenses; assets/textures/README.md and assets/fonts/OFL.txt retain existing notices. Original geometry is authored for this project; proprietary game assets are not included.
