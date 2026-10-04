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

func _building(data: Dictionary) -> void:
	var p := _polygon(data.p)
	if p.size()<3:return
	world.register_mapped_building(p);footprint_reference[str(data.id)]=p
	var mid := Vector2.ZERO
	for v in p:mid+=v
	mid/=float(p.size())
	var center := Vector3(mid.x,0,mid.y)
	var roof_points := roof_outline(p)
	var roof_kind: String=data.tags.get("roof:shape",data.roof)
	if roof_kind=="half-hipped":roof_kind="hipped"
	var h := clampf(float(data.h),2.4,40)
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
	var facade_shader := Shader.new()
	facade_shader.code="""shader_type spatial; render_mode cull_disabled;
void fragment(){
 vec2 p=UV*vec2(12.0,18.0);p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 edge=min(fract(p),1.0-fract(p));vec2 aa=fwidth(p);
 float joint=smoothstep(0.018-aa.x,0.04+aa.x,edge.x)*smoothstep(0.018-aa.y,0.04+aa.y,edge.y);
 float brick=step(COLOR.g,COLOR.r*0.78);
 float variation=fract(sin(dot(floor(p),vec2(17.4,71.3)))*17471.13);
 ALBEDO=COLOR.rgb*mix(0.97,0.80+joint*0.20,brick)*(0.96+variation*0.04);ROUGHNESS=0.9;
}"""
	var facade := ShaderMaterial.new();facade.shader=facade_shader;wall_material=facade
	var roof := StandardMaterial3D.new();roof.vertex_color_use_as_albedo=true;roof.roughness=0.88;roof.cull_mode=BaseMaterial3D.CULL_DISABLED;roof_material=roof
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
		var mat: Material=world._textured_material("res://assets/nature/forrest_ground_01_diff.jpg",tint)
		_ground(p,mat,-0.06)
	# Local connecting streets, including the bend, driveway junctions and farm access roads.
	var paved: Material=world._textured_material("res://assets/textures/asphalt_v10.png",Color("929b98"))
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
	var water: Material=world._material(Color("3d6572"),0.24)
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
