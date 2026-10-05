# 0.15 validation

Godot 4.4.1 official, native Android Preview, package com.ghostrally.racer.preview, versionCode 15.

Eleven headless test scripts passed: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15. Route integrity checks pass for the stored 16,010 m loop; original OSM snapshot was unavailable for source-edge revalidation. Three connected WPs and per-WP records are preserved.

Upgrade15 regression tests exercise the finish-to-result update, duplicate completion, pause input reset and timestamp/height ghost interpolation across a collision penalty.

Actual Mobile/Vulkan captures use desktop llvmpipe, not a phone. 4x MSAA triggered a driver/render-thread crash; retain the existing 2x MSAA setting. Dummy audio may warn at shutdown. APK built with the existing preview signing key. A physical Android-device test, FPS benchmark, full-reference graphics and vehicle-specific sound authenticity remain unverified.
