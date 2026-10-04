"""Bake offline map data. Requires `pip install shapely`; network access for OSM."""
import collections
import heapq
import json
import math
import pathlib
import sys
import os
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "data"
OUT.mkdir(parents=True, exist_ok=True)
RAW = pathlib.Path(os.environ.get("GHOST_RALLY_OSM_CACHE", str(ROOT / "tools" / "osm")))
RAW.mkdir(exist_ok=True)
sys.path.insert(0, os.environ.get("GHOST_RALLY_PYDEPS", str(ROOT / "tools" / "pythondeps")))
from shapely.geometry import shape
from shapely.validation import make_valid

SEEDS = [
    ("08", "Schwarzwald", 48.46, 8.41),
    ("09", "Bayerischer Wald", 49.06, 13.10),
    ("11", "Müggelheim", 52.43, 13.67),
    ("12", "Großräschen", 51.568, 14.019),
    ("04", "Bremen Süd", 53.05, 8.80),
    ("02", "Hamburger Hafen", 53.52, 9.95),
    ("06", "Taunus", 50.22, 8.45),
    ("13", "Müritz", 53.47, 12.68),
    ("03", "Oberharz", 51.81, 10.31),
    ("05", "Winterberg", 51.19, 8.56),
    ("07", "Eifel", 50.35, 6.86),
    ("10", "Saarbrücken", 49.28, 7.02),
    ("14", "Erzgebirge", 50.72, 13.00),
    ("15", "Ostharz", 51.71, 10.89),
    ("01", "Plön", 54.16, 10.42),
    ("16", "Thüringer Wald", 50.62, 10.73),
]
STATES = {f["properties"]["sn_l"]: f for f in json.loads((ROOT / "tools" / "states.geojson").read_text(encoding="utf-8"))["features"] if f["properties"].get("gf") == 4}
ALLOWED = {"track", "unclassified", "tertiary", "secondary", "residential", "living_street", "service", "primary", "primary_link"}


def meters(a, b):
    lat = (a[0] + b[0]) * 0.5
    return math.hypot((b[0] - a[0]) * 111195, (b[1] - a[1]) * 111195 * math.cos(math.radians(lat)))


def in_ring(point, ring):
    x, y = point[1], point[0]
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def in_state(latlon, state):
    code = state["properties"]["sn_l"]
    simple = json.loads((OUT / "states.json").read_text(encoding="utf-8")) if not hasattr(in_state, "cache") else in_state.cache
    in_state.cache = simple
    entry = next(s for s in simple if s["code"] == code)
    for ring in entry["polygons"]:
        if in_ring(latlon, ring):
            return True
    return False


def rdp(points, tol):
    if len(points) <= 2:
        return points
    a, b = points[0], points[-1]
    dx, dy = b[0]-a[0], b[1]-a[1]
    scale = dx*dx+dy*dy
    best, idx = 0, 0
    for i, p in enumerate(points[1:-1], 1):
        t = max(0, min(1, ((p[0]-a[0])*dx+(p[1]-a[1])*dy)/scale)) if scale else 0
        dist = math.hypot(p[0]-a[0]-t*dx, p[1]-a[1]-t*dy)
        if dist > best: best, idx = dist, i
    return rdp(points[:idx+1], tol)[:-1] + rdp(points[idx:], tol) if best > tol else [a, b]


def bake_states():
    result = []
    for code, feature in sorted(STATES.items()):
        polys = []
        geometry = shape(feature["geometry"])
        if not geometry.is_valid: geometry = make_valid(geometry)
        parts = list(geometry.geoms) if hasattr(geometry, "geoms") else [geometry]
        for poly in parts:
            if poly.geom_type != "Polygon" or poly.area < (0.00008 if code in {"02", "04", "11"} else 0.001): continue
            tol = 0.001 if code in {"02", "04", "11"} else 0.006
            simplified = poly.simplify(tol, preserve_topology=True)
            ring = list(simplified.exterior.coords)[:-1]
            if len(ring) < 3: continue
            polys.append([[round(p[0], 5), round(p[1], 5)] for p in ring])
        result.append({"code": code, "name": feature["properties"]["gen"], "polygons": polys})
    (OUT / "states.json").write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print("states", len(result), "bytes", (OUT / "states.json").stat().st_size, flush=True)


