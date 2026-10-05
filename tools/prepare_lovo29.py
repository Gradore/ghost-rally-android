"""Blender 4.4: --python tools/prepare_lovo29.py -- SOURCE_028.glb OUTPUT.glb.
Reconstruct a clean reference sedan from the supplied silhouette; replace baked reflections.
All added wheel/detail geometry is original; no third-party vehicle mesh is copied.
"""
import bpy,bmesh,math,sys,json
from pathlib import Path
from mathutils import Vector,Matrix

source,output=map(Path,sys.argv[sys.argv.index('--')+1:][:2])
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source))
body=next(o for o in bpy.context.scene.objects if o.name=='lovo_body')
for o in list(bpy.context.scene.objects):
    if o!=body:bpy.data.objects.remove(o,do_unlink=True)
bpy.context.view_layer.objects.active=body;body.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
# Work at tyre-floor datum, width matched to the native 1.75m shell.
bottom=min(v.co.z for v in body.data.vertices)
xfit=1.75/(max(v.co.x for v in body.data.vertices)-min(v.co.x for v in body.data.vertices))
for v in body.data.vertices:
    v.co.x*=xfit;v.co.z-=bottom
    # Align body wheel arch centres with the native 2.77m axle spacing.
    z=-v.co.y
    if v.co.z<.75:
        amount=max(0,1-abs(abs(z)-1.46)/.65)
        v.co.y+=math.copysign(.075*amount,z)
