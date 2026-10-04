# Texturen und Bildgenerierung

Diese sechs PNG-Assets wurden mit der integrierten Bildgenerierung neu für GHOST RALLY erstellt und anschließend unverändert in `assets/textures/` übernommen. Die Prompts waren:

- `gravel_v10.png`: Nahtlos kachelbare PBR-Albedo, kompaktierter deutscher Wald-Schotterweg, beige-graue Steine, Staub, orthografisch von oben, diffuse Beleuchtung, keine Markierungen oder Objekte.
- `ground_v10.png`: Nahtlos kachelbare PBR-Albedo, mitteleuropäischer Wiesen- und Waldboden, kurzes Gras, Blätter und Erdstellen, orthografisch von oben, diffuse Beleuchtung.
- `asphalt_v10.png`: Nahtlos kachelbare PBR-Albedo, abgenutzter deutscher Asphalt einer Nebenstraße, graues Mineralaggregat, feine Patina, von oben, keine Markierungen.
- `spruce_v10.png`: Einzelne realistische mitteleuropäische Fichte als freigestellter Baum mit transparentem Hintergrund, gerade Seitenansicht und vollständiger Silhouette.
- `oak_v10.png`: Einzelner realistischer mitteleuropäischer Laubbaum als freigestellter Baum mit transparentem Hintergrund, gerade Seitenansicht und vollständiger Silhouette.
- `facade_v10.png`: Kachelbare Albedo einer mitteleuropäischen Stadtfassade, heller Putz, regelmäßige dunkle Fenster, frontale orthografische Ansicht, keine Schilder oder Personen.

Die Dateien sind Spielgrafiken. Die Bildgenerierung garantiert keine mathematisch exakte Kachelung; der Godot-Import nutzt Mipmaps und wiederholte UVs für den Einsatz im Spiel.
