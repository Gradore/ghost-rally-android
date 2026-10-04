extends Node3D

const Data = preload("res://scripts/game_data.gd")
const Car = preload("res://scripts/rally_car.gd")
const World = preload("res://scripts/track_world.gd")
const GermanyMapScene = preload("res://scripts/germany_map.gd")
const MinimapScene = preload("res://scripts/race_minimap.gd")

var save: Dictionary
var state := "home"
var active_track := 0
var active_wp := 0
var mobile_steering=preload("res://scripts/input/mobile_steering.gd").new()
var touch_anchor := {}
var engine_layers: Array[AudioStreamPlayer]=[]
var tilt_zero := 0.0
var built_world_key := ""
var showroom: Node3D
var settings_return := "home"
var settings_tab := 0
var active_car := 0
var world: TrackWorld
var car: RallyCar
var ghost_car: RallyCar
var camera: Camera3D
var sky: WorldEnvironment
var sun: DirectionalLight3D
var ui_layer: CanvasLayer
var ui: Control
var top_bar: Control
var timer_label: Label
var sector_label: Label
var speed_label: Label
var gear_label: Label
var nav_label: Label
var progress_bar: ProgressBar
var countdown_label: Label
var control_panel: Control
var minimap
var minimap_label: Label
var touch: Dictionary = {}
var steer := 0.0
var steering_input := 0.0
var throttle := 0.0
var brake := 0.0
var handbrake := false
var velocity := Vector2.ZERO
var reverse_engaged := false
var yaw := 0.0
var dynamics := preload("res://scripts/vehicle_dynamics.gd").new()
var speed := 0.0
var race_time := 0.0
var countdown := 3.0
var checkpoint := 0
var sector_times: Array[float] = []
var replay_index := 0
var ghost_frames: Array = []
var replay_frames: Array = []
var sample_clock := 0.0
var result_new_pb := false
var previous_best := 0.0
var previous_sector_times: Array = []
var camera_target := Vector3.ZERO
var lateral_slip := 0.0
var selected_ghost := true
var event_daily := false
var race_progress := 0.0
var map_control: Control
var map_side: Panel
var setup_step := 0
var font_regular: Font = preload("res://assets/fonts/Rajdhani-Medium.ttf")
var font_bold: Font = preload("res://assets/fonts/Rajdhani-Bold.ttf")
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var tire_phase := 0.0
var audio_rpm := 1600.0
var audio_noise := 0.0
var audio_seed := 192857
var camera_mode := 0
var impact_label: Label
var camera_button: Button
var cockpit_panel: Control
var impact_timer := 0.0
var impact_cooldown := 0.0
var crash_energy := 0.0
var collision_count := 0

func _ready() -> void:
	load_save()
	active_track = int(save.selected_track)
	active_car = int(save.selected_car)
	tilt_zero=float(save.get("tilt_neutral",0.0))
	build_scene()
	build_audio()
	build_ui()
	show_home()

func load_save() -> void:
	save = Data.default_save()
	if FileAccess.file_exists("user://save.json"):
		var f := FileAccess.open("user://save.json",FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in parsed: save[k] = parsed[k]
	var defaults: Dictionary = Data.default_save()
	if not save.has("save_version"):
		var old_car := clampi(int(save.selected_car),0,2)
		save.selected_car=[0,3,6][old_car]
		save.save_version=3
	for key in ["setup","upgrades","livery","mastery"]:
		if not save.has(key) or not (save[key] is Array): save[key]=[]
		while save[key].size()<Data.CARS.size():
			save[key].append(defaults[key][save[key].size()])
	if not save.has("rc"): save.rc=300
	save.selected_car=clampi(int(save.selected_car),0,Data.CARS.size()-1)
	save.selected_track=clampi(int(save.selected_track),0,Data.TRACKS.size()-1)
	for key in ["best","best_sectors"]:
		if not save[key] is Dictionary:save[key]={}
	for i in Data.CARS.size():
		if not save.setup[i] is Dictionary:save.setup[i]=defaults.setup[i].duplicate()
		if not save.upgrades[i] is Dictionary:save.upgrades[i]=defaults.upgrades[i].duplicate()
	save.sensitivity=clampf(float(save.sensitivity),0.35,1.65)

func write_save() -> void:
	var f := FileAccess.open("user://save.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(save))

func ghost_path() -> String:
	return "user://ghost_%d_%d_wp%d.bin" % [active_track,active_car,active_wp if active_track==3 else -1]

func load_ghost() -> void:
	replay_frames.clear()
	replay_index=0
	if not selected_ghost or not FileAccess.file_exists(ghost_path()): return
	var f := FileAccess.open_compressed(ghost_path(),FileAccess.READ,FileAccess.COMPRESSION_DEFLATE)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary and parsed.get("physics_version","") == Data.PHYSICS_VERSION and int(parsed.get("physics_hz",0))==dynamics.tick_hz and parsed.get("frames",[]) is Array:
			var frames: Array=parsed.frames
			var last_time := -1.0
			for frame in frames:
				if not frame is Array or frame.size()<8:return
				for value in frame:
					if not (value is float or value is int) or not is_finite(float(value)):return
				if float(frame[0])<=last_time:return
				last_time=float(frame[0])
			replay_frames = frames

func save_ghost() -> void:
	var f := FileAccess.open_compressed(ghost_path(),FileAccess.WRITE,FileAccess.COMPRESSION_DEFLATE)
	if f:
		f.store_string(JSON.stringify({"physics_version":Data.PHYSICS_VERSION,"physics_hz":dynamics.tick_hz,"track":active_track,"car":active_car,"time":race_time,"sample_hz":10,"frames":ghost_frames}))

func build_scene() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var atmosphere := Sky.new()
	var sky_colors := ProceduralSkyMaterial.new()
	sky_colors.sky_top_color=Color("2876ba")
	sky_colors.sky_horizon_color=Color("c3d6df")
	sky_colors.ground_bottom_color=Color("344f49")
	sky_colors.ground_horizon_color=Color("82988c")
	var cloud_sky := ShaderMaterial.new()
	cloud_sky.shader=load("res://assets/shaders/day_sky.gdshader")
	atmosphere.sky_material=cloud_sky
	atmosphere.radiance_size=Sky.RADIANCE_SIZE_128
	environment.sky=atmosphere
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9bb7b2")
	environment.ambient_light_energy = 0.50
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_density = 0.0016
	environment.fog_sky_affect = 0.08
	environment.fog_light_color = Color("b1b8af")
	sky = WorldEnvironment.new()
	sky.environment = environment
	add_child(sky)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-22,35,0)
	cloud_sky.set_shader_parameter("sun_direction",sun.transform.basis.z)
	sun.light_color = Color("ffdfb2")
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	sun.shadow_opacity=0.78
	sun.directional_shadow_max_distance = 70
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits=true
	add_child(sun)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 62
	add_child(camera)

func build_audio() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.22
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = generator
	audio_player.volume_db = -8.0
	add_child(audio_player)
	if DisplayServer.get_name()!="headless":
		audio_player.play()
		audio_playback = audio_player.get_stream_playback()
	var recording: AudioStreamWAV=load("res://assets/audio/recorded_engine.wav")
	recording.loop_mode=AudioStreamWAV.LOOP_FORWARD;recording.loop_begin=0
	recording.loop_end=int(recording.get_length()*recording.mix_rate)
	var recorded := AudioStreamPlayer.new();recorded.stream=recording;recorded.volume_db=-14
	add_child(recorded)
	if DisplayServer.get_name()!="headless":recorded.play()
	engine_layers.append(recorded)

func _process(delta: float) -> void:
	if not audio_playback: return
	var frame_count := audio_playback.get_frames_available()
	var target_rpm: float=dynamics.rpm
	audio_rpm=lerpf(audio_rpm,target_rpm,clampf(delta*7.5,0,1))
	crash_energy=maxf(0.0,crash_energy-delta*2.8)
	for layer in engine_layers:
		var target_pitch := clampf(audio_rpm/1800.0,0.50,3.6)
		layer.pitch_scale=lerpf(layer.pitch_scale,target_pitch,1-exp(-delta*12))
		var db := -14.0+throttle*6.0 if state=="race" else -24.0 if state=="garage" else -60.0
		layer.volume_db=lerpf(layer.volume_db,db,1-exp(-delta*10))
	var engine_hz := audio_rpm/30.0
	var engine_load := 0.33+throttle*0.25 if state=="race" else 0.0
	var offroad := state=="race" and is_instance_valid(world) and is_instance_valid(car) and absf(world.lateral_offset(car.position))>world.road_width_at(race_progress)*0.5
	var gravel: bool=state=="race" and is_instance_valid(world) and world.gravel_at(race_progress)
	var tire_level := clampf((absf(lateral_slip)-3.0)/14.0,0.0,0.22) if state=="race" else 0.0
	for i in frame_count:
		audio_phase = fposmod(audio_phase+engine_hz/22050.0,1.0)
		tire_phase=fposmod(tire_phase+(1160.0+speed*12.0)/22050.0,1.0)
		audio_seed=(audio_seed*1664525+1013904223)&0x7fffffff
		var noise := float(audio_seed&65535)/32768.0-1.0
		audio_noise=lerpf(audio_noise,noise,0.18)
		var exhaust := sin(audio_phase*TAU)+sin(audio_phase*TAU*2.0)*0.42+sin(audio_phase*TAU*3.0)*0.17
		var rumble := sin(audio_phase*PI)*0.19
		var road_hiss := (noise-audio_noise)*(0.018+speed*0.0015)
		if gravel: road_hiss+=audio_noise*(0.035+speed*0.0024)
		if offroad: road_hiss+=noise*0.075
		var skid := sin(tire_phase*TAU)*tire_level
		var sample := clampf((exhaust+rumble)*engine_load*(0.0 if not engine_layers.is_empty() else 0.42)+road_hiss+skid+noise*crash_energy*0.28,-0.95,0.95)
		audio_playback.push_frame(Vector2(sample,sample) if state=="race" else Vector2.ZERO)

func build_world() -> void:
	sun.light_energy=1.18
	built_world_key="%d:%d:%d" % [active_track,active_wp,active_car]
	if is_instance_valid(showroom): showroom.visible=false
	apply_graphics()
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	if is_instance_valid(car): car.queue_free()
	if is_instance_valid(ghost_car): ghost_car.queue_free()
	world = World.new()
	add_child(world)
	var stage: Dictionary=Data.TRACKS[active_track].duplicate()
	if active_track==3:stage.wp_index=active_wp
	world.build(stage)
	car = Car.new()
	add_child(car)
	car.configure(Data.CARS[active_car],false,int(save.livery[active_car]))
	car.position = world.center_at(4.0)+Vector3(0,0.05,0)
	yaw = world.heading_at(4.0)
	car.rotation.y = yaw
	velocity = Vector2.ZERO
	dynamics.reset()
	mobile_steering.reset()
	ghost_car = Car.new()
	add_child(ghost_car)
	ghost_car.configure(Data.CARS[active_car],true)
	ghost_car.visible = false
	camera_target=car.position
	var back := Vector3(sin(yaw),0,cos(yaw))
	camera.position=car.position+back*31.0+Vector3(0,33,0)
	camera.look_at(car.position-back*16.0,Vector3.UP)

func _panel(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 16) -> StyleBoxFlat:
	var p := StyleBoxFlat.new()
	p.bg_color=bg
	p.border_color=border
	p.set_border_width_all(1 if border.a>0 else 0)
	p.set_corner_radius_all(radius)
	return p

func _label(parent: Control, txt: String, size: int, color: Color, pos: Vector2, dimensions: Vector2, bold: bool = false) -> Label:
	var l := Label.new()
	l.text=txt
	l.position=pos
	l.size=dimensions
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_font_override("font",font_bold if bold else font_regular)
	l.add_theme_color_override("font_color",color)
	if bold: l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.35)); l.add_theme_constant_override("shadow_offset_x",1); l.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(l)
	return l

