extends SceneTree
var meshes := [];var materials := [];var nodes := [];var mesh_cache := {};var mat_cache := {};var binary := PackedByteArray()
func _initialize() -> void:call_deferred("run")
func material_id(mat: Material) -> int:
 var key := mat.get_instance_id() if mat!=null else 0
 if mat_cache.has(key):return mat_cache[key]
 var c := Color.WHITE;var metal := 0.0;var rough := 0.9;var texture := "";var cutout := false;var kind := -1
 if mat is StandardMaterial3D:
  c=mat.albedo_color;metal=mat.metallic;rough=mat.roughness;cutout=mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
  if mat.albedo_texture!=null:texture="Assets/Resources/Migration/SourceTextures/"+mat.albedo_texture.resource_path.trim_prefix("res://assets/")
 elif mat is ShaderMaterial:
  var tint: Variant=mat.get_shader_parameter("tint")
  if tint is Color:c=tint
  var k: Variant=mat.get_shader_parameter("kind")
  if k!=null:kind=int(k)
  texture="Assets/Resources/Migration/SourceTextures/textures/material_atlas25.png"
 var id := materials.size();materials.append({"name":"Transferred "+str(key),"color":[c.r,c.g,c.b,c.a],"emission":[0,0,0],"metallic":metal,"roughness":rough,"cutout":cutout,"cutoff":0.42,"texture":texture,"doubleSided":true,"atlasKind":kind,"worldAtlas":kind>=0});mat_cache[key]=id;return id
func mesh_id(mesh: Mesh,override_mat: Material) -> int:
 var key := str(mesh.get_instance_id())+":"+str(override_mat.get_instance_id() if override_mat!=null else 0)
 if mesh_cache.has(key):return mesh_cache[key]
 var primitives := []
 for s in mesh.get_surface_count():
  var arrays: Array=mesh.surface_get_arrays(s)
  var v: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array();var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array();var ids: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array();var colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
  if ids.is_empty():
   for i in v.size():ids.append(i)
  var start := binary.size();var packed := PackedFloat32Array();packed.resize(v.size()*12)
  for i in v.size():
   var norm := n[i] if i<n.size() else Vector3.UP;var t := uv[i] if i<uv.size() else Vector2.ZERO
   var c := colors[i] if i<colors.size() else Color.WHITE
   for j in 12:packed[i*12+j]=[v[i].x,v[i].y,-v[i].z,norm.x,norm.y,-norm.z,t.x,t.y,c.r,c.g,c.b,c.a][j]
  binary.append_array(packed.to_byte_array())
  for i in range(0,ids.size(),3):var reverse := ids[i+1];ids[i+1]=ids[i+2];ids[i+2]=reverse
  binary.append_array(ids.to_byte_array());var mat: Material=override_mat if override_mat!=null else mesh.surface_get_material(s)
  primitives.append({"offset":start,"stride":48,"vertices":v.size(),"indices":ids.size(),"material":material_id(mat)})
 var id := meshes.size();meshes.append({"primitives":primitives});mesh_cache[key]=id;return id
func add_mesh(mesh: Mesh,t: Transform3D,mat: Material,name: String) -> void:
 var b := t.basis;var p := t.origin;var matrix := [b.x.x,b.x.y,-b.x.z,0,b.y.x,b.y.y,-b.y.z,0,-b.z.x,-b.z.y,b.z.z,0,p.x,p.y,-p.z,1]
 nodes.append({"name":name,"mesh":mesh_id(mesh,mat),"children":[],"position":[0,0,0],"rotation":[0,0,0,1],"scale":[1,1,1],"matrix":matrix})
func visit(node: Node,world: Node) -> void:
 if node is MeshInstance3D and node.mesh!=null and node.is_visible_in_tree():
  # Native road is regenerated in Unity with its original sampled height and width.
  if not world.road.is_ancestor_of(node):add_mesh(node.mesh,node.global_transform,node.material_override,node.name)
 elif node is MultiMeshInstance3D and node.multimesh!=null and node.is_visible_in_tree():
  var mm: MultiMesh=node.multimesh
  # Tiny ground clutter is retained by geometry/texture source but bounded for Android.
  var step := maxi(1,int(ceil(float(mm.instance_count)/1200.0)))
  for i in range(0,mm.instance_count,step):add_mesh(mm.mesh,node.global_transform*mm.get_instance_transform(i),node.material_override,str(node.name)+"_"+str(i))
 for child in node.get_children():visit(child,world)
func run() -> void:
 for index in range(17):
  var chosen := -1
  for arg in OS.get_cmdline_user_args():
   if arg.begins_with("--stage="):chosen=int(arg.trim_prefix("--stage="))
  if chosen>=0 and chosen!=index:continue
  if OS.get_cmdline_user_args().has("--remaining") and index in [3,16]:continue
  meshes=[];materials=[];nodes=[];mesh_cache={};mat_cache={};binary=PackedByteArray()
  var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[index]);visit(world,world)
  if index==3:
   var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/lake_relief.json"));var low := Vector2(meta.low[0],meta.low[1]);var high := Vector2(meta.high[0],meta.high[1]);var nx := int(ceil((high.x-low.x)/16))+1;var nz := int(ceil((high.y-low.y)/16))+1
   for z0 in range(0,nz-1,32):
    for x0 in range(0,nx-1,32):
     var width := mini(33,nx-x0);var height := mini(33,nz-z0);var vertices := PackedVector3Array();var ids := PackedInt32Array()
     for z in height:
      for x in width:
       var p := Vector3(low.x+(x0+x)*16,0,low.y+(z0+z)*16);p.y=world.ground_height(p);vertices.append(p)
     for z in height-1:
      for x in width-1:
       var i := z*width+x;ids.append_array(PackedInt32Array([i,i+width,i+1,i+1,i+width,i+width+1]))
     var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
     for v in vertices:st.set_uv(Vector2(v.x,v.z)/16);st.add_vertex(v)
     for i in ids:st.add_index(i)
     st.generate_normals();var mesh := st.commit();add_mesh(mesh,Transform3D.IDENTITY,load("res://scripts/render/materials25.gd").surface(4),"LakeTerrain")
  var roots := [];for i in nodes.size():roots.append(i)
  var header := JSON.stringify({"materials":materials,"meshes":meshes,"nodes":nodes,"roots":roots}).to_utf8_buffer();var f := FileAccess.open("res://unity/Assets/Resources/Migration/Geometry/scenery_"+str(index)+".grmesh",FileAccess.WRITE);f.store_buffer("GRM1".to_utf8_buffer());f.store_32(header.size());f.store_buffer(header);f.store_buffer(binary);f.close()
  print("PASS: scenery ",index," meshes=",meshes.size()," nodes=",nodes.size()," bytes=",binary.size())
  world.queue_free();await process_frame
 quit()
