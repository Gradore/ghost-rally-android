# 0.19 graphics validation

Godot 4.4.1 Mobile/Vulkan; Android Preview versionCode 19 / 0.19.0.

All twelve existing groups passed: dynamics, sim, start_area, geo, realism, smoke, progression, suspension, suspension_integration, upgrade14, upgrade15, vegetation16. A thirteenth graphics19 regression checks outward loft normals including both end caps and finite wheel geometry with no more than four material meshes per wheel across all twelve cars. Stored 16,010 m route integrity passes; no new survey or OSM comparison was performed. WP1 tree collider digest remains unchanged.

Actual Mobile/Vulkan software captures cover start, lake, chase, all three WP previews and a rear three-quarter vehicle view. No shader/script errors in final captures or export. Android APK signing verification uses the unchanged Godot preview signer. Physical Android FPS, memory and visual acceptance remain unmeasured.

Rounded tyres, tread material and recessed rim details are visual only. Wheel spin/steering pivots remain articulated; vehicle physics, collision shapes, progression and route coordinates are unchanged. Static wheel parts are merged by shared material. The sky reflection cubemap uses 128-pixel resolution; no extra reflection probe or postprocessing pass was added. This remains a procedural graphics prototype, below high-end authored reference assets.

The loft normal regression corrects a pre-existing inward orientation affecting side panels and glass. The gear/speed display is separated to avoid treating first gear plus zero speed as 1,000 km/h. Existing Dummy-audio shutdown resource warning may occur when capturing; no physical-device benchmark is inferred from the software renderer.