func _button(parent: Control, txt: String, pos: Vector2, dimensions: Vector2, action: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text=txt
	b.position=pos
	b.size=dimensions
	b.add_theme_font_size_override("font_size",20 if accent else 16)
	b.add_theme_font_override("font",font_bold)
	b.add_theme_color_override("font_color",Color("13292d") if accent else Color("ecf3e9"))
	b.add_theme_color_override("font_hover_color",Color("13292d") if accent else Color.WHITE)
	b.add_theme_stylebox_override("normal",_panel(Color("f6ca50") if accent else Color(0.08,0.16,0.20,0.9),Color("f6ca50") if accent else Color(0.37,0.53,0.55,0.5),10))
	b.add_theme_stylebox_override("hover",_panel(Color("ffdc74") if accent else Color("30505a"),Color("f6ca50") if accent else Color("86b5ae"),10))
	b.add_theme_stylebox_override("pressed",_panel(Color("d9a93b") if accent else Color("24414a"),Color("f6ca50") if accent else Color("86b5ae"),10))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _card(parent: Control, pos: Vector2, dimensions: Vector2, dark: bool = true) -> Panel:
	var p := Panel.new()
	p.position=pos
	p.size=dimensions
	p.add_theme_stylebox_override("panel",_panel(Color(0.035,0.095,0.12,0.94) if dark else Color(0.10,0.20,0.23,0.90),Color(0.35,0.51,0.53,0.35),18))
	parent.add_child(p)
	return p

func build_ui() -> void:
	ui_layer=CanvasLayer.new()
	add_child(ui_layer)
	ui=Control.new()
	ui.size=Vector2(1280,720)
	ui_layer.add_child(ui)
	get_viewport().size_changed.connect(_resize_ui)
	_resize_ui()

func _resize_ui() -> void:
	if is_instance_valid(ui):
		var viewport_size := get_viewport().get_visible_rect().size
		ui.scale=Vector2(viewport_size.x/1280.0,viewport_size.y/720.0)

func clear_ui() -> void:
	for child in ui.get_children():
		if child is CanvasItem: child.hide()
		child.queue_free()

func ensure_race_world() -> void:
	sun.light_energy=1.18
	var key := "%d:%d:%d" % [active_track,active_wp,active_car]
	if not is_instance_valid(world) or not is_instance_valid(car) or built_world_key!=key:
		build_world()
	else:
		world.show();car.show()
		if is_instance_valid(showroom):showroom.hide()
		car.position=world.center_at(4)+Vector3.UP*0.07
		yaw=world.heading_at(4);car.rotation.y=yaw
		velocity=Vector2.ZERO;dynamics.reset();mobile_steering.reset()
	apply_graphics()

func display_showroom() -> void:
	if is_instance_valid(world): world.hide()
	if is_instance_valid(car): car.hide()
	if is_instance_valid(ghost_car): ghost_car.hide()
	if not is_instance_valid(showroom):
		showroom=preload("res://scripts/garage_world.gd").new()
		add_child(showroom)
	showroom.show()
	sun.light_energy=0.18
	showroom.select_car(Data.CARS[active_car],int(save.livery[active_car]))
	camera.position=Vector3(5.6,2.35,5.6)
	camera.look_at(Vector3(1.25,0.85,0),Vector3.UP)
	camera.fov=48
	apply_graphics()

func apply_graphics() -> void:
	var economy: bool=save.get("graphics","balanced")=="economy"
	var detail: bool=save.get("graphics","balanced")=="detail"
	var in_showroom := is_instance_valid(showroom) and showroom.visible
	get_viewport().scaling_3d_scale=1.0 if in_showroom or detail else 0.65 if economy else 0.80
	get_viewport().msaa_3d=Viewport.MSAA_2X if in_showroom or detail else Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if not economy and not in_showroom and not detail else Viewport.SCREEN_SPACE_AA_DISABLED
	sun.shadow_enabled=not economy
	if OS.has_feature("android"): dynamics.set_tick_hz(240)

func show_home() -> void:
	state="home"
	touch.clear();touch_anchor.clear()
	event_daily=false
	clear_ui()
	display_showroom()
	_label(ui,"GHOST RALLY",43,Color.WHITE,Vector2(38,22),Vector2(650,58),true)
	_label(ui,"MEINE GARAGE   /   %d RC   /   LEVEL %d" % [int(save.rc),1+int(save.xp)/400],18,Color("f4c64f"),Vector2(42,80),Vector2(680,30))
	var daily: Dictionary=Data.TRACKS[Data.today_track()]
	var card := _card(ui,Vector2(912,147),Vector2(326,335))
	_label(card,"RALLYE DES TAGES",17,Color("f4c64f"),Vector2(22,19),Vector2(282,30),true)
	_label(card,daily.name,30,Color.WHITE,Vector2(22,61),Vector2(282,90),true)
	_label(card,"%s  ·  %.1f KM" % [daily.place,float(daily.length)/1000],18,Color("aac7c3"),Vector2(22,172),Vector2(282,48))
	_button(card,"TAGESRALLYE  →",Vector2(22,251),Vector2(282,59),func(): active_track=Data.today_track(); event_daily=true; show_pre_race(),true)
	_label(ui,Data.CARS[active_car].name,33,Color.WHITE,Vector2(44,532),Vector2(700,48),true)
	_button(ui,"STRECKENKARTE",Vector2(40,620),Vector2(378,66),func(): show_tracks(),true)
	_button(ui,"GARAGE",Vector2(450,620),Vector2(378,66),func(): show_garage())
	_button(ui,"EINSTELLUNGEN",Vector2(860,620),Vector2(378,66),func(): settings_return="home"; show_settings())

func show_tracks() -> void:
	state="tracks"
	clear_ui()
	var veil := ColorRect.new(); veil.color=Color(0.015,0.05,0.07,0.94); veil.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(veil)
	_label(ui,"DEUTSCHLAND  /  17 RALLY-STRECKEN",42,Color.WHITE,Vector2(48,20),Vector2(1050,59),true)
	_label(ui,"BUNDESLAND WÄHLEN  →  ECHTE OSM-KARTE  →  ZIELPUNKT",16,Color("f4c64f"),Vector2(50,78),Vector2(850,28))
	var map_frame := _card(ui,Vector2(38,119),Vector2(639,546))
	map_control=GermanyMapScene.new()
	map_control.position=Vector2(10,10)
	map_control.size=Vector2(619,526)
	map_frame.add_child(map_control)
	map_control.selected.connect(_on_map_selected)
	map_side=_card(ui,Vector2(703,119),Vector2(540,546))
	_render_map_side(-1)
	_button(ui,"← ZURÜCK",Vector2(48,671),Vector2(172,41),func(): show_home())
	_label(ui,"© BKG 2025 (dl-de/by-2-0) · © OpenStreetMap-Mitwirkende",13,Color("9dbbb7"),Vector2(711,672),Vector2(510,30))

func _on_map_selected(index: int) -> void:
	if index<0 or index>=Data.TRACKS.size(): return
	active_track=index
	save.selected_track=index
	write_save()
	_render_map_side(index)

func _render_map_side(index: int) -> void:
	for child in map_side.get_children(): child.hide(); child.queue_free()
	if index<0:
		_label(map_side,"WÄHLE EIN BUNDESLAND",25,Color.WHITE,Vector2(22,18),Vector2(490,38),true)
		_label(map_side,"Tippe auf die Karte oder wähle aus der Liste.",16,Color("a9c7c2"),Vector2(23,58),Vector2(490,28))
		var labels := ["SH Schleswig-Holstein","HH Hamburg","NI Niedersachsen","HB Bremen","NW Nordrhein-Westfalen","HE Hessen","RP Rheinland-Pfalz","BW Baden-Württemberg","BY Bayern","SL Saarland","BE Berlin","BB Brandenburg","MV Mecklenburg-Vorp.","SN Sachsen","ST Sachsen-Anhalt","TH Thüringen"]
		var codes := ["01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16"]
		for j in labels.size():
			var col := j%2
			var row := int(j/2)
			_button(map_side,labels[j],Vector2(21+col*258,106+row*51),Vector2(246,43),func(code=codes[j]): map_control.choose_code(code))
	else:
		var t: Dictionary=Data.TRACKS[index]
		_label(map_side,"BUNDESLAND  /  %s" % t.state_code,16,Color("f4c64f"),Vector2(27,25),Vector2(475,28),true)
		_label(map_side,t.state,31,Color.WHITE,Vector2(27,61),Vector2(486,52),true)
		_label(map_side,t.name,25,Color("f6ca50"),Vector2(27,144),Vector2(486,38),true)
		_label(map_side,"REGION    %s" % t.place,19,Color("c5d9d3"),Vector2(27,203),Vector2(486,34))
		_label(map_side,"LÄNGE     %.1f KM" % [float(t.length)/1000.0],19,Color("c5d9d3"),Vector2(27,244),Vector2(486,34))
		_label(map_side,"BELAG       %s" % ("ASPHALT / FELDWEGE" if t.surface=="MIXED" else "SCHOTTER" if t.surface=="GRAVEL" else "ASPHALT"),19,Color("c5d9d3"),Vector2(27,285),Vector2(486,34))
		_label(map_side,"ZIEL CA. 7 MIN / WAGENABHÄNGIG",19,Color("c5d9d3"),Vector2(27,326),Vector2(486,34))
		if t.state_code!="13":_label(map_side,"OSM-Straßen und Gebäude auf der Streckenkarte.",15,Color("9bb9b4"),Vector2(27,379),Vector2(486,28))
		_button(map_side,"STRECKE FAHREN  →",Vector2(27,429),Vector2(486,58),func(): event_daily=false; show_pre_race(),true)
		if t.state_code=="13":
			_button(map_side,"MÜRITZ / ROSTOCK WECHSELN",Vector2(27,379),Vector2(486,34),func(): map_control.select_route(7 if active_track==16 else 16))
		_button(map_side,"ANDERES BUNDESLAND",Vector2(27,497),Vector2(486,42),func(): map_control.reset_view(); _render_map_side(-1))

func select_garage_car(direction: int) -> void:
	active_car=posmod(active_car+direction,Data.CARS.size())
	save.selected_car=active_car;write_save();show_garage()

func show_garage() -> void:
	state="garage";clear_ui();display_showroom()
	_label(ui,"GARAGE",43,Color.WHITE,Vector2(125,25),Vector2(550,58),true)
	_label(ui,"FAHRZEUG %02d / %02d" % [active_car+1,Data.CARS.size()],19,Color("f4c64f"),Vector2(128,84),Vector2(500,30))
	_button(ui,"◀",Vector2(40,32),Vector2(68,68),func(): select_garage_car(-1))
	_button(ui,"▶",Vector2(732,32),Vector2(68,68),func(): select_garage_car(1))
	var current: Dictionary=Data.CARS[active_car]
	var card := _card(ui,Vector2(849,32),Vector2(389,570))
	_label(card,"%s  /  KLASSE %s  /  %d RC" % [current.drive,current["class"],int(save.rc)],16,Color("f4c64f"),Vector2(22,18),Vector2(346,28),true)
	_label(card,current.name,34,Color.WHITE,Vector2(22,60),Vector2(346,65),true)
	_label(card,"%d PS   ·   %d KM/H" % [int(current.power),roundi(current.top*3.6)],22,Color.WHITE,Vector2(22,140),Vector2(346,32),true)
	_label(card,"0–100 KM/H: 10,5 S  ·  SERIE" if current.get("voc",false) else "FRONTANTRIEB" if current.drive=="FWD" else "HECKANTRIEB" if current.drive=="RWD" else "ALLRADANTRIEB",18,Color("aac7c3"),Vector2(22,180),Vector2(346,35))
	var levels: Dictionary=save.upgrades[active_car]
	for j in 3:
		var key: String=["engine","handling","brakes"][j]
		var level: int=int(levels[key]);var cost: int=100*(level+1)
		_label(card,["MOTOR","FAHRWERK","BREMSEN"][j]+"  %d/3" % level,17,Color.WHITE,Vector2(22,244+j*55),Vector2(195,28),true)
		if current.get("voc",false):
			_label(card,"SERIENKLASSE",15,Color("f4c64f"),Vector2(226,244+j*55),Vector2(147,28))
		else:_button(card,"MAX" if level>=3 else "%d RC +" % cost,Vector2(225,236+j*55),Vector2(142,43),func(k=key): buy_upgrade(k),level<3 and int(save.rc)>=cost)
	for j in 2:
		var key: String=["gearing","suspension"][j]
		var yy := 422+j*54
		_label(card,["ÜBERSETZUNG","FEDERUNG"][j],16,Color.WHITE,Vector2(22,yy+8),Vector2(165,28))
		_button(card,"−",Vector2(189,yy),Vector2(44,42),func(k=key): change_setup(k,-0.25))
		_label(card,"%+.2f" % float(save.setup[active_car][key]),17,Color("f4c64f"),Vector2(244,yy+8),Vector2(66,28))
		_button(card,"+",Vector2(323,yy),Vector2(44,42),func(k=key): change_setup(k,0.25))
	_label(ui,current.name,38,Color.WHITE,Vector2(44,533),Vector2(760,55),true)
	_button(ui,"↶",Vector2(320,627),Vector2(62,59),func():showroom.rotate_view(-0.35))
	_button(ui,"360°",Vector2(394,627),Vector2(110,59),func():showroom.turntable=not showroom.turntable)
	_button(ui,"↷",Vector2(516,627),Vector2(62,59),func():showroom.rotate_view(0.35))
	_button(ui,"← HAUPTMENÜ",Vector2(40,627),Vector2(240,59),func(): show_home())
	_button(ui,"MIT DIESEM AUTO FAHREN  →",Vector2(849,627),Vector2(389,59),func(): show_pre_race(),true)

func show_pre_race() -> void:
	state="prerace"
	clear_ui()
	ensure_race_world()
	car.position=world.center_at(7.0)+Vector3(0,0.07,0)
	var veil := ColorRect.new()
	veil.color=Color(0.012,0.048,0.064,0.40)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(veil)
	_label(ui,"FAHRZEUG WÄHLEN",47,Color.WHITE,Vector2(42,25),Vector2(760,61),true)
	_label(ui,"%s   ·   %s" % [Data.TRACKS[active_track].state,world.track.name],19,Color("f4c64f"),Vector2(45,92),Vector2(730,31),true)
	if active_track==3:
		for wp in 3:
			var chosen := wp
			_button(ui,"WP %d" % [wp+1],Vector2(42+wp*108,447),Vector2(100,44),func():active_wp=chosen;show_pre_race(),active_wp==wp)
	var cfg: Dictionary=Data.CARS[active_car]
	var info := _card(ui,Vector2(852,135),Vector2(382,463))
	_label(info,"FAHRZEUG %d / %d" % [active_car+1,Data.CARS.size()],18,Color("f4c64f"),Vector2(23,20),Vector2(337,27),true)
	_label(info,cfg.name,35,Color.WHITE,Vector2(23,60),Vector2(340,58),true)
	_label(info,"%s  ·  KLASSE %s" % [cfg.drive,cfg["class"]],20,Color("d7e5dd"),Vector2(23,124),Vector2(340,31),true)
	var drive_info := "FRONTANTRIEB  ·  stabil, schiebt unter Gas" if cfg.drive=="FWD" else ("HECKANTRIEB  ·  agiles Heck" if cfg.drive=="RWD" else "ALLRAD  ·  Traktion auf Schotter")
	_label(info,drive_info,17,Color("a9c7c2"),Vector2(23,163),Vector2(345,30))
	_label(info,"%d PS" % int(cfg.power),28,Color("f4c64f"),Vector2(23,224),Vector2(140,41),true)
	_label(info,"%d KM/H" % int(cfg.top*3.6),28,Color.WHITE,Vector2(188,224),Vector2(167,41),true)
	_label(info,"ANTRIEB %s" % cfg.drive,18,Color("c8dbd1"),Vector2(23,301),Vector2(335,28),true)
	_label(info,"RC-UPGRADES: MOTOR %d  ·  HANDLING %d" % [int(save.upgrades[active_car].engine),int(save.upgrades[active_car].handling)],17,Color("c8dbd1"),Vector2(23,343),Vector2(342,31))
	_label(info,"GEWICHT  %d KG" % int(cfg.mass),16,Color("a9c7c2"),Vector2(23,390),Vector2(160,27))
	_label(info,"GRIP  %.1f" % float(cfg.grip),16,Color("a9c7c2"),Vector2(188,390),Vector2(160,27))
	var map_panel := _card(ui,Vector2(42,135),Vector2(320,300))
	_label(map_panel,"STRECKE · NORDEN OBEN",17,Color("f4c64f"),Vector2(12,8),Vector2(296,25),true)
	var stage_map := preload("res://scripts/stage_map.gd").new()
	stage_map.world=world
	stage_map.position=Vector2(10,38)
	stage_map.size=Vector2(300,206)
	map_panel.add_child(stage_map)
	_label(map_panel,"%.1f km · %s" % [float(world.track.length)/1000.0,"WP %d/3" % [active_wp+1] if active_track==3 else "Ziel ~7 min"],17,Color.WHITE,Vector2(12,248),Vector2(296,25))
	_label(map_panel,"Grün: Start · Rot: Ziel",14,Color("b2c6cd"),Vector2(12,274),Vector2(296,22))
	_button(ui,"◀",Vector2(185,503),Vector2(87,79),func(): select_pre_race_car(-1))
	_button(ui,"▶",Vector2(713,503),Vector2(87,79),func(): select_pre_race_car(1))
	_button(ui,"ZUR KARTE",Vector2(41,637),Vector2(220,56),func(): show_tracks())
	_button(ui,"RENNEN STARTEN  →",Vector2(852,615),Vector2(382,68),func(): start_race(),true)

func select_pre_race_car(direction: int) -> void:
	active_car=posmod(active_car+direction,Data.CARS.size())
	save.selected_car=active_car
	write_save()
	show_pre_race()

func buy_upgrade(key: String) -> void:
	if Data.CARS[active_car].get("voc",false): return
	var levels: Dictionary=save.upgrades[active_car]
	var level: int=int(levels.get(key,0))
	if level>=3: return
	var cost := 100*(level+1)
	if int(save.rc)<cost: return
	save.rc=int(save.rc)-cost
	levels[key]=level+1
	write_save()
	show_garage()

func change_setup(key: String, amount: float) -> void:
	var s: Dictionary=save.setup[active_car]
	s[key]=clampf(float(s[key])+amount,-1,1)
	write_save()
	show_garage()

func settings_adjust(key: String, amount: float, low: float, high: float) -> void:
	save[key]=clampf(float(save.get(key,low))+amount,low,high);write_save();show_settings()

func setting_row(card: Control, title: String, key: String, yy: float, amount: float, low: float, high: float) -> void:
	_label(card,title,20,Color("b8cfcb"),Vector2(32,yy+8),Vector2(335,32))
	_button(card,"−",Vector2(383,yy),Vector2(55,45),func(): settings_adjust(key,-amount,low,high))
	_label(card,"%.1f" % float(save.get(key,low)),20,Color("f4c64f"),Vector2(458,yy+8),Vector2(70,30))
	_button(card,"+",Vector2(527,yy),Vector2(55,45),func(): settings_adjust(key,amount,low,high))

func calibrate_tilt() -> void:
	tilt_zero=Input.get_gravity().x
	if Input.get_gravity().length_squared()<1.0:tilt_zero=Input.get_accelerometer().x
	save.tilt_neutral=tilt_zero;write_save()

func close_settings() -> void:
	if settings_return=="pause":show_pause()
	else:show_home()

func show_settings() -> void:
	state="settings";clear_ui()
	var veil := ColorRect.new();veil.color=Color(0.015,0.025,0.035,0.78);veil.set_anchors_preset(Control.PRESET_FULL_RECT);ui.add_child(veil)
	var card := _card(ui,Vector2(327,45),Vector2(626,630))
	_label(card,"EINSTELLUNGEN",36,Color.WHITE,Vector2(32,22),Vector2(560,50),true)
	for i in 4:
		_button(card,["FAHREN","GRAFIK","KAMERA","FAHRHILFEN"][i],Vector2(32+i*140,88),Vector2(130,45),func(tab=i):settings_tab=tab;show_settings(),settings_tab==i)
	if settings_tab==0:
		for i in 3:
			var mode: String=["wheel","tilt","buttons"][i]
			_button(card,["DAUMEN ↔","NEIGEN","TASTEN"][i],Vector2(32+i*185,165),Vector2(175,45),func():save.control_mode=mode;tilt_zero=Input.get_gravity().x;write_save();show_settings(),save.get("control_mode","wheel")==mode)
		setting_row(card,"LENKEMPFINDLICHKEIT","sensitivity",234,0.1,0.5,1.5)
		_label(card,"GAS AUTOMATISCH",20,Color("b8cfcb"),Vector2(32,309),Vector2(360,32))
		_button(card,"AN" if save.casual else "AUS",Vector2(440,301),Vector2(142,45),func():save.casual=not save.casual;write_save();show_settings(),save.casual)
		_button(card,"NEIGUNG: MITTE KALIBRIEREN",Vector2(32,370),Vector2(550,45),func():calibrate_tilt())
		_button(card,"NEIGUNG INVERTIEREN: "+("AN" if save.get("tilt_invert",false) else "AUS"),Vector2(32,432),Vector2(550,45),func():save.tilt_invert=not save.get("tilt_invert",false);write_save();show_settings())
		_label(card,"Daumen nach links = links. Handy im Querformat neigen.",17,Color("aac7c3"),Vector2(32,498),Vector2(565,40))
	elif settings_tab==1:
		_label(card,"DARSTELLUNG",22,Color.WHITE,Vector2(32,170),Vector2(550,35),true)
		for i in 3:
			var mode: String=["economy","balanced","detail"][i]
			_button(card,["FLÜSSIG","AUSGEWOGEN","DETAIL"][i],Vector2(32+i*185,228),Vector2(175,60),func():save.graphics=mode;write_save();apply_graphics();show_settings(),save.get("graphics","balanced")==mode)
		_label(card,"FLÜSSIG: 65 % 3D-Auflösung, ohne Echtzeitschatten.\nAUSGEWOGEN: 80 % Auflösung, schnelle Kantenglättung.\nDETAIL: volle 3D-Auflösung, 2× Kantenglättung.\nMenüs bleiben in voller Bildschirmauflösung.",20,Color("aac7c3"),Vector2(32,330),Vector2(550,130))
	elif settings_tab==2:
		setting_row(card,"VERFOLGUNG: ABSTAND (M)","camera_distance",170,0.5,4.0,12.0)
		setting_row(card,"VERFOLGUNG: HÖHE (M)","camera_height",242,0.2,1.5,5.0)
		setting_row(card,"SICHTFELD (GRAD)","camera_fov",314,5.0,50.0,85.0)
		_label(card,"Im Rennen zwischen Cockpit und Verfolgung wechseln.\nEinstellungen werden gespeichert.",20,Color("aac7c3"),Vector2(32,416),Vector2(550,85))
	else:
		for i in 3:
			var key: String=["abs_assist","traction_assist","steering_assist"][i]
			_label(card,["ABS / BLOCKIERSCHUTZ","TRAKTIONSKONTROLLE","LENKHILFE BEI HOHEM TEMPO"][i],19,Color.WHITE,Vector2(32,178+i*82),Vector2(390,32))
			_button(card,"AN" if save.get(key,true) else "AUS",Vector2(440,170+i*82),Vector2(142,45),func(k=key):save[k]=not save.get(k,true);write_save();show_settings(),save.get(key,true))
		_label(card,"Hilfen erleichtern die Kontrolle. Für freies Driften\nTraktionskontrolle und Lenkhilfe ausschalten.\nDie Handbremse löst weiterhin die Hinterräder.",19,Color("aac7c3"),Vector2(32,430),Vector2(560,90))
	_button(card,"KARTENDATEN UND LIZENZEN",Vector2(32,541),Vector2(270,45),func():show_credits())
	_button(card,"FERTIG",Vector2(322,541),Vector2(260,45),func():close_settings(),true)

func show_credits() -> void:
	state="credits"
	clear_ui()
	var veil := ColorRect.new(); veil.color=Color(0.015,0.05,0.07,0.88); veil.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(veil)
	var card := _card(ui,Vector2(242,70),Vector2(796,578))
	_label(card,"KARTENDATEN UND LIZENZEN",35,Color.WHITE,Vector2(32,28),Vector2(730,50),true)
	_label(card,"BUNDESLANDGRENZEN",21,Color("f4c64f"),Vector2(32,106),Vector2(730,30),true)
	_label(card,"© Bundesamt für Kartographie und Geodäsie 2025",18,Color("c7ddd5"),Vector2(32,145),Vector2(730,28))
	_label(card,"VG250, vereinfacht und für das Spiel verändert · dl-de/by-2-0",17,Color("a5c2bc"),Vector2(32,177),Vector2(730,28))
	_label(card,"www.bkg.bund.de  ·  www.govdata.de/dl-de/by-2-0",16,Color("87bfb5"),Vector2(32,210),Vector2(730,28))
	_label(card,"STRECKEN, STRAßEN UND GEBÄUDE",21,Color("f4c64f"),Vector2(32,267),Vector2(730,30),true)
	_label(card,"© OpenStreetMap-Mitwirkende",18,Color("c7ddd5"),Vector2(32,306),Vector2(730,28))
	_label(card,"OSM-Geometrie vereinfacht und für das Spiel aufbereitet · ODbL",17,Color("a5c2bc"),Vector2(32,338),Vector2(730,28))
	_label(card,"www.openstreetmap.org/copyright",16,Color("87bfb5"),Vector2(32,371),Vector2(730,28))
	_label(card,"Die Strecken sind Spieladaptionen und keine Navigation.",17,Color("b4cbc3"),Vector2(32,424),Vector2(730,28))
	_button(card,"ZURÜCK",Vector2(32,500),Vector2(732,51),func(): show_settings(),true)

func start_race() -> void:
	state="race"
	touch.clear()
	touch_anchor.clear()
	clear_ui()
	ensure_race_world()
	load_ghost()
	ghost_car.visible = replay_frames.size()>1
	if ghost_car.visible: ghost_car.position=Vector3(float(replay_frames[0][1]),0.08,float(replay_frames[0][2]))
	velocity=Vector2.ZERO
	dynamics.reset()
	mobile_steering.reset()
	steering_input=0.0
	reverse_engaged=false
	speed=0
	race_time=0
	countdown=3.2
	checkpoint=0
	race_progress=0.0
	sector_times.clear()
	ghost_frames.clear()
	sample_clock=0
	previous_best=float(save.best.get(record_key(),0.0))
	previous_sector_times=save.best_sectors.get(record_key(),[]).duplicate()
	impact_timer=0.0
	impact_cooldown=0.0
	collision_count=0
	build_race_ui()

func build_race_ui() -> void:
	var top := _card(ui,Vector2(25,19),Vector2(305,84))
	_label(top,world.track.name,16,Color("f4c64f"),Vector2(19,11),Vector2(365,25),true)
	timer_label=_label(top,"00:00.000",34,Color.WHITE,Vector2(18,38),Vector2(278,44),true)
	var info := _card(ui,Vector2(1050,19),Vector2(205,84))
	sector_label=_label(info,"SECTOR 1 / 3",20,Color.WHITE,Vector2(18,15),Vector2(143,27),true)
	gear_label=_label(info,"G1",18,Color("f4c64f"),Vector2(162,16),Vector2(37,25),true)
	speed_label=_label(info,"000 KM/H",27,Color("f4c64f"),Vector2(18,45),Vector2(184,34),true)
	progress_bar=ProgressBar.new()
	progress_bar.position=Vector2(451,42); progress_bar.size=Vector2(429,17)
	progress_bar.max_value=float(world.track.length)
	progress_bar.value=0
	progress_bar.show_percentage=false
	progress_bar.add_theme_stylebox_override("background",_panel(Color(0.04,0.12,0.15,0.8)))
	progress_bar.add_theme_stylebox_override("fill",_panel(Color("f4c64f")))
	ui.add_child(progress_bar)
	_label(ui,"START",13,Color("243f3d"),Vector2(452,65),Vector2(90,20))
	_label(ui,"FINISH",13,Color("243f3d"),Vector2(815,65),Vector2(90,20))
	var nav_card := _card(ui,Vector2(451,98),Vector2(429,47),false)
	nav_label=_label(nav_card,"ROADBOOK  ·  START",18,Color("f4c64f"),Vector2(13,9),Vector2(400,30),true)
	var map_card := _card(ui,Vector2(25,120),Vector2(175,184))
	_label(map_card,"STRECKENKARTE",16,Color("f4c64f"),Vector2(13,8),Vector2(190,23),true)
	minimap=MinimapScene.new()
	minimap.position=Vector2(12,34)
	minimap.size=Vector2(151,120)
	minimap.track_world=world
	minimap.player_position=car.position
	map_card.add_child(minimap)
	minimap_label=_label(map_card,"0.0 / %.1f KM" % [float(world.track.length)/1000.0],15,Color("c9d9ce"),Vector2(13,158),Vector2(151,22),true)
	_button(ui,"HAUPTMENÜ",Vector2(1002,132),Vector2(170,59),func(): show_home())
	_button(ui,"Ⅱ",Vector2(1192,132),Vector2(63,59),func(): show_pause())
	camera_button=_button(ui,"COCKPIT" if camera_mode==0 else "VERFOLGUNG",Vector2(1055,202),Vector2(200,49),func(): toggle_camera())
	cockpit_panel=Control.new()
	cockpit_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	cockpit_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(cockpit_panel)
	var dash := ColorRect.new()
	dash.color=Color(0.025,0.05,0.057,0.91)
	dash.position=Vector2(0,668)
	dash.size=Vector2(1280,52)
	dash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cockpit_panel.add_child(dash)
	var wheel_rim := _card(cockpit_panel,Vector2(348,616),Vector2(130,130),false)
	wheel_rim.add_theme_stylebox_override("panel",_panel(Color("18292e"),Color("b6aaa0"),65))
	wheel_rim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var wheel_hub := _card(wheel_rim,Vector2(42,42),Vector2(46,46),false)
	wheel_hub.add_theme_stylebox_override("panel",_panel(Color("344549"),Color("d6b755"),23))
	wheel_hub.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var dash_label := _label(cockpit_panel,"GHOST RALLY   •   ONBOARD",17,Color("d8bc68"),Vector2(519,680),Vector2(350,29),true)
	dash_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cockpit_panel.visible=camera_mode==1
	impact_label=_label(ui,"",24,Color("ff9378"),Vector2(481,180),Vector2(370,43),true)
	impact_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	impact_label.visible=false
	countdown_label=_label(ui,"3",93,Color("f4c64f"),Vector2(565,257),Vector2(200,130),true)
	countdown_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	control_panel=Control.new()
	control_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	control_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(control_panel)
	if save.get("control_mode","wheel")=="buttons":
		control_hint("◀",Vector2(38,544),Vector2(141,133),Color("eaf2e8"));control_hint("▶",Vector2(191,544),Vector2(141,133),Color("eaf2e8"))
	elif save.get("control_mode","wheel")=="wheel":
		var wheel_control=preload("res://scripts/input/steering_wheel.gd").new();wheel_control.game=self
		wheel_control.position=Vector2(81,525);wheel_control.size=Vector2(198,168);control_panel.add_child(wheel_control)
		var hint := _label(control_panel,"DAUMEN ↔",16,Color("eaf2e8"),Vector2(86,681),Vector2(185,27),true);hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	else:control_hint("NEIGEN",Vector2(38,544),Vector2(294,133),Color("eaf2e8"))
	control_hint("BREMSE",Vector2(945,544),Vector2(139,133),Color("ec9486"))
	control_hint("GAS",Vector2(1096,544),Vector2(140,133),Color("f4c64f"))
	for panel in ui.get_children():
		if panel is Panel: panel.add_theme_stylebox_override("panel",_panel(Color(0.025,0.055,0.065,0.78),Color(1,1,1,0.35),10))
		if panel is Button: panel.add_theme_stylebox_override("normal",_panel(Color(0.025,0.055,0.065,0.65),Color(1,1,1,0.60),10))

func control_hint(title: String, pos: Vector2, dimensions: Vector2, color: Color) -> void:
	var p := _card(control_panel,pos,dimensions,false)
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",_panel(Color(0.025,0.055,0.065,0.40),Color(1,1,1,0.7),14))
	p.modulate.a=0.9
	var l := _label(p,title,29 if title.length()<4 else 20,color,Vector2(0,44),dimensions)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE

func show_pause() -> void:
	if state not in ["race","pause","settings"]: return
	state="pause"
	touch.clear()
	touch_anchor.clear()
	steer=0;throttle=0;brake=0
	clear_ui()
	var veil := ColorRect.new(); veil.color=Color(0.015,0.05,0.07,0.77); veil.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(veil)
	var card := _card(ui,Vector2(427,83),Vector2(426,554))
	_label(card,"PAUSE",49,Color.WHITE,Vector2(29,31),Vector2(370,67),true)
	_button(card,"WEITER",Vector2(29,138),Vector2(368,56),func(): state="race"; build_race_ui(),true)
	_button(card,"NEUSTART",Vector2(29,218),Vector2(368,56),func(): start_race())
	_button(card,"ZURÜCK AUF DIE STRECKE",Vector2(29,288),Vector2(368,56),func(): reset_to_road())
	_button(card,"EINSTELLUNGEN",Vector2(29,358),Vector2(368,56),func():settings_return="pause";show_settings())
	_button(card,"HAUPTMENÜ",Vector2(29,428),Vector2(368,56),func(): show_home())

func reset_to_road() -> void:
	var at := clampf(race_progress,0,float(world.track.length)-5.0)
	car.position=world.center_at(at)+Vector3.UP*0.07
	yaw=world.heading_at(at);car.rotation.y=yaw
	velocity=Vector2.ZERO;speed=0;reverse_engaged=false
	dynamics.reset();mobile_steering.reset();touch.clear();touch_anchor.clear()
	race_time+=5.0;state="race";build_race_ui()

func toggle_camera() -> void:
	camera_mode=1-camera_mode
	if state=="race" and is_instance_valid(camera_button): camera_button.text="COCKPIT" if camera_mode==0 else "VERFOLGUNG"
	if state=="race" and is_instance_valid(cockpit_panel): cockpit_panel.visible=camera_mode==1

func show_result() -> void:
	state="result"
	clear_ui()
	var veil := ColorRect.new(); veil.color=Color(0.008,0.043,0.06,0.72); veil.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(veil)
	var card := _card(ui,Vector2(268,49),Vector2(744,617))
	_label(card,"NEW PERSONAL BEST" if result_new_pb else "STAGE COMPLETE",18,Color("f4c64f"),Vector2(33,24),Vector2(680,30),true)
	_label(card,Data.format_time(race_time),64,Color.WHITE,Vector2(31,66),Vector2(675,82),true)
	_label(card,"%s  /  %s  /  %s" % [world.track.name,Data.CARS[active_car].name,Data.TRACKS[active_track].surface],17,Color("a6c4c0"),Vector2(35,158),Vector2(670,30))
	if previous_best>0:
		var diff := race_time-previous_best
		_label(card,"%+.3f S VS PREVIOUS BEST" % diff,21,Color("72dccb") if diff<0 else Color("ed8f78"),Vector2(35,208),Vector2(650,35),true)
	else:
		_label(card,"FIRST CLEAN RUN  •  YOUR GHOST IS READY",20,Color("72dccb"),Vector2(35,208),Vector2(650,35))
	_label(card,"+%d RC   •   BALANCE %d RC" % [120 if result_new_pb else 80,int(save.rc)],16,Color("f4c64f"),Vector2(35,246),Vector2(650,27),true)
	_label(card,"SECTOR SPLITS",16,Color("f4c64f"),Vector2(35,275),Vector2(640,27))
	for i in 3:
		var split := sector_times[i] if i<sector_times.size() else 0.0
		var prev := sector_times[i-1] if i>0 and i<sector_times.size() else 0.0
		_label(card,"SECTOR %d" % [i+1],18,Color("cfdfd8"),Vector2(35,315+i*43),Vector2(300,30))
		_label(card,Data.format_time(split-prev),18,Color.WHITE,Vector2(425,315+i*43),Vector2(160,30))
		if previous_sector_times.size()>i:
			var old_prev := float(previous_sector_times[i-1]) if i>0 else 0.0
			var old_sector := float(previous_sector_times[i])-old_prev
			var delta_sector := split-prev-old_sector
			_label(card,"%+.2f" % delta_sector,16,Color("72dccb") if delta_sector<0 else Color("ed8f78"),Vector2(598,315+i*43),Vector2(95,30))
	if active_track==3 and active_wp<2:
		_button(card,"NÄCHSTE WP  →",Vector2(33,466),Vector2(678,62),func():active_wp+=1;show_pre_race(),true)
	else:_button(card,"REMATCH  →",Vector2(33,466),Vector2(678,62),func(): start_race(),true)
	_button(card,"STAGES",Vector2(33,544),Vector2(324,45),func(): show_tracks())
	_button(card,"HOME",Vector2(385,544),Vector2(326,45),func(): show_home())

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		call_deferred("show_pause")

func _input(event: InputEvent) -> void:
	if state!="race": return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_C:
			toggle_camera()
			return
		if event.keycode==KEY_ESCAPE:
			show_pause()
			return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch[event.index]=event.position;touch_anchor[event.index]=event.position
		else: touch.erase(event.index);touch_anchor.erase(event.index)
	elif event is InputEventScreenDrag:
		touch[event.index]=event.position

func get_controls() -> void:
	steer=0; throttle=0; brake=0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): steer-=1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): steer+=1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): throttle=1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): brake=1
	handbrake=Input.is_key_pressed(KEY_SPACE)
	var width := get_viewport().get_visible_rect().size.x
	var height := get_viewport().get_visible_rect().size.y
	for index in touch:
		var pos: Vector2=touch[index]
		var anchor: Vector2=touch_anchor.get(index,pos)
		if anchor.y<height*0.64: continue
		if anchor.x<width*0.27:
			if save.get("control_mode","wheel")=="buttons":steer += -1 if pos.x<width*0.142 else 1
			else:
				steer+=clampf((pos.x-anchor.x)/(width*0.085),-1,1)
		elif anchor.x>width*0.73:
			if anchor.x>width*0.855: throttle=1
			else: brake=1
	if save.get("control_mode","wheel")=="tilt":
		var tilt := Input.get_gravity().x
		if Input.get_gravity().length_squared()<1.0: tilt=Input.get_accelerometer().x
		steer=tilt_steering(tilt)
	steer=clampf(steer,-1,1)*float(save.sensitivity)
	if save.casual and brake<0.5: throttle=1

