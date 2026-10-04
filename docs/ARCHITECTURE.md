# Architecture

`main.gd` gathers inputs and calls `VehicleDynamics.step`. A fixed accumulator consumes these inputs at fixed 360 Hz on Android (240 Hz selectable) or 720 Hz on desktop, independent of the 60 Hz world-collision/UI tick. `scripts/sim` contains pure tyre and differential functions; JSON describes tyre curves, engine curves and assumptions. The simulation returns vehicle velocity/yaw and wheel telemetry. The scene adapter resolves world contacts, advances the vehicle and updates rendering/audio/HUD. Physics does not import scene meshes or camera/UI code.

The current chassis has longitudinal/lateral translation and yaw. Four wheels have independent angular velocity, inertia, load, slip and tyre state. Algebraic load transfer is interim suspension behavior, not full multibody/6-DOF suspension. Static colliders use Godot; generated shoreline relief is for visual context and is not surveyed physical topography.

The adapter performs collision movement at 60 Hz with shape sweeps. Increasing internal tyre integration frequency does not increase the external collision frequency. Ghosts store world positions and orientation; physics-version changes invalidate old records. Replays are recorded-state playback; numeric operations are repeatable within a tested runtime, with no cross-platform bit identity guarantee.

## 0.13 reduced vertical dynamics

`sim/suspension.gd` integrates body heave, pitch and roll plus four unsprung vertical masses using the same fixed tick as tyre rotation. Spring/damper forces react on both chassis and hub. Tire normal forces are unilateral stiffness/damping contact; they cannot pull a wheel into the ground. Two axle anti-roll elements conserve the pair's force. The old algebraic wheel-load transfer is replaced with these dynamic normal forces. Acceleration enters pitch/roll as inertial load-transfer moments. This is a small-angle, reduced full-car model, not unrestricted quaternion 6-DOF dynamics or correct solid rear axle kinematics.

The scene adapter samples four mapped wheel-ground heights once per world-collision frame and holds them across inner steps. Gravel road and contact queries share a generated piecewise-linear 5 m height profile (up to 3.5 cm undulation), while the original sealed start stays flat. Generated undulations are assumptions, not geographic survey data. Render-frame partition equivalence on flat ground does not prove equivalence for these held moving-ground samples.

Scene body pose and wheel travel use the simulated states. Records now include physics version and tick preset in their comparison key; old values remain in the save dictionary. External collision handling remains at 60 Hz.
