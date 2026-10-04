extends RefCounted
class_name GameData

const PHYSICS_VERSION := "14.mobile.1"
const CARS := [
	{"id":"kite", "name":"KITE SPRINT", "class":"C", "drive":"FWD", "color":Color("f2bd45"), "mass":1080.0, "power":190.0, "grip":14.0, "rear_grip":12.5, "top":61.0, "steer":3.15},
	{"id":"mira", "name":"MIRA TURBO", "class":"B", "drive":"FWD", "color":Color("ef8f69"), "mass":1160.0, "power":235.0, "grip":13.5, "rear_grip":11.8, "top":67.0, "steer":3.0},
	{"id":"volt", "name":"VOLT GTI", "class":"A", "drive":"FWD", "color":Color("c5df70"), "mass":1210.0, "power":285.0, "grip":15.0, "rear_grip":12.1, "top":72.0, "steer":2.85},
	{"id":"vanta", "name":"VANTA R2", "class":"B", "drive":"RWD", "color":Color("ed5c50"), "mass":1240.0, "power":260.0, "grip":13.6, "rear_grip":10.8, "top":71.0, "steer":3.05},
	{"id":"strix", "name":"STRIX RS", "class":"A", "drive":"RWD", "color":Color("a98cd5"), "mass":1280.0, "power":325.0, "grip":13.3, "rear_grip":10.0, "top":78.0, "steer":2.9},
	{"id":"venom", "name":"VENOM R", "class":"S", "drive":"RWD", "color":Color("e66e82"), "mass":1190.0, "power":400.0, "grip":12.8, "rear_grip":9.5, "top":85.0, "steer":2.75},
	{"id":"nord", "name":"NORD 4X", "class":"B", "drive":"AWD", "color":Color("72d2d0"), "mass":1350.0, "power":280.0, "grip":15.0, "rear_grip":14.5, "top":70.0, "steer":2.85},
	{"id":"talon", "name":"TALON EVO", "class":"A", "drive":"AWD", "color":Color("6aa9e3"), "mass":1390.0, "power":335.0, "grip":16.0, "rear_grip":15.0, "top":77.0, "steer":2.75},
	{"id":"rover", "name":"ROVER X", "class":"A", "drive":"AWD", "color":Color("d3bc8c"), "mass":1450.0, "power":370.0, "grip":17.0, "rear_grip":16.2, "top":75.0, "steer":2.65},
	{"id":"apex", "name":"APEX WRC", "class":"S", "drive":"AWD", "color":Color("f2f2e4"), "mass":1320.0, "power":430.0, "grip":18.0, "rear_grip":17.0, "top":83.0, "steer":2.8},
	{"id":"lovo940voc", "name":"Lovo 940 VOC", "class":"VOC", "drive":"RWD", "color":Color("214c36"), "mass":1350.0, "power":116.0, "grip":12.0, "rear_grip":11.8, "top":49.0, "steer":2.8, "wheelbase":2.77, "wheel_radius":0.317, "front_weight":0.53, "final_drive":4.1, "voc":true},
	{"id":"kestrel_s1_evo", "name":"KESTREL S1 EVO", "class":"B", "drive":"AWD", "color":Color("eeeadd"), "mass":1090.0, "power":476.0, "grip":16.0, "rear_grip":15.0, "top":77.0, "steer":2.8, "wheelbase":2.224, "wheel_radius":0.32, "front_weight":0.52, "final_drive":4.2, "fictional":true}
]

