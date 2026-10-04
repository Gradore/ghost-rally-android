"""30 m survey grid from existing OSM route; no Street View images downloaded."""
import bisect,csv,json,math,pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
def distance(a,b):
 lat1,lat2=map(math.radians,(a[0],b[0])); dl=math.radians(b[0]-a[0]);dn=math.radians(b[1]-a[1])
 return 6371000*2*math.atan2(math.sqrt(math.sin(dl/2)**2+math.cos(lat1)*math.cos(lat2)*math.sin(dn/2)**2),math.sqrt(1-(math.sin(dl/2)**2+math.cos(lat1)*math.cos(lat2)*math.sin(dn/2)**2)))
def samples(route):
 p=route['coordinates'];d=[0.0]
 for a,b in zip(p,p[1:]):d.append(d[-1]+distance(a,b))
 stations=list(range(0,math.floor(d[-1])+1,30))
 if d[-1]-stations[-1]>0.01:stations.append(d[-1])
 for station in stations:
  i=min(len(p)-2,max(0,bisect.bisect_right(d,station)-1));f=(station-d[i])/max(.00001,d[i+1]-d[i])
  lat,lon=[p[i][k]+f*(p[i+1][k]-p[i][k]) for k in range(2)]
  dy=p[i+1][0]-p[i][0];dx=(p[i+1][1]-p[i][1])*math.cos(math.radians(lat));bearing=math.degrees(math.atan2(dx,dy))%360
  yield {'distance_m':round(station,3),'latitude':round(lat,8),'longitude':round(lon,8),'heading_degrees':round(bearing,1),'coverage':'unverified','photo_file':'','notes':''}
def main():
 routes=json.loads((ROOT/'assets/data/routes.json').read_text())
 out=ROOT/'docs/reference-grid25';out.mkdir(exist_ok=True)
 for name,index in [('grossraeschen',3),('rostock',16)]:
  rows=list(samples(routes[index]))
  assert all(abs(b['distance_m']-a['distance_m']-30)<.001 for a,b in zip(rows[:-2],rows[1:-1]))
  with (out/(name+'.csv')).open('w',newline='') as file:
   writer=csv.DictWriter(file,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
  print(name,len(rows),'stations',rows[-1]['distance_m'],'m; image coverage unverified')
if __name__=='__main__':main()