func tilt_steering(sensor_x: float) -> float:
	var value := (sensor_x-tilt_zero)/4.0
	if save.get("tilt_invert",false): value=-value
	var deadzone := 0.06
	return signf(value)*clampf((absf(value)-deadzone)/(1.0-deadzone),0,1)

func _physics_process(delta: float) -> void:
	if state=="race":
		impact_timer=maxf(0.0,impact_timer-delta)
		if is_instance_valid(impact_label): impact_label.visible=impact_timer>0.0
		if countdown>0:
			countdown-=delta
			countdown_label.text=str(maxi(1,int(ceil(countdown)))) if countdown>0 else "GO!"
			if countdown<=-0.5: countdown_label.visible=false
		else:
			race_time+=delta
			countdown_label.visible = race_time < 0.45
			get_controls()
			steer=mobile_steering.step(steer,speed,delta)
			update_vehicle(delta)
			record_ghost(delta)
			update_replay()
			check_progress()
			if state!="race":return
			update_navigation()
			timer_label.text=Data.format_time(race_time)
			speed_label.text="%03d KM/H" % int(speed*3.6)
			gear_label.text="R" if reverse_engaged else "G%d" % dynamics.gear
			progress_bar.value=clampf(race_progress,0,float(world.track.length))
			if is_instance_valid(minimap):
				minimap.progress=race_progress
				minimap.player_position=car.position
				minimap.queue_redraw()
			if is_instance_valid(minimap_label): minimap_label.text="%.1f / %.1f KM" % [race_progress/1000.0,float(world.track.length)/1000.0]
			if race_time>900.0: show_pause()
	if is_instance_valid(car) and not (is_instance_valid(showroom) and showroom.visible):
		var in_menu := state in ["home","garage","settings","tracks","prerace"]
		var back := Vector3(sin(car.rotation.y),0,cos(car.rotation.y))
		if is_instance_valid(car.body): car.body.visible=not (state=="race" and camera_mode==1)
		if state=="race" and camera_mode==1:
			var bob := sin(race_time*18.0)*minf(0.035,speed*0.0005)
			var onboard := car.position-back*1.35+Vector3(0,1.46+bob,0)
			camera.position=onboard
			camera.look_at(camera.position-back*22.0+Vector3(0,-0.16,0),Vector3.UP)
			camera.fov=lerpf(camera.fov,74.0+clampf(speed*0.07,0.0,6.0),clampf(delta*8.0,0,1))
		else:
			var look_ahead := (2.0 if state=="garage" else 0.0) if in_menu else 12.0+speed*0.36
			var desired := car.position+back*(8.0 if state=="prerace" else (12.0 if in_menu else float(save.get("camera_distance",7.0))+speed*0.030))+Vector3(0,4.8 if state=="prerace" else (11 if in_menu else float(save.get("camera_height",2.5))+speed*0.010),0)
			# Keep the chase camera above hills and roadside objects.
			desired.y=maxf(desired.y,world.ground_height(desired)+1.0)
			if not in_menu:
				var focus := car.position+Vector3.UP*1.25
				var ray := PhysicsRayQueryParameters3D.create(focus,desired,1,[car.get_rid()])
				var obstruction := get_world_3d().direct_space_state.intersect_ray(ray)
				if not obstruction.is_empty():desired=obstruction.position+obstruction.normal*0.35
			camera.position=camera.position.lerp(desired,1-exp(-delta*6.2))
			camera.position.y=maxf(camera.position.y,world.ground_height(camera.position)+0.65)
			var side_focus := 3.0 if state=="prerace" else (1.2 if state=="garage" else (-3.0 if in_menu else 0.0))
			var right := Vector3(cos(car.rotation.y),0,-sin(car.rotation.y))
			camera_target=camera_target.lerp(car.position+right*side_focus-back*look_ahead,clampf(delta*7.0,0,1))
			camera.look_at(camera_target,Vector3.UP)
			camera.fov=lerpf(camera.fov,float(save.get("camera_fov",65.0))+clampf(speed*0.20,0.0,14.0) if state=="race" else 58.0,clampf(delta*4.0,0,1))
		if state in ["garage","prerace"]: car.rotation.y+=delta*0.45

