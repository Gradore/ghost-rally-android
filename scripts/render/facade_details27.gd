extends RefCounted
# Interpreted architectural detailing; source footprints remain unchanged.
static func quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,n: Vector3,color: Color) -> void:
 for v in [a,b,c,c,b,d]:
  st.set_normal(n);st.set_color(color);st.set_uv(Vector2(v.x+v.z,v.y));st.add_vertex(v)
static func block(st: SurfaceTool,at: Vector3,u: Vector3,n: Vector3,size: Vector3,color: Color) -> void:
 var r := u*size.x*0.5;var h := Vector3.UP*size.y*0.5;var f := n*size.z*0.5
 quad(st,at-r-h+f,at-r+h+f,at+r-h+f,at+r+h+f,n,color)
 quad(st,at-r+h-f,at-r+h+f,at+r+h-f,at+r+h+f,Vector3.UP,color)
static func face(st: SurfaceTool,a: Vector3,b: Vector3,n: Vector3,h: float,levels: int,entrance: bool,modern: bool=false) -> void:
 var edge := b-a;var u := edge.normalized();var length := edge.length()
 if length<2:return
 var grey := Color("8c9290");var trim := Color("e0e1d9");var dark := Color("343e42")
 block(st,(a+b)*0.5+n*0.045+Vector3.UP*0.24,u,n,Vector3(length,0.48,0.10),grey)
 block(st,(a+b)*0.5+n*0.07+Vector3.UP*(h-0.10),u,n,Vector3(length,0.18,0.18),grey)
 for end in [a+u*0.14,b-u*0.14]:
  block(st,end+n*0.13+Vector3.UP*(h*0.5),u,n,Vector3(0.095,h,0.11),grey)
 var bays := mini(8,int(length/(3.3 if modern else 3.6)));var step := h/maxi(1,levels) if modern else 3.0
 for floor_id in mini(4,levels):
  for bay in bays:
   var at := a.lerp(b,(bay+0.5)/maxf(bays,1))+Vector3.UP*(1.55+step*floor_id)+n*0.07
   var half := minf(0.65,length/maxi(1,bays)*0.28) if modern else 0.55
   var top := 0.94 if modern else 0.72
   if 1.55+step*floor_id+top>h:continue
   for side in [-1,1]:block(st,at+u*side*(half+0.055),u,n,Vector3(0.085,top*2+0.18,0.13),trim)
   block(st,at+Vector3.UP*(top+0.055),u,n,Vector3(half*2+0.19,0.085,0.13),trim)
   block(st,at-Vector3.UP*(top+0.07)+n*0.10,u,n,Vector3(half*2+0.29,0.11,0.34),grey)
   block(st,at+Vector3.UP*0.14+n*0.025,u,n,Vector3(half*2,0.045,0.08),trim)
 if entrance and length>5:
  var door := a.lerp(b,0.52)+Vector3.UP*1.14+n*0.16
  block(st,door,u,n,Vector3(1.32,2.28,0.12),dark)
  for side in [-1,1]:block(st,door+u*side*0.73,u,n,Vector3(0.13,2.47,0.22),trim)
  block(st,door+Vector3.UP*1.22,u,n,Vector3(1.59,0.14,0.25),trim)
  block(st,door+u*0.37+Vector3.UP*0.02+n*0.13,u,n,Vector3(0.04,0.30,0.06),grey)
  block(st,door-Vector3.UP*1.09+n*0.22,u,n,Vector3(1.82,0.12,0.65),grey)
  block(st,door+Vector3.UP*1.46+n*0.43,u,n,Vector3(1.92,0.10,1.10),grey)
