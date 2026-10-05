# Eigenes Fahrzeug aus Meshy

Exportiere ein **GLB mit eingebetteten Texturen** und lade es im Chat hoch. Das Modell wird als Darstellung in Garage und Rennen eingebunden. Die Lovo-Fahrphysik bleibt separat abgestimmt.

Für ein Handy zunächst etwa 15.000–40.000 Dreiecke, wenige Materialien und maximal 1K–2K-Texturen anstreben. Das sind Startbudgets; die endgültige Grenze hängt vom Gerät ab. Vor dem Export vereinfachen und normale PBR-Texturen verwenden. Ein detailliertes Meshy-Modell ist noch kein optimiertes Spielfahrzeug.

Für drehende/lenkende Räder vier separate Objekte benennen: `wheel_fl`, `wheel_fr`, `wheel_rl`, `wheel_rr`. Lokale X-Achse ist die Radachse, Fahrzeugfront zeigt nach −Z, +Y ist oben. Radzentren müssen als Drehpunkte eingerichtet sein. Ein einzelnes verschmolzenes Mesh kann angezeigt werden, seine Räder lassen sich jedoch nicht separat bewegen.

Zusätzlich hilfreich: Länge/Breite/Höhe, Radstand, Fotos von vorn/hinten/beiden Seiten sowie Felgen und Innenraum. Marken-/Modellbezeichnung im Spiel bleibt **Lovo 940 VOC**.

Technik: Datei unter `assets/vehicles/lovo940voc.glb` importieren, Profil in `config/vehicle_visuals.json` prüfen. Der Adapter kontrolliert Proportionen und Polygonbudget; ein fehlendes oder abgelehntes Modell lässt die vorhandene Darstellung aktiv. Es gibt noch keinen Datei-Auswahldialog im Android-Spiel. Derzeit ist der Import durch Einbau ins Projekt vorgesehen.

Für Streckenverbesserungen: GPX/KML der gewünschten Route, Straßenfotos mit Standort und Blickrichtung, zusammenhängendes Streckenvideo, Gebäude-/Straßenbreiten und ein Höhenprofil liefern. Aktuelle eigene Aufnahmen helfen insbesondere dort, wo die vorhandenen Panoramen alt oder lückenhaft sind.

## Eingebaut in 0.28
Die Nutzerdatei vom 5. Oktober 2026 wird jetzt in Garage und Rennen geladen. Aus dem einzelnen Mesh wurden die source Räder entfernt und vier eigene Räder mit Drehpunkten erstellt. Der Grill und der hintere Bereich mit Emblem/Kennzeichen wurden ersetzt. Das rohe Original wird nicht mitgeliefert. Physik und Kollisionskörper bleiben separat; Logoentfernung und „Lovo“ sind keine rechtliche Marken-/Designfreigabe. Siehe assets/vehicles/provenance28.json und CREDITS.md.