body.data.update()
def material(name,color,metal=0,rough=.4,coat=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;p.inputs['Coat Weight'].default_value=coat;p.inputs['Coat Roughness'].default_value=.18
    return m
paint=material('Lovo original dark green paint',(.026,.115,.064),.38,.30,.7)
glass=material('Clean smoked glass',(.027,.052,.060),.18,.15,.9)
trim=material('Original rubber trim',(.012,.016,.018),0,.72)
chrome=material('Brushed aluminium',(.43,.48,.50),.85,.27)
rubber=material('Tyre rubber',(.022,.027,.028),0,.86)
treadmat=rubber  # Four material surfaces per wheel, including fasteners.
wheelwhite=material('Original rally wheel ivory',(.72,.75,.70),.38,.3,.25)
red=material('Lovo brake lens',(.42,.011,.013),.05,.23)
white=material('Headlamp lens',(.68,.75,.76),.18,.20,.6)
amber=material('Indicator lens',(.85,.20,.02),.05,.3)
# The upload is a silhouette guide. Its disconnected surfaces are unsuitable for
# a clean car, so replace its topology with a closed, regularised reference shell.
bpy.data.objects.remove(body,do_unlink=True)
parts=[]

def mesh(name,verts,faces,mat,smooth=False):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.materials.append(mat);data.update()
    if 'tread' in name.lower():
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    o=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(o)
    for f in data.polygons:f.use_smooth=smooth
    return o
def box(name,at,size,mat,bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Rounded edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def lathe(name,profile,center,mat,segments=64):
    # Profiles use axle X and radial Y/Z in metres.
    verts=[];faces=[]
    for radius,axle in profile:
        for i in range(segments):
            a=i*math.tau/segments;verts.append((center[0]+axle,center[1]+math.sin(a)*radius,center[2]+math.cos(a)*radius))
    for j in range(len(profile)-1):
        for i in range(segments):
            ni=(i+1)%segments;faces.append(((j+1)*segments+i,(j+1)*segments+ni,j*segments+ni,j*segments+i))
    return mesh(name,verts,faces,mat,True)
# Clean reference retopology. Source cabin envelope: z -1.1..1.65m, roof -0.4..0.9m.
# Values are artistic fits, not a surveyed OEM model.
rings=[(-2.355,.80,.90),(-2.24,.851,.954),(-1.5,.875,1.024),(-1.1,.875,1.041),(.60,.875,1.04),(1.62,.865,1.032),(2.20,.84,.99),(2.355,.80,.926)]
verts=[];faces=[]
for depth,width,top in rings:
    profile=[(0,.325),(.74,.325),(.802,.35),(width*.985,.475),(width,.65),(width*.974,top-.050),(width*.944,top-.009),(width*.88,top),(0,top)]
    profile+= [(-x,y) for x,y in profile[-2:0:-1]]
    for x,y in profile:
        if y>=top-.0001:y+=.012*(1-(x/max(width,.01))**2)
        verts.append((x,-depth,y))
n=len(profile)
for r in range(len(rings)-1):
    for j in range(n):faces.append((r*n+j,r*n+(j+1)%n,(r+1)*n+(j+1)%n,(r+1)*n+j))
faces.append(tuple(range(n-1,-1,-1)));faces.append(tuple((len(rings)-1)*n+j for j in range(n)))
body=mesh('lovo_body',verts,faces,paint)
bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
bpy.context.view_layer.objects.active=body;body.select_set(True)
# Exact curved wheel openings and edge bevels, preserving the uploaded shape guide.
for depth in [1.385,-1.385]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=.349,depth=2.3,location=(0,depth,.317),rotation=(0,math.pi/2,0))
    cutter=bpy.context.object
    bpy.context.view_layer.objects.active=body
    mod=body.modifiers.new('Wheel opening','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
mod=body.modifiers.new('Panel edge highlights','BEVEL');mod.width=.014;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
mod=body.modifiers.new('Planar panel normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
# Roof crown, pillars and glazing; no uploaded reflection atlas or logos are used.
vs=[];fs=[]
for j in range(13):
    z=-.40+1.32*j/12
    for i in range(17):
        x=-.69+1.38*i/16;y=1.426+.030*(1-(x/.69)**2)+.004*math.sin(j*math.pi/12)
        vs.append((x,-z,y))
for j in range(12):
    for i in range(16):fs.append((j*17+i,(j+1)*17+i,(j+1)*17+i+1,j*17+i+1))
roof=mesh('Curved roof crown',vs,fs,paint,True)
# Thin rounded roof rails seal the crown at the window edges.
for side in [-1,1]:box('Roof edge',(side*.69,-.26,1.423),(.025,1.34,.028),paint,.012)
def cabin_quad(name,points,mat):
    vertices=[Vector((x,-z,y)) for x,y,z in points]
    normal=(vertices[1]-vertices[0]).cross(vertices[2]-vertices[0])
    center=sum(vertices,Vector())/4
    outward=normal.x*center.x if 'Side' in name else normal.y*center.y
    order=(0,1,2,3) if outward>0 else (3,2,1,0)
    return mesh(name,vertices,[order],mat)
front_lower=[(-.798,1.045,-1.095),(.798,1.045,-1.095)]
front_upper=[(-.665,1.410,-.402),(.665,1.410,-.402)]
rear_lower=[(-.798,1.045,1.635),(.798,1.045,1.635)]
rear_upper=[(-.675,1.43,.918),(.675,1.43,.918)]
cabin_quad('Front glass',[front_lower[0],front_lower[1],front_upper[1],front_upper[0]],glass)
cabin_quad('Rear glass',[rear_upper[0],rear_upper[1],rear_lower[1],rear_lower[0]],glass)
for side in [-1,1]:
    def x_at(y):return side*(.804-(y-1.025)*.31+.003)
    pts=[(x_at(1.05),1.05,-1.07),(x_at(1.395),1.395,-.40),(x_at(1.419),1.419,.91),(x_at(1.05),1.05,1.59)]
    cabin_quad('Side glass',pts,glass)
    # A, B and C pillars are slender structural strips with rounded edges.
    for z0,y0,z1,y1,width in [(-1.10,1.046,-.414,1.425,.063),(.11,1.041,.11,1.425,.075),(1.633,1.046,.92,1.44,.080)]:
        start=Vector((x_at(y0),-z0,y0));finish=Vector((x_at(y1),-z1,y1));pillar=box('Window pillar',(start+finish)*.5,(width,width,(finish-start).length),paint,.010)
        pillar.rotation_euler=(finish-start).to_track_quat('Z','X').to_euler()
    box('Window lower trim',(side*.804,-.27,1.043),(.018,2.67,.025),trim,.006)
    # Fine door openings. The upper ends stop at the glass belt line.
    for z in [-1.03,.14,1.49]:box('Door seam',(side*.857,-z,.776),(.003,.006,.46),trim,.001)
    box('Door lower seam',(side*.867,-.25,.53),(.003,2.49,.006),trim,.001)
    # Dividers must not extend above sloped A/C pillars.
    box('Original number plate',(side*.875,.36,.755),(.005,.39,.30),white,.012)
    bpy.ops.object.text_add(location=(side*.88,.36,.755),rotation=(math.pi/2,0,side*math.pi/2))
    text=bpy.context.object;text.name='Original racing number 69';text.data.body='69';text.data.align_x='CENTER';text.data.align_y='CENTER';text.data.size=.23;text.data.extrude=.0003
    fonts=list((Path(__file__).resolve().parent.parent/'assets/fonts').glob('*.ttf'))
    if fonts:text.data.font=bpy.data.fonts.load(str(fonts[0]))
    text.data.materials.append(trim);bpy.ops.object.convert(target='MESH')
# Independent lower bumper forms keep a clean, rounded impact strip.
for depth in [-2.35,2.35]:box('Original bumper',(0,-depth,.49),(1.70,.17,.17),trim,.035)
for depth in [-.71,1.93]:box('Deck panel gap',(0,-depth,1.030 if depth<0 else 1.002),(1.51,.006,.003),trim,.001)
# Rounded 195/65 R15 tyre. Crown, shoulder, sidewall and bead form an actual annulus.
tyre_profile=[(.187,-.065),(.203,-.083),(.243,-.097),(.280,-.096),(.301,-.084),(.313,-.063),(.317,-.035),(.317,.035),(.313,.063),(.301,.084),(.280,.096),(.243,.097),(.203,.083),(.187,.065)]
wheelstats=[]
for i,(side,depth) in enumerate([(-1,1.385),(1,1.385),(-1,-1.385),(1,-1.385)]):
    center=Vector((side*.835,depth,.317));parts=[lathe('Rounded 195-65-R15 tyre',tyre_profile,center,rubber)]
    # Four separated tread lanes, with alternating angled grooves and rounded shoulders.
    verts=[];faces=[]
    for lane,axle in enumerate([-.062,-.023,.023,.062]):
        for n in range(44):
            a=(n+(lane%2)*.42)*math.tau/44;da=.053
            start=len(verts)
            for radius in [.314,.318]:
                for xx,aa in [(-.015,-da),(.015,-da+.010),(.015,da),(-.015,da-.010)]:
                    verts.append((center.x+axle+xx,center.y+math.sin(a+aa)*radius,center.z+math.cos(a+aa)*radius))
            for f in [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]:faces.append(tuple(start+k for k in f))
    parts.append(mesh('Directional tread blocks',verts,faces,treadmat))
    # Bead lip and real recessed wheel barrel; no flat disc across the tyre sidewall.
    face=side*.086
    parts.append(lathe('Rolled rim lip',[(.177,face-side*.01),(.188,face),(.192,face+side*.004),(.188,face+side*.009),(.177,face+side*.009)],center,wheelwhite))
    parts.append(lathe('Inner barrel',[(.178,-.060),(.178,.065)],center,trim))
    # Five original rounded rally spokes with a recessed dish.
    for n in range(5):
        a=n*math.tau/5
        spoke=box('Rally spoke',(center.x+face-side*.020,center.y+math.sin(a)*.113,center.z+math.cos(a)*.113),(.025,.034,.146),wheelwhite,.008)
        spoke.rotation_euler.x=-a;parts.append(spoke)
    parts.append(lathe('Unmarked hub',[(.050,face-side*.037),(.054,face-side*.020),(.050,face-side*.008),(0,face-side*.008)],center,wheelwhite,32))
    for n in range(5):
        a=n*math.tau/5
        bolt=box('Wheel fastener',(center.x+face-side*.003,center.y+math.sin(a)*.037,center.z+math.cos(a)*.037),(.010,.012,.012),chrome,.002);parts.append(bolt)
    # Two fine sidewall rings catch light without a manufacturer mark.
    for rr in [.267,.290]:parts.append(lathe('Sidewall moulding',[(rr-.0015,side*.097),(rr,side*.0985),(rr+.0015,side*.097)],center,rubber))
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();wheel=bpy.context.object
    wheel.name=['wheel_fl','wheel_fr','wheel_rl','wheel_rr'][i]
    bpy.context.scene.cursor.location=center;bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    wheelstats.append(sum(len(p.vertices)-2 for p in wheel.data.polygons))
# Body details use clean original geometry; no source badges or atlas are shipped.
box('Original horizontal grille',(0,2.335,.668),(.81,.024,.215),trim)
for y in [.594,.636,.678,.720]:box('Grille horizontal bar',(0,2.363,y),(.76,.012,.009),chrome,.003)
for side in [-1,1]:
    box('Red rear lens',(side*.625,-2.362,.755),(.29,.018,.18),red,.010)
    box('Front headlamp',(side*.612,2.361,.763),(.34,.018,.188),white,.012)
    box('Front indicator',(side*.824,2.336,.763),(.076,.018,.173),amber,.006)
    for z in [-.32,.64]:box('Door handle',(side*.854,-z,.839),(.018,.115,.032),chrome,.008)
    box('Side moulding',(side*.873,0,.565),(.024,3.12,.043),trim,.008)
    box('Mirror',(side*.928,.70,1.04),(.135,.20,.115),paint,.024)
    # Rounded clean fender lips cover the jagged cut boundary of the source wheel arches.
    for d in [1.385,-1.385]:
        vs=[];fs=[]
        for radius in [.348,.367]:
            for j in range(33):
                a=j*math.pi/32;vs.append((side*.876,d+math.cos(a)*radius,.317+math.sin(a)*radius))
        for j in range(32):
            f=(j,j+1,33+j+1,33+j);fs.append(tuple(reversed(f)) if side>0 else f)
        mesh('Clean fender lip',vs,fs,trim,True)
# Headlamp ribbing and original wipers make the front read as a car rather than a white box.
for side in [-1,1]:
    for j in range(13):box('Headlamp optic rib',(side*.612+(j-6)*.023,2.375,.765),(.004,.003,.165),chrome,.001)
    for j in range(4):box('Tail optic rib',(side*.625,-2.376,.70+j*.037),(.27,.003,.003),amber if j==0 else red,.001)
    wipe=box('Wiper',(side*.36,1.025,1.079),(.45,.020,.015),trim,.004)
    wipe.rotation_euler.y=side*.05
# Subtle original cabin fittings are seen through reflective glazing; no opaque photo windows.
# Source window material remains opaque PBR to avoid expensive sorted transparency on Android.
box('Blank rear plate',(0,-2.346,.540),(.40,.012,.105),white,.006)
# Join all static details: one multi-material body plus four articulated wheel meshes.
static=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.name.startswith('wheel_')]
bpy.ops.object.select_all(action='DESELECT')
for o in static:o.select_set(True)
bpy.context.view_layer.objects.active=body;bpy.ops.object.join();body.name='lovo_body'
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
output.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
print('OUTPUT',output,'TRIANGLES',triangles,'WHEELS',wheelstats,'BYTES',output.stat().st_size,flush=True)
# Real Blender inspection render from the same exported geometry.
if '--preview' in sys.argv:
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.world=bpy.data.worlds.new('World');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.3,.35,.4,1)
    scene.render.resolution_x=1100;scene.render.resolution_y=700;scene.render.resolution_percentage=100
    for pos,power,size in [((2,-3,6),550,5),((-3,4,4),400,4)]:
        d=bpy.data.lights.new('Softbox','AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new('Softbox',d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler()
    d=bpy.data.cameras.new('camera');cam=bpy.data.objects.new('camera',d);scene.collection.objects.link(cam);scene.camera=cam;d.type='ORTHO';d.ortho_scale=6.4
    for name,pos in [('front',(5,7,3.1)),('rear',(-5,-7,3.1)),('side',(7,0,2.1))]:
        cam.location=pos;cam.rotation_euler=(Vector((0,0,.7))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(output.parent.parent.parent.parent/'model29'/('clean-'+name+'.png'));bpy.ops.render.render(write_still=True)
