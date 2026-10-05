using UnityEngine;
using UnityEngine.UI;
namespace GhostRally{
 public sealed class RallyMap:MaskableGraphic{
  public StageSpec stage;public Transform player;Vector2 low,high;float scale;
  public void Configure(StageSpec s,Transform p){stage=s;player=p;low=new Vector2(float.MaxValue,float.MaxValue);high=-low;foreach(var n in s.samples){var v=new Vector2(n.x,n.z);low=Vector2.Min(low,v);high=Vector2.Max(high,v);}SetVerticesDirty();}
  Vector2 Project(Vector3 p){var size=rectTransform.rect.size;scale=Mathf.Min((size.x-20)/Mathf.Max(1,high.x-low.x),(size.y-20)/Mathf.Max(1,high.y-low.y));return (new Vector2(p.x,p.z)-(low+high)*.5f)*scale;}
  protected override void OnPopulateMesh(VertexHelper vh){vh.Clear();if(stage==null)return;for(int i=0;i<stage.samples.Length-1;i+=2){Vector2 a=Project(stage.samples[i].Position),b=Project(stage.samples[Mathf.Min(i+2,stage.samples.Length-1)].Position),n=new Vector2(-(b-a).y,(b-a).x).normalized*1.25f;int k=vh.currentVertCount;vh.AddVert(a-n,new Color(.3f,.8f,.78f),Vector2.zero);vh.AddVert(a+n,new Color(.3f,.8f,.78f),Vector2.zero);vh.AddVert(b+n,new Color(.3f,.8f,.78f),Vector2.zero);vh.AddVert(b-n,new Color(.3f,.8f,.78f),Vector2.zero);vh.AddTriangle(k,k+1,k+2);vh.AddTriangle(k,k+2,k+3);}if(player!=null){Vector2 p=Project(player.position),d=new Vector2(player.forward.x,player.forward.z).normalized,n=new Vector2(-d.y,d.x);int k=vh.currentVertCount;vh.AddVert(p+d*8,Color.white,Vector2.zero);vh.AddVert(p-d*5+n*5,Color.white,Vector2.zero);vh.AddVert(p-d*5-n*5,Color.white,Vector2.zero);vh.AddTriangle(k,k+1,k+2);}}
  void LateUpdate(){if(player!=null)SetVerticesDirty();}
 }
}
