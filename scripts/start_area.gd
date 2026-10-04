extends Node3D
# Actual OSM footprints; facade details and landscaping interpreted from reference photos.
var world: Node3D
var plaster: StandardMaterial3D
var glass: StandardMaterial3D
var stone: ShaderMaterial
var red_roof: ShaderMaterial
var metal: StandardMaterial3D
var material_cache := {}

func mat(color: String, roughness: float = 0.8) -> StandardMaterial3D:
	var key := color+str(roughness)
	if material_cache.has(key): return material_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=Color(color); m.roughness=roughness
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	material_cache[key]=m
	return m

func tile_material(color: Color, size: Vector2, brick: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code="""shader_type spatial;
uniform vec4 tint : source_color;
uniform vec2 tile_size;
uniform bool stagger;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=wp.xz/tile_size;
 if(stagger){p.x+=mod(floor(p.y),2.0)*0.5;}
 vec2 f=fract(p);
 vec2 aa=fwidth(p)*1.5;
 float joint=smoothstep(0.01-aa.x,0.035+aa.x,f.x)*smoothstep(0.01-aa.y,0.035+aa.y,f.y);
 float n=fract(sin(dot(floor(p),vec2(12.9898,78.233)))*43758.5453);
 ALBEDO=tint.rgb*(0.93+n*0.07)*mix(0.75,1.0,joint);
 ROUGHNESS=0.90;
} """
	var m := ShaderMaterial.new(); m.shader=shader
	m.set_shader_parameter("tint",color); m.set_shader_parameter("tile_size",size); m.set_shader_parameter("stagger",brick)
	return m

func box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new(); var shape := BoxMesh.new(); shape.size=size
	mesh.mesh=shape; mesh.position=at; mesh.material_override=material; parent.add_child(mesh)
	return mesh

func line(a: Vector3,b: Vector3,width: float,height: float,material: Material) -> void:
	var length := a.distance_to(b)
	var m := box(self,(a+b)*0.5,Vector3(width,height,length),material)
	m.rotation.y=atan2(a.x-b.x,a.z-b.z)

func geo(ll: Array, height: float = 0.0) -> Vector3:
	return world.geo_to_world(float(ll[0]),float(ll[1]))+Vector3.UP*height

func polygon(points: PackedVector2Array,height: float,material: Material) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in Geometry2D.triangulate_polygon(points):
		st.set_normal(Vector3.UP); st.add_vertex(Vector3(points[i].x,height,points[i].y))
	var m := MeshInstance3D.new(); m.mesh=st.commit(); m.material_override=material; add_child(m)

func building(data: Dictionary) -> void:
	var points := PackedVector2Array()
	var center := Vector3.ZERO
	for ll in data.p:
		var p := geo(ll); points.append(Vector2(p.x,p.z)); center+=p
	if points[0].is_equal_approx(points[-1]): points.remove_at(points.size()-1)
	center/=float(data.p.size())
	var height := float(data.h)
	var root := Node3D.new(); add_child(root)
	var wall := SurfaceTool.new(); wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size():
		var a := Vector3(points[i].x,0,points[i].y)
		var j := (i+1)%points.size(); var b := Vector3(points[j].x,0,points[j].y)
		var edge := b-a; var normal := Vector3(-edge.z,0,edge.x).normalized()
		for v in [a,a+Vector3.UP*height,b,b,a+Vector3.UP*height,b+Vector3.UP*height]:
			wall.set_normal(normal); wall.add_vertex(v)
		var bay_count := int(edge.length()/3.2)
		var levels := 3 if data.kind=="hotel" else 1 if data.kind=="tourist" else 2
		for floor_id in levels:
			for bay in bay_count:
				var at := a.lerp(b,(float(bay)+0.5)/maxf(bay_count,1))+Vector3.UP*(1.8+floor_id*3.15)+normal*0.04
				var frame := box(root,at,Vector3(1.28,1.88,0.12),mat("d8d6ce"))
				frame.rotation.y=atan2(normal.x,normal.z)
				var win := box(root,at+normal*0.08,Vector3(1.02,1.60,0.06),glass); win.rotation.y=frame.rotation.y
				var mullion := box(root,at+normal*0.12,Vector3(0.065,1.60,0.045),plaster); mullion.rotation.y=frame.rotation.y
				var sill := box(root,at+normal*0.14-Vector3.UP*0.85,Vector3(1.40,0.10,0.28),plaster); sill.rotation.y=frame.rotation.y
		line(a+Vector3.UP*0.22,b+Vector3.UP*0.22,0.16,0.44,mat("9c9c93"))
		line(a+Vector3.UP*(height-0.15),b+Vector3.UP*(height-0.15),0.28,0.24,plaster)
	var walls := MeshInstance3D.new(); walls.mesh=wall.commit(); walls.material_override=plaster; root.add_child(walls)
	walls.create_trimesh_collision()
	if data.kind=="tourist":
		polygon(points,height+0.12,mat("c0c2ba"))
		var sign := Label3D.new(); sign.text="TOURIST i"; sign.font_size=64; sign.pixel_size=0.028
		sign.modulate=Color("324452"); sign.position=center+Vector3(0,height-0.6,0)
		sign.rotation.y=world.metric_rotation+PI*0.5; root.add_child(sign)
	else:
		var roof := SurfaceTool.new(); roof.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Pitched roof faces follow the building footprint, rather than a generic city box.
		var peak := center+Vector3.UP*(height+3.0)
		for i in points.size():
			var j := (i+1)%points.size()
			var a := Vector3(points[i].x,height,points[i].y); var b := Vector3(points[j].x,height,points[j].y)
			var inner_a := a.lerp(peak,0.72); var inner_b := b.lerp(peak,0.72)
			inner_a.y=peak.y; inner_b.y=peak.y
			for v in [a,b,inner_a,b,inner_b,inner_a]:roof.add_vertex(v)
		roof.generate_normals(); var mesh := MeshInstance3D.new(); mesh.mesh=roof.commit(); mesh.material_override=red_roof; root.add_child(mesh)
		if data.kind=="hotel":
			var label := Label3D.new(); label.text="SEEHOTEL"; label.font_size=64; label.pixel_size=0.025
			label.position=center+Vector3(0,8.8,0); label.rotation.y=world.metric_rotation+PI*0.5; label.modulate=Color("5b655f"); root.add_child(label)

func configure(track_world: Node3D) -> void:
	world=track_world
	plaster=mat("ece7dc"); glass=mat("263f4b",0.20); glass.metallic=0.4
	metal=mat("8d9899",0.38)
	stone=tile_material(Color("b3afa0"),Vector2(0.24,0.18),true)
	red_roof=tile_material(Color("9e4931"),Vector2(0.30,0.21),true)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/start_area.json"))
	for b in data.buildings:building(b)
	# Seestraße terminus and the original paved roundabout.
	var circle := PackedVector2Array(); var island := PackedVector2Array()
	var round_center: Vector3= world.geo_to_world(51.575193,14.009919)
	for i in 64:
		var angle := float(i)*TAU/64.0
		circle.append(Vector2(round_center.x,round_center.z)+Vector2(cos(angle),sin(angle))*14.0)
		island.append(Vector2(round_center.x,round_center.z)+Vector2(cos(angle),sin(angle))*6.2)
	polygon(circle,0.06,world._textured_material("res://assets/textures/asphalt_v10.png",Color.WHITE))
	polygon(island,0.13,stone)
	var plaza: Vector3= world.geo_to_world(51.57512,14.01014)
	var paved := box(self,plaza+Vector3(0,0.025,0),Vector3(37,0.045,48),stone); paved.rotation.y=world.metric_rotation
	for i in 12:
		var point: Vector3=world.geo_to_world(51.57502+float(i)*0.000032,14.01036)
		box(self,point+Vector3.UP*0.45,Vector3(0.30,0.9,0.30),mat("777c7b"))
	for pier in data.piers:
		for i in range(pier.size()-1):
			var a := geo(pier[i],-5.70); var b := geo(pier[i+1],-5.70)
			if a.distance_to(b)>30: a.y=0.17; b.y=0.17
			line(a,b,2.0 if a.distance_to(b)>30 else 0.9,0.20,mat("afa68b"))
			if a.distance_to(b)>30:
				line(a+Vector3(0.9,0.85,0),b+Vector3(0.9,0.85,0),0.05,0.05,metal)
	# Promenade rails, lamps and terraced retaining walls along the northern shore.
	for i in 18:
		var a: Vector3=world.geo_to_world(51.57433,14.0084+i*0.00013)
		var b: Vector3=world.geo_to_world(51.57433,14.0084+(i+1)*0.00013)
		line(a+Vector3.UP*0.9,b+Vector3.UP*0.9,0.045,0.05,metal)
		box(self,a+Vector3.UP*0.45,Vector3(0.06,0.9,0.06),metal)
	for ll in [[51.57535,14.01032],[51.57502,14.0097],[51.57565,14.00969],[51.5760,14.00972]]:
		var p := geo(ll)
		box(self,p+Vector3.UP*3.1,Vector3(0.10,6.2,0.10),metal)
		box(self,p+Vector3.UP*6.2,Vector3(0.7,0.16,0.4),mat("c3c8bc"))
	_landscaping()
	_batch_details()

func _batch_details() -> void:
	var groups := {}
	for node in find_children("*","MeshInstance3D",true,false):
		if not node.mesh is BoxMesh: continue
		var key: int=node.material_override.get_instance_id()
		if not groups.has(key):groups[key]={"material":node.material_override,"transforms":[]}
		var t: Transform3D=global_transform.affine_inverse()*node.global_transform
		t.basis=t.basis.scaled(node.mesh.size)
		groups[key].transforms.append(t)
		node.queue_free()
	for group in groups.values():
		var mm := MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=BoxMesh.new(); mm.mesh.size=Vector3.ONE
		mm.instance_count=group.transforms.size()
		for i in mm.instance_count:mm.set_instance_transform(i,group.transforms[i])
		var m := MultiMeshInstance3D.new();m.multimesh=mm;m.material_override=group.material;add_child(m)

func _landscaping() -> void:
	# Photo-matched dormers on the long main hotel wing, facing Seestraße.
	for i in 7:
		var p: Vector3=world.geo_to_world(51.57581+i*0.000064,14.00936)
		var root := Node3D.new(); root.position=p; root.rotation.y=world.metric_rotation;add_child(root)
		box(root,Vector3(0,11.8,0),Vector3(2.0,1.8,1.7),plaster)
		box(root,Vector3(1.02,11.8,0),Vector3(0.05,1.25,1.05),glass)
		var cap := box(root,Vector3(0,12.75,0),Vector3(2.4,0.14,2.05),mat("874c3b"));cap.rotation.z=0.10
	var trees: Array[Transform3D]=[]
	for ll in [[51.57575,14.00902],[51.57566,14.009],[51.57555,14.00907],[51.57543,14.00895],[51.57634,14.00912],[51.57642,14.00934],[51.57618,14.00975],[51.57587,14.00970],[51.57574,14.00968],[51.57495,14.0105],[51.57505,14.01048],[51.57518,14.01055]]:
		var p := geo(ll)
		trees.append(Transform3D(Basis().scaled(Vector3(9,12,1)),p+Vector3.UP*6))
		world.add_tree_collider(p,3.0)
	var card := QuadMesh.new();card.size=Vector2.ONE
	world._multimesh(card,world._tree_material("res://assets/textures/oak_v10.png"),trees)
	for ll in [[51.57554,14.00970],[51.57566,14.00970],[51.57580,14.00970]]:_palm(geo(ll))

func _palm(at: Vector3) -> void:
	var root := Node3D.new();root.position=at;add_child(root)
	var pot := MeshInstance3D.new();var cylinder := CylinderMesh.new()
	cylinder.top_radius=0.65;cylinder.bottom_radius=0.44;cylinder.height=0.85;cylinder.radial_segments=20
	pot.mesh=cylinder;pot.material_override=mat("b58b58");pot.position.y=0.43;root.add_child(pot)
	var trunk := MeshInstance3D.new();var stem := CylinderMesh.new()
	stem.top_radius=0.13;stem.bottom_radius=0.25;stem.height=2.7;stem.radial_segments=12
	trunk.mesh=stem;trunk.material_override=mat("79634a");trunk.position.y=2.0;root.add_child(trunk)
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 14:
		var a := i*TAU/14.0;var direction := Vector3(cos(a),0,sin(a));var side := Vector3(-sin(a),0,cos(a))
		for j in 5:
			var t := float(j)/5.0;var u := float(j+1)/5.0
			var p := direction*t*2.0+Vector3.UP*(3.45+sin(t*PI)*0.7-t*0.9)
			var q := direction*u*2.0+Vector3.UP*(3.45+sin(u*PI)*0.7-u*0.9)
			var w := sin(t*PI)*0.24;var v := sin(u*PI)*0.24
			for vertex in [p-side*w,q-side*v,p+side*w,p+side*w,q-side*v,q+side*v]:st.add_vertex(vertex)
	st.generate_normals();var leaves := MeshInstance3D.new();leaves.mesh=st.commit();leaves.material_override=mat("53754a");root.add_child(leaves)
