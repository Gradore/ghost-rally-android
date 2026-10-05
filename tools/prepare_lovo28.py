"""Run with Blender 4.4: blender -b --python tools/prepare_lovo28.py -- SOURCE OUTPUT.
User-supplied Meshy geometry only; no original upload is redistributed. Visual-only asset.
"""
import bpy, bmesh, math, sys, json, hashlib, tempfile
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
source,output=map(Path,args[:2])
bpy.ops.wm.read_factory_settings(use_empty=True)
if len(args)>2:
    bpy.ops.wm.open_mainfile(filepath=args[2])
else:
    bpy.ops.import_scene.gltf(filepath=str(source))
body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
body.name='lovo_body'
bpy.context.view_layer.objects.active=body;body.select_set(True)
if len(body.data.polygons)>100000:
    mod=body.modifiers.new('Mobile reduction','DECIMATE');mod.ratio=.05
    bpy.ops.object.modifier_apply(modifier=mod.name)
# Remove fused source wheels; grille/rear identifiers are replaced with untextured materials.
# Selection is in original Blender coordinates: front -X, up Z.
bm=bmesh.new();bm.from_mesh(body.data)
remove=[]
for f in bm.faces:
    c=f.calc_center_median();x,y,z=c
    wheel=abs(y)>.22 and any((x-cx)**2+(z+.155)**2 < .137**2 for cx in [-.575,.565])
    grille=False  # Retain surface; remove source logo material below.
    rear=False  # Keep rear body surface; replace its central material below.
    if wheel or grille or rear:remove.append(f)
bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(body.data);bm.free()
# Flatten the small source emblem relief into the neighbouring trunk surface.
# This also removes the identifying raised shape, rather than merely its color.
from statistics import median
neighbours=[v.co.copy() for v in body.data.vertices if v.co.x>.78 and .045<abs(v.co.y)<.12]
for vertex in body.data.vertices:
    c=vertex.co
    if c.x>.78 and abs(c.y)<.028 and -.045<c.z<.060:
        row=[p.x for p in neighbours if abs(p.z-c.z)<.009 and abs(p.x-c.x)<.10]
        if row:c.x=median(row)
def mat(name,color,metal=0,rough=.4):
    m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m
rubber=mat('Original unmarked tyre',(.013,.018,.022),0,.85)
alloy=mat('Original six-spoke alloy',(.36,.40,.44),.8,.27)
dark=mat('Original grille and trim',(.018,.028,.036),.35,.4)
body.data.materials.append(dark)
for face in body.data.polygons:
    c=face.center
    if c.x<-.74 and abs(c.y)<.195 and -.14<c.z<.035:face.material_index=len(body.data.materials)-1
paint=mat('Badge-free rear panel',(.045,.095,.115),.55,.32)
body.data.materials.append(paint)
for face in body.data.polygons:
    c=face.center
    if c.x>.63 and abs(c.y)<.24 and -.15<c.z<.110:face.material_index=len(body.data.materials)-1
red=mat('Rear red lens',(.5,.012,.018),.05,.22)
white=mat('Original blank registration',(.74,.78,.76),.1,.5)
objects=[body]
def cube(name,at,size,material):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name
    o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=o.modifiers.new('Edge highlights','BEVEL');bevel.width=.004;bevel.segments=2
    bpy.ops.object.modifier_apply(modifier=bevel.name);o.data.materials.append(material);objects.append(o);return o
cube('Original horizontal grille',(-.910,0,-.042),(.018,.350,.105),dark)
for z in [-.081,-.055,-.029,-.003]:cube('Horizontal slat',(-.924,0,z),(.010,.349,.010),alloy)
# The badge-free panel follows existing body geometry; no extra box is attached.
cube('Fictional registration backing',(.917,0,-.088),(.007,.190,.047),dark)
cube('Unmarked plate',(.922,0,-.088),(.004,.178,.036),white)
# Red taillamps cover the baked silver AI lens; no manufacturer-specific graphics.
for side in [-1,1]:cube('Red rear lens',(.932,side*.276,.000),(.006,.085,.050),red)
# All wheel geometry is authored here and has no copied hub symbols.
wheel_parts=[]
def cylinder(at,radius,depth,material,segments=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=radius,depth=depth,location=at,rotation=(math.pi/2,0,0))
    o=bpy.context.object;o.data.materials.append(material);objects.append(o);wheel_parts.append(o)
    for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
    return o
scale=4.87/(max(v.co.x for v in body.data.vertices)-min(v.co.x for v in body.data.vertices))
for idx,(cx,side) in enumerate([(-1.385/scale,-1),(-1.385/scale,1),(1.385/scale,-1),(1.385/scale,1)]):
    # Original Blender -Y becomes game -X after orientation; left = -Y.
    cy=side*.79/scale;cz=-.29252+.317/scale
    center=Vector((cx,cy,cz));wheel_parts=[]
    cylinder(center,.317/scale,.195/scale,rubber,40)
    outer=cy+side*.100/scale
    cylinder((cx,outer,cz),.231/scale,.008/scale,dark)
    cylinder((cx,outer+side*.003,cz),.052/scale,.014/scale,alloy,20)
    for a in range(6):
        angle=a*math.pi/3
        part=cube('Spoke',(cx+math.sin(angle)*.070,outer,cz+math.cos(angle)*.070),(.019,.009,.085),alloy)
        part.rotation_euler.y=angle;wheel_parts.append(part)
    bpy.ops.object.select_all(action='DESELECT')
    for p in wheel_parts:p.select_set(True)
    bpy.context.view_layer.objects.active=wheel_parts[0];bpy.ops.object.join();w=bpy.context.object
    w.name=['wheel_fl','wheel_fr','wheel_rl','wheel_rr'][idx]
    bpy.context.scene.cursor.location=center;bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
# Orient and scale geometry into game coordinates, preserving wheel pivots.
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
from mathutils import Matrix
rot=Matrix.Rotation(-math.pi/2,4,'Z')
for o in meshes:
    world=o.matrix_world.copy()
    for v in o.data.vertices:
        v.co=rot @ (world @ v.co)*scale
    pivot=rot @ o.location*scale if o.name.startswith('wheel_') else Vector((0,0,0))
    for v in o.data.vertices:v.co-=pivot
    o.matrix_world=Matrix.Translation(pivot)
    o.data.update()
# Keep atlas UV fidelity but halve memory footprint. Raster content is not repainted.
image_dir=Path(tempfile.mkdtemp(prefix='lovo28-textures-'))
for i,image in enumerate(bpy.data.images):
    if not image.has_data:continue
    if image.size[0]>2048:image.scale(2048,2048)
    image.file_format='JPEG';image.filepath_raw=str(image_dir/('map%d.jpg'%i));image.save()
    image.reload();image.pack()
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
output.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_image_format='JPEG',export_jpeg_quality=88,export_animations=False,export_cameras=False,export_lights=False)
triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
print('EXPORTED',output,'TRIANGLES',triangles,'BYTES',output.stat().st_size,flush=True)
