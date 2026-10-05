extends RefCounted
# Appearance-only GLB adapter. Dimensions, tyres, engine and collision stay in the native simulation.
static func bounds(node: Node, transform: Transform3D=Transform3D.IDENTITY) -> AABB:
	var result := AABB();var found := false
	if node is Node3D:transform=transform*node.transform
	if node is MeshInstance3D and node.mesh!=null:
		result=transform*node.mesh.get_aabb();found=true
	for child in node.get_children():
		var child_bounds := bounds(child,transform)
		if child_bounds.size.length_squared()<0.000001:continue
		result=result.merge(child_bounds) if found else child_bounds;found=true
	return result
static func inspect(node: Node) -> Dictionary:
	var triangles := 0;var meshes := 0
	if node is MeshInstance3D and node.mesh!=null:
		meshes=1
		for surface in node.mesh.get_surface_count():
			if node.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			triangles+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
	for child in node.get_children():
		var data := inspect(child);triangles+=int(data.triangles);meshes+=int(data.meshes)
	return {"triangles":triangles,"meshes":meshes}
static func find_named(node: Node, title: String) -> Node3D:
	if node.name==title and node is Node3D:return node
	for child in node.get_children():
		var match_node := find_named(child,title)
		if match_node!=null:return match_node
	return null
static func attach(vehicle: Node3D, config: Dictionary, override_profile: Dictionary={}) -> Dictionary:
	var profile := override_profile
	if profile.is_empty():
		var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://config/vehicle_visuals.json"))
		profile=profiles.get(str(config.id),{})
	if profile.is_empty():return {}
	var path: String=profile.get("scene_path","")
	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):return {}
	var imported: Node3D
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var scene: Resource=load(path)
		if scene is PackedScene:imported=scene.instantiate()
	else:
		var document := GLTFDocument.new();var state := GLTFState.new()
		if document.append_from_file(path,state)!=OK:return {"error":"GLB konnte nicht gelesen werden"}
		imported=document.generate_scene(state)
	if imported==null:return {"error":"Keine 3D-Szene"}
	var rotated := Node3D.new();rotated.rotation.y=deg_to_rad(float(profile.get("rotation_y_degrees",0)));rotated.add_child(imported)
	var stats := inspect(rotated);var box := bounds(rotated)
	if not box.size.is_finite() or box.size.z<0.001 or int(stats.triangles)>int(profile.get("max_triangles",100000)):
		rotated.free();return {"error":"Geometrie ungültig oder Polygonbudget überschritten"}
	var scale_factor := float(profile.get("target_length_m",4.87))/box.size.z
	var scaled_size := box.size*scale_factor
	if scaled_size.x>3.0 or scaled_size.y>3.0 or scaled_size.x<0.5 or scaled_size.y<0.3:
		rotated.free();return {"error":"Modellausrichtung oder Proportionen prüfen"}
	var holder := Node3D.new();holder.name="ImportedVisual";holder.add_child(rotated)
	rotated.scale=Vector3.ONE*scale_factor
	rotated.position=-Vector3(box.get_center().x,box.position.y,box.get_center().z)*scale_factor
	# Imported meshes never replace the established collision shape.
	for child in vehicle.body.get_children():
		if child is Node3D:child.hide()
	vehicle.body.add_child(holder)
	var wheel_names: Dictionary=profile.get("wheel_nodes",{})
	var mapped: Array[Node3D]=[]
	for key in ["front_left","front_right","rear_left","rear_right"]:
		var wheel := find_named(imported,str(wheel_names.get(key,"")))
		if wheel!=null:mapped.append(wheel)
	if mapped.size()==4:
		for i in 4:
			var spin: Node3D=vehicle.wheel_spins[i];var pivot: Node3D=spin.get_parent()
			for child in spin.get_children():
				if child is Node3D:child.free()
			pivot.show();mapped[i].reparent(spin,true)
			if profile.get("center_wheels_on_native_pivots",false):mapped[i].position=Vector3.ZERO
	var brake_name: String=profile.get("brake_material_name","")
	if not brake_name.is_empty():
		bind_brake_material(imported,vehicle,brake_name)
	stats["articulated_wheels"]=mapped.size()==4
	stats["length_m"]=scaled_size.z;stats["width_m"]=scaled_size.x;stats["height_m"]=scaled_size.y
	return stats

static func bind_brake_material(node: Node, vehicle: Node3D, title: String) -> void:
	if node is MeshInstance3D and node.mesh!=null:
		for i in node.mesh.get_surface_count():
			var source: Material=node.get_active_material(i)
			if source is StandardMaterial3D and source.resource_name==title:
				# Per-car native material avoids shared resource changes across garage/race.
				node.set_surface_override_material(i,vehicle.rear_lamps)
	for child in node.get_children():bind_brake_material(child,vehicle,title)