def fetch_osm(code, lat, lon):
    city = code in {"02", "04", "11"}
    tiles = []
    if city:
        for dy in (-1, 1):
            for dx in (-1, 1):
                tiles.append((f"{code}_{dy}_{dx}", lon+(dx-1)*0.015, lat+(dy-1)*0.0125, lon+(dx+1)*0.015, lat+(dy+1)*0.0125))
    else:
        cache_name = "12_grossraeschen" if code == "12" else code
        tiles.append((cache_name, 13.976, 51.550, 14.046, 51.620) if code == "12" else (cache_name, lon-0.020, lat-0.020, lon+0.020, lat+0.020))
    paths = []
    for name, x0, y0, x1, y1 in tiles:
        paths.extend(fetch_tile(name,x0,y0,x1,y1))
    return paths


def fetch_tile(name,x0,y0,x1,y1):
    path = RAW / f"{name}.xml"
    if path.exists(): return [path]
    bbox = f"{x0:.5f},{y0:.5f},{x1:.5f},{y1:.5f}"
    url = "https://api.openstreetmap.org/api/0.6/map?bbox=" + bbox
    request = urllib.request.Request(url, headers={"User-Agent": "GhostRally/0.2 (offline game prototype; OSM credit included)"})
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            path.write_bytes(response.read())
        print(name, "download", path.stat().st_size, flush=True)
        return [path]
    except urllib.error.HTTPError as exc:
        if exc.code != 400 or x1-x0 < 0.008: raise
        mx,my=(x0+x1)/2,(y0+y1)/2
        result=[]
        for i,(xa,ya,xb,yb) in enumerate([(x0,y0,mx,my),(mx,y0,x1,my),(x0,my,mx,y1),(mx,my,x1,y1)]):
            result.extend(fetch_tile(f"{name}_{i}",xa,ya,xb,yb))
        return result


def graph_from_xml(paths, state):
    nodes, edges, types = {}, collections.defaultdict(list), {}
    roots = [ET.parse(path).getroot() for path in paths]
    for root in roots:
        for child in root:
            if child.tag == "node":
                ll = (float(child.attrib["lat"]), float(child.attrib["lon"]))
                if state["properties"]["sn_l"] not in {"02", "04", "11"} or in_state(ll, state):
                    nodes[child.attrib["id"]] = ll
    seen_ways = set()
    for root in roots:
        for child in root:
            if child.tag != "way" or child.attrib["id"] in seen_ways: continue
            seen_ways.add(child.attrib["id"])
            tags = {e.attrib["k"]: e.attrib["v"] for e in child.findall("tag")}
            kind = tags.get("highway", "")
            if kind not in ALLOWED or tags.get("motor_vehicle") in {"no", "private"} or tags.get("access") in {"no", "private"}: continue
            refs = [n.attrib["ref"] for n in child.findall("nd")]
            for a, b in zip(refs, refs[1:]):
                if a not in nodes or b not in nodes: continue
                length = meters(nodes[a], nodes[b])
                if length < 0.01: continue
                edges[a].append((b, length, child.attrib["id"], kind))
                edges[b].append((a, length, child.attrib["id"], kind))
            types[child.attrib["id"]] = kind
    return nodes, edges


def dijkstra(start, edges, limit=6800):
    dist = {start: 0.0}
    prev = {}
    todo = [(0.0, start)]
    while todo:
        d, u = heapq.heappop(todo)
        if d != dist[u]: continue
        for v, w, way, kind in edges[u]:
            nd = d + w
            if nd < dist.get(v, float("inf")) and nd < limit:
                dist[v] = nd
                prev[v] = (u, way, kind)
                heapq.heappush(todo, (nd, v))
    return dist, prev


