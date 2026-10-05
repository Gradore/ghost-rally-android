extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var scenery := preload("res://scripts/mv_scenery.gd").new()
	var p := PackedVector2Array([Vector2(0,0),Vector2(12,0),Vector2(12,4),Vector2(5,4),Vector2(5,10),Vector2(0,10)])
	var cap := SurfaceTool.new();cap.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall := SurfaceTool.new();wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	scenery.pitched_polygon(p,6,cap,wall,Color("a95435"),Color.WHITE)
	var arrays := cap.commit_to_arrays();var highest := 0.0
	for v in arrays[Mesh.ARRAY_VERTEX]:
		highest=maxf(highest,v.y)
		var q := Vector2(v.x,v.z);var distance := INF
		for i in p.size():distance=minf(distance,q.distance_to(Geometry2D.get_closest_point_to_segment(q,p[i],p[(i+1)%p.size()])))
		assert(Geometry2D.is_point_in_polygon(q,p) or distance<0.001,"concave pitched roof stays in source outline")
	for normal in arrays[Mesh.ARRAY_NORMAL]:assert(normal.is_finite() and normal.y>0.1,"outward pitched roof normals")
	assert(highest>7,"ridge is elevated")
	scenery.free()
	var forest=preload("res://scripts/render/forest.gd")
	for variant in 3:
		var near: Mesh=forest.broadleaf_mesh(variant,false);var far: Mesh=forest.broadleaf_mesh(variant,true)
		assert(forest.broadleaf_mesh(variant,false)==near,"shared cached geometry")
		assert(near.surface_get_array_len(1)<14000 and far.surface_get_array_len(1)<3000,"bounded canopy geometry")
		assert(near.get_aabb().size.is_finite() and far.get_aabb().size.is_finite())
	print("PASS: clipped concave roof ridges, finite normals, cached and bounded canopy geometry");quit()