func update_vehicle(delta: float) -> void:
	impact_cooldown=maxf(0.0,impact_cooldown-delta)
	var cfg: Dictionary=Data.CARS[active_car]
	var set: Dictionary=save.setup[active_car].duplicate()
	set.abs_assist=save.get("abs_assist",true)
	set.traction_assist=save.get("traction_assist",true)
	set.steering_assist=save.get("steering_assist",true)
	var upgrades: Dictionary=save.upgrades[active_car]
	var longitudinal := velocity.dot(Vector2(-sin(yaw),-cos(yaw)))
	if brake<0.1 or throttle>0.1: reverse_engaged=false
	elif brake>0.5 and absf(longitudinal)<0.7: reverse_engaged=true
	var on_road := absf(world.lateral_offset(car.position))<world.road_width_at(world.progress_at(car.position,race_progress))*0.5
	var gravel: bool=world.gravel_at(race_progress)
	var axle_base: float=cfg.get("wheelbase",2.6)
	var facing := Vector3(-sin(yaw),0,-cos(yaw));var across := Vector3(cos(yaw),0,-sin(yaw))
	for wheel_i in 4:
		var at := car.position+facing*axle_base*(0.5 if wheel_i<2 else -0.5)+across*( -0.73 if wheel_i%2==0 else 0.73)
		dynamics.wheel_ground[wheel_i]=world.contact_height(at,race_progress)
	var result: Dictionary=dynamics.step(velocity,yaw,steer,throttle,brake,handbrake,reverse_engaged,cfg,set,upgrades,gravel,on_road,delta)
	velocity=result.velocity
	yaw=result.yaw
	var lateral: float=result.lateral
	var before_move := car.position
	var impact := car.move_and_collide(Vector3(result.displacement.x,0,result.displacement.y))
	var tree_contact: Dictionary=world.sweep_trees(before_move,car.position,1.25)
	var impact_normal := Vector2.ZERO
	if not tree_contact.is_empty():
		var contact: Vector2=tree_contact.position
		car.position.x=contact.x
		car.position.z=contact.y
		impact_normal=tree_contact.normal
	elif impact:
		var normal3: Vector3=impact.get_normal()
		impact_normal=Vector2(normal3.x,normal3.z).normalized()
	if not tree_contact.is_empty() or impact:
		var normal := impact_normal
		if normal.length_squared()>0.01:
			var hit_speed := maxf(0.0,-velocity.dot(normal))
			velocity=velocity.slide(normal)*0.32
			if hit_speed>5.0 and impact_cooldown<=0.0:
				var penalty := clampf(hit_speed*0.035,0.4,2.0)
				if state=="race": race_time+=penalty
				collision_count+=1
				impact_timer=1.3
				impact_cooldown=0.7
				crash_energy=clampf(hit_speed/34.0,0.25,0.9)
				if is_instance_valid(impact_label): impact_label.text="AUFPRALL  +%.1f S" % penalty
	car.position.y=0.07+dynamics.suspension.height-dynamics.suspension.ride_height
	car.rotation.y=yaw
	speed=velocity.length()
	lateral_slip=lateral
	car.animate_car(steer,lateral,speed,delta)
	car.set_braking(brake>0.1)
	car.update_dust(world.gravel_at(race_progress),speed)
	car.update_wheel_visuals(dynamics.wheels)
	car.update_suspension_visuals(dynamics.suspension)

