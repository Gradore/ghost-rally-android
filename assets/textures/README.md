# Texturen und Bildgenerierung

Diese sechs PNG-Assets wurden mit der integrierten Bildgenerierung neu für GHOST RALLY erstellt und anschließend unverändert in `assets/textures/` übernommen. Die Prompts waren:

- `gravel_v10.png`: Nahtlos kachelbare PBR-Albedo, kompaktierter deutscher Wald-Schotterweg, beige-graue Steine, Staub, orthografisch von oben, diffuse Beleuchtung, keine Markierungen oder Objekte.
- `ground_v10.png`: Nahtlos kachelbare PBR-Albedo, mitteleuropäischer Wiesen- und Waldboden, kurzes Gras, Blätter und Erdstellen, orthografisch von oben, diffuse Beleuchtung.
- `asphalt_v10.png`: Nahtlos kachelbare PBR-Albedo, abgenutzter deutscher Asphalt einer Nebenstraße, graues Mineralaggregat, feine Patina, von oben, keine Markierungen.
- `spruce_v10.png`: Einzelne realistische mitteleuropäische Fichte als freigestellter Baum mit transparentem Hintergrund, gerade Seitenansicht und vollständiger Silhouette.
- `oak_v10.png`: Einzelner realistischer mitteleuropäischer Laubbaum als freigestellter Baum mit transparentem Hintergrund, gerade Seitenansicht und vollständiger Silhouette.
- `facade_v10.png`: Kachelbare Albedo einer mitteleuropäischen Stadtfassade, heller Putz, regelmäßige dunkle Fenster, frontale orthografische Ansicht, keine Schilder oder Personen.

Die Dateien sind Spielgrafiken. Die Bildgenerierung garantiert keine mathematisch exakte Kachelung; der Godot-Import nutzt Mipmaps und wiederholte UVs für den Einsatz im Spiel.

## 0.25: neue synthetische Material-Assets

Mit dem eingebauten Imagegen-Werkzeug neu erzeugt und unverändert übernommen; keine Google-Pixel und keine örtlichen Fotogrammetrie-Aufnahmen:

- `material_atlas25.png`: sechs gleich große orthografische Materialfelder in 3×2 Anordnung: oben Asphalt / norddeutscher Ziegel / heller Putz; unten Sand / kurzes Gras / mineralischer Schotter. Neutral diffuses Licht, keine Beschriftung, kein Rahmen, keine Perspektive, für wiederholte Albedo-Texturen. Prompt: "Six equal square panels, exact 3 columns by 2 rows, edge to edge ... gray worn German rural asphalt ... red-brown brick wall ... warm off-white lime plaster ... pale tan sand ... dense short natural green grass ... gray-beige gravel ... orthographically with flat neutral diffuse overcast illumination ... original synthetic material design."
- `sky25.png`: 360°-Panorama mit 2:1-Projektion, norddeutscher Frühlingshimmel mit Cumuli und Cirrus, Horizont in Bildmitte, untere Hälfte neutral, ohne Landschaft. Prompt: "game sky equirectangular panorama texture ... seamless 360 degree latitude-longitude ... natural central/northern German late spring daytime ... blue sky ... scattered cumulus and wispy cirrus ... no buildings, vegetation, land silhouettes, roads, water, text, logos."
- `oak_branch25.png`: freigestellter Eichen-Laubzweig mit Blattadern und feinen Ästen, kein kompletter Baum. Prompt: "single transparent game foliage card ... European pedunculate oak ... about 16 overlapping ... authentic lobed outlines ... neutral diffuse summer daylight ... entire twig visible ... no pot, tree trunk, ground, grass, sky, text or frame."

Die Texturen wirken fotografisch, sind aber synthetisch und keine identischen Oberflächen aus Großräschen oder Rostock. Seamless-Kachelung ist nicht garantiert. Der Shader nutzt begrenzte Atlasfelder, Mipmaps, Gradienten und Materialmaßstäbe; Terrain3D erhält zur Laufzeit regionale Kopien der Gras-/Sandfelder. Die bestehenden CC0-Normalmaps bleiben erhalten. Quelle und Erzeugungsprompts werden hier dokumentiert.
