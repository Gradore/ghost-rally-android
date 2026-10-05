extends RefCounted
var low := Vector2.ZERO
var spacing := 16.0
var width := 0
var height := 0
var samples := PackedFloat32Array()
func _init() -> void:
 var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/rostock_height27.json"))
 low=Vector2(meta.low[0],meta.low[1]);spacing=meta.runtime_spacing_m;width=meta.width;height=meta.height
 var file := FileAccess.open("res://assets/data/rostock_height27.bin",FileAccess.READ)
 samples=file.get_buffer(file.get_length()).to_float32_array()
 assert(samples.size()==width*height)
func sample(at: Vector3) -> float:
 var q := (Vector2(at.x,at.z)-low)/spacing
 var x := clampi(int(floor(q.x)),0,width-2);var z := clampi(int(floor(q.y)),0,height-2)
 var fx := clampf(q.x-x,0,1);var fz := clampf(q.y-z,0,1)
 return lerpf(lerpf(samples[z*width+x],samples[z*width+x+1],fx),lerpf(samples[(z+1)*width+x],samples[(z+1)*width+x+1],fx),fz)
func build(parent: Node3D) -> void:
 var material: Material=preload("res://scripts/render/materials25.gd").surface(4,Color("a5b48b"))
 # Indexed 512m tiles: shared vertices, frustum/range culling, no scene node per sample.
 for z0 in range(0,height-1,32):
  for x0 in range(0,width-1,32):
   var nx := mini(33,width-x0);var nz := mini(33,height-z0)
   var vertices := PackedVector3Array();var normals := PackedVector3Array();var indices := PackedInt32Array()
   for z in nz:
    for x in nx:
     var at := Vector3(low.x+(x0+x)*spacing,samples[(z0+z)*width+x0+x]-0.08,low.y+(z0+z)*spacing)
     vertices.append(at)
     var dx := sample(at+Vector3(spacing,0,0))-sample(at-Vector3(spacing,0,0))
     var dz := sample(at+Vector3(0,0,spacing))-sample(at-Vector3(0,0,spacing))
     normals.append(Vector3(-dx,spacing*2,-dz).normalized())
   for z in nz-1:
    for x in nx-1:
     var i := z*nx+x;indices.append_array(PackedInt32Array([i,i+nx,i+1,i+1,i+nx,i+nx+1]))
   var arrays := [];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
   var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   var node := MeshInstance3D.new();node.name="Official_DGM_tile_%d_%d" % [x0,z0];node.mesh=mesh;node.material_override=material
   node.visibility_range_end=1000;node.visibility_range_end_margin=100;parent.add_child(node)