func record_ghost(delta: float) -> void:
	sample_clock+=delta
	if sample_clock<0.1: return
	sample_clock-=0.1
	ghost_frames.append([snappedf(race_time,0.001),snappedf(car.position.x,0.01),snappedf(car.position.z,0.01),snappedf(yaw,0.001),snappedf(speed,0.01),snappedf(steer,0.01),throttle,brake,snappedf(car.position.y,0.001)])

func update_replay() -> void:
	if replay_frames.size()<2: return
	while replay_index<replay_frames.size()-2 and float(replay_frames[replay_index+1][0])<=race_time:
		replay_index+=1
	var idx := replay_index
	var a: Array=replay_frames[idx]
	var b: Array=replay_frames[idx+1]
	var t := clampf((race_time-float(a[0]))/maxf(0.001,float(b[0])-float(a[0])),0,1)
	var y := lerpf(float(a[8]),float(b[8]),t) if a.size()>8 and b.size()>8 else world.contact_height(Vector3(float(a[1]),0,float(a[2])),race_progress)+0.11
	ghost_car.position=Vector3(lerpf(float(a[1]),float(b[1]),t),y,lerpf(float(a[2]),float(b[2]),t))
	ghost_car.rotation.y=lerp_angle(float(a[3]),float(b[3]),t)
	ghost_car.visible=race_time<=float(replay_frames[-1][0])

