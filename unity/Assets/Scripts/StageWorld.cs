using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
namespace GhostRally {
 public sealed class StageWorld:MonoBehaviour {
  public StageSpec stage;public readonly List<GameObject> chunks=new List<GameObject>();Transform follow;float cullTimer;readonly Dictionary<GameObject,Bounds> chunkBounds=new Dictionary<GameObject,Bounds>();
  public void Build(StageSpec s,Transform player){stage=s;follow=player;CreateRoad();
   var snapshot=Resources.Load<GameObject>("Migration/Geometry/scenery_"+s.routeIndex);
   if(snapshot!=null){var scenery=Instantiate(snapshot,transform);scenery.name="Transferred scenery";ConfigureScenery(scenery);}
   else{CreateFallbackGround();CreateTrees();}
  }
  void ConfigureScenery(GameObject scenery){
   // Retain all authored mesh instances and shared resources. Cull spatial chunks.
   var groups=new Dictionary<Vector2Int,GameObject>();
   foreach(var r in scenery.GetComponentsInChildren<MeshRenderer>()){
    // Replace transferred road with native per-surface colliders, retaining road markings.
    bool road=false;for(Transform p=r.transform;p!=null&&p!=scenery.transform;p=p.parent)if(p.name.ToLowerInvariant()=="road")road=true;
    if(road){r.enabled=false;continue;}
    Vector3 c=r.bounds.center;var key=new Vector2Int(Mathf.FloorToInt(c.x/256),Mathf.FloorToInt(c.z/256));
    if(!groups.TryGetValue(key,out GameObject group)){group=new GameObject("SceneryChunk "+key);group.transform.SetParent(transform,false);group.transform.position=new Vector3((key.x+.5f)*256,0,(key.y+.5f)*256);groups.Add(key,group);chunks.Add(group);}
    if(chunkBounds.TryGetValue(group,out Bounds bounds)){bounds.Encapsulate(r.bounds);chunkBounds[group]=bounds;}else chunkBounds[group]=r.bounds;
    // Mesh-only leaves can be reparented safely; keep their world pose.
    r.transform.SetParent(group.transform,true);
    var filter=r.GetComponent<MeshFilter>();if(filter==null)continue;
    if((r.bounds.size.x>100&&r.bounds.size.z>100)||(r.bounds.size.y>2&&r.bounds.size.x>2&&r.bounds.size.z>2&&!r.name.ToLowerInvariant().Contains("leaf"))){
     var mc=r.gameObject.AddComponent<MeshCollider>();mc.sharedMesh=filter.sharedMesh;
    }
   }
   // Road-adjacent terrain must remain collidable for excursions.
   foreach(var r in scenery.GetComponentsInChildren<MeshRenderer>())if(r.enabled&&r.bounds.size.x>100&&r.bounds.size.z>100){var f=r.GetComponent<MeshFilter>();if(f!=null&&r.GetComponent<Collider>()==null){r.gameObject.AddComponent<MeshCollider>().sharedMesh=f.sharedMesh;}}
  }
  void CreateRoad(){
   var asphalt=SurfaceMaterial(false);var gravel=SurfaceMaterial(true);int start=0;
   while(start<stage.samples.Length-1){bool unsealed=stage.samples[start].gravel;int end=start+1;while(end<stage.samples.Length-1&&end-start<64&&stage.samples[end].gravel==unsealed)end++;
    int count=end-start+1;var v=new Vector3[count*2];var uv=new Vector2[v.Length];var tri=new int[(count-1)*6];
    for(int j=0;j<count;j++){int i=start+j;var p=stage.samples[i].Position;var dir=(stage.samples[Mathf.Min(i+1,stage.samples.Length-1)].Position-stage.samples[Mathf.Max(0,i-1)].Position).normalized;var side=Vector3.Cross(Vector3.up,dir).normalized;float half=stage.samples[i].width*.5f;
     v[j*2]=p-side*half;v[j*2+1]=p+side*half;uv[j*2]=new Vector2(0,stage.samples[i].distance/6);uv[j*2+1]=new Vector2(half*2/6,stage.samples[i].distance/6);
     if(j<count-1){int k=j*6,a=j*2;tri[k]=a;tri[k+1]=a+2;tri[k+2]=a+1;tri[k+3]=a+1;tri[k+4]=a+2;tri[k+5]=a+3;}
    }
    var mesh=new Mesh{name="Mapped road",indexFormat=IndexFormat.UInt32};mesh.vertices=v;mesh.uv=uv;mesh.triangles=tri;mesh.RecalculateNormals();mesh.RecalculateTangents();mesh.RecalculateBounds();
    var go=new GameObject("Road "+start);go.transform.SetParent(transform,false);go.AddComponent<MeshFilter>().sharedMesh=mesh;go.AddComponent<MeshRenderer>().sharedMaterial=unsealed?gravel:asphalt;go.AddComponent<MeshCollider>().sharedMesh=mesh;go.AddComponent<RallySurface>().gravel=unsealed;start=end;
   }
  }
  public static Material SurfaceMaterial(bool gravel){var m=new Material(Shader.Find("Universal Render Pipeline/Lit")){enableInstancing=true};var texture=Resources.Load<Texture2D>(gravel?"Migration/SourceTextures/nature/gravel_floor_diff":"Migration/SourceTextures/nature/road_asphalt_02_diff");if(texture!=null)m.SetTexture("_BaseMap",texture);m.SetColor("_BaseColor",gravel?new Color(.63f,.56f,.45f):new Color(.4f,.42f,.44f));m.SetFloat("_Smoothness",.12f);return m;}
  void CreateFallbackGround(){Vector3 lo=stage.samples[0].Position,hi=lo;foreach(var s in stage.samples){lo=Vector3.Min(lo,s.Position);hi=Vector3.Max(hi,s.Position);}var go=GameObject.CreatePrimitive(PrimitiveType.Cube);go.name="Fallback ground";go.transform.SetParent(transform,false);go.transform.position=new Vector3((hi.x+lo.x)*.5f,-.65f,(hi.z+lo.z)*.5f);go.transform.localScale=new Vector3(hi.x-lo.x+500,1,hi.z-lo.z+500);go.GetComponent<MeshRenderer>().sharedMaterial=SurfaceMaterial(true);}
  void CreateTrees(){var rng=new System.Random(stage.routeIndex+21);var material=new Material(Shader.Find("Universal Render Pipeline/Lit")){color=new Color(.16f,.28f,.12f),enableInstancing=true};for(int i=0;i<stage.samples.Length;i+=20)for(int side=-1;side<=1;side+=2){var p=stage.samples[i].Position;var dir=(stage.samples[Mathf.Min(i+1,stage.samples.Length-1)].Position-stage.samples[Mathf.Max(0,i-1)].Position).normalized;p+=Vector3.Cross(Vector3.up,dir)*side*(18+(float)rng.NextDouble()*22);var tree=GameObject.CreatePrimitive(PrimitiveType.Capsule);tree.transform.SetParent(transform,false);tree.transform.position=p+Vector3.up*4;tree.transform.localScale=new Vector3(3,4,3);tree.GetComponent<MeshRenderer>().sharedMaterial=material;chunks.Add(tree);}}
  void Update(){cullTimer-=Time.unscaledDeltaTime;if(cullTimer>0||follow==null)return;cullTimer=.4f;foreach(var go in chunks)if(go!=null){var d=go.transform.position-follow.position;d.y=0;float distance=chunkBounds.TryGetValue(go,out Bounds bounds)?bounds.SqrDistance(follow.position):d.sqrMagnitude;go.SetActive(distance<950*950);}}
  public int NearestSegment(Vector3 p,int hint){int best=Mathf.Clamp(hint,0,stage.samples.Length-2);float distance=float.PositiveInfinity;int from=Mathf.Max(0,best-40),to=Mathf.Min(stage.samples.Length-2,best+80);for(int i=from;i<=to;i++){float d=(p-stage.samples[i].Position).sqrMagnitude;if(d<distance){distance=d;best=i;}}return best;}
  public Vector3 At(float distance){int i=Mathf.Clamp(Mathf.FloorToInt(distance/5),0,stage.samples.Length-2);var a=stage.samples[i];var b=stage.samples[i+1];return Vector3.Lerp(a.Position,b.Position,Mathf.InverseLerp(a.distance,b.distance,distance));}
  public Quaternion Heading(float distance){return Quaternion.LookRotation((At(Mathf.Min(stage.length,distance+5))-At(Mathf.Max(0,distance-5))).normalized,Vector3.up);}
 }
}
