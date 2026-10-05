# Ghost Rally — Unity migration

The user explicitly selected Unity on 2026-10-05. Unity is the new development target; retain the Godot baseline until Unity editor/runtime and Android acceptance pass. Root legacy Godot commands do not validate Unity.

- Project: Unity 6000.0.82f1, URP 17, Android ARM64, Input System. Use `GhostRally.Editor.BuildProject.Prepare` before Play Mode or builds. The bootstrap is created by RuntimeInitializeOnLoadMethod.
- Verify data: `python tools/unity/validate_migration.py`; syntax: `python tools/unity/check_csharp_syntax.py` from repository root.
- Full local preview command: `python tools/unity/build_preview.py --unity <editor executable>`; includes prepare, both test suites and a fresh APK/archive check.
- Managed API check: `python tools/unity/check_unity_api.py --unity-data <Editor/Data>` uses bundled template references and does not prove actual project package import or runtime.
- Actual Unity tests: `Unity -batchmode -nographics -projectPath unity -runTests -testPlatform EditMode -testResults <absolute.xml> -logFile <absolute.log>`. Do not use `-quit` with asynchronous test runner.
- APK: activated Unity editor with Android Build Support, SDK/NDK and OpenJDK: `Unity -batchmode -nographics -quit -projectPath unity -executeMethod GhostRally.Editor.BuildProject.AndroidPreview -logFile <absolute.log>`.
- Physics uses Unity Rigidbody/WheelCollider at 120 Hz with wheel substeps. Treat all tuning as provisional assumptions. Old Godot fixed integration tick and physics test results are not interchangeable with Unity physics.
- No proprietary Rally One APK code/assets, no GPL Open Throttle code/assets, no Godot-native Terrain3D/M.A.V.S binaries in Unity. Preserve resource attribution and original vehicle provenance.
- Source/data/grammar tests are not evidence of successful Unity API compilation, rendering, device FPS, feel or signed APK build. Report those gaps.
- Review branch only. Unity preview uses a separate package. Do not replace or disclose production signing keys or commit license/activation files.
