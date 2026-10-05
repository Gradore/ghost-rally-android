# Validation 0.24.0 — 2026-10-04

Godot 4.4.1, Mobile/Vulkan; physics version 24.mobile.1.

All fifteen AGENTS.md Godot groups pass. Additional controls22, driving22, tree22, model23, assists23, street23, driving24 and graphics24 groups pass: **23 groups total**. Smoke's reverse fixture was updated to release/repress the brake for the new deliberate reverse behavior; driving24 independently verifies a held brake cannot launch reverse. The original monotonic thumb-response bound remains unchanged and passes with the new 24/30 response constants.

- Full dry-tarmac braking from 20 m/s: 21.2852 m at 240 Hz, 21.1529 m at 720 Hz. Half pedal: 25.9245 m; quarter: 48.4840 m. Full gravel braking: 31.4746 m. Useful deceleration exceeds 4 m/s² within the first 16.7 ms simulation sample. These are simulation results, not real Volvo stopping measurements or touch-to-photon latency.
- Low-speed full steering reaches over 35° in each direction with assistance on; inner-wheel Ackermann angle exceeds outer-wheel angle. Turn sign remains correct. Handbrake locks rear wheels while front wheels keep rotating.
- Simultaneous left steering, full analogue brake and handbrake from three touch contacts passes; half-up gives proportional throttle, full-down brake, release resets all. Holding service brake while slowing to zero does not reverse; releasing/repressing at rest does.
- Lovo stock acceleration remains 10.4667 seconds to 100 km/h at both integration rates; top speed 184.52/184.50 km/h. Low-speed lateral-slide bounds pass.
- Concave roof vertices remain inside the original footprint; ridge elevated, normals finite/outward. Near leaf geometry stays below 14,000 vertices and far below 3,000 per variant; repeated requests share cached meshes. Existing 81 Großräschen and 2,137 MV footprint/collision tests pass.
- Python source verification: 451 MV route edges and 2,137 source building outlines retained; stored Großräschen 16,010 m loop integrity passes. Full original Großräschen snapshot is unavailable, so independent full-source edge comparison cannot be rerun.

Actual software-Vulkan captures inspected: garage, steering/pedal settings, driving aids, Rostock start, Großräschen start and forest road. Android Preview exports as version 0.24.0/code 24 and is verified using the existing preview certificate. Production configuration is retained.

No phone/emulator is attached. Hardware frame time, physical tilt and touch latency remain unmeasured. The game still uses simplified authored assets and interpreted scenery. This release improves controls, tyre/brake/rack behavior and rendering; it does not establish full six-DOF multibody physics or photorealistic assets.