def choose_route(nodes, edges, seed, code):
    if not edges: raise RuntimeError(f"no roads in {code}")
    # Start near the requested landscape, while preferring roads with a sizable network.
    near = sorted(edges, key=lambda n: meters(nodes[n], seed))[:30]
    best = None
    for start in near[:16]:
        dist, prev = dijkstra(start, edges)
        candidates = []
        for end, d in dist.items():
            if d < 4900 or d > 6600: continue
            direct = meters(nodes[start], nodes[end])
            if direct < 950 or direct > d * 0.83: continue
            compactness = d / max(direct, 1)
            prior = compactness * 240 - abs(d - 5700) * 0.13 - meters(nodes[start], seed) * 0.08
            candidates.append((prior, end, d, direct))
        for _, end, d, direct in sorted(candidates, reverse=True)[:320]:
            refs = [end]
            while refs[-1] != start:
                refs.append(prev[refs[-1]][0])
            refs.reverse()
            points = [nodes[n] for n in refs]
            turn_total, hard_turns = curvature_score(points)
            score = turn_total * 62 + hard_turns * 22 - abs(d - 5700) * 0.11 - abs(direct - 2400) * 0.025 - meters(nodes[start], seed) * 0.06
            if best is None or score > best[0]: best = (score, start, end, d, prev)
    if best is None:
        start = near[0]
        dist, prev = dijkstra(start, edges)
        end = max(dist, key=dist.get)
        best = (0, start, end, dist[end], prev)
    _, start, end, length, prev = best
    refs, ways, kinds = [end], [], []
    while refs[-1] != start:
        old, way, kind = prev[refs[-1]]
        refs.append(old); ways.append(way); kinds.append(kind)
    refs.reverse()
    coordinates = [nodes[n] for n in refs]
    # Merge jitter on the road centerline, preserving major bends and intersections.
    lat0, lon0 = coordinates[0]
    metric = [((lon-lon0)*111195*math.cos(math.radians(lat0)), (lat-lat0)*111195) for lat, lon in coordinates]
    simplified = rdp(metric, 5.0)
    samples = []
    for x, y in simplified:
        samples.append([round(lat0+y/111195, 6), round(lon0+x/(111195*math.cos(math.radians(lat0))), 6)])
    if start_curvature(samples[::-1]) < start_curvature(samples):
        samples.reverse()
    return {"length": round(length), "coordinates": samples, "way_ids": sorted(set(ways)), "road_kinds": dict(collections.Counter(kinds)), "direct": round(meters(coordinates[0], coordinates[-1]))}


def curvature_score(coords):
    if len(coords) < 3: return 0.0, 0
    lat0, lon0 = coords[0]
    xy = [((lon-lon0)*111195*math.cos(math.radians(lat0)), (lat-lat0)*111195) for lat, lon in coords]
    xy = rdp(xy, 8.0)
    total = 0.0
    hard = 0
    for a,b,c in zip(xy,xy[1:],xy[2:]):
        x1,y1=b[0]-a[0],b[1]-a[1]
        x2,y2=c[0]-b[0],c[1]-b[1]
        l1,l2=math.hypot(x1,y1),math.hypot(x2,y2)
        if min(l1,l2)<10: continue
        angle=abs(math.atan2(x1*y2-y1*x2,x1*x2+y1*y2))
        if angle>0.24:
            total+=min(angle,1.5)
            if angle>0.65: hard+=1
    return total, hard


def start_curvature(coords):
    bearings = []
    total = 0
    for a,b in zip(coords,coords[1:]):
        x = (b[1]-a[1])*111195*math.cos(math.radians(a[0]))
        y = (b[0]-a[0])*111195
        length = math.hypot(x,y)
        if length<0.01: continue
        bearings.append(math.atan2(x,y))
        total += length
        if total>160: break
    turns = [abs((bearings[i+1]-bearings[i]+math.pi)%(2*math.pi)-math.pi) for i in range(len(bearings)-1)]
    return max(turns,default=0)*2+sum(turns)


def main():
    bake_states()
    routes = []
    for code, area, lat, lon in SEEDS:
        path = fetch_osm(code, lat, lon)
        nodes, edges = graph_from_xml(path, STATES[code])
        route = choose_route(nodes, edges, (lat, lon), code)
        route.update({"state_code": code, "area": area, "source": "OpenStreetMap contributors", "surface": "ASPHALT" if code in {"02", "04", "11"} else "GRAVEL"})
        routes.append(route)
        print(code, area, "meters", route["length"], "direct", route["direct"], "points", len(route["coordinates"]), "roads", route["road_kinds"], flush=True)
    (OUT / "routes.json").write_text(json.dumps(routes, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print("route bytes", (OUT / "routes.json").stat().st_size)


if __name__ == "__main__": main()
