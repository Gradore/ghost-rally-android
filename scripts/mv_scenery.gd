extends Node3D
# Geographic footprints from OSM; untagged facade/roof appearance is interpreted.
var world: TrackWorld
var batches := {}
var footprint_reference := {}
var field_polygons: Array[PackedVector2Array] = []
var woods: Array[PackedVector2Array] = []
var glass: StandardMaterial3D
var roof_material: Material
var wall_material: Material
var street_reference := {}
var local_reference := {}
var below_ground_ids := []
var completed_building_ids := []

func _polygon(ll: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for c in ll:
		var v := world.geo_to_world(float(c[0]),float(c[1]));p.append(Vector2(v.x,v.z))
	return p

func _batch(key: String, at: Vector3, material: Material, distance: float = 500) -> SurfaceTool:
	var cell := Vector2i(floori(at.x/200),floori(at.z/200))
	var id := key+str(cell)
	if not batches.has(id):
		var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[id]={"st":st,"material":material,"distance":distance}
	return batches[id].st

func _tri(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,normal: Vector3,color: Color) -> void:
	for v in [a,b,c]:
		st.set_color(color);st.set_normal(normal);st.set_uv(Vector2(v.x,v.z)/4.0 if absf(normal.y)>0.7 else Vector2(v.x+v.z,v.y)/3.0);st.add_vertex(v)

func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,n: Vector3,col: Color) -> void:
	_tri(st,a,b,c,n,col);_tri(st,c,b,d,n,col)

