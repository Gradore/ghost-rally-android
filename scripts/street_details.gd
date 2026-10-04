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
	var curb := material("b3b7b2");var metal := material("657d85");var roof := material("596d71")
	# Only the observed residential sections receive interpreted sidewalk profiles.
	for road in data.roads:
		if str(road.id) not in ["25879792","392265568"]:continue
		var pts: Array=road.p
		for i in range(pts.size()-1):
			var a := geo(pts[i]);var b := geo(pts[i+1]);var side := Vector3(-(b-a).z,0,(b-a).x).normalized()
			var sides: Array=[1.0] if str(road.id)=="25879792" else [-1.0,1.0]
			for sign_side in sides:
				beam(a+side*2.4*sign_side+Vector3.UP*0.08,b+side*2.4*sign_side+Vector3.UP*0.08,0.16,0.16,curb)
				beam(a+side*3.05*sign_side+Vector3.UP*0.10,b+side*3.05*sign_side+Vector3.UP*0.10,1.2,0.09,pave)
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
