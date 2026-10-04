extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
 var camera := Camera3D.new();root.add_child(camera);camera.current=true
 var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[16])
 for i in 3:await process_frame
 var local: Node3D=null
 for node in world.scenery.get_children():
  if node.get_script()!=null and node.get_script().resource_path.ends_with("mv_scenery.gd"):local=node
 assert(local!=null)
 assert(local.completed_building_ids.has("1033343752"),"number 17 completed modern facade applied")
 assert(local.below_ground_ids.has("1033343741"),"underground garage hidden above ground")
 var parking := world.geo_to_world(54.0865,12.1889)
 assert(world.scenery_clear(parking,0),"courtyard above underground garage stays open")
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/local_details26.json"))
 assert(config.building_overrides["1033343752"].status=="completed" and not config.building_overrides["1033343752"].scaffolding)
 var found_height := false
 for node in local.get_children():
  if not node is MeshInstance3D:continue
  var arrays: Array=node.mesh.surface_get_arrays(0)
  if arrays.is_empty():continue
  for v in arrays[Mesh.ARRAY_VERTEX]:
   assert(v.is_finite(),"finite facade geometry")
   if v.y>14 and Geometry2D.is_point_in_polygon(Vector2(v.x,v.z),local.footprint_reference["1033343752"]):found_height=true
 assert(found_height,"setback upper storey present")
 world.queue_free();await process_frame
 var gross := TrackWorld.new();root.add_child(gross);gross.build(GameData.TRACKS[3])
 for i in 3:await process_frame
 var area: Node3D=null
 for node in gross.scenery.get_children():
  if node.get_script()!=null and node.get_script().resource_path.ends_with("start_area.gd"):area=node
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/start_area.json"))
 var expected := Vector3.ZERO
 for i in data.roundabout.size()-1:expected+=gross.geo_to_world(data.roundabout[i][0],data.roundabout[i][1])
 expected/=float(data.roundabout.size()-1)
 assert((area.get_meta("roundabout_center")-expected).length()<0.01,"roundabout follows original OSM polyline centre")
 assert(not area.find_children("roundabout_columnar_trees*","MultiMeshInstance3D",true,false).is_empty())
 print("PASS: finished number 17, open underground-garage courtyard, finite modern facades and OSM-aligned planted roundabout")
 gross.queue_free();await process_frame;quit()
