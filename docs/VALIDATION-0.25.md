# 0.25.0 graphics validation — 2026-10-04

Godot 4.4.1 native Android Preview, physics version unchanged 24.mobile.1.

All fifteen required Godot groups and controls22/driving22/tree22/model23/assists23/street23/driving24/graphics24 pass (23 existing groups). New graphics25 passes (24 total): material cache identity, atlas availability, 2:1 sky projection, leaf alpha, Terrain3D shore texture bits and preserved source heights. Following final terrain/foliage changes, graphics25, graphics24, graphics19, vegetation16, start_area, maps20, mv21 and controls22 were rerun successfully.

Python MV source check passes: 451 route edges, four ordered anchors, 2,137 original building footprints. Stored Großräschen loop check passes: 16,010 m and exact start/finish. Independent full-source Großräschen check still requires its unavailable full original snapshot. Neither route nor building source coordinates were changed.

Reference raster generator produces 535 Großräschen and 522 Rostock stations, 30 m between regular stations plus the final remainder. No Google screenshots were captured and no Street View coverage is claimed. Separate screenshot collection was not executed because Google's current geo guidelines prohibit screenshotting/extracting Street View imagery.

Synthetic atlas, equirectangular LDR sky and transparent oak branch were generated using built-in Imagegen and integrated into the project. Original prompts/provenance retained in assets/textures/README.md. Existing asset licenses preserved. Shared material caching and existing foliage budgets retained. No photorealistic 1:1 reconstruction or original detailed car meshes are claimed.

Software-Vulkan actual game captures: garage, front garage, controls, assists, Rostock, Großräschen, forest. Android package/version/signature verified using existing preview certificate. No Android device is attached; actual phone FPS, memory pressure, thermal behavior and shader quality remain unmeasured.
