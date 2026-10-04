"""Extract compact offline OSM road and building geometry for the in-game vector map."""
import json
import math
import os
import pathlib
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW = pathlib.Path(os.environ.get("GHOST_RALLY_OSM_CACHE", str(ROOT / "tools" / "osm")))
ROUTES = json.loads((ROOT / "assets" / "data" / "routes.json").read_text(encoding="utf-8"))
OUTPUT = ROOT / "assets" / "data" / "map_features.json"


def near_route(point, route, limit=220):
    lat, lon = point
    scale = 111195 * math.cos(math.radians(lat))
    px, py = lon * scale, lat * 111195
    nearest = 1e30
    for a, b in zip(route, route[1:]):
        ax, ay = a[1] * scale, a[0] * 111195
        bx, by = b[1] * scale, b[0] * 111195
        dx, dy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((px-ax)*dx+(py-ay)*dy)/max(1.0,dx*dx+dy*dy)))
        nearest = min(nearest, math.hypot(px-ax-t*dx,py-ay-t*dy))
        if nearest < limit: return True
    return False


def main():
    baked = []
    for route in ROUTES:
        code = route["state_code"]
        prefix = "12_grossraeschen" if code == "12" else code
        paths = sorted(RAW.glob(prefix + "*.xml"))
        # The old Brandenburg cache covers Schorfheide and is unrelated.
        if code == "12": paths = [p for p in paths if p.name.startswith("12_grossraeschen")]
        nodes = {}
        ways = {}
        for path in paths:
            root = ET.parse(path).getroot()
            for child in root:
                if child.tag == "node":
                    nodes[child.attrib["id"]] = (float(child.attrib["lat"]),float(child.attrib["lon"]))
                elif child.tag == "way":
                    ways[child.attrib["id"]] = child
        coords = route["coordinates"]
        lats = [p[0] for p in coords]
        lons = [p[1] for p in coords]
        bbox = (min(lats)-0.006,max(lats)+0.006,min(lons)-0.008,max(lons)+0.008)
        roads, buildings, water = [], [], []
        for way in ways.values():
            tags = {e.attrib["k"]:e.attrib["v"] for e in way.findall("tag")}
            is_road = "highway" in tags and tags["highway"] not in {"footway","path","steps","cycleway","pedestrian","proposed","construction"}
            is_building = code in {"11","02","04"} and "building" in tags
            is_water = tags.get("natural") == "water" or tags.get("waterway") == "riverbank"
            if not (is_road or is_building or is_water): continue
            points = [nodes[ref.attrib["ref"]] for ref in way.findall("nd") if ref.attrib["ref"] in nodes]
            if len(points)<2 or not any(bbox[0]<=p[0]<=bbox[1] and bbox[2]<=p[1]<=bbox[3] for p in points): continue
            points = [[round(p[0],6),round(p[1],6)] for p in points]
            if is_road:
                kind = tags["highway"]
                if kind in {"motorway","trunk"}: kind="major"
                elif kind in {"primary","secondary","tertiary"}: kind="main"
                elif kind in {"residential","living_street","unclassified"}: kind="street"
                else: kind="minor"
                roads.append({"p":points,"k":kind})
            elif is_building and len(points)>=4 and points[0]==points[-1]:
                lat = sum(p[0] for p in points[:-1])/(len(points)-1)
                lon = sum(p[1] for p in points[:-1])/(len(points)-1)
                if near_route((lat,lon),coords,200):
                    height = 0.0
                    try: height = float(tags.get("height","0").replace(" m",""))
                    except ValueError: pass
                    if height<=0:
                        try: height = float(tags.get("building:levels","2"))*3.2
                        except ValueError: height=6.4
                    buildings.append({"p":points[:-1],"h":round(min(height,48.0),1)})
            elif is_water and len(points)>=4 and points[0]==points[-1]:
                water.append(points[:-1])
        # Put useful local roads first, while keeping the map compact.
        roads = roads[:1700]
        buildings = buildings[:850]
        water = water[:100]
        baked.append({"state_code":code,"roads":roads,"buildings":buildings,"water":water})
        print(code, "roads", len(roads), "buildings", len(buildings), "water", len(water), flush=True)
    OUTPUT.write_text(json.dumps(baked,separators=(",", ":")),encoding="utf-8")
    print("bytes",OUTPUT.stat().st_size)


if __name__ == "__main__": main()
