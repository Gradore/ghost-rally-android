"""Interpret the visible bank relief from photos; this is NOT surveyed DEM data."""
import json, math
from pathlib import Path
import numpy as np
from PIL import Image
import shapely
from shapely.geometry import Polygon,LineString
p=Path(__file__).resolve().parents[1]
r=json.loads((p/'assets/data/routes.json').read_text())[3]['coordinates'];lat,lon=r[0];factor=111195*math.cos(math.radians(lat))
coords=np.array([[(c[1]-lon)*factor,-(c[0]-lat)*111195] for c in r]);first=coords[1]-coords[0];angle=math.atan2(-first[0],-first[1]);rot=np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]])
coords=coords@rot.T;lo=coords.min(axis=0)-150;hi=coords.max(axis=0)+150
water=json.loads((p/'assets/data/map_features.json').read_text())[3]['water'][0]
w=np.array([[(c[1]-lon)*factor,-(c[0]-lat)*111195] for c in water])@rot.T;lake=Polygon(w).buffer(0);route=LineString(coords)
n=512;x,z=np.meshgrid(np.linspace(lo[0],hi[0],n),np.linspace(lo[1],hi[1],n));pts=shapely.points(x.ravel(),z.ravel());inside=shapely.contains(lake,pts);d=shapely.distance(lake.boundary,pts);road=shapely.distance(route,pts)
height=np.minimum(-0.12,-6.0+d*0.16);height=np.maximum(height,np.minimum(-0.12,-.12-(road-12)*.20));height[inside]=-6
pixels=np.zeros((n*n,3),dtype=np.uint8);pixels[:,0]=np.clip((height+6)/6*255,0,255);pixels[:,2]=inside*255
Image.fromarray(pixels.reshape(n,n,3)).save(p/'assets/data/lake_relief.png')
(p/'assets/data/lake_relief.json').write_text(json.dumps({'low':lo.tolist(),'high':hi.tolist(),'height_min':-6,'source':'Photo-interpreted six metre shoreline relief; not surveyed elevation data'}))
print('Relief grid',n,'photo interpretation, not DEM')

# Terrain3D global grid: four 512 regions at 8 m spacing.
gx,gz=np.meshgrid(np.arange(1024)*8-4096,np.arange(1024)*8-4096)
uvx=np.clip((gx-lo[0])/(hi[0]-lo[0])*511,0,511)
uvz=np.clip((gz-lo[1])/(hi[1]-lo[1])*511,0,511)
ix=uvx.astype(int);iz=uvz.astype(int);jx=np.minimum(ix+1,511);jz=np.minimum(iz+1,511)
fx=uvx-ix;fz=uvz-iz;h=pixels[:,0].reshape(512,512)/255*6-6
out=(h[iz,ix]*(1-fx)+h[iz,jx]*fx)*(1-fz)+(h[jz,ix]*(1-fx)+h[jz,jx]*fx)*fz
out.astype('<f4').tofile(p/'assets/data/lake_terrain3d.bin')
