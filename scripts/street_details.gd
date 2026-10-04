extends RefCounted
# Street View supplies visual interpretation; OSM road vertices supply alignment.
# Fine object offsets and dimensions are explicitly assumptions in streetview_reference.json.
var groups := {}
var world: TrackWorld
var parent: Node3D
func material(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=0.8;return m
func cube(at: Vector3,size: Vector3,mat: Material,angle: float=0) -> void:
	var key := mat.get_instance_id()
	if not groups.has(key):groups[key]={"mat":mat,"transforms":[]}
	groups[key].transforms.append(Transform3D(Basis(Vector3.UP,angle).scaled(size),at))
func beam(a: Vector3,b: Vector3,width: float,height: float,mat: Material) -> void:
	cube((a+b)*0.5,Vector3(width,height,a.distance_to(b)),mat,atan2((b-a).x,(b-a).z))
func geo(ll: Array) -> Vector3:return world.geo_to_world(float(ll[0]),float(ll[1]))
func build(owner: Node3D,track_world: TrackWorld,data: Dictionary,reference: Dictionary) -> void:
	parent=owner;world=track_world
	var pave := ShaderMaterial.new();pave.shader=preload("res://assets/shaders/street_paving.gdshader")
	var red_pave := ShaderMaterial.new();red_pave.shader=preload("res://assets/shaders/street_paving.gdshader");red_pave.set_shader_parameter("tint",Color("b28e7e"))
	var curb := material("b3b7b2");var metal := material("657d85");var roof := material("596d71")
	# Only the observed residential sections receive interpreted sidewalk profiles.
	for road in data.roads:
		if str(road.id) not in ["25879792","392265568","32036620"]:continue
		var pts: Array=road.p
		if str(road.id)=="32036620":
			_residential_paths(pts,red_pave,pave,curb)
			continue
		for i in range(pts.size()-1):
			var a := geo(pts[i]);var b := geo(pts[i+1]);var side := Vector3(-(b-a).z,0,(b-a).x).normalized()
			var sides: Array=[1.0] if str(road.id)=="25879792" else [-1.0,1.0]
			for sign_side in sides:
				var residential: bool=str(road.id)=="32036620"
				var curb_offset := 3.0 if residential else 2.4
				var path_offset := 4.35 if residential else 3.05
				beam(a+side*curb_offset*sign_side+Vector3.UP*0.08,b+side*curb_offset*sign_side+Vector3.UP*0.08,0.16,0.16,curb)
				beam(a+side*path_offset*sign_side+Vector3.UP*0.10,b+side*path_offset*sign_side+Vector3.UP*0.10,2.4 if residential else 1.2,0.09,red_pave if residential else pave)
				if residential:
					beam(a+side*3.35*sign_side+Vector3.UP*0.15,b+side*3.35*sign_side+Vector3.UP*0.15,0.22,0.012,pave)
					beam(a+side*5.32*sign_side+Vector3.UP*0.15,b+side*5.32*sign_side+Vector3.UP*0.15,0.22,0.012,pave)
	var details: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/local_details26.json"))
	_rostock_details(data,details,pave,curb,metal,roof)
	var line: Array=reference.details.riekdahler_railing.line
	var a := geo(line[0]);var b := geo(line[1])
	beam(a+Vector3.UP*1.05,b+Vector3.UP*1.05,0.045,0.05,metal)
	beam(a+Vector3.UP*0.23,b+Vector3.UP*0.23,0.035,0.035,metal)
	for i in 20:cube(a.lerp(b,float(i)/19.0)+Vector3.UP*0.64,Vector3(0.035,0.84,0.035),metal)
	# A compact blue-grey shelter; panes intentionally omitted to avoid transparent overdraw.
	var shelter: Dictionary=reference.details.neuendorf_shelter
	var at := geo(shelter.at);var angle := deg_to_rad(float(shelter.heading_degrees))+world.metric_rotation
	var basis := Basis(Vector3.UP,angle)
	for x in [-1.4,1.4]:
		for z in [-0.6,0.6]:cube(at+basis*Vector3(x,1.12,z),Vector3(0.065,2.24,0.065),metal,angle)
	cube(at+Vector3.UP*2.30,Vector3(3.1,0.12,1.55),roof,angle)
	cube(at+Vector3.UP*0.48,Vector3(2.3,0.12,0.36),roof,angle)
	for group in groups.values():
		var mm := MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=BoxMesh.new();mm.mesh.size=Vector3.ONE
		mm.instance_count=group.transforms.size()
		for i in mm.instance_count:mm.set_instance_transform(i,group.transforms[i])
		var node := MultiMeshInstance3D.new();node.name="StreetReferenceDetails"+str(group.mat.get_instance_id());node.multimesh=mm;node.material_override=group.mat
		node.visibility_range_end=170;node.visibility_range_end_margin=20;parent.add_child(node)

func _rostock_details(data: Dictionary,config: Dictionary,pave: Material,curb: Material,metal: Material,roof: Material) -> void:
	var bus: Dictionary=config.rostock_bus_stop
	for road in data.roads:
		if str(road.id)!=str(bus.road_id):continue
		var start := geo(road.p[0]);var finish := geo(road.p[-1]);var along := (finish-start).normalized();var side := Vector3(-along.z,0,along.x)*float(bus.sidewalk_side)
		var angle := atan2(along.x,along.z)
		for i in range(1,7):
			var at := start.lerp(finish,float(i)/7.0)+side*5.9
			cube(at+Vector3.UP*2.9,Vector3(0.08,5.8,0.08),metal)
			cube(at+Vector3.UP*5.8,Vector3(0.68,0.10,0.68),roof,angle)
		var anchor := geo(bus.stop_position)+side*4.4
		for x in [-1.3,1.3]:
			for z in [-0.5,0.5]:cube(anchor+along*x+side*z+Vector3.UP*1.1,Vector3(0.06,2.2,0.06),metal)
		cube(anchor+Vector3.UP*2.24,Vector3(1.4,0.12,3.0),roof,angle)
		cube(anchor+Vector3.UP*0.50,Vector3(0.36,0.10,2.0),metal,angle)
		cube(anchor+side*0.56+Vector3.UP*1.2,Vector3(0.03,1.8,2.5),material("667a82"),angle)
		cube(anchor+along*2.0+Vector3.UP*0.58,Vector3(0.30,1.16,0.30),material("d46e28"))
		# Broken centre markings follow OSM segments, never span the original junction kink.
		var white := material("deded1")
		for index in range(road.p.size()-1):
			var a := geo(road.p[index]);var b := geo(road.p[index+1]);var delta := b-a;var length := delta.length()
			for station in range(0,int(length)-2,9):
				beam(a+delta.normalized()*station+Vector3.UP*0.048,a+delta.normalized()*(station+2.5)+Vector3.UP*0.048,0.10,0.005,white)

func _residential_paths(points: Array,red: Material,grey: Material,curb: Material) -> void:
	for side in [-1.0,1.0]:
		for band in [[3.12,5.55,red,0.13],[3.20,3.42,grey,0.139],[5.20,5.42,grey,0.139],[2.95,3.11,curb,0.15]]:
			var pairs: Array=[]
			for i in points.size():
				var at := geo(points[i]);var before := (at-geo(points[maxi(0,i-1)])).normalized();var after := (geo(points[mini(points.size()-1,i+1)])-at).normalized()
				if before.length_squared()<0.01:before=after
				if after.length_squared()<0.01:after=before
				var a := Vector3(-before.z,0,before.x);var b := Vector3(-after.z,0,after.x)
				var n := (a+b).normalized()/maxf(0.65,(a+b).normalized().dot(b))
				pairs.append([at+n*float(band[0])*side+Vector3.UP*float(band[3]),at+n*float(band[1])*side+Vector3.UP*float(band[3])])
			var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in pairs.size()-1:
				for v in [pairs[i][0],pairs[i][1],pairs[i+1][0],pairs[i][1],pairs[i+1][1],pairs[i+1][0]]:st.set_normal(Vector3.UP);st.add_vertex(v)
			var node := MeshInstance3D.new();node.name="ContinuousResidentialPath";node.mesh=st.commit();node.material_override=band[2];node.visibility_range_end=350;parent.add_child(node)
