# 0.13 preview validation

The saved 0.12 source was recovered after workspace maintenance; source baseline is retained in Library.

Suspension tests passed at 240/360/720 Hz: total static tire load equals weight, acceleration/braking transfer has the correct direction, one-wheel bump excites the individual wheel/body, damping settles, airborne normal force is zero, drop landing remains finite and settles. Scene integration tests passed: sealed start stays flat, rendered road and contact heights agree, body heave/pitch reaches the scene, tick presets produce distinct best-time keys.

Existing dynamics, sim, start area, geo, realism, smoke and progression checks passed. Geo/smoke reran after final surface changes. Fixed external-rate simulation comparisons remain tested on flat ground. Native physics, unlimited 6-DOF, actual solid rear-axle kinematics, chassis-ground collision and slope force projection remain unimplemented. Existing ObjectDB cleanup warnings occur on some headless test shutdowns.

Android debug export uses the original preview application ID, same debug signer and version code 13 / 0.13.0. No production signing key was invented. SDK 34 prebuilt templates remain preview-only. No Play Store submission or Android device benchmark.

Final Mobile/Vulkan llvmpipe start/area/inspection capture passed with Terrain3D 1.0.1. Screenshots are real desktop software renders, not evidence of phone frame rate. APK debug signature and packaged arm64 Terrain3D library verified.
