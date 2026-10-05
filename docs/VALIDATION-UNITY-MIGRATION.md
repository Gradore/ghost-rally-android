# Unity migration validation — 2026-10-05

User direction: move the existing Ghost Rally to Unity, retain compatible resources and improve driving/graphics.

Executed:
- Godot source export of all 12 cars and 20 route/WP selections.
- Native scenery transfer for all 17 stages, including Großräschen and Rostock using shared mesh cache, vertex colours, mapped terrain and matrix conversion.
- Independent Python coordinate test against original route segments: maximum centreline deviation **2.72 m**, reflecting existing corner smoothing; no substituted fictional route.
- Contiguous WP boundaries match within 0.1 m. All sampled progress values are ordered, finite and end at the exported native stage length.
- All 29 geometric containers have finite attributes, valid triangle indices and available referenced textures. All 48 independent wheel names are present.
- Lovo mass 1350 kg, wheelbase 2.77 m, radius 0.317 m and source stock torque curve retained as provisional calibration.
- All 16 C# files parse with a C# grammar parser. All three local assembly definitions resolve their game/test references. A missing `GhostRally.Runtime` definition was repaired.
- Separate managed API compilation of Runtime, Editor, EditModeTests and PlayModeTests passed against the installed 6000.0.82f1 engine and its bundled 3D template assemblies (`tools/unity/check_unity_api.py`). These bundled package references do not prove resolution of the project manifest.
- A real Unity 6000.0.82f1 Linux editor was downloaded and started twice for `BuildProject.Prepare`. Both runs failed to initialise the licensing-client IPC channel before project import. Starting the bundled licensing client separately did not resolve the connection.
- Automatic GitHub Android run **37300875738** passed source/data validation and failed activation preflight: `UNITY_LICENSE` was empty. No engine test or APK step executed.

The previous Godot 0.30 baseline independently passed all 29 regression scripts and both Python route checks, and its preview export succeeded before the user changed the target engine. Those results are legacy evidence only.

Still unverified: Unity project/package import, editor compilation through the actual asset pipeline, shader compile, EditMode/PlayMode test execution, Unity screenshots, Unity APK/AAB and Android device benchmarking. An installed editor alone does not provide activation. The local runtime cannot connect to its licensing client in this environment, and hosted CI has no activation secret. Android Build Support/SDK/NDK/OpenJDK still need installation in the eventual activated build environment.

`tools/unity/build_preview.py` prepares the project, runs both test suites, refuses absent/failed test reports, builds a fresh APK and checks its ZIP integrity plus ARM64 Unity library. The added PlayMode acceptance case requires four wheel contacts, forward acceleration and reduced speed after braking. Those assertions have not yet been executed. The automatic workflow prepares/builds before its test step so generated settings are present in the next editor process, and uploads the APK only after tests pass. The kinematic countdown/recovery reset no longer attempts unsupported velocity writes.

Primary scenery has large imported node counts and needs profiling. Spatial range culling, shared meshes/materials and ASTC import policies are implemented source-level optimisations, not measured FPS proof. The other 15 stages retain their previous authored procedural scenery; model shape, detailed audio, menu/controller calibration parity and gameplay acceptance are unfinished.

Terrain3D/M.A.V.S are Godot add-ons; their native binaries are not Unity assets. Compatible terrain/geometry/data transfer is used. The Rally One mod APK was identified as Unity/IL2CPP, but no proprietary executable, code, texture or audio was copied. Its internal physics/menus were not runtime-observed, so matching them is not asserted.
