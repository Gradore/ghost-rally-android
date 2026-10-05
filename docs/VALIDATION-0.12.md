# Validation: 0.12 preview

Godot 4.4.1 Linux, October 3, 2026.

- Final headless sim, start-area, geographic and smoke checks passed after pinning Terrain3D 1.0.1. Earlier dynamics, realism and progression checks also passed.
- Fixed-tick partition tests cover 30/60/120/144 Hz callers; 240/360/720 Hz presets; grip/braking, MF combined slip, torque conservation, turbo lag and independently rotating airborne wheels.
- Route integrity checks match the closed 16,010 m Brandenburg route to connected source OSM edges.
- Real Mobile/Vulkan screenshots ran through start, moving gameplay and stationary inspection. Desktop llvmpipe is a software renderer; no Android-device performance claim. Terrain has four 512 regions. Some test shutdowns report existing ObjectDB cleanup warnings.
- Terrain3D 1.0.2 integration crashed in a longer moving Vulkan capture. The final pinned 1.0.1 version with corrected texture assets completed the capture. This does not identify a single proven upstream cause.
- Debug APK signature verified with Android apksigner; package com.ghostrally.racer.preview, version 0.12.0/code 12. Native arm64 Terrain3D library and extension descriptor verified inside APK.
- Preview still targets SDK 34 using existing prebuilt export templates. It is not a Play Store production submission. Production signing, updated Store-compatible build configuration, Console declarations and device acceptance remain outstanding.

Current wheel bodies retain rotational inertia but not full vertical multibody dynamics. No C#/native simulation core or gdUnit4 integration is claimed. Seven minutes is a design target; neither stage lengths nor handling are falsified to guarantee that time for every car. Reference graphics, exact VOC compliance and RBR-equivalent handling remain unfulfilled acceptance targets.
