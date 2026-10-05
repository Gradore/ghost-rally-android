# ADR 0001: retain Godot for the requested Android continuation

Status: accepted for the native build; the browser stack remains a possible separate port.

The supplied master prompt prefers strict TypeScript, Vite, Three.js and query-only Rapier. This task already has a working Godot/GDScript Android game, mapped stages, touch input and a verified APK export. The user asks to include the prompt in this build, while retaining the Android/Play Store objective. A wholesale browser rewrite would replace that deliverable and invalidate the existing export work.

Therefore retain Godot 4.4.1 and GDScript, with an independent RefCounted simulation core, explicit fixed substeps, separate tyre/driveline functions, JSON configs, headless CLI tests and captures of the real renderer. Godot CharacterBody3D performs world collision queries; VehicleBody3D is not used. No Rapier is needed in this native path. C# is also deferred to avoid an unnecessary language/export migration.

A browser port should reuse the config schemas and behavior tests, but requires an explicitly scoped TS implementation and WebGL test adapter. Neither bit-identical cross-platform determinism nor 60 fps on phones is claimed. Ghosts play recorded states rather than resimulating inputs.
