extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
 change_scene_to_file("res://scenes/main.tscn")
 for i in 4:await process_frame
 var game := current_scene
 game.active_track=3;game.active_car=10;game.build_world()
 assert(str(game.world.tree_centers).sha256_text()=="c9b07e3a318c1e81ab9c1a6cea2ba60e65f82ed57e0ab2db064a675f3e5941ff","preserve 0.15 tree collision positions")
 var grass := 0;var oaks := 0
 for node in game.world.scenery.get_children():
  if node.is_in_group("verge_grass"):
   grass+=node.multimesh.instance_count
   assert(node.visibility_range_end<=90,"grass visibility budget")
  if node.is_in_group("spatial_oaks"):oaks+=node.multimesh.instance_count
 assert(grass>3000,"dense batched grass")
 assert(oaks>20,"spatial broadleaf forest")
 print("PASS: spatial oaks ",oaks," and bounded dense grass ",grass)
 quit()
