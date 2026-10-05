extends Node3D
class_name TrackWorld

var track: Dictionary
var road_width := 14.8
var road_material: StandardMaterial3D
var scenery := Node3D.new()
var road := Node3D.new()
var route_points := PackedVector2Array()
var distances := PackedFloat32Array()
var origin_lat := 0.0
var origin_lon := 0.0
var metric_rotation := 0.0
var surface_segments: Array = []
var source_route_length := 1.0
var mapped_buildings: Array[PackedVector2Array] = []
var mapped_building_cells := {}
var tree_grid := {}
var tree_max_radius := 0.0
var tree_candidates_last := 0
var tree_centers := PackedVector2Array()
var tree_radii := PackedFloat32Array()
var water_polygons: Array[PackedVector2Array] = []
var terrain3d: Node3D
var official_height: RefCounted
var official_road := PackedFloat32Array()
var relief: Image
var relief_low := Vector2.ZERO
var relief_span := Vector2.ONE

func _material(color: Color, rough: float = 1.0, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
	return m

func _road_material(color: Color) -> StandardMaterial3D:
	var m := _material(color)
	m.roughness=0.92
	return m

func _textured_material(path: String, tint: Color, uv_scale: Vector3 = Vector3.ONE) -> StandardMaterial3D:
	var material := _material(tint)
	material.albedo_texture=load(path)
	var normal_path := path.replace("_v10.png","_normal.png")
	if path.ends_with("_diff.jpg"):
		normal_path=path.replace("_diff.jpg","_nor_gl.jpg")
		material.roughness_texture=load(path.replace("_diff.jpg","_rough.jpg"))
	if ResourceLoader.exists(normal_path):
		material.normal_enabled=true
		material.normal_texture=load(normal_path)
		material.normal_scale=0.65
	material.uv1_scale=uv_scale
	material.texture_repeat=true
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material

func _tree_material(path: String) -> StandardMaterial3D:
	var material := _material(Color.WHITE)
	material.albedo_texture=load(path)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold=0.42
	material.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.billboard_mode=BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale=true
	return material

func _load_route() -> void:
	var f := FileAccess.open("res://assets/data/routes.json",FileAccess.READ)
	var routes: Array=JSON.parse_string(f.get_as_text()) if f else []
	var route: Dictionary=routes[int(track.route_index)]
	surface_segments=route.get("segments",[]) if track.get("mapped_mv",false) else []
	source_route_length=float(route.length)
	var coordinates: Array=route.coordinates
	var lat0: float=float(coordinates[0][0])
	var lon0: float=float(coordinates[0][1])
	origin_lat=lat0
	origin_lon=lon0
	var factor := 111195.0*cos(deg_to_rad(lat0))
	var metric := PackedVector2Array()
	for ll in coordinates:
		metric.append(Vector2((float(ll[1])-lon0)*factor,-(float(ll[0])-lat0)*111195.0))
	var first := (metric[1]-metric[0]).normalized()
	var rotation := atan2(-first.x,-first.y)
	metric_rotation=rotation
	var rotated_points := PackedVector2Array()
	for p in metric:
		var rotated := p.rotated(rotation)
		if rotated_points.is_empty() or rotated_points[-1].distance_to(rotated)>0.1:
			rotated_points.append(rotated)
	# Round hard OSM junctions by a few metres without moving away from the mapped road.
	route_points.append(rotated_points[0])
	for i in range(1,rotated_points.size()-1):
		var a := rotated_points[i-1]
		var b := rotated_points[i]
		var c := rotated_points[i+1]
		var incoming := (b-a).normalized()
		var outgoing := (c-b).normalized()
		var angle := absf(atan2(incoming.cross(outgoing),incoming.dot(outgoing)))
		if angle<0.27 or minf(a.distance_to(b),b.distance_to(c))<12.0:
			route_points.append(b)
			continue
		var cut := minf(11.0,minf(a.distance_to(b),b.distance_to(c))*0.27)
		var entry := b-incoming*cut
		var exit := b+outgoing*cut
		for step in 5:
			var t := float(step)*0.25
			route_points.append(entry*(1.0-t)*(1.0-t)+b*2.0*(1.0-t)*t+exit*t*t)
	route_points.append(rotated_points[-1])
	distances.append(0.0)
	for i in range(1,route_points.size()): distances.append(distances[-1]+route_points[i-1].distance_to(route_points[i]))
	track.length=distances[-1]
	if track.has("wp_index"):
		var full_points := route_points.duplicate();var full_distances := distances.duplicate()
		var total_length: float=distances[-1]
		var start: float=total_length*float(track.wp_index)/3.0;var finish: float=total_length*float(track.wp_index+1)/3.0
		var first_point := center_at(start);var last_point := center_at(finish)
		route_points=PackedVector2Array([Vector2(first_point.x,first_point.z)])
		for i in full_points.size():
			if full_distances[i]>start and full_distances[i]<finish:route_points.append(full_points[i])
		route_points.append(Vector2(last_point.x,last_point.z));distances=PackedFloat32Array([0.0])
		for i in range(1,route_points.size()):distances.append(distances[-1]+route_points[i-1].distance_to(route_points[i]))
		track.source_offset=start;track.full_length=total_length;track.length=distances[-1]
		track.name="GROßRÄSCHEN · WP %d / 3" % [track.wp_index+1]

func geo_to_world(lat: float, lon: float) -> Vector3:
	var p := Vector2((lon-origin_lon)*111195.0*cos(deg_to_rad(origin_lat)),-(lat-origin_lat)*111195.0).rotated(metric_rotation)
	return Vector3(p.x,0,p.y)

func _build_city_buildings() -> void:
	if track.state_code not in ["11","02","04"]: return
	var file := FileAccess.open("res://assets/data/map_features.json",FileAccess.READ)
	if not file: return
	var features: Array=JSON.parse_string(file.get_as_text())
	for feature in features:
		if feature.state_code!=track.state_code: continue
		var walls := SurfaceTool.new()
		var roofs := SurfaceTool.new()
		var windows := SurfaceTool.new()
		walls.begin(Mesh.PRIMITIVE_TRIANGLES)
		roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
		windows.begin(Mesh.PRIMITIVE_TRIANGLES)
		var wall_faces := 0
		var roof_faces := 0
		var window_faces := 0
		var collider_count := 0
		for building in feature.buildings:
			var footprint := PackedVector2Array()
			for ll in building.p:
				var p := geo_to_world(float(ll[0]),float(ll[1]))
				footprint.append(Vector2(p.x,p.z))
			if footprint.size()<3: continue
			var lo := Vector2(INF,INF)
			var hi := Vector2(-INF,-INF)
			for p in footprint: lo=lo.min(p); hi=hi.max(p)
			var span := hi-lo
			if span.x<2.0 or span.y<2.0 or span.x>90.0 or span.y>90.0: continue
			var mid := (lo+hi)*0.5
			var center := Vector3(mid.x,0,mid.y)
			if not scenery_clear(center,maxf(span.x,span.y)*0.55): continue
			var height: float=clampf(float(building.h),4.0,46.0)
			if collider_count<400 and absf(lateral_offset(center))<65.0:
				add_obstacle(center+Vector3.UP*height*0.5,Vector3(span.x,height,span.y))
				collider_count+=1
			for i in footprint.size():
				var a := footprint[i]
				var b := footprint[(i+1)%footprint.size()]
				var edge := b-a
				if edge.length_squared()<0.25: continue
				var base_a := Vector3(a.x,0,a.y)
				var base_b := Vector3(b.x,0,b.y)
				var top_a := base_a+Vector3.UP*height
				var top_b := base_b+Vector3.UP*height
				var normal := Vector3(-edge.y,0,edge.x).normalized()
				var wall_vertices := [base_a,top_a,base_b,base_b,top_a,top_b]
				var wall_uv := [Vector2(0,height/6.0),Vector2(0,0),Vector2(edge.length()/6.0,height/6.0),Vector2(edge.length()/6.0,height/6.0),Vector2(0,0),Vector2(edge.length()/6.0,0)]
				for j in 6:
					walls.set_normal(normal)
					walls.set_uv(wall_uv[j])
					walls.add_vertex(wall_vertices[j])
					wall_faces+=1
			var indices := Geometry2D.triangulate_polygon(footprint)
			for index in indices:
				roofs.set_normal(Vector3.UP)
				roofs.add_vertex(Vector3(footprint[index].x,height+0.04,footprint[index].y))
				roof_faces+=1
		if wall_faces>0:
			var wall_node := MeshInstance3D.new()
			wall_node.mesh=walls.commit()
			wall_node.material_override=_textured_material("res://assets/textures/facade_v10.png",Color(0.86,0.88,0.86))
			scenery.add_child(wall_node)
		if roof_faces>0:
			var roof_node := MeshInstance3D.new()
			roof_node.mesh=roofs.commit()
			roof_node.material_override=_material(Color("56636a"))
			scenery.add_child(roof_node)
		if window_faces>0:
			var window_node := MeshInstance3D.new()
			window_node.mesh=windows.commit()
			window_node.material_override=_material(Color("294c60"),0.26)
			scenery.add_child(window_node)
		break

func _build_map_context() -> void:
	var file := FileAccess.open("res://assets/data/map_features.json",FileAccess.READ)
	if not file: return
	var features: Array=JSON.parse_string(file.get_as_text())
	for feature in features:
		if feature.state_code!=track.state_code: continue
		var road_mesh := SurfaceTool.new()
		road_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var road_segments := 0
		for way in feature.roads:
			var points: Array=way.p
			var width := 5.5 if way.k=="main" else (3.7 if way.k=="street" else 2.2)
			for i in range(points.size()-1):
				var a := geo_to_world(float(points[i][0]),float(points[i][1]))
				var b := geo_to_world(float(points[i+1][0]),float(points[i+1][1]))
				var delta := b-a
				if delta.length_squared()<0.04 or delta.length_squared()>90000.0: continue
				var side := Vector3(-delta.z,0,delta.x).normalized()*width*0.5
				var p := a-side+Vector3.UP*0.003
				var q := a+side+Vector3.UP*0.003
				var r := b-side+Vector3.UP*0.003
				var s := b+side+Vector3.UP*0.003
				for vertex in [p,q,r,q,s,r]:
					road_mesh.set_normal(Vector3.UP)
					road_mesh.add_vertex(vertex)
				road_segments+=1
		if road_segments>0:
			var roads := MeshInstance3D.new()
			roads.mesh=road_mesh.commit()
			roads.material_override=_road_material(Color("58615b") if track.surface=="GRAVEL" else Color("4c5357"))
			scenery.add_child(roads)
		var water_mesh := SurfaceTool.new()
		water_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var water_triangles := 0
		for polygon in feature.water:
			if polygon.size()<3: continue
			var coords := PackedVector2Array()
			for ll in polygon:
				var p := geo_to_world(float(ll[0]),float(ll[1]))
				coords.append(Vector2(p.x,p.z))
			water_polygons.append(coords)
			var indices := Geometry2D.triangulate_polygon(coords)
			for index in indices:
				water_mesh.set_normal(Vector3.UP)
				water_mesh.add_vertex(Vector3(coords[index].x,-5.95 if track.state_code=="12" else -0.055,coords[index].y))
				water_triangles+=1
		if water_triangles>0:
			var water := MeshInstance3D.new()
			water.mesh=water_mesh.commit()
			water.material_override=_water_material()
			scenery.add_child(water)
		break

func _segment(progress: float) -> int:
	var target := clampf(progress,0.0,float(track.length))
	var lo := 0
	var hi := distances.size()-2
	while lo<hi:
		var mid := int((lo+hi)/2)
		if distances[mid+1]<target: lo=mid+1
		else: hi=mid
	return lo

func center_at(progress: float) -> Vector3:
	var i := _segment(progress)
	var frac := clampf((progress-distances[i])/maxf(0.001,distances[i+1]-distances[i]),0,1)
	var p := route_points[i].lerp(route_points[i+1],frac)
	return Vector3(p.x,0,p.y)

func heading_at(progress: float) -> float:
	var before := center_at(maxf(progress-3.0,0.0))
	var after := center_at(minf(progress+3.0,float(track.length)))
	var d := Vector2(after.x-before.x,after.z-before.z).normalized()
	return atan2(-d.x,-d.y)

func road_width_at(progress: float) -> float:
	if track.get("mapped_mv",false): return float(_surface_segment(progress).get("width",5.6))
	var before := heading_at(maxf(0.0,progress-18.0))
	var after := heading_at(minf(float(track.length),progress+18.0))
	var bend := absf(wrapf(after-before,-PI,PI))
	return road_width+minf(1.0,bend*0.65)

func add_obstacle(center: Vector3, dimensions: Vector3) -> void:
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer=1
	obstacle.collision_mask=0
	obstacle.position=center
	var hitbox := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=dimensions
	hitbox.shape=shape
	obstacle.add_child(hitbox)
	scenery.add_child(obstacle)

func add_tree_collider(origin: Vector3, size: float) -> void:
	var cell := Vector2i(floori(origin.x/32),floori(origin.z/32))
	if not tree_grid.has(cell): tree_grid[cell]=[]
	tree_grid[cell].append(tree_centers.size())
	tree_max_radius=maxf(tree_max_radius,size*0.10)
	tree_centers.append(Vector2(origin.x,origin.z))
	tree_radii.append(size*0.10)
	var trunk := StaticBody3D.new()
	trunk.add_to_group("rally_tree")
	trunk.collision_layer=1
	trunk.collision_mask=0
	trunk.position=origin+Vector3.UP*size*0.55
	var hitbox := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius=size*0.10
	shape.height=size*1.45
	hitbox.shape=shape
	trunk.add_child(hitbox)
	scenery.add_child(trunk)

func sweep_trees(from: Vector3, to: Vector3, car_radius: float) -> Dictionary:
	var start := Vector2(from.x,from.z)
	var end := Vector2(to.x,to.z)
	var motion := end-start
	var length_squared := motion.length_squared()
	var earliest := 2.0
	var result := {}
	var padding := tree_max_radius+car_radius+1.0
	var low := Vector2i(floori((minf(start.x,end.x)-padding)/32),floori((minf(start.y,end.y)-padding)/32))
	var high := Vector2i(floori((maxf(start.x,end.x)+padding)/32),floori((maxf(start.y,end.y)+padding)/32))
	var candidates: Array=[]
	for x in range(low.x,high.x+1):
		for z in range(low.y,high.y+1): candidates.append_array(tree_grid.get(Vector2i(x,z),[]))
	candidates.sort() # Retain deterministic tie-breaking.
	tree_candidates_last=candidates.size()
	for i in candidates:
		var center := tree_centers[i]
		var radius := tree_radii[i]+car_radius
		if start.distance_squared_to(center)>pow(radius+motion.length()+1.0,2.0): continue
		var t := clampf((center-start).dot(motion)/maxf(length_squared,0.0001),0.0,1.0)
		if start.lerp(end,t).distance_squared_to(center)>radius*radius: continue
		var relative := start-center
		var entry := t
		if length_squared>0.0001:
			var b := relative.dot(motion)
			var disc := b*b-length_squared*(relative.length_squared()-radius*radius)
			if disc>=0.0: entry=clampf((-b-sqrt(disc))/length_squared,0.0,1.0)
		if entry>=earliest: continue
		var at := start.lerp(end,entry)
		var normal := (at-center).normalized()
		if normal.length_squared()<0.01: normal=(start-center).normalized()
		if normal.length_squared()<0.01: normal=Vector2(1,0)
		earliest=entry
		result={"position":center+normal*(radius+0.04),"normal":normal,"tree_index":i}
	return result

func register_mapped_building(p: PackedVector2Array) -> void:
	mapped_buildings.append(p)
	var lo := p[0];var hi := lo
	for v in p:lo=lo.min(v);hi=hi.max(v)
	for x in range(floori(lo.x/80),floori(hi.x/80)+1):
		for z in range(floori(lo.y/80),floori(hi.y/80)+1):
			var key := Vector2i(x,z)
			if not mapped_building_cells.has(key):mapped_building_cells[key]=[]
			mapped_building_cells[key].append(p)

func scenery_clear(position: Vector3, radius: float) -> bool:
	for polygon in mapped_building_cells.get(Vector2i(floori(position.x/80),floori(position.z/80)),[]):
		if Geometry2D.is_point_in_polygon(Vector2(position.x,position.z),polygon): return false
	for polygon in water_polygons:
		if Geometry2D.is_point_in_polygon(Vector2(position.x,position.z),polygon): return false
	if track.state_code=="12" and position.distance_to(geo_to_world(51.5753876,14.0098543))<220.0: return false
	var nearest := _nearest(position)
	var safe_distance := road_width_at(nearest.x)*0.5+radius+2.0
	return nearest.y>safe_distance*safe_distance

func _nearest(pos: Vector3, reference: float = -1.0) -> Vector2:
	var p := Vector2(pos.x,pos.z)
	var best := Vector2(0,1e20)
	for i in range(route_points.size()-1):
		var a := route_points[i]
		var b := route_points[i+1]
		var ab := b-a
		var t := clampf((p-a).dot(ab)/maxf(ab.length_squared(),0.001),0,1)
		var point := a+ab*t
		var progress := distances[i]+(distances[i+1]-distances[i])*t
		var cost := point.distance_squared_to(p)
		if reference>=0: cost+=pow(maxf(0,absf(progress-reference)-80.0)*0.025,2)
		if cost<best.y: best=Vector2(progress,cost)
	return best

func progress_at(pos: Vector3, reference: float = -1.0) -> float:
	return _nearest(pos,reference).x

func lateral_offset(pos: Vector3) -> float:
	var progress := progress_at(pos)
	var c := center_at(progress)
	var h := heading_at(progress)
	return Vector2(pos.x-c.x,pos.z-c.z).dot(Vector2(cos(h),-sin(h)))

func _add_strip(parent: Node3D, width: float, y: float, mat: Material, offset: float = 0.0, dash: bool = false, surface_kind: int = -1) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var count := int(ceil(float(track.length)/5.0))
	for i in range(count):
		if dash and i%6 > 2: continue
		var p0 := float(i)*5.0
		var p1 := minf(float(track.length),float(i+1)*5.0)
		if p1<=p0: continue
		if surface_kind>=0 and int(gravel_at((p0+p1)*0.5))!=surface_kind: continue
		var c0 := center_at(p0)
		var c1 := center_at(p1)
		var h0 := heading_at(p0)
		var h1 := heading_at(p1)
		var r0 := Vector3(cos(h0),0,-sin(h0))
		var r1 := Vector3(cos(h1),0,-sin(h1))
		var w0 := road_width_at(p0) if is_equal_approx(width,road_width) else width
		var w1 := road_width_at(p1) if is_equal_approx(width,road_width) else width
		var o0 := signf(offset)*(road_width_at(p0)*0.5-1.0) if absf(offset)>road_width*0.4 and width<1.0 else offset
		var o1 := signf(offset)*(road_width_at(p1)*0.5-1.0) if absf(offset)>road_width*0.4 and width<1.0 else offset
		var a := c0+r0*(o0-w0*0.5)+Vector3.UP*y
		var b := c0+r0*(o0+w0*0.5)+Vector3.UP*y
		var c := c1+r1*(o1-w1*0.5)+Vector3.UP*y
		var d := c1+r1*(o1+w1*0.5)+Vector3.UP*y
		a.y+=road_relief(p0);b.y+=road_relief(p0);c.y+=road_relief(p1);d.y+=road_relief(p1)
		if official_height!=null:
			var base0: float=official_height.sample(c0);var base1: float=official_height.sample(c1)
			a.y+=official_height.sample(a)-base0;b.y+=official_height.sample(b)-base0
			c.y+=official_height.sample(c)-base1;d.y+=official_height.sample(d)-base1
		vertices.append_array(PackedVector3Array([a,c,b,b,c,d]))
		var face_normal := (c-a).cross(b-a).normalized()
		for j in 6: normals.append(face_normal)
		var u0 := (o0-w0*0.5)/4.0
		var u1 := (o0+w0*0.5)/4.0
		var u2 := (o1-w1*0.5)/4.0
		var u3 := (o1+w1*0.5)/4.0
		uvs.append_array(PackedVector2Array([Vector2(u0,p0/4.0),Vector2(u2,p1/4.0),Vector2(u1,p0/4.0),Vector2(u1,p0/4.0),Vector2(u2,p1/4.0),Vector2(u3,p1/4.0)]))
	if vertices.is_empty(): return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tangents := SurfaceTool.new()
	tangents.create_from(mesh,0)
	tangents.generate_tangents()
	mesh=tangents.commit()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	parent.add_child(instance)

func _multimesh(mesh: Mesh, mat: Material, transforms: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size(): mm.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = mat
	scenery.add_child(node)

func _fill_bends(mat: Material, surface_kind: int = -1) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := 0
	for i in range(1,route_points.size()-1):
		if surface_kind>=0 and int(gravel_at(distances[i]))!=surface_kind: continue
		var incoming := (route_points[i]-route_points[i-1]).normalized()
		var outgoing := (route_points[i+1]-route_points[i]).normalized()
		var angle := absf(atan2(incoming.cross(outgoing),incoming.dot(outgoing)))
		if angle<0.17: continue
		var radius := road_width_at(distances[i])*0.53
		var center := Vector3(route_points[i].x,0.038+road_relief(distances[i]),route_points[i].y)
		for j in 12:
			var first := float(j)*TAU/12.0
			var next := float(j+1)*TAU/12.0
			for vertex in [center,center+Vector3(cos(first)*radius,0,sin(first)*radius),center+Vector3(cos(next)*radius,0,sin(next)*radius)]:
				surface.set_normal(Vector3.UP)
				surface.set_uv(Vector2(vertex.x/4.0,vertex.z/4.0))
				surface.add_vertex(vertex)
			triangles+=1
	if triangles==0: return
	var mesh := MeshInstance3D.new()
	mesh.mesh=surface.commit()
	mesh.material_override=mat
	road.add_child(mesh)

func _finish_gate(progress: float, label_color: Color) -> void:
	var c := center_at(progress)
	var h := heading_at(progress)
	var root := Node3D.new()
	root.position = c
	root.rotation.y = h
	road.add_child(root)
	var metal := _material(Color("202a31"),0.55)
	var glow := _material(label_color,0.4,label_color*0.8)
	for x in [-road_width*0.5-2.4,road_width*0.5+2.4]:
		var pole := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = Vector3(0.4,5.8,0.4)
		pole.mesh = box; pole.material_override = metal; pole.position = Vector3(x,2.9,0)
		root.add_child(pole)
		add_obstacle(root.to_global(Vector3(x,2.9,0)),Vector3(0.58,5.8,0.58))
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size=Vector3(road_width+5.2,0.40,0.45)
	beam.mesh=bm; beam.material_override=glow; beam.position=Vector3(0,5.8,0)
	root.add_child(beam)
	for x in range(-2,3):
		var patch := MeshInstance3D.new()
		var pm := BoxMesh.new(); pm.size=Vector3(1,0.015,0.7)
		patch.mesh=pm; patch.material_override=_material(Color("d7e8db") if x%4==0 else Color("1c252a"))
		patch.position=Vector3(x,0.08,0)
		root.add_child(patch)

func build(data: Dictionary) -> void:
	track = data.duplicate()
	_load_route()
	if track.get("mapped_mv",false):
		official_height=preload("res://scripts/rostock_height27.gd").new()
		for i in range(int(ceil(float(track.length)/5))+2):official_road.append(official_height.sample(center_at(i*5.0)))
	road_width=6.4 if track.surface=="ASPHALT" else 5.6
	add_child(road)
	add_child(scenery)
	var asphalt: bool = track.surface == "ASPHALT"
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var low := route_points[0]
	var high := route_points[0]
	for p in route_points: low=low.min(p); high=high.max(p)
	plane.size = high-low+Vector2(1800,1800) if track.get("mapped_mv",false) else high-low+Vector2(300,300)
	ground.mesh=plane
	ground.position=Vector3((high.x+low.x)*0.5,-0.12,(high.y+low.y)*0.5)
	ground.material_override=_textured_material("res://assets/nature/forrest_ground_01_diff.jpg",Color(0.57,0.67,0.57),Vector3(plane.size.x/14.0,plane.size.y/14.0,1.0))
	if track.state_code=="12":
		var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/lake_relief.json"))
		relief_low=Vector2(meta.low[0],meta.low[1]); relief_span=Vector2(meta.high[0],meta.high[1])-relief_low
		relief=load("res://assets/data/lake_relief.png").get_image()
		plane.size=relief_span; plane.subdivide_width=254; plane.subdivide_depth=254
		ground.position=Vector3(relief_low.x+relief_span.x*0.5,0,relief_low.y+relief_span.y*0.5)
		var terrain := ShaderMaterial.new(); terrain.shader=load("res://assets/shaders/lake_ground.gdshader")
		terrain.set_shader_parameter("relief",load("res://assets/data/lake_relief.png"))
		terrain.set_shader_parameter("atlas",load("res://assets/textures/material_atlas25.png"))
		terrain.set_shader_parameter("grass",load("res://assets/nature/forrest_ground_01_diff.jpg"))
		terrain.set_shader_parameter("low",relief_low); terrain.set_shader_parameter("span",relief_span)
		ground.material_override=terrain
	scenery.add_child(ground)
	if official_height!=null:
		ground.visible=false;official_height.build(scenery)
	if track.state_code=="12" and not OS.get_cmdline_user_args().has("--flat-terrain"):
		terrain3d=load("res://scripts/lake_terrain.gd").build(scenery)
		if terrain3d!=null: ground.visible=false
	_build_city_buildings()
	if not track.get("mapped_mv",false): _build_map_context()
	else:
		var mv: Node3D=load("res://scripts/mv_scenery.gd").new()
		scenery.add_child(mv);mv.configure(self)
	if track.state_code=="12":
		var start_area: Node3D=load("res://scripts/start_area.gd").new()
		scenery.add_child(start_area)
		start_area.configure(self)
	var shoulder := ShaderMaterial.new();shoulder.shader=load("res://assets/shaders/road_shoulder.gdshader")
	shoulder.set_shader_parameter("grass_tex",load("res://assets/nature/forrest_ground_01_diff.jpg"))
	shoulder.set_shader_parameter("gravel_tex",load("res://assets/nature/gravel_floor_diff.jpg"))
	shoulder.set_shader_parameter("grass_normal",load("res://assets/nature/forrest_ground_01_nor_gl.jpg"))
	shoulder.set_shader_parameter("gravel_normal",load("res://assets/nature/gravel_floor_nor_gl.jpg"))
	shoulder.set_shader_parameter("half_width",road_width*0.5)
	shoulder.set_shader_parameter("atlas",load("res://assets/textures/material_atlas25.png"))
	_add_strip(road,road_width+3.0,0.015,shoulder)
	var driving_surface: Material = _textured_material("res://assets/textures/asphalt_v10.png" if asphalt else "res://assets/nature/gravel_floor_diff.jpg",Color(0.82,0.84,0.83) if asphalt else Color(0.92,0.86,0.75))
	if not asphalt:
		var gravel_shader := ShaderMaterial.new()
		gravel_shader.shader=load("res://assets/shaders/gravel_road.gdshader")
		gravel_shader.set_shader_parameter("albedo_tex",load("res://assets/nature/gravel_floor_diff.jpg"))
		gravel_shader.set_shader_parameter("normal_tex",load("res://assets/nature/gravel_floor_nor_gl.jpg"))
		gravel_shader.set_shader_parameter("road_half_width",road_width*0.5)
		gravel_shader.set_shader_parameter("atlas",load("res://assets/textures/material_atlas25.png"))
		driving_surface=gravel_shader
	var asphalt_mat := preload("res://scripts/render/materials25.gd").surface(0)
	if asphalt:driving_surface=asphalt_mat
	if track.get("mapped_mv",false):
		var paved: Material=asphalt_mat
		_add_strip(road,road_width,0.035,driving_surface,0,false,1)
		_add_strip(road,road_width,0.035,paved,0,false,0)
		_fill_bends(driving_surface,1);_fill_bends(paved,0)
	else:
		_add_strip(road,road_width,0.035,driving_surface)
		_fill_bends(driving_surface)
	if track.state_code=="12" and float(track.get("source_offset",0))==0: _start_asphalt()
	if asphalt:
		_add_strip(road,0.17,0.052,_road_material(Color("eed9a6")),road_width*0.5-1.0)
		_add_strip(road,0.17,0.052,_road_material(Color("eed9a6")),-road_width*0.5+1.0)
	if asphalt: _add_strip(road,0.12,0.054,_road_material(Color("d6ddd8")),0.0,true)
	var marker := _material(Color("bdc39e"),0.5,Color("626940"))
	for sector in [1,2]:
		var line := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size=Vector3(road_width,0.025,0.45)
		line.mesh=box; line.material_override=marker
		line.position=center_at(float(track.length)*float(sector)/3.0)+Vector3(0,0.08,0)
		line.rotation.y=heading_at(float(track.length)*float(sector)/3.0)
		road.add_child(line)
	_finish_gate(8.0,Color("f5c950"))
	if track.state_code!="12": _finish_gate(float(track.length)-5.0,Color("78dcd1"))
	var rng := RandomNumberGenerator.new(); rng.seed = int(track.seed)*70821
	var grass_rng := RandomNumberGenerator.new();grass_rng.seed=int(track.seed)*70821+357
	var spatial_pines: Array[Transform3D] = []
	var spruce_a: Array[Transform3D] = []
	var spruce_b: Array[Transform3D] = []
	var oak_a: Array[Transform3D] = []
	var oak_b: Array[Transform3D] = []
	var spatial_oaks: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var bushes: Array[Transform3D] = []
	var grass_dark: Array[Transform3D] = []
	var grass_light: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var reflectors: Array[Transform3D] = []
	var light_poles: Array[Transform3D] = []
	var light_caps: Array[Transform3D] = []
	var industrial: bool = track.surface == "ASPHALT"
	for p in range(0,int(track.length),5):
		for side in [-1.0,1.0]:
			var direction := Vector3(cos(heading_at(p)),0,-sin(heading_at(p)))
			var verge := road_width_at(float(p))*0.5+1.8
			if not industrial or rng.randf()<0.45:
				var grass_position: Vector3 = center_at(p)+direction*side*(verge+rng.randf_range(0.8,7.0))+Vector3(rng.randf_range(-2.0,2.0),0.23,rng.randf_range(-2.0,2.0))
				if scenery_clear(grass_position,0.9):
					grass_position.y=ground_height(grass_position)+0.02
					var tuft := Transform3D(Basis().rotated(Vector3.UP,grass_rng.randf_range(-PI,PI)).scaled(Vector3(rng.randf_range(0.65,1.2),rng.randf_range(0.55,1.05),rng.randf_range(0.65,1.2))),grass_position)
					if rng.randf()<0.5: grass_dark.append(tuft)
					else: grass_light.append(tuft)
					for extra in 3:
						var dense := tuft
						var scatter_rng := rng if extra<3 else grass_rng
						dense.origin+=Vector3(scatter_rng.randf_range(-1.8,1.8),0,scatter_rng.randf_range(-1.8,1.8))
						if scenery_clear(dense.origin,0.4):
							dense.origin.y=ground_height(dense.origin)+0.02
							grass_dark.append(dense)
			if p%50==0:
				var post_position: Vector3 = center_at(p)+direction*side*(verge+0.3)
				if scenery_clear(post_position,0.2):
					posts.append(Transform3D(Basis().scaled(Vector3(0.17,1.05,0.17)),post_position+Vector3.UP*0.53))
					reflectors.append(Transform3D(Basis().scaled(Vector3(0.2,0.18,0.2)),post_position+Vector3.UP*0.91))
			if industrial and p%80==0:
				var lamp_position: Vector3=center_at(p)+direction*side*(verge+1.5)
				if scenery_clear(lamp_position,0.45):
					light_poles.append(Transform3D(Basis().scaled(Vector3(0.22,5.8,0.22)),lamp_position+Vector3.UP*2.9))
					light_caps.append(Transform3D(Basis().scaled(Vector3(0.8,0.2,0.6)),lamp_position+Vector3.UP*5.76))
					add_obstacle(lamp_position+Vector3.UP*2.9,Vector3(0.38,5.8,0.38))
			if track.get("mapped_mv",false): continue
			if rng.randf() < (0.55 if industrial else 0.08):
				continue
			var distance := rng.randf_range(7.0,26.0)
			var origin: Vector3 = center_at(p) + direction*side*distance+Vector3(0,0,rng.randf_range(-7,7))
			var size := rng.randf_range(2.1,5.6)
			if not scenery_clear(origin,size*0.75): continue
			var deciduous := rng.randf()<(0.42 if industrial else 0.23)
			var height := size*(1.70 if deciduous else 2.08)
			var breadth := size*(1.45 if deciduous else 1.18)
			var angle := rng.randf_range(-PI,PI)
			origin.y=ground_height(origin)-0.08
			var sprite_center := origin+Vector3.UP*height*0.5
			var view_a := Transform3D(Basis().rotated(Vector3.UP,angle).scaled(Vector3(breadth,height,1.0)),sprite_center)
			var view_b := Transform3D(Basis().rotated(Vector3.UP,angle+PI*0.5).scaled(Vector3(breadth,height,1.0)),sprite_center)
			if deciduous:
				oak_a.append(view_a)
				spatial_oaks.append(Transform3D(Basis().rotated(Vector3.UP,angle).scaled(Vector3.ONE*(height/8.0)),origin))
				oak_b.append(view_b)
			else:
				spruce_a.append(view_a)
				spatial_pines.append(Transform3D(Basis().rotated(Vector3.UP,angle).scaled(Vector3.ONE*(height/8.2)),origin))
				var companion: Vector3= origin+direction*side*rng.randf_range(3.5,7.0)+Vector3(0,0,rng.randf_range(-5,5))
				if scenery_clear(companion,size*0.65) and ground_height(companion)>-4.5:
					companion.y=ground_height(companion)-0.08
					spatial_pines.append(Transform3D(Basis().rotated(Vector3.UP,angle+1.7).scaled(Vector3.ONE*(height/8.2)*0.85),companion))
					add_tree_collider(companion,size*0.85)
				spruce_b.append(view_b)
			add_tree_collider(origin,size)
			if rng.randf() < 0.34:
				var rpos: Vector3 = center_at(p)+direction*side*rng.randf_range(13,34)+Vector3(0,0,rng.randf_range(-5,5))
				var rs := rng.randf_range(0.45,1.5)
				if scenery_clear(rpos,rs):
					rocks.append(Transform3D(Basis().scaled(Vector3(rs*1.6,rs,rs)),Vector3(rpos.x,ground_height(rpos)+rs*0.25,rpos.z)))
					if p%40==0: add_obstacle(rpos+Vector3.UP*rs*0.5,Vector3(rs*1.6,rs,rs))
			if rng.randf() < 0.48:
				var bp: Vector3 = center_at(p)+direction*side*rng.randf_range(15,38)+Vector3(0,0.36,rng.randf_range(-5,5))
				var bs := rng.randf_range(0.6,1.4)
				if scenery_clear(bp,bs): bushes.append(Transform3D(Basis().scaled(Vector3(bs*1.5,bs*0.7,bs)),Vector3(bp.x,ground_height(bp)+bs*0.20,bp.z)))
	var card := QuadMesh.new()
	card.size=Vector2.ONE
	var spruce_material := _tree_material("res://assets/textures/spruce_v10.png")
	var oak_material := _tree_material("res://assets/textures/oak_v10.png")
	preload("res://scripts/render/forest.gd").plant(scenery,spatial_pines)
	var forest_batch=preload("res://scripts/render/forest.gd")
	forest_batch.plant_variants(scenery,spatial_pines,"far_pines",420,167,false,true)
	forest_batch.plant_variants(scenery,spatial_oaks,"far_oaks",420,117,true,true)
	forest_batch.plant_variants(scenery,spatial_oaks,"spatial_oaks",125,0,true,false)

	var rock := _stone_mesh()
	_multimesh(rock,_material(Color("77776d")),rocks)
	_multimesh(rock,_material(Color("35614a") if track.place=="NORDIC FOREST" else Color("63735a")),bushes)
	var tuft_mesh := _grass_mesh()
	var grass_mat := ShaderMaterial.new();grass_mat.shader=load("res://assets/shaders/verge_grass.gdshader")
	tuft_mesh.surface_set_material(0,grass_mat)
	var grass_batch=preload("res://scripts/render/forest.gd")
	grass_batch.plant_mesh(scenery,grass_dark,tuft_mesh,"verge_grass",45)
	grass_batch.plant_mesh(scenery,grass_light,tuft_mesh,"verge_grass",45)
	var ferns: Array[Transform3D]=[]
	for i in range(0,grass_dark.size(),23):
		var t: Transform3D=grass_dark[i];t.basis=t.basis.scaled(Vector3.ONE*1.45);ferns.append(t)
	var fern := _fern_mesh();fern.surface_set_material(0,grass_mat)
	grass_batch.plant_mesh(scenery,ferns,fern,"verge_grass",65)
	var post_mesh := BoxMesh.new()
	_multimesh(post_mesh,_material(Color("e1dbc1")),posts)
	_multimesh(post_mesh,_material(Color("d39d5a"),0.55,Color("6b4322")),reflectors)
	_multimesh(post_mesh,_material(Color("596468")),light_poles)
	_multimesh(post_mesh,_material(Color("ecdeb4"),0.4,Color("bda969")),light_caps)



func _grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 22:
		var angle := float(i)*2.39996
		var base := Vector3(cos(angle)*0.32,0,sin(angle)*0.32)
		var side := Vector3(cos(angle+1.57),0,sin(angle+1.57))*0.019
		var bend := Vector3(cos(angle)*0.16,0,sin(angle)*0.16)
		var height := 0.26+float(i%5)*0.065
		var mid := base+bend*0.35+Vector3.UP*height*0.55
		var tip := base+bend+Vector3.UP*height
		var color := Color(0.65+float(i%3)*0.08,0.73+float(i%4)*0.06,0.43,1)
		for pair in [[base-side,0.0],[base+side,0.0],[mid-side*0.65,0.55],[base+side,0.0],[mid+side*0.65,0.55],[mid-side*0.65,0.55],[mid-side*0.65,0.55],[mid+side*0.65,0.55],[tip,1.0]]:
			st.set_color(color);st.set_uv(Vector2(0,pair[1]));st.add_vertex(pair[0])
	st.generate_normals()
	return st.commit()

func _water_material() -> ShaderMaterial:
	var m := ShaderMaterial.new();m.shader=preload("res://assets/shaders/water25.gdshader");return m

func _start_asphalt() -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,270,3):
		var a := center_at(i); var b := center_at(i+3)
		var h := heading_at(i); var side := Vector3(cos(h),0,-sin(h))*3.2
		for v in [a-side,b-side,a+side,a+side,b-side,b+side]:
			st.set_normal(Vector3.UP); st.set_uv(Vector2(v.x,v.z)/4.0); st.add_vertex(v+Vector3.UP*0.065)
	var m := MeshInstance3D.new(); m.mesh=st.commit()
	m.material_override=preload("res://scripts/render/materials25.gd").surface(0)
	road.add_child(m)

func _surface_segment(progress: float) -> Dictionary:
	if surface_segments.is_empty():return {}
	var target := progress*source_route_length/float(track.length)
	var lo := 0;var hi := surface_segments.size()-1
	while lo<hi:
		var mid := int((lo+hi)/2)
		if float(surface_segments[mid].to)<target:lo=mid+1
		else:hi=mid
	return surface_segments[lo]

func gravel_at(progress: float) -> bool:
	if track.get("mapped_mv",false):return bool(_surface_segment(progress).get("gravel",false))
	return track.surface=="GRAVEL" and not (track.state_code=="12" and progress+float(track.get("source_offset",0))<270.0)

func ground_height(at: Vector3) -> float:
	if official_height!=null:return official_height.sample(at)-0.08
	if terrain3d!=null:
		var actual: float=terrain3d.get("data").call("get_height",at)
		if is_finite(actual):return actual
	if relief==null:return -0.12
	var uv := (Vector2(at.x,at.z)-relief_low)/relief_span
	var p := uv*Vector2(relief.get_width()-1,relief.get_height()-1)
	var x := clampi(int(p.x),0,relief.get_width()-2); var y := clampi(int(p.y),0,relief.get_height()-2)
	var a := lerpf(relief.get_pixel(x,y).r,relief.get_pixel(x+1,y).r,clampf(p.x-x,0,1))
	var b := lerpf(relief.get_pixel(x,y+1).r,relief.get_pixel(x+1,y+1).r,clampf(p.x-x,0,1))
	return lerpf(a,b,clampf(p.y-y,0,1))*6.0-6.0

func contact_height(at: Vector3, reference: float) -> float:
	var near := _nearest(at,reference)
	if near.y<=pow(road_width_at(near.x)*0.5,2):
		var crossfall: float=official_height.sample(at)-official_height.sample(center_at(near.x)) if official_height!=null else 0.0
		return road_relief(near.x)+crossfall
	return ground_height(at)

# ASSUMPTION: subtle generated gravel undulations, not surveyed topography.
# The same piecewise-linear height profile drives the rendered road and contact query.
func road_relief(progress: float) -> float:
	var p0 := floorf(progress/5.0)*5.0
	return lerpf(_road_relief_sample(p0),_road_relief_sample(p0+5),fposmod(progress,5.0)/5.0)

func _road_relief_sample(progress: float) -> float:
	if not official_road.is_empty():
		var index := clampi(int(round(progress/5)),0,official_road.size()-1)
		return official_road[index]+0.16
	if not gravel_at(progress):return 0.0
	var fade := clampf((progress+float(track.get("source_offset",0))-270)/25,0,1) if track.state_code=="12" else clampf(progress/25,0,1)
	return (sin(progress*TAU/23)*0.023+sin(progress*TAU/41)*0.012)*fade

func _fern_mesh() -> ArrayMesh:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in 7:
		var a := frond*2.39996
		var axis := Vector3(cos(a),0,sin(a));var side := Vector3(-sin(a),0,cos(a))
		for i in range(1,9):
			var along := float(i)/9
			var base := axis*along*0.50+Vector3.UP*(sin(along*PI)*0.28+0.04)
			var breadth := sin(along*PI)*0.11
			for sign in [-1.0,1.0]:
				var leaf: Vector3 = base+side*sign*breadth+axis*0.04
				for pair in [[base-axis*0.035,0.0],[leaf,1.0],[base+axis*0.045,0.0]]:
					st.set_color(Color(0.70,0.97,0.60));st.set_uv(Vector2(0,pair[1]));st.add_vertex(pair[0])
	st.generate_normals();return st.commit()

func _stone_mesh() -> ArrayMesh:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for level in 3:
		var ring := PackedVector3Array()
		for i in 7:
			var angle := float(i)*TAU/7+level*0.18
			var radius := (0.47 if level==1 else 0.28)*(0.86+float((i*3+level)%5)*0.075)
			ring.append(Vector3(cos(angle)*radius,(level-1)*0.35,sin(angle)*radius))
		rings.append(ring)
	for level in 2:
		for i in 7:
			var next := (i+1)%7
			for vertex in [rings[level][i],rings[level+1][i],rings[level][next],rings[level][next],rings[level+1][i],rings[level+1][next]]:st.add_vertex(vertex)
	for i in 7:
		for vertex in [Vector3(0,0.38,0),rings[2][i],rings[2][(i+1)%7]]:st.add_vertex(vertex)
	st.generate_normals();return st.commit()
