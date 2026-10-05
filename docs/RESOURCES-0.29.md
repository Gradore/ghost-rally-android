# 0.29 — Lovo reconstruction and resource integration

The supplied Meshy silhouette is now a guide for original closed reference geometry rather than an overlapping source mesh. The 39,878-triangle, 2,016,368-byte GLB contains no baked source images. One static multi-material body and four independent wheels preserve native steering/rotation/brake lights. Rounded 195/65R15 tyres have shoulder profile, tread grooves and recessed unmarked 15-inch five-spoke rims. Body includes roof crown, clear panel outlines, smoked windows, mirrors, handles and light/grille detail. Garage framing is closer and lower. These are artistic proportions, not a measured factory model.

Terrain3D 1.0.2 replaces 1.0.1 from the user archive, preserving platform binaries and MIT notices. CC0 ambientCG Ground037 packed maps from its demo replace the synthetic grass tile on Großräschen lake terrain. Rostock DGM geometry, original OSM routes and collision remain unchanged.

M.A.V.S. MIT camera ideas and implementation are adapted into a standalone helper: right-stick/numpad orbit, bounded vertical look, automatic reverse view and frame-rate independent recenter. Main vehicle forces, native fixed integration and calibrated Lovo specification are retained. M.A.V.S. whole controller targets Godot 4.5; it is not installed into this Godot 4.4.1 game.

Open Throttle is GPL-3.0. Repository rules prohibit copying GPL game code/assets, so it serves as a feature reference only. All shipped third-party additions here are MIT or CC0. No GPL files are bundled.

Preview 0.29 uses the same isolated preview27 Android package and debug certificate as 0.27/0.28, retaining local data on update. Production signing is unchanged. Desktop software-Vulkan captures demonstrate appearance; no Android-device frame-rate benchmark is claimed.
