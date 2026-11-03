"""Flat geometry-only owner silhouette evidence; never modifies art sources."""
import bpy,math,sys,shutil
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[2]
if shutil.disk_usage(R).free/2**30<18:raise RuntimeError('18 GiB headroom required before review generation')
for folder in sorted((R/'art_source/collectible_v1').glob('*/*')):
 bpy.ops.wm.open_mainfile(filepath=str(folder/'candidate.blend'))
 scene=bpy.context.scene;scene.frame_set(0);scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
 scene.render.resolution_x=480;scene.render.resolution_y=480;scene.render.resolution_percentage=100;scene.render.film_transparent=True
 black=bpy.data.materials.new('Review geometry silhouette');black.use_nodes=True
 nodes=black.node_tree.nodes;nodes.clear();out=nodes.new('ShaderNodeOutputMaterial');shader=nodes.new('ShaderNodeEmission');shader.inputs[0].default_value=(0,0,0,1);black.node_tree.links.new(shader.outputs[0],out.inputs[0])
 for ob in bpy.data.objects:
  if ob.type=='MESH':ob.data.materials.clear();ob.data.materials.append(black)
 bpy.ops.object.camera_add(location=(0,-3.5,1.7));c=bpy.context.object;c.data.type='ORTHO';c.data.ortho_scale=1.95;c.rotation_euler=(Vector((0,0,.78))-c.location).to_track_quat('-Z','Y').to_euler();scene.camera=c
 dest=R/'artifacts/v1_closure/review/owner_override/silhouettes'/folder.parent.name/folder.name;dest.mkdir(parents=True,exist_ok=True)
 scene.render.filepath=str(dest/'front.png');bpy.ops.render.render(write_still=True)
 print('SILHOUETTE',folder.parent.name,folder.name,flush=True)
