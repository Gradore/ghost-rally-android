# Third-party credits

Terrain3D 1.0.1-stable: Tokisan Games and contributors, MIT license. Full license is in `addons/terrain_3d/LICENSE.txt`; official release: https://github.com/TokisanGames/Terrain3D/releases/tag/v1.0.1-stable . Version is pinned after testing Mobile/Vulkan integration with Godot 4.4.1.

Mapped route, lake, building and pier features: © OpenStreetMap contributors, ODbL; https://www.openstreetmap.org/copyright . Original provenance and attribution are retained in map-data files and existing project documentation.

Google Maps and the user's photographs were visual references for the start area. Google imagery is not shipped as a texture. Most cars remain original procedural prototype meshes; the Lovo uses the user-supplied, adapted Meshy mesh; no assets or code from Richard Burns Rally, NGP or CarX are included.

## 0.14 recorded audio and vegetation

- Recorded engine base: domasx2, “racing car engine sound loops”, loop_0.wav, CC0. https://opengameart.org/content/racing-car-engine-sound-loops . Author describes a public-domain car startup recording edited into a loop; the page's follow-up confirms it was remade from a public-domain source. It is NOT identified as a Volvo B230 or any particular garage car. The game varies playback rate with RPM and amplitude with throttle; gravel/skid sounds remain procedural.
- Pine bark and needle texture atlas: “Pine Tree 01”, Rico Cilliers (modeling), Rob Tuytel (photography), Poly Haven CC0. https://polyhaven.com/a/pine_tree_01 . Only texture maps are used; game branch geometry is authored procedurally. UVs address the needle part of the supplied atlas.
- Gravel Floor and Forest Ground 01: Poly Haven CC0. https://polyhaven.com/a/gravel_floor and https://polyhaven.com/a/forrest_ground_01 . Diffuse, OpenGL normal and roughness maps, 1K resolution. https://polyhaven.com/license .

Real Racing 3 is an input-design reference only; no game code, audio, logo or interface assets are copied.

## 0.25 synthetic assets

Material atlas, panorama sky and oak branch: original synthetic assets generated with built-in Imagegen for this project; prompts in assets/textures/README.md. No Street View screenshots downloaded or shipped. Existing OSM coordinates and all earlier source/license notices retained.

## 0.27 additions
- ambientCG Plaster002 / Bricks001: CC0 1.0, https://docs.ambientcg.com/license/. Unmodified 1K color/normal/roughness maps; source hashes in assets/textures/facades27/provenance.json.
- Rostock elevation: © GeoBasis-DE/M-V, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), DGM1/DGM5 via https://www.geodaten-mv.de/dienste/dgm_wcs, retrieved 2026-10-05. Modified: local coordinate conversion, relative start datum, bilinear 16m grid and road profile. Attribution also appears in game credits.

## 0.28 user vehicle
- Lovo visual based on a model created with Meshy AI, supplied by the user on 2026-10-05. https://www.meshy.ai/ . Modified: decimated body, resized embedded PBR maps, custom horizontal grille, rear centre panel, red lenses and four original unmarked six-spoke wheels. No manufacturer affiliation is implied.
- User instructed use in this project. Meshy plan and source-image rights were not supplied: do not label this asset CC0 or apply the code license to it. If generated on the free plan, the original is available under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/); paid-plan ownership differs. See https://help.meshy.ai/en/articles/10137554-what-is-the-ownership-of-the-generated-models . Attribution is shown in game. Distribution here is a user-authorized development preview; production/commercial legal clearance is not established.
