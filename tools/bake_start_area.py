"""Verify/update existing mapped footprints from a public OSM XML snapshot.

Usage: python3 tools/bake_start_area.py snapshot.osm [--verify-only]
Visual roof/facade choices are retained; the footprint set is not silently expanded.
"""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('snapshot', type=Path)
parser.add_argument('--verify-only', action='store_true')
args = parser.parse_args()
root = ET.parse(args.snapshot).getroot()
nodes = {n.attrib['id']: [float(n.attrib['lat']), float(n.attrib['lon'])] for n in root.findall('node')}
ways = {w.attrib['id']: w for w in root.findall('way')}
path = Path(__file__).resolve().parents[1] / 'assets/data/start_area.json'
data = json.loads(path.read_text())
updates = []
for building in data['buildings']:
    way = ways.get(building['id'])
    if way is None:
        raise SystemExit('Missing mapped building ' + building['id'])
    footprint = [nodes[n.attrib['ref']] for n in way.findall('nd')]
    if footprint != building['p']:
        updates.append(building['id'])
    if not args.verify_only:
        building['p'] = footprint
        building['osm_version'] = way.attrib['version']
if args.verify_only and updates:
    raise SystemExit('Changed footprints: ' + ', '.join(updates))
if not args.verify_only:
    path.write_text(json.dumps(data, separators=(',', ':')))
print(f'PASS: {len(data["buildings"])} mapped building footprints; {len(updates)} changed')
