# Referenzraster für Großräschen und Rostock

Die CSV-Dateien in `docs/reference-grid25/` enthalten 535 bzw. 522 Stationen entlang der bestehenden OSM-Strecken: Start, alle 30 Meter und das Ende. Berechnet mit Haversine-Abständen; Koordinaten linear auf dem jeweiligen kurzen Quellsegment interpoliert. Die tatsächliche abgerundete Spielstrecke kann davon leicht abweichen. `heading_degrees` ist die Tangentenrichtung, im Uhrzeigersinn ab Norden.

**Dies ist keine Screenshot-Sammlung und kein Nachweis von Street-View-Abdeckung.** `coverage` bleibt `unverified`; `photo_file` und `notes` sind leer. Keine Bilder wurden automatisch abgerufen oder als Texturen übernommen.

Google untersagt Screenshots/Herauslösen von Street-View-Bildern sowie separate Offline-Kopien in seinen Geo-Richtlinien: https://about.google/brand-resource-center/products-and-services/geo-guidelines/#street-view . Deshalb wird die gewünschte vollständige 30-m-Screenshot-Serie nicht angefertigt.

Für eigene Fotos: Stationsnummer/Distanz, Koordinate, Blickrichtung, Datum und Dateiname in der CSV ergänzen. Je Standort sind Blick nach vorn, links und rechts sowie Detailfotos von Straße, Fassaden, Dächern und Vegetation hilfreich. Nur selbst aufgenommene oder entsprechend freigegebene Dateien für Spieltexturen verwenden. Ein georeferenziertes eigenes Video kann die Stationen ebenfalls abdecken. Fotos von Autos von vorn, hinten, beiden Seiten und schräg plus Maße oder ein eigenes GLB helfen bei der Fahrzeugform.

Der Rastergenerator `python3 tools/reference_grid25.py` ist deterministisch und verändert keine Routen oder Gebäude.
