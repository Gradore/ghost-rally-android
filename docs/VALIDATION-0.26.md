# 0.26.0 local scenery validation — 2026-10-04

25 Godot groups pass: the fifteen AGENTS.md groups, controls22/driving22/tree22/model23/assists23/street23/driving24/graphics24/graphics25 and new local26. Relevant final checks were rerun after facade/sidewalk/roundabout changes.

New local26 verifies that number 17's completion override is applied to the exact source building, no scaffolding is enabled, rendered setback vertices above 14 m are inside its original footprint, all facade vertices are finite, the courtyard over source underground garage 1033343741 remains open, and roundabout decorative centre equals the mean of the original OSM circular line within 1 cm. Two narrow tree instances are present. The test supplies an active camera for Terrain3D.

Existing mv21 and controls22 collision fixtures now correctly exclude explicitly underground/layer-negative source buildings from above-ground collider expectations; above-ground buildings still require colliders. This is an intentional semantic correction, additionally checked at a courtyard position. Source footprint dictionaries still retain every original outline.

Python checks pass: 451 MV source edges, four ordered anchors and 2,137 unchanged building outlines; original stored Großräschen loop 16,010 m, exact start/finish, no >400 m gaps. Full independent original Großräschen snapshot remains unavailable.

Actual software-Vulkan game renders inspected: completed Rostock apartment blocks, bus-stop area, Großräschen roundabout with planters and narrow crowns. Joined sidewalk strips remove gaps at the original road bends. Asphalt material scale/contrast is reduced to avoid the coarse gravel-like appearance in the reference views. Screenshots depict staged camera views in the running game, not a measured driving test.

Android Preview 0.26.0/code26 exports and uses the unchanged preview signing certificate. Physics version remains 24.mobile.1. Original height arrays and route coordinates unchanged. No physical Android device benchmark or 1:1 surveyed facade reconstruction is claimed. Uploaded screenshots are not shipped in the game or repository.
