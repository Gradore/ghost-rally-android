# 0.27 — architectural detail and official Rostock elevation

Free PBR: ambientCG Plaster002 and Bricks001, 1K JPG color, OpenGL normal and roughness maps; CC0 1.0. Maps are unmodified downloads, not Google images. Plaster002 is procedural; this update does not claim all textures are photography. Material shader uses metric world UVs, mapped surface roughness and shallow bump normals. Source links and SHA-256 values: assets/textures/facades27/provenance.json.

Both Rostock and Großräschen receive recessed-looking window surrounds, protruding sills, crossbars, wall bases, roof-edge strips, downpipes and interpreted entrances/handles/canopies/steps. Modern Rostock top storeys receive windows. Original OSM footprints, addresses and completed Rudolf-Tarnow-Straße 17 remain. Detail geometry is interpreted (_assumption), not measured facades. Rostock fine details are generated within 45m of the stage (modern reference buildings always included), with 180m culling and max 8 bays / 4 floors per detailed face. Uploaded geometry is indexed and construction SurfaceTools are released. Distant buildings retain their existing geometry.

## Official elevation

© GeoBasis-DE/M-V, CC BY 4.0, https://creativecommons.org/licenses/by/4.0/. https://www.geodaten-mv.de/dienste/dgm_wcs; coverages mv_dgm5 for the whole Rostock stage and mv_dgm (DGM1) in the start area. Coordinates ETRS89 / UTM33 EPSG:25833, heights DE_DHHN2016_NH EPSG:7837. Metadata/license: https://www.geoportal-mv.de/portal/Geowebdienste/Metadatenviewer/3caf8c20-afe1-4ac6-ad3e-5bc547e3d27d.

Changes to data: bilinear resampling to the game's 16m local metric grid, height relative to start (official baseline 3.385781m NHN), 5m piecewise road-centre profile, indexed 512m terrain tiles. Original 1m source samples show about +2.98m by route station 102.5m. This confirms an initial ascent, without inventing a ramp. Road strips and tyre contact share the same profile and DGM-derived crossfall. A 16cm game clearance above the coarse terrain prevents grass overlays obscuring the asphalt; this is an explicit rendering adaptation, not surveyed pavement thickness. Land overlays, side streets, paths, trees and above-ground building walls/colliders follow elevation; building floors use a level centre foundation. Above-ground underground-garage courtyard remains open.

The coarser runtime grid is a game adaptation, not centimetre-accurate road surveying. Großräschen's existing lake terrain is preserved; this update supplies new official elevation only for Rostock. Isolated bridge/deck heights are not separately surveyed. Physics version 27.terrain.1 separates records from earlier flat-terrain previews. A fixed-tick projected gravity force uses the local height gradient; slope handling remains a reduced model, not full six-degree-of-freedom dynamics.

Download the two exact WCS requests retained in assets/data/rostock_height27.json and run `python tools/bake_rostock27.py dgm5.tif dgm1.tif` (numpy, scipy, rasterio, pyproj). Service revisions may change source hashes; downloaded source SHA-256 and baked grid SHA-256 are recorded.

## Preview installation

The supplied 0.27 APK is a separate test application, package com.ghostrally.racer.preview27, because the earlier ephemeral preview key is unavailable after workspace cleanup. It uses a new Godot debug certificate and installs alongside previous previews. Previous local saves do not transfer automatically. Production package and signing configuration remain untouched. The committed default preview preset retains its usual package; the isolated package override was applied only to this delivered APK.