const TRACKS := [
	{"name":"BLACK FOREST RUN", "state":"Baden-Württemberg", "state_code":"08", "place":"SCHWARZWALD", "surface":"GRAVEL", "length":5415.0, "seed":1, "route_index":0, "color":Color("375e51")},
	{"name":"BAVARIAN TRAIL", "state":"Bayern", "state_code":"09", "place":"BAYERISCHER WALD", "surface":"GRAVEL", "length":5479.0, "seed":2, "route_index":1, "color":Color("3b6154")},
	{"name":"MÜGGELHEIM SPRINT", "state":"Berlin", "state_code":"11", "place":"MÜGGELHEIM", "surface":"ASPHALT", "length":4967.0, "seed":3, "route_index":2, "color":Color("466264")},
	{"name":"LAUSITZ LAKE RUN", "state":"Brandenburg", "state_code":"12", "place":"GROßRÄSCHEN", "surface":"GRAVEL", "length":16010.1, "seed":4, "route_index":3, "color":Color("49664f")},
	{"name":"WESER DASH", "state":"Bremen", "state_code":"04", "place":"BREMEN SÜD", "surface":"ASPHALT", "length":5005.0, "seed":5, "route_index":4, "color":Color("49646a")},
	{"name":"HARBOR CHASE", "state":"Hamburg", "state_code":"02", "place":"HAMBURGER HAFEN", "surface":"ASPHALT", "length":5926.0, "seed":6, "route_index":5, "color":Color("3f5d69")},
	{"name":"TAUNUS ASCENT", "state":"Hessen", "state_code":"06", "place":"TAUNUS", "surface":"GRAVEL", "length":5561.0, "seed":7, "route_index":6, "color":Color("46674e")},
	{"name":"MÜRITZ TRAIL", "state":"Mecklenburg-Vorpommern", "state_code":"13", "place":"MÜRITZ", "surface":"GRAVEL", "length":5826.0, "seed":8, "route_index":7, "color":Color("4b6a5d")},
	{"name":"HARZ RIDGE", "state":"Niedersachsen", "state_code":"03", "place":"OBERHARZ", "surface":"GRAVEL", "length":5024.0, "seed":9, "route_index":8, "color":Color("53675b")},
	{"name":"WINTERBERG CUT", "state":"Nordrhein-Westfalen", "state_code":"05", "place":"WINTERBERG", "surface":"GRAVEL", "length":6020.0, "seed":10, "route_index":9, "color":Color("52644e")},
	{"name":"EIFEL RUSH", "state":"Rheinland-Pfalz", "state_code":"07", "place":"EIFEL", "surface":"GRAVEL", "length":4726.0, "seed":11, "route_index":10, "color":Color("656b52")},
	{"name":"SAAR FOREST", "state":"Saarland", "state_code":"10", "place":"SAARBRÜCKEN", "surface":"GRAVEL", "length":5947.0, "seed":12, "route_index":11, "color":Color("4d6b58")},
	{"name":"ERZGEBIRGE PASS", "state":"Sachsen", "state_code":"14", "place":"ERZGEBIRGE", "surface":"GRAVEL", "length":4556.0, "seed":13, "route_index":12, "color":Color("5a665c")},
	{"name":"OSTHARZ DRIVE", "state":"Sachsen-Anhalt", "state_code":"15", "place":"OSTHARZ", "surface":"GRAVEL", "length":5185.0, "seed":14, "route_index":13, "color":Color("53694e")},
	{"name":"PLÖN LAKES", "state":"Schleswig-Holstein", "state_code":"01", "place":"PLÖN", "surface":"GRAVEL", "length":3940.0, "seed":15, "route_index":14, "color":Color("4c6c67")},
	{"name":"THÜRINGER WALD", "state":"Thüringen", "state_code":"16", "place":"THÜRINGER WALD", "surface":"GRAVEL", "length":5578.0, "seed":16, "route_index":15, "color":Color("486652")},
	{"name":"ROSTOCK → MÖNCHHAGEN", "state":"Mecklenburg-Vorpommern", "state_code":"13", "place":"BRINCKMANNSDORF · NEUENDORF", "surface":"MIXED", "length":15623.4, "seed":21, "route_index":16, "mapped_mv":true, "color":Color("6a7951")}
]

static func today_track() -> int:
	var day := int(Time.get_unix_time_from_system() / 86400.0)
	return posmod(day, TRACKS.size())

static func format_time(seconds: float) -> String:
	var ms := int(round(seconds * 1000.0))
	return "%02d:%02d.%03d" % [int(ms / 60000), int(ms / 1000) % 60, ms % 1000]

static func default_save() -> Dictionary:
	var setup := []
	var upgrades := []
	var livery := []
	var mastery := []
	for i in CARS.size():
		setup.append({"gearing":0.0,"brake_bias":0.0,"suspension":0.0})
		upgrades.append({"engine":0,"handling":0,"brakes":0})
		livery.append(0)
		mastery.append(0)
	return {"races":0, "xp":0, "rc":300, "selected_car":0, "selected_track":0, "best":{}, "best_sectors":{}, "mastery":mastery, "setup":setup, "upgrades":upgrades, "livery":livery, "casual":false, "sensitivity":1.0, "control_mode":"wheel"}

