# Ghost Rally engineering rules

- Preserve the native Android game and the original mapped stages. Refer to `PLANS.md` for milestones.
- Build: Godot 4.4.1 `--headless --editor --import`, then `--headless --export-debug 'Android Preview' <absolute.apk>`.
- Test: Godot `--headless --script tools/dynamics_test.gd`, `tools/sim_test.gd`, `tools/start_area_test.gd`, `tools/geo_test.gd`, `tools/realism_test.gd`, `tools/smoke_test.gd`, `tools/progression_test.gd`, `tools/suspension_test.gd`, `tools/suspension_integration_test.gd`, `tools/upgrade14_test.gd`, `tools/upgrade15_test.gd`, `tools/vegetation16_test.gd`, `tools/graphics19_test.gd`, `tools/maps20_test.gd`; Python `tools/route_integrity_test.py <OSM snapshot>`.
- Keep physics separate from rendering/UI; use SI units and fixed 240/360 Hz Android or 720 Hz desktop integration ticks. No frame-time dependent force updates.
- Mark invented parameters with `_assumption: true` in configs and update `docs/ASSUMPTIONS.md`. Never claim reference-equivalent physics or surveyed terrain without evidence.
- Do not copy proprietary or GPL game code/assets. Preserve existing asset licenses.
- Do not commit failing tests. The user authorized continued development in GitHub on 2026-10-04; publish changes on a review branch. Production signing key must not be replaced.