func check_progress() -> void:
	var p := world.progress_at(car.position,race_progress)
	race_progress=p
	var track_length := float(world.track.length)
	var next := (float(checkpoint+1)/3.0)*track_length if checkpoint<2 else track_length-5.0
	if p<next: return
	if absf(world.lateral_offset(car.position))>world.road_width_at(p)*0.75: return
	checkpoint+=1
	sector_times.append(race_time)
	if checkpoint<3:
		if previous_sector_times.size()>=checkpoint:
			var diff := race_time-float(previous_sector_times[checkpoint-1])
			sector_label.text="SECTOR %d / 3  •  %+.2f S" % [checkpoint+1,diff]
		else:
			sector_label.text="SECTOR %d / 3  •  %s" % [checkpoint+1,Data.format_time(race_time)]
	else:
		finish_race()

func update_navigation() -> void:
	if not is_instance_valid(nav_label) or state!="race": return
	var current := world.heading_at(race_progress)
	var advice := "ROADBOOK  ·  GERADEAUS"
	for look in [35.0,70.0,110.0,160.0]:
		var ahead := minf(race_progress+look,float(world.track.length))
		var bend := wrapf(world.heading_at(ahead)-current,-PI,PI)
		if absf(bend)>0.3:
			advice="ROADBOOK  ·  %s IN %d M" % ["LINKS ↖" if bend>0 else "RECHTS ↗",int(look)]
			break
	nav_label.text=advice

func finish_race() -> void:
	if state!="race":return
	result_new_pb=previous_best<=0 or race_time<previous_best
	save.races=int(save.races)+1
	save.xp=int(save.xp)+50+(25 if result_new_pb else 0)
	save.rc=int(save.rc)+80+(40 if result_new_pb else 0)
	save.mastery[active_car]=int(save.mastery[active_car])+1
	if result_new_pb:
		save.best[record_key()]=race_time
		save.best_sectors[record_key()]=sector_times.duplicate()
		save_ghost()
	write_save()
	show_result()

func record_key() -> String:
	return "%s_%d_%d_%d_wp%d" % [Data.PHYSICS_VERSION,dynamics.tick_hz,active_track,active_car,active_wp if active_track==3 else -1]

func _exit_tree() -> void:
	if is_instance_valid(audio_player):audio_player.stop();audio_player.stream=null
	for layer in engine_layers:
		if is_instance_valid(layer):layer.stop();layer.stream=null
	engine_layers.clear();audio_playback=null
