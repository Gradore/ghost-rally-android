# 0.18 graphics validation

Godot 4.4.1 Mobile/Vulkan, Android Preview versionCode 18 / 0.18.0.

All twelve headless groups passed: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15, vegetation16. Shader validation after adding alpha-to-coverage and directional sun passed without compilation errors. Stored 16,010 m route integrity passes. Tree collider digest and progression keys remain unchanged.

Actual software-rendered Mobile/Vulkan captures cover the start, lake area, chase view, three WP previews and a close three-quarter car view. APK exports and verifies with the existing preview signer. Existing Dummy-audio shutdown resource warning remains. No physical Android FPS/memory or device visual acceptance is claimed.

Mesh batching affects static visuals only: labelled badges and wheel pivots remain separate; car collision geometry and simulation configs are unchanged. Original texture credits retained; new crown geometry and shaders are authored. This remains a procedural art prototype, below reference-quality authored assets.
