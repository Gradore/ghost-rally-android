# Unity migration validation — 2026-10-05

User direction: move the existing Ghost Rally to Unity, retain compatible resources and improve driving/graphics.

Executed:
- Godot source export of all 12 cars and 20 route/WP selections.
- Native scenery transfer for all 17 stages, including Großräschen and Rostock using shared mesh cache, vertex colours, mapped terrain and matrix conversion.
- Independent Python coordinate test against original route segments: maximum centreline deviation **2.72 m**, reflecting existing corner smoothing; no substituted fictional route.
- Contiguous WP boundaries match within 0.1 m. All sampled progress values are ordered, finite and end at the exported native stage length.
- All 29 geometric containers have finite attributes, valid triangle indices and available referenced textures. All 48 independent wheel names are present.
- Lovo mass 1350 kg, wheelbase 2.77 m, radius 0.317 m and source stock torque curve retained as provisional calibration.
- All 15 C# files parse with a C# grammar parser. Unity runtime/API/shader compilation was not executed.

The previous Godot 0.30 baseline independently passed all 29 regression scripts and both Python route checks, and its preview export succeeded before the user changed the target engine. Those results are legacy evidence only.

Not executed: Unity import, Unity C# API compile, shader compile, EditMode/play-mode physics tests, Unity screenshots, Unity APK/AAB, Android device benchmarking and licence/signing validation. No Unity editor is installed in this environment. The prepared build path requires an activated editor with Android modules or appropriate CI activation.

Primary scenery has large imported node counts and needs profiling. Spatial range culling, shared meshes/materials and ASTC import policies are implemented source-level optimisations, not measured FPS proof. The other 15 stages retain their previous authored procedural scenery; model shape, detailed audio, menu/controller calibration parity and gameplay acceptance are unfinished.

Terrain3D/M.A.V.S are Godot add-ons; their native binaries are not Unity assets. Compatible terrain/geometry/data transfer is used. The Rally One mod APK was identified as Unity/IL2CPP, but no proprietary executable, code, texture or audio was copied. Its internal physics/menus were not runtime-observed, so matching them is not asserted.
