# Ghost Rally Unity migration

Unity is the user's requested new engine as of 2026-10-05. This directory is a Unity 6.0 LTS / URP Android project within the existing repository. The previous Godot implementation stays available as a verified reference while the migration is tested.

## Included source implementation

- All 12 original vehicle choices and their separate wheel pivots. Lovo retains the clean original body reconstruction, 195/65R15 treaded wheels and PBR factors.
- All 17 mapped routes; Großräschen also has three separately selectable, contiguous WPs. Sampling calls the existing route loader, corner smoothing, width, surface and road-height methods before reflecting Z for Unity.
- Both primary authored scenery snapshots, shared meshes/materials, vertex tints, official Rostock DGM geometry and reconstructed lake terrain. Tiny grass clusters are bounded during export; spatial 256 m scenery groups are culled by range in Unity. Other stages currently use fallback ground/vegetation, retaining their original mapped alignment. Their authored context is not yet migrated visually.
- Four independent WheelColliders, 6-DOF Rigidbody chassis, spring/damper/anti-roll coupling, front Ackermann steering, stock torque curves, automatic gearbox and brake-to-reverse latch; ABS/TC and individual ground-surface grip. Unity's slip-based model replaces the custom Godot planar solver: reference-equivalent handling is not asserted.
- Touch thumb steering, tilt calibration, analogue pedal joystick, automatic gas respecting analogue input, keyboard and mapped gamepad. Camera includes speed FOV, reverse view and collision avoidance.
- Garage, scrollable stage selector, countdown/race/pause/recovery/result transitions, ordered progress gates, minimap, best-time/RC storage, paid upgrades excluding VOC engine upgrades, timestamped independent Unity ghosts, next-WP action, licence view and recorded CC0 engine loop.
- URP HDR, ACES tone mapping, low-intensity bloom, sun/soft shadows, distance fog, shared instanced PBR materials, world-projected facade texture/normal maps, Android ASTC 6x6 and 1K texture limits.

## Open and build

Use Unity Hub to install **6000.0.82f1** with Android Build Support, SDK/NDK and OpenJDK. Open `unity`, allow package import, then run **Ghost Rally → Prepare Unity Android project** and enter Play Mode. This generates the renderer asset and bootstrap scene. The project intentionally contains no activation or production signing files.

Batch commands are in `AGENTS.md`. The manually triggered workflow `.github/workflows/unity-migration.yml` has source validation plus a separate licensed Android build. It requires the repository's `UNITY_LICENSE` secret. No existing Unity licence is assumed. Preview ID: `com.ghostrally.racer.unitypreview`, code 1001. Store publishing/signing remains a separate release task.

## Reproduce the transfer

Run Godot 4.4.1 `--headless --script tools/unity/export_native.gd`, then `python tools/unity/convert_glb.py /tmp/ghost-unity-export unity/Assets/Resources/Migration/Geometry`. Run `tools/unity/export_scenery.gd` with the same Godot binary for the primary scenery. GRMesh containers are z-reflected vertex/index data with scene transforms, materials and source texture references. Gzip compression is supported by the Unity importer; compressed scene data does not alter decoded geometry. Texture/config/audio inputs are retained in `Assets/Resources/Migration` with provenance.

## Acceptance still required

Unity editor package resolution/API compile, custom importer/shader compile, EditMode tests and Android build have **not** run in the available environment because the Unity editor is absent. The C# grammar and independent transfer checks passed; that does not certify Unity compatibility. On-device driving, thermal/FPS/memory performance and comparison with Rally One remain untested. Full landscape context for the other 15 routes, full UI parity/localisation/controller calibration and rendering-quality acceptance remain open. The transferred Lovo body remains visibly stylised; Unity does not automatically increase model detail. No Unity screenshot, installable Unity APK, reference-equivalent physics or production readiness is claimed.
