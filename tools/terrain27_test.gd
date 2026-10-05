extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
 var camera := Camera3D.new();root.add_child(camera);camera.current=true
 var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[16])
 assert(world.official_height!=null)
 var h0 := world.road_relief(0);var h100 := world.road_relief(100)
 assert(h100-h0>2.2 and h100-h0<3.7,"actual DGM confirms early climb near 3m")
 for progress in [0.0,50.0,100.0,300.0,800.0,1500.0,5000.0,12000.0]:
  var at := world.center_at(progress)
  assert(absf(world.contact_height(at,progress)-world.road_relief(progress))<0.001,"wheel query follows rendered road profile")
  assert(absf(world.ground_height(at)+0.08+0.16-world.road_relief(progress))<0.1,"road stays near DGM")
 var tiles := world.scenery.find_children("Official_DGM_tile*","MeshInstance3D",true,false)
 assert(tiles.size()>100 and tiles.size()<250,"indexed bounded terrain tiles")
 for tile in tiles:
  var arrays: Array=tile.mesh.surface_get_arrays(0)
  assert(arrays[Mesh.ARRAY_VERTEX].size()<=1089)
  assert(arrays[Mesh.ARRAY_INDEX].size()>0)
 var detail_vertices := 0
 for node in world.scenery.get_children():
  if node.get_script()!=null and node.get_script().resource_path.ends_with("mv_scenery.gd"):
   for mesh in node.get_children():
    if mesh is MeshInstance3D and mesh.visibility_range_end==180:detail_vertices+=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
 print("Architectural vertices: ",detail_vertices,"; terrain tiles: ",tiles.size())
 assert(detail_vertices>10000,"real batched architectural detail present")
 var material: ShaderMaterial=preload("res://scripts/render/materials25.gd").surface(6,Color.WHITE,true)
 assert(material.shader.resource_path.ends_with("facade27.gdshader"))
 assert(material.get_shader_parameter("brick_normal")!=null and material.get_shader_parameter("plaster_rough")!=null)
 world.queue_free();await process_frame
 # Grade force runs within the fixed integrator, including when facing downhill.
 var uphill := VehicleDynamics.new();var downhill := VehicleDynamics.new()
 var cfg: Dictionary=GameData.CARS[10];var ups := {"engine":0,"handling":0,"brakes":0}
 var up_v := Vector2(0,-10);var down_v := up_v
 for i in 60:
  up_v=uphill.step(up_v,0,0,0,0,false,false,cfg,{"terrain_gradient":Vector2(0,-0.05),"suspension":0.0,"gearing":0.0,"brake_bias":0.0},ups,false,true,1.0/60).velocity
  down_v=downhill.step(down_v,0,0,0,0,false,false,cfg,{"terrain_gradient":Vector2(0,0.05),"suspension":0.0,"gearing":0.0,"brake_bias":0.0},ups,false,true,1.0/60).velocity
 assert(down_v.length()>up_v.length()+0.6,"uphill slows more than downhill")
 print("PASS: DGM rise, wheel/road contact, indexed tiles, batched facade details, free PBR maps and fixed-tick slope force")
 quit()
