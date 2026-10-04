# Validation 0.23.0 — 2026-10-04

Godot 4.4.1, native Android Mobile/Vulkan project. Physics version 23.mobile.1.

## Automated checks

All fifteen required Godot groups pass: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15, vegetation16, graphics19, maps20, mv21. Three 0.22 regressions (controls22, driving22, tree22) pass. New model23, assists23 and street23 groups pass. The Street View test's initial exact-name assertion was corrected to match distinct batched-node names and rerun successfully.

- Actual GLB fixture is written, read and instantiated, fitted to metre dimensions, with four animated wheel nodes. Native collider remains unchanged. Over-budget import falls back. No user vehicle model is present.
- Fixed 240 Hz dry-tarmac braking from 25 m/s: ABS stopping distance 33.3367 m versus 34.7871 m without assist, sustained front-wheel-lock samples 0 versus 125. These are comparisons inside this game, not road test measurements.
- Four-second powerful RWD gravel acceleration: mean rear-wheel slip 0.4093 with traction control versus 0.8433 without; steering assistance preserves direction and bounds high-speed angle.
- Original highway tags identify Mönchhagen footways; roof simplification leaves source vertices unchanged; original-material reference details render as batched meshes.
- Python MV integrity: all 451 route edges match original source ways, four anchors ordered, all 2,137 building footprints retained; 3,438 m modeled unpaved, 1,842 m explicitly tagged. Original Großräschen stored loop: 16,010 m, exact start/finish and no gaps over 400 m. The full original Großräschen source snapshot is unavailable in this workspace, so that source-edge comparison was not rerun; the fresh start-area snapshot is not a full-stage substitute.

## Visual/reference verification

Five dated panoramas were inspected manually in Google Maps. Dates and IDs are recorded in assets/data/streetview_reference.json; one is a 2018 user-contributed 360 panorama, not current official Street View. Historical construction is not reproduced as current. Own procedural materials/geometry are used; no Google pixels are shipped.

Actual in-engine garage, front view, assist-settings, Rostock start and Großräschen start captures rendered with software Vulkan. Garage light/reflections, floor seams, contact shadow and UI were inspected. No fabricated speed/FPS labels. Final Android Preview exported as version/code 0.23.0/23 using the existing preview certificate; production signing configuration retained.

## Remaining limits

No Android phone/emulator is connected: device frame time, physical tilt input and hardware Vulkan behavior are unverified. Street View inspection covers representative landmarks, not every road metre or unpaved path. Fine object offsets are interpretation, terrain is not surveyed, complex pitched roofs remain simplified, and the garage still displays the authored Lovo mesh until the user supplies their GLB. Imported meshes will need asset-specific material, wheel-pivot and mobile-performance checks.
