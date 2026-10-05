# Validation 0.28.0

2026-10-05, Godot 4.4.1 Linux: all 27 GDScript groups passed (15 AGENTS-required, all 0.22–0.27 regression groups and model28). After the final front/rear material and lamp-placement revision, model28 and graphics19 passed again against the final imported model.

- Final GLB: 30,570 triangles vs 951,340 source triangles; 9,967,984 bytes, embedded maps capped at 2048px. Godot imports automatic LODs/shadow meshes and embeds Basis Universal textures. No generated duplicate JPGs are committed.
- Actual asset loads in metres, four wheel origins centered on native physics axles, 317mm tyre radius, front wheel steering and rolling verified. Native collider equals a procedural fixture with the same dimensions. Imported lenses use each car's own live brake material. Old hidden procedural wheel meshes are freed after a successful import.
- Native acceleration/braking, low-speed grip, handbrake/joystick, fixed-step simulation, suspension, tilt calibration and building collision regressions pass. Physics version stays 27.terrain.1; this update does not change forces, stock performance or collision shapes.
- Python MV route integrity and stored Großräschen route checks pass. Full independent Großräschen source-XML comparison was not rerun.
- Godot import and Android Preview export succeed. The headless Dummy texture backend emits its texture_2d_get warning while importing embedded maps; actual Mobile/Vulkan rendering has working textures. The Android adb-daemon warning is unrelated to APK export; no device is attached.
- APK signature verified. Package com.ghostrally.racer.preview27, versionCode 28 / 0.28.0, same debug SHA-256 certificate d53f7b22229e11c150364c495974d957a8cbc395caa6610f488716b9f4f986d1 as 0.27. Production signing untouched.

Actual Mobile/Vulkan llvmpipe game captures checked: front/rear garage, Rostock chase with braking, head-on front detail. These are game frames, not generated mockups. Physical Android FPS, thermals and memory have not been measured. The retained source body has AI panel/texture defects, baked reflections and opaque-looking glass; no factory-equivalent interior or full photorealism is claimed. Visible manufacturer identifiers are overridden/replaced, but trademark/design/source-image clearance is not established; see CREDITS.md and assets/vehicles/NOTICE.txt.
