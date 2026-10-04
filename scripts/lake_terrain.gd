extends RefCounted
const Extension=preload("res://addons/terrain_3d/terrain.gdextension")
# Terrain3D adapter. Heights are photo-interpreted, not surveyed DEM.
static func build(parent: Node3D) -> Node3D:
	if not ClassDB.class_exists("Terrain3D"):return null
	var terrain: Node3D=ClassDB.instantiate("Terrain3D")
	terrain.name="LakeTerrain3D";terrain.set("vertex_spacing",8.0);terrain.set("free_editor_textures",false)
	terrain.set("collision_mode",0);terrain.set("mesh_lods",6);terrain.set("mesh_size",32)
	var assets: Resource=ClassDB.instantiate("Terrain3DAssets")
	var grass: Resource=ClassDB.instantiate("Terrain3DTextureAsset")
	grass.set("id",0);grass.set("name","Lausitz grass")
	grass.set("albedo_texture",atlas_tile(4))
	grass.set("normal_texture",texture("res://assets/nature/forrest_ground_01_nor_gl.jpg"))
	grass.set("albedo_color",Color(0.84,0.88,0.79));grass.set("roughness",0.8);grass.set("uv_scale",0.8)
	assets.call("set_texture",0,grass)
	var soil: Resource=ClassDB.instantiate("Terrain3DTextureAsset")
	soil.set("id",1);soil.set("name","Lausitz gravel bank");soil.set("albedo_texture",atlas_tile(3))
	soil.set("normal_texture",texture("res://assets/nature/gravel_floor_nor_gl.jpg"));soil.set("roughness",0.9);soil.set("uv_scale",0.25)
	assets.call("set_texture",1,soil);terrain.set("assets",assets)
	var camera: Camera3D=parent.get_viewport().get_camera_3d()
	if camera!=null:terrain.call("set_camera",camera)
	parent.add_child(terrain)
	terrain.call("change_region_size",512)
	var height := Image.create_from_data(1024,1024,false,Image.FORMAT_RF,FileAccess.get_file_as_bytes("res://assets/data/lake_terrain3d.bin"))
	var control := shore_control(height)
	var images: Array[Image]=[height,control,null]
	terrain.get("data").call("import_images",images,Vector3(-4096,0,-4096),0.0,1.0)
	print("TERRAIN: size ",terrain.get("region_size")," regions ",terrain.get("data").call("get_region_count"))
	return terrain

static func texture(path: String) -> ImageTexture:
	var image: Image=load(path).get_image()
	image.resize(1024,1024,Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func atlas_tile(index: int) -> ImageTexture:
	var atlas: Image=load("res://assets/textures/material_atlas25.png").get_image()
	var w := atlas.get_width()/3;var h := atlas.get_height()/2
	var image := atlas.get_region(Rect2i((index%3)*w,(index/3)*h,w,h))
	image.resize(1024,1024,Image.INTERPOLATE_LANCZOS);image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func shore_control(height: Image) -> Image:
	# Terrain3D 1.0.1 control: base bits 27..31, overlay 22..26, blend 14..21.
	# Sand between -5.9 and -5.0 m is an artistic shore band, not surveyed substrate.
	var source := height.get_data();var encoded := PackedByteArray();encoded.resize(source.size())
	for pixel in height.get_width()*height.get_height():
		var h := source.decode_float(pixel*4)
		var amount := clampf((-4.8-h)/1.1,0,1)
		var value := (1<<22)|(int(round(amount*255))<<14)
		encoded.encode_u32(pixel*4,value)
	return Image.create_from_data(height.get_width(),height.get_height(),false,Image.FORMAT_RF,encoded)
