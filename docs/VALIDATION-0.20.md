# 0.20 trees and Großräschen buildings

Godot 4.4.1 Mobile/Vulkan, Android Preview versionCode 20 / 0.20.0.

## Map evidence and scope

All 81 existing start-area footprints were compared with a fresh OpenStreetMap API XML snapshot retrieved on 2026-10-04 (bbox 14.003,51.573,14.018,51.583). Every stored coordinate sequence is unchanged. The independent extracted footprint reference and way versions are in assets/data/grossraeschen_footprint_reference.json; `python3 tools/bake_start_area.py snapshot.osm --verify-only` passes.

Google Maps map and satellite views at 51.5759,14.0104 / zoom 18 were manually inspected in the browser. This confirms the relative layout of Seehotel and IBA-Studierhaus west of Seestraße, Seesporthalle east, curved pavilions and the terrace complex south. Map imagery was used as a visual reference; no imagery or Google geometry was copied into the game. Geometry coordinates remain attributed OSM data (ODbL). This verification covers the existing start-area set, not every building around the whole 16 km lake route, and does not establish surveyed centimetre accuracy relative to Google.

The renderer preserves all footprint coordinates. Hotel roofing now follows its two T-shaped wings; roofs no longer bridge the courtyard. Sports hall and mapped flat-roof pavilions use flat roofs. Three IBA cubes are contained within the mapped shared terrace footprint. Window/frame normals are checked toward the polygon exterior. Batching now multiplies size on the local basis columns, preserving rotated windows, piers and rails; the prior global-axis scale distorted them. Cube subdivision, facade detail and untagged roof heights/types are visual assumptions.

## Trees and validation

Three authored tree variants replace regular horizontal pine tiers. Actual trunks/branches carry irregular photographed CC0 needle sprays; distant meshes use simplified versions of the same silhouettes. Start-area broadleaf image cards become spatial crowns. Existing collision RNG and the WP1 tree-contact digest remain unchanged. Tree positions/species remain procedural or photo interpretations, not surveyed individual trees. No new third-party vegetation assets were downloaded.

All fourteen groups pass: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15, vegetation16, graphics19, maps20. Maps20 checks all 81 source footprints, their rendered world-coordinate alignment, containment of the hotel roofs and three terrace cubes, plus rotated detail transform preservation. Stored route integrity passes at 16,010 m with exact start/finish and no >400 m gaps.

Actual software-rendered Mobile/Vulkan captures cover the race, start, lake, three WP previews and a north-up building inspection. Fog is disabled only for the overhead inspection capture to expose the geometry; game fog remains enabled. Final import/captures/export have no shader/script errors. Android APK signature verifies with the unchanged preview signer. Dummy-audio shutdown may emit its existing resource warning. Real Android FPS, memory and device visual acceptance remain unmeasured; this is still procedural prototype art.
