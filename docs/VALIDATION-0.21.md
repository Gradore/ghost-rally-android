# 0.21 Rostock–Mönchhagen mapped mixed-surface stage

Godot 4.4.1 Mobile/Vulkan; Android Preview versionCode 21 / 0.21.0. The original sixteen stage indices and records remain intact. The new MV stage uses index 16; state selection defaults to it and a switch exposes the original Müritz stage.

## Source geometry

The OSM export UI retrieved two XML map extracts on 2026-10-04: south bbox 12.164,54.08,12.23,54.104 and north bbox 12.184,54.103,12.236,54.159. The supplied screenshots identify the Carbäk/Riekdahl start, Köster-Klickermann-Weg/Rudolf-Tarnow-Straße waypoint and Neuendorf village. Geometry comes from OSM rather than copied Google imagery. Short Plus Codes recover in the 9F6J area. Each anchor is projected onto a mapped eligible road edge: 4.9, 0.2, 21.1 and 2.4 metres from the code centre. The final anchor is on Ibenweg.

451 source edges form a continuous ordered 15,623 m route before inherited junction smoothing. The graph prefers unpaved tracks after Neuendorf and retains asphalt links between them. About 3,438 m is modeled unpaved, including 1,842 m explicitly tagged dirt/grass/compacted. The remaining unpaved track surfaces are unknown in OSM and flagged as assumptions. This is a mixed stage, not a claim that the whole Neuendorf–Mönchhagen connection is loose gravel.

2,137 closed building ways within the route corridor retain their complete source outlines and way versions. Renderer verification checks every projected vertex. Building walls follow concave/curved footprints rather than broad bounding boxes. Nearby wall collisions use their actual triangle geometry. Rectangular tagged gabled roofs have gable ends; other rectangular pitched roofs use hips. Heights/levels inform dimensions; untagged roofs/heights, facade colors and windows remain interpretations. Known total-height tags subtract the modeled roof rise from wall height.

405 mapped land/water polygons, 217 individual tree nodes, 189 tree-row polylines, 39 stream/ditch lines and 13 rail polylines add context. Broadleaf crowns are sampled along mapped rows and inside mapped woods; open fields and buildings are excluded. Tree scale/species/spacing, street widths, flat terrain and small road undulations are documented assumptions. Multipolygon relations are not yet reconstructed, so coverage is not exhaustive or surveyed.

## Rendering and checks

Walls/windows/roofs are batched in 200 m cells, with windows culled at 220 m and general building detail at 500 m. Building footprints use an 80 m spatial index during vegetation generation. Context roads and land meshes generate tangents for normal maps; empty detail batches are skipped. Shadow opacity 0.78 and ambient energy 0.50 keep shade more readable. Device FPS and Android memory/frame-time performance remain unmeasured.

All fifteen required groups passed: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15, vegetation16, graphics19, maps20 and mv21. After final geometry/UI changes, geo, mv21 and smoke were rerun. The independent pruned OSM XML regression verifies every source edge, every anchor projection, waypoint order, and all 2,137 footprint coordinate sequences/versions. The existing Großräschen closed-loop integrity check still passes at 16,010 m.

Real Mobile/Vulkan inspection captures show the start, three waypoints and a north-up town-layout view. Only the north-up inspection hides UI and fog; race captures preserve game rendering. Android Preview exports and APK signing/version verification use the existing preview signer. No Android-device performance claim is made.

Rebake: `python tools/bake_mv_rostock.py south.osm north.osm`. Check: `python tools/mv_route_integrity_test.py` and Godot `--headless --script tools/mv21_test.gd`. The pruned XML source reference allows offline edge/footprint verification without the transient complete map exports.
