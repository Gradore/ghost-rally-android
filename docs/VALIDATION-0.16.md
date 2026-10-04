# 0.16 graphics validation

Godot 4.4.1, Mobile/Vulkan, Android Preview com.ghostrally.racer.preview, versionCode 16.

The eleven existing headless groups passed. Added vegetation validation passes: WP1 has 299 spatial broadleaf trees and 16,254 batched grass clumps; grass visibility ends at 85 m. After the final chunk/LOD edit, vegetation validation and the connected three-WP regression passed again. Original 0.15 WP1 tree collider hash c9b07e3a318c1e81ab9c1a6cea2ba60e65f82ed57e0ab2db064a675f3e5941ff is preserved exactly. Stored route integrity passes.

Actual Mobile/Vulkan software-rendered views cover the start, lake area, racing and all three pre-race stages. Retain 2x MSAA. Existing Dummy-audio shutdown leak warning remains. Android APK exported with the existing preview signer; no production signing or Play publication. A physical Android test and FPS/memory measurements remain open; higher vegetation detail is not a demonstrated 60 fps result.

No new third-party assets were downloaded. Original procedural mesh/shader work reuses existing licensed bark, oak, gravel and ground textures; credits are preserved.
