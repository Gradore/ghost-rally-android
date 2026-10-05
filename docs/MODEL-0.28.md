# Lovo Meshy integration 0.28

The user's two uploads represent the same 951,340-face sedan. The file named OBJ is actually an archive containing OBJ/MTL/PNG; the embedded-PBR GLB is used as the processing source. Raw originals are not added to the repository or APK. Source and processed hashes are recorded in assets/vehicles/provenance28.json.

The mobile model has 30,570 triangles (96.8% fewer), approximately 9.6MiB, and embedded PBR maps capped at 2048px. The retained body still has AI-generated geometry irregularities and baked reflections. It is an improved silhouette/mesh, not a factory-exact body or finished photorealistic model.

Four fused source wheels are removed and replaced with original unmarked six-spoke wheels. Source wheel hubs are removed; source grille markings use an untextured replacement material; the centre rear region uses an untextured material and its raised emblem relief is flattened. A horizontal grille replaces the identifying front component. The fictional garage/game name remains Lovo 940 VOC. Original unused atlas pixels may retain source details but are not mapped onto these replacement surfaces. No manufacturer affiliation or complete legal clearance is claimed.

Wheel meshes are reparented with preserved metre scale onto the native physics pivots and centered on those axles. Hidden old wheel meshes are freed. Wheel rolling, steering, suspension motion and brake lamps follow simulation state. Imported red lenses use each car's own native brake material, avoiding shared-material leakage. Ghosts retain the inexpensive procedural appearance.

Native 131 PS, 185 km/h, existing 0–100 target, tyre dynamics, suspension, fixed integration rate and building/car colliders are unchanged. No model-derived physics shapes are generated. Missing/rejected visual imports retain the procedural car. The garage initially faces the front of the car.

Licensing: user-authorized project integration; Meshy attribution and modifications documented in CREDITS.md and shipped NOTICE.txt. The generation plan/source imagery rights are unknown. Free-plan CC BY 4.0 and paid-plan ownership differ. Renaming and debranding do not establish trademark/design clearance, including for Lovo or the overall silhouette. Production/commercial release needs separate rights assessment.

Android Preview 0.28.0 uses com.ghostrally.racer.preview27, versionCode 28, the same debug certificate as 0.27. It can update that isolated preview and preserve its data. Store/production package and signing are untouched.