func roof_outline(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	var changed := true
	while changed and result.size()>4:
		changed=false
		for i in result.size():
			var a := result[i]-result[(i-1+result.size())%result.size()]
			var b := result[(i+1)%result.size()]-result[i]
			if a.length()<0.02 or b.length()<0.02 or (a.dot(b)>0 and absf(a.cross(b))/maxf(a.length()*b.length(),0.001)<0.01):
				result.remove_at(i);changed=true;break
	return result

func pitched_polygon(p: PackedVector2Array,h: float,cap: SurfaceTool,wall: SurfaceTool,roof_color: Color,color: Color) -> void:
	# Split at the ridge before triangulation. Each resulting roof half is planar
	# and clipped to the source footprint, including concave notches.
	var longest := 0.0;var axis := Vector2.RIGHT
	for i in p.size():
		var edge := p[(i+1)%p.size()]-p[i]
		if edge.length()>longest:longest=edge.length();axis=edge.normalized()
	var across := Vector2(-axis.y,axis.x);var local := PackedVector2Array()
	var lo := Vector2(INF,INF);var hi := Vector2(-INF,-INF)
	for v in p:
		var q := Vector2(v.dot(axis),v.dot(across));local.append(q);lo=lo.min(q);hi=hi.max(q)
	var middle := (lo.y+hi.y)*0.5;var half := maxf(0.1,(hi.y-lo.y)*0.5);var rise := minf(3.0,half*0.45)
	for interval in [[lo.y-1,middle],[middle,hi.y+1]]:
		var clip := PackedVector2Array([Vector2(lo.x-1,interval[0]),Vector2(hi.x+1,interval[0]),Vector2(hi.x+1,interval[1]),Vector2(lo.x-1,interval[1])])
		for polygon in Geometry2D.intersect_polygons(local,clip):
			var indices := Geometry2D.triangulate_polygon(polygon)
			for j in range(0,indices.size(),3):
				var tri: Array[Vector3]=[]
				for k in 3:
					var q: Vector2=polygon[indices[j+k]];var v := axis*q.x+across*q.y
					tri.append(Vector3(v.x,h+rise*maxf(0,1-absf(q.y-middle)/half),v.y))
				var n := (tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized();if n.y<0:n=-n
				_tri(cap,tri[0],tri[1],tri[2],n,roof_color)
	for i in p.size():
		var a := p[i];var b := p[(i+1)%p.size()];var breaks: Array[Vector2]=[a,b]
		var ya := a.dot(across)-middle;var yb := b.dot(across)-middle
		if ya*yb<0:breaks.insert(1,a.lerp(b,ya/(ya-yb)))
		for j in range(breaks.size()-1):
			var x := breaks[j];var y := breaks[j+1]
			var top_a := h+rise*maxf(0,1-absf(x.dot(across)-middle)/half);var top_b := h+rise*maxf(0,1-absf(y.dot(across)-middle)/half)
			var normal := Vector3(-(y-x).y,0,(y-x).x).normalized()
			_quad(wall,Vector3(x.x,h,x.y),Vector3(x.x,top_a,x.y),Vector3(y.x,h,y.y),Vector3(y.x,top_b,y.y),normal,color)

func _building(data: Dictionary) -> void:
	var p := _polygon(data.p)
	if p.size()<3:return
	footprint_reference[str(data.id)]=p
	if data.tags.get("location","")=="underground" or int(data.tags.get("layer","0"))<0:
		# Preserve geographic reference, but an underground garage is not a solid above-ground block.
		below_ground_ids.append(str(data.id))
		var paving := ShaderMaterial.new();paving.shader=preload("res://assets/shaders/street_paving.gdshader")
		_ground(p,paving,0.006);return
	world.register_mapped_building(p)
	var mid := Vector2.ZERO
	for v in p:mid+=v
	mid/=float(p.size())
	var center := Vector3(mid.x,0,mid.y)
	var roof_points := roof_outline(p)
	var roof_kind: String=data.tags.get("roof:shape",data.roof)
	if roof_kind=="half-hipped":roof_kind="hipped"
	var local_appearance: Dictionary=local_reference.get("building_overrides",{}).get(str(data.id),{})
	var modern: bool=local_appearance.get("style","")=="modern_apartments"
	var h := clampf(float(local_appearance.get("height_m",data.h)),2.4,40)
	if modern:completed_building_ids.append(str(data.id))
	if roof_kind in ["gabled","hipped"] and data.tags.has("height") and roof_points.size()==4:
		h=maxf(2.0,h-minf(3.0,minf(p[0].distance_to(p[1]),p[1].distance_to(p[2]))*0.3))
	var wall := _batch("wall",center,wall_material)
	var windows := _batch("window",center,glass,220)
	var cap := _batch("roof",center,roof_material)
	var palette := [Color("e3d9c5"),Color("b57453"),Color("e0dcd2"),Color("c9bc9c"),Color("976a53")]
	var color: Color=palette[int(data.id)%palette.size()]
	if data.tags.has("building:colour"):color=Color.from_string(data.tags["building:colour"],color)
	var appearance: Dictionary=street_reference.get("building_overrides",{}).get(str(data.id),{})
	if appearance.has("facade"):color=Color(appearance.facade)
	if local_appearance.has("facade"):color=Color(local_appearance.facade)
	var levels := maxi(1,int(h/3.0))
	var garage: bool=data.kind in ["garage","garages","shed","farm_auxiliary"]
	var collision := SurfaceTool.new();collision.begin(Mesh.PRIMITIVE_TRIANGLES)
	var near_road := true # Every mapped footprint blocks the car, including large/set-back buildings.
	for i in p.size():
		var a := Vector3(p[i].x,0,p[i].y);var b := Vector3(p[(i+1)%p.size()].x,0,p[(i+1)%p.size()].y)
		var edge := b-a
		if edge.length_squared()<0.01:continue
		var n := Vector3(-edge.z,0,edge.x).normalized()
		if Geometry2D.is_point_in_polygon(Vector2((a.x+b.x)*0.5+n.x*0.1,(a.z+b.z)*0.5+n.z*0.1),p):n=-n
		_quad(wall,a,a+Vector3.UP*h,b,b+Vector3.UP*h,n,color)
		if near_road:_quad(collision,a,a+Vector3.UP*h,b,b+Vector3.UP*h,n,Color.WHITE)
		if garage:continue
		if modern:
			_modern_face(a,b,n,h,wall,windows,local_appearance)
			continue
		var bays := int(edge.length()/3.6)
		for floor_id in levels:
			for bay in bays:
				var at := a.lerp(b,(bay+0.5)/maxf(bays,1))+Vector3.UP*(1.55+3.0*floor_id)+n*0.045
				if at.y+0.8>h:continue
				var right := edge.normalized()*0.55
				_quad(windows,at-right-Vector3.UP*0.72,at-right+Vector3.UP*0.72,at+right-Vector3.UP*0.72,at+right+Vector3.UP*0.72,n,Color.WHITE)
				# Thin mullion and sill in the same facade batch.
				_quad(wall,at-edge.normalized()*0.035-Vector3.UP*0.74+n*0.012,at-edge.normalized()*0.035+Vector3.UP*0.74+n*0.012,at+edge.normalized()*0.035-Vector3.UP*0.74+n*0.012,at+edge.normalized()*0.035+Vector3.UP*0.74+n*0.012,n,Color("ebe7de"))
	if near_road:
		var hit := StaticBody3D.new();var shape := CollisionShape3D.new();shape.shape=collision.commit().create_trimesh_shape();shape.shape.backface_collision=true;hit.add_child(shape);add_child(hit)
	if modern:_setback_storey(p,h,wall,cap,local_appearance)
	p=roof_points
	var roof_color := Color("9b5540") if roof_kind in ["hipped","gabled"] else Color("626b68")
	if data.tags.has("roof:colour"):roof_color=Color.from_string(data.tags["roof:colour"],roof_color)
	if roof_kind in ["hipped","gabled"] and p.size()==4:
		if p[0].distance_to(p[1])<p[1].distance_to(p[2]):p=PackedVector2Array([p[1],p[2],p[3],p[0]])
		var a := Vector3(p[0].x,h,p[0].y);var b := Vector3(p[1].x,h,p[1].y);var c := Vector3(p[2].x,h,p[2].y);var d := Vector3(p[3].x,h,p[3].y)
		var near := (a+d)*0.5;var far := (b+c)*0.5;var axis := (far-near).normalized();var inset := 0.0 if roof_kind=="gabled" else minf(a.distance_to(d)*0.4,near.distance_to(far)*0.4)
		var r0 := near+axis*inset+Vector3.UP*minf(3,a.distance_to(d)*0.3);var r1 := far-axis*inset+Vector3.UP*minf(3,a.distance_to(d)*0.3)
		if roof_kind=="gabled":
			_tri(wall,d,a,r0,(near-far).normalized(),color);_tri(wall,b,c,r1,(far-near).normalized(),color)
		for t in [[a,b,r0],[b,r1,r0],[b,c,r1],[c,d,r1],[d,r0,r1],[d,a,r0]]:
			var normal: Vector3=(t[1]-t[0]).cross(t[2]-t[0]).normalized()
			if normal.y<0:normal=-normal
			_tri(cap,t[0],t[1],t[2],normal,roof_color)
	elif roof_kind in ["gabled","hipped"]:
		pitched_polygon(p,h,cap,wall,roof_color,color)
	else:
		for i in Geometry2D.triangulate_polygon(p):
			cap.set_normal(Vector3.UP);cap.set_color(roof_color);cap.set_uv(p[i]/2);cap.add_vertex(Vector3(p[i].x,h,p[i].y))

func _ground(p: PackedVector2Array,mat: Material,y: float) -> void:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(p)
	if indices.is_empty():return
	for i in indices:st.set_normal(Vector3.UP);st.set_uv(p[i]/12);st.add_vertex(Vector3(p[i].x,y,p[i].y))
	var node := MeshInstance3D.new();st.generate_tangents();node.mesh=st.commit();node.material_override=mat;add_child(node)

func configure(track_world: TrackWorld) -> void:
	world=track_world
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/mv_rostock.json"))
	street_reference=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/streetview_reference.json"))
	local_reference=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/local_details26.json"))
	wall_material=preload("res://scripts/render/materials25.gd").surface(6,Color.WHITE,true)
	var roof := ShaderMaterial.new();roof.shader=preload("res://assets/shaders/roof24.gdshader");roof_material=roof
	glass=StandardMaterial3D.new();glass.albedo_color=Color("344a55");glass.roughness=0.24;glass.metallic=0.35;glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	for b in data.buildings:_building(b)
	for b in batches.values():
		_flush(b,float(b.distance))
	var tones := [Color("9c9869"),Color("8b975d"),Color("697b48"),Color("b2a47a")]
	for area in data.land:
		var p := _polygon(area.p)
		if p.size()<3:continue
		var tint: Color=tones[int(area.id)%tones.size()]
		if area.kind in ["wood","forest"]:woods.append(p);tint=Color("4e6750")
		if area.kind=="farmland":field_polygons.append(p)
		if area.kind=="water":world.water_polygons.append(p);tint=Color("526f77")
		var mat := ShaderMaterial.new();mat.shader=preload("res://assets/shaders/rural_ground24.gdshader")
		mat.set_shader_parameter("albedo_tex",load("res://assets/nature/forrest_ground_01_diff.jpg"));mat.set_shader_parameter("normal_tex",load("res://assets/nature/forrest_ground_01_nor_gl.jpg"))
		mat.set_shader_parameter("tint",tint*0.65);mat.set_shader_parameter("farmland",area.kind=="farmland")
		_ground(p,world._water_material() if area.kind=="water" else preload("res://scripts/render/materials25.gd").surface(4,Color("b8c294")) if area.kind not in ["wood","forest","farmland"] else mat,-0.06)
	# Local connecting streets, including the bend, driveway junctions and farm access roads.
	var paved: Material=preload("res://scripts/render/materials25.gd").surface(0)
	var paving := ShaderMaterial.new();paving.shader=preload("res://assets/shaders/street_paving.gdshader")
	var dirt: Material=world._textured_material("res://assets/nature/gravel_floor_diff.jpg",Color("b4a586"))
	for road in data.roads:
		var pts := _polygon(road.p)
		var footway: bool=road.get("highway","") in ["footway","path","cycleway","pedestrian","steps"]
		var half_width := 0.75 if footway else 2.3
		for i in range(pts.size()-1):
			var a := Vector3(pts[i].x,0.008,pts[i].y);var b := Vector3(pts[i+1].x,0.008,pts[i+1].y)
			var n := Vector3(-(b-a).z,0,(b-a).x).normalized()*half_width
			var unpaved: bool=road.surface in ["dirt","ground","gravel","compacted","grass"]
			var is_paving: bool=road.surface=="paving_stones"
			var st := _batch("streetPaving" if is_paving else ("dirtroad" if unpaved else "street"),(a+b)*0.5,paving if is_paving else (dirt if unpaved else paved),600)
			_quad(st,a-n,a+n,b-n,b+n,Vector3.UP,Color.WHITE)
	preload("res://scripts/street_details.gd").new().build(self,world,data,street_reference)
	var rail_mat: Material=world._material(Color("697376"),0.42)
	var ballast: Material=world._textured_material("res://assets/nature/gravel_floor_diff.jpg",Color("777970"))
	for ll in data.rails:
		var pts := _polygon(ll)
		for i in range(pts.size()-1):
			var a := Vector3(pts[i].x,0.01,pts[i].y);var b := Vector3(pts[i+1].x,0.01,pts[i+1].y)
			var n := Vector3(-(b-a).z,0,(b-a).x).normalized()
			var st := _batch("dirtroadRail",(a+b)*0.5,ballast,500)
			_quad(st,a-n*1.8,a+n*1.8,b-n*1.8,b+n*1.8,Vector3.UP,Color.WHITE)
			var rails := _batch("streetRail",(a+b)*0.5,rail_mat,500)
			for side in [-1.0,1.0]:
				var x: Vector3 = a+n*side*0.7175+Vector3.UP*0.10;var y: Vector3 = b+n*side*0.7175+Vector3.UP*0.10
				_quad(rails,x-n*0.035,x+n*0.035,y-n*0.035,y+n*0.035,Vector3.UP,Color.WHITE)
	var water: Material=world._water_material()
	for ll in data.get("streams",[]):
		var pts := _polygon(ll)
		for i in range(pts.size()-1):
			var a := Vector3(pts[i].x,-0.005,pts[i].y);var b := Vector3(pts[i+1].x,-0.005,pts[i+1].y)
			var side := Vector3(-(b-a).z,0,(b-a).x).normalized()*1.15
			var st := _batch("streetWater",(a+b)*0.5,water,500)
			_quad(st,a-side,a+side,b-side,b+side,Vector3.UP,Color.WHITE)
	# Flush the newly created road batches only.
	for key in batches:
		if not (key.begins_with("street") or key.begins_with("dirtroad")):continue
		_flush(batches[key],600)
	var trees: Array[Transform3D]=[]
	for ll in data.trees:
		var at := world.geo_to_world(float(ll[0]),float(ll[1]))
		if world.scenery_clear(at,1.7):trees.append(Transform3D(Basis().scaled(Vector3.ONE*1.15),at));world.add_tree_collider(at,2.1)
	for ll in data.get("tree_rows",[]):
		var pts := _polygon(ll)
		for i in range(pts.size()-1):
			var count := maxi(1,int(pts[i].distance_to(pts[i+1])/11))
			for j in count:
				var v := pts[i].lerp(pts[i+1],float(j)/count);var at := Vector3(v.x,0,v.y)
				if not world.scenery_clear(at,1.8):continue
				trees.append(Transform3D(Basis().rotated(Vector3.UP,float(j)*1.63).scaled(Vector3.ONE*(1.0+float(j%3)*0.18)),at));world.add_tree_collider(at,2.1)
	# Sample crowns only inside mapped woodland, leaving open fields and house plots clear.
	var rng := RandomNumberGenerator.new();rng.seed=2104
	for p in woods:
		var lo := p[0];var hi := lo
		for v in p:lo=lo.min(v);hi=hi.max(v)
		for x in range(int(lo.x),int(hi.x),23):
			for z in range(int(lo.y),int(hi.y),23):
				var at := Vector3(x+rng.randf_range(-6,6),0,z+rng.randf_range(-6,6))
				if not Geometry2D.is_point_in_polygon(Vector2(at.x,at.z),p):continue
				if world._nearest(at).y>90000 or not world.scenery_clear(at,3):continue
				trees.append(Transform3D(Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(1.05,1.7)),at));world.add_tree_collider(at,2.5)
	preload("res://scripts/render/forest.gd").plant_variants(self,trees,"mv_broadleaf",75,0,true,false)
	preload("res://scripts/render/forest.gd").plant_variants(self,trees,"mv_broadleaf_far",320,67,true,true)

func _flush(batch: Dictionary, distance: float) -> void:
	var st: SurfaceTool=batch.st
	var arrays := st.commit_to_arrays()
	if arrays[Mesh.ARRAY_VERTEX]==null or arrays[Mesh.ARRAY_VERTEX].is_empty():return
	st.generate_tangents()
	var node := MeshInstance3D.new();node.mesh=st.commit();node.material_override=batch.material
	node.visibility_range_end=distance;node.visibility_range_end_margin=35;add_child(node)

func _modern_face(a: Vector3,b: Vector3,n: Vector3,h: float,wall: SurfaceTool,windows: SurfaceTool,appearance: Dictionary) -> void:
	var edge := b-a;var along := edge.normalized()
	var bays := maxi(1,int(edge.length()/3.3));var levels: int=appearance.levels
	var spacing := h/levels
	_quad(wall,a+n*0.015,a+Vector3.UP*spacing+n*0.015,b+n*0.015,b+Vector3.UP*spacing+n*0.015,n,Color("b4b9b8"))
	for level in levels:
		for bay in bays:
			var at := a.lerp(b,(float(bay)+0.5)/bays)+Vector3.UP*(spacing*level+1.55)+n*0.045
			var half := minf(0.65,edge.length()/bays*0.28)
			var right := along*half
			# Dark vertical window surround and restrained warm facade panels.
			_quad(wall,at-right*1.16-Vector3.UP*1.12,at-right*1.16+Vector3.UP*1.12,at+right*1.16-Vector3.UP*1.12,at+right*1.16+Vector3.UP*1.12,n,Color("4c5356"))
			_quad(windows,at-right-Vector3.UP*0.94+n*0.015,at-right+Vector3.UP*0.94+n*0.015,at+right-Vector3.UP*0.94+n*0.015,at+right+Vector3.UP*0.94+n*0.015,n,Color.WHITE)
			_quad(wall,at-along*0.025-Vector3.UP*0.96+n*0.022,at-along*0.025+Vector3.UP*0.96+n*0.022,at+along*0.025-Vector3.UP*0.96+n*0.022,at+along*0.025+Vector3.UP*0.96+n*0.022,n,Color("c1c6c4"))
			if level>0 and bay%3==1:
				var center := at+n*0.02+along*(half+0.33)
				_quad(wall,center-along*0.20-Vector3.UP*1.38,center-along*0.20+Vector3.UP*1.36,center+along*0.20-Vector3.UP*1.38,center+along*0.20+Vector3.UP*1.36,n,Color(appearance.accent))
			if level>0 and bay%2==0 and edge.length()>12:
				var floor_at := at-Vector3.UP*1.02;var width := along*1.22;var front := n*1.05
				_quad(wall,floor_at-width,floor_at+width,floor_at-width+front,floor_at+width+front,Vector3.UP,Color("c8ccca"))
				_quad(wall,floor_at-width+front,floor_at-width+front+Vector3.UP*0.84,floor_at+width+front,floor_at+width+front+Vector3.UP*0.84,n,Color("8d999c"))
				for sign_side in [-1,1]:
					var end: Vector3=floor_at+width*sign_side
					_quad(wall,end,end+Vector3.UP*0.84,end+front,end+front+Vector3.UP*0.84,along*sign_side,Color("a3adac"))

func _setback_storey(p: PackedVector2Array,h: float,wall: SurfaceTool,cap: SurfaceTool,appearance: Dictionary) -> void:
	for inset in Geometry2D.offset_polygon(p,-1.45):
		if inset.size()<3:continue
		var top := h+float(appearance.setback_height_m)
		for i in inset.size():
			var a := Vector3(inset[i].x,h,inset[i].y);var b := Vector3(inset[(i+1)%inset.size()].x,h,inset[(i+1)%inset.size()].y)
			var n := Vector3(-(b-a).z,0,(b-a).x).normalized()
			_quad(wall,a,a+Vector3.UP*(top-h),b,b+Vector3.UP*(top-h),n,Color("d5d9d6"))
		for index in Geometry2D.triangulate_polygon(inset):
			cap.set_color(Color("65706e"));cap.set_normal(Vector3.UP);cap.set_uv(inset[index]/2);cap.add_vertex(Vector3(inset[index].x,top,inset[index].y))
