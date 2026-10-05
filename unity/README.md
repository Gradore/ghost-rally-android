# Ghost Rally Unity migration

Unity is the user's requested new engine as of 2026-10-05. This directory is a Unity 6.0 LTS / URP Android project within the existing repository. The previous Godot implementation stays available as a verified reference while the migration is tested.

## Included source implementation

- All 12 original vehicle choices and their separate wheel pivots. Lovo retains the clean original body reconstruction, 195/65R15 treaded wheels and PBR factors.
- All 17 mapped routes; Großräschen also has three separately selectable, contiguous WPs. Sampling calls the existing route loader, corner smoothing, width, surface and road-height methods before reflecting Z for Unity.
- All 17 authored scenery snapshots, shared meshes/materials, vertex tints, official Rostock DGM geometry and reconstructed lake terrain. Tiny grass clusters are bounded during export; spatial 256 m scenery groups are culled by range in Unity. The remaining stages retain their original authored procedural scenery; their elevation and photographic fidelity are not survey-certified. Fallback geometry is only used if a snapshot is absent.
- Four independent WheelColliders, 6-DOF Rigidbody chassis, spring/damper/anti-roll coupling, front Ackermann steering, stock torque curves, automatic gearbox and brake-to-reverse latch; ABS/TC and individual ground-surface grip. Unity's slip-based model replaces the custom Godot planar solver: reference-equivalent handling is not asserted.
- Touch thumb steering, tilt calibration, analogue pedal joystick, automatic gas respecting analogue input, keyboard and mapped gamepad. Camera includes speed FOV, reverse view and collision avoidance.
- Garage, scrollable stage selector, countdown/race/pause/recovery/result transitions, ordered progress gates, minimap, best-time/RC storage, paid upgrades excluding VOC engine upgrades, timestamped independent Unity ghosts, next-WP action, licence view and recorded CC0 engine loop.
- URP HDR, ACES tone mapping, low-intensity bloom, sun/soft shadows, distance fog, shared instanced PBR materials, world-projected facade texture/normal maps, Android ASTC 6x6 and 1K texture limits.

## Open and build

Use Unity Hub to install **6000.0.82f1** with Android Build Support, SDK/NDK and OpenJDK. Open `unity`, allow package import, then run **Ghost Rally → Prepare Unity Android project** and enter Play Mode. This generates the renderer asset and bootstrap scene. The project intentionally contains no activation or production signing files.

Run `python tools/unity/build_preview.py` from the repository root for preparation, actual EditMode/PlayMode tests and the APK build. Use `--unity "path/to/Unity"` if the activated editor is installed elsewhere. It stops on failed/absent test results, removes stale APKs and verifies the ARM64 Unity runtime in the resulting APK. Logs and test XML stay in `unity/Logs/`. Linux PlayMode tests require an X display or `xvfb-run`; they use OpenGL and deliberately keep graphics enabled. The graphics test renders the transferred Lovo on the mapped Rostock start and writes `unity/Logs/Unity-Rostock-Lovo-render.png`. Blank frames and missing-shader magenta fail acceptance.

Batch commands are in `AGENTS.md`. The workflow `.github/workflows/unity-migration.yml` runs source validation and attempts the licensed Android build on each relevant PR update or manual dispatch. It only uploads the APK after Unity tests pass. It requires the repository secrets `UNITY_LICENSE`, `UNITY_EMAIL` and `UNITY_PASSWORD` (GameCI activation). Never paste passwords or licences into source files or chat. No existing Unity licence is assumed. Preview ID: `com.ghostrally.racer.unitypreview`, code 1001. Store publishing/signing remains a separate release task.

## Automated environment setup

Install the official [Unity CLI](https://docs.unity.com/en-us/unity-cli/use-unity-cli), then run `python tools/unity/setup_build_environment.py --sign-in`. This installs the pinned editor and Android modules, executes Java/NDK/ADB/aapt2 checks, and opens Unity's own account login. For an existing installation use `--verify-only`. Signing in and installing modules do not establish that an editor licence is active: complete the appropriate Unity account licence activation, then run `build_preview.py` for actual acceptance.

On 2026-10-05, editor 6000.0.82f1, Android Build Support, OpenJDK 17.0.18, NDK r27c, SDK build tools 36.0.0 and Android API 36 were installed in the working environment. Executable tool checks passed. Native local socket creation is blocked here: both editor licensing IPC and Xvfb display startup fail. Account sign-in has not completed. Therefore this session cannot claim an activated build worker; the GitHub job or another activated worker must pass the engine tests before delivery.

## Reproduce the transfer

Run Godot 4.4.1 `--headless --script tools/unity/export_native.gd`, then `python tools/unity/convert_glb.py /tmp/ghost-unity-export unity/Assets/Resources/Migration/Geometry`. Run `tools/unity/export_scenery.gd` with the same Godot binary for all original scenery. GRMesh containers are z-reflected vertex/index data with scene transforms, materials and source texture references. Gzip compression is supported by the Unity importer; compressed scene data does not alter decoded geometry. Texture/config/audio inputs are retained in `Assets/Resources/Migration` with provenance.

## Acceptance still required

Unity editor package resolution/API compile, custom importer/shader compile, EditMode/PlayMode tests and Android build have **not passed** in the available environment. The 2026-10-05 automatic Android job reached activation preflight and failed because `UNITY_LICENSE` was empty (run 37300875738). Installing the editor alone does not activate it. The C# grammar, local assembly references, independent transfer checks and separate managed API compilation against installed editor/template assemblies passed. Actual Unity package import/shader/runtime compatibility remains unverified. The local editor starts but cannot initialise licensing-client IPC; GitHub activation preflight also fails. On-device driving, thermal/FPS/memory performance and comparison with Rally One remain untested. Full UI parity/localisation/controller calibration, per-stage graphics authoring and rendering-quality acceptance remain open. The transferred Lovo body remains visibly stylised; Unity does not automatically increase model detail. No Unity screenshot, installable Unity APK, reference-equivalent physics or production readiness is claimed.
