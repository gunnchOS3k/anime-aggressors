"""Bake original arm acting to the actual evaluated victim surface.

Offline source constraints only. No runtime IK, stretch, root translation,
collision, throw timing or damage authority. A connected Palm surface vertex,
not an abstract wrist target, is the contact witness. Unreachable targets stay
explicitly blocked rather than distorting anatomy.
"""
import math
import bpy
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree


def surface(objects):
    verts=[];faces=[];graph=bpy.context.evaluated_depsgraph_get()
    for ob in objects:
        evaluated=ob.evaluated_get(graph);mesh=evaluated.to_mesh();start=len(verts)
        verts.extend(evaluated.matrix_world@v.co for v in mesh.vertices)
        faces.extend(tuple(start+i for i in p.vertices)for p in mesh.polygons)
        evaluated.to_mesh_clear()
    assert verts and faces
    return BVHTree.FromPolygons(verts,faces),sum(verts,Vector())/len(verts),len(verts)


def contact_vertex(arm,hand):
    """Actual dense source skin vertex in the fully Hand-bound palm pad."""
    ob=bpy.data.objects[hand['mesh']];matrix=arm.matrix_world.inverted()@ob.matrix_world
    group=ob.vertex_groups['Hand_'+hand['side']].index
    candidates=[v for v in ob.data.vertices if any(g.group==group and g.weight>.99999 for g in v.groups)]
    nominal=Vector(hand['palm_contact_rest']);v=min(candidates,key=lambda v:(matrix@v.co-nominal).length)
    p=matrix@v.co
    return {'index':v.index,'mesh':ob.name,'hand_local':list(arm.data.bones['Hand_'+hand['side']].matrix_local.inverted()@p),'rest_armature':list(p),'normal_hand_local':list(arm.data.bones['Hand_'+hand['side']].matrix_local.to_quaternion().inverted()@Vector(hand['chains'][0]['normal']))}


def sample_vertex(ob,index):
    evaluated=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
    result=evaluated.matrix_world@mesh.vertices[index].co;evaluated.to_mesh_clear();return result


def solve_arm(arm,side,wrist,hand_q):
    """Two-segment anatomical solve; preserve preferred authored elbow pole."""
    upper=arm.pose.bones['UpperArm_'+side];lower=arm.pose.bones['LowerArm_'+side];hand=arm.pose.bones['Hand_'+side]
    u=upper.matrix.translation.copy();e=lower.matrix.translation.copy();w=hand.matrix.translation.copy()
    a=(e-u).length;b=(w-e).length;axis=wrist-u;distance=axis.length
    if distance>=a+b-.00001 or distance<=abs(a-b)+.00001:return {'reachable':False,'reach_excess_m':max(distance-a-b,abs(a-b)-distance,0)}
    axis.normalize();along=(a*a-b*b+distance*distance)/(2*distance);height=math.sqrt(max(0,a*a-along*along))
    pole=e-u-axis*(e-u).dot(axis)
    if pole.length<.00001:pole=Vector((1 if side=='R'else-1,.2,-.2)).cross(axis)
    pole.normalize();elbow=u+axis*along+pole*height
    q=(e-u).rotation_difference(elbow-u)@upper.matrix.to_quaternion()
    upper.matrix=Matrix.LocRotScale(u,q,Vector((1,1,1)));bpy.context.view_layer.update()
    e=lower.matrix.translation.copy();w=hand.matrix.translation.copy()
    q=(w-e).rotation_difference(wrist-e)@lower.matrix.to_quaternion()
    lower.matrix=Matrix.LocRotScale(e,q,Vector((1,1,1)));bpy.context.view_layer.update()
    hand.matrix=Matrix.LocRotScale(hand.matrix.translation,hand_q,Vector((1,1,1)));bpy.context.view_layer.update()
    residual=(hand.matrix.translation-wrist).length
    assert residual<.00005,('Offline arm constraint residual',side,residual)
    for p in [upper,lower,hand]:
        assert max(abs(s-1)for s in p.scale)<.00005 and p.location.length<.00005,('No arm translation/stretch',p.name,list(p.location),list(p.scale))
    return {'reachable':True,'wrist_residual_m':residual}


def constrain_hand(arm,side,witness,victim_objects,pressure=.0015):
    tree,center,count=surface(victim_objects)
    # A faces source -Y. Cast from the actual attacker's side onto the victim's
    # front arm skin/armor; no bone sphere or invisible idealized cylinder.
    origin=center+Vector((0,2,0));point,normal,triangle,distance=tree.ray_cast(origin,Vector((0,-1,0)),4)
    assert point is not None,'Actual victim mesh ray missed'
    inv=arm.matrix_world.inverted();target=inv@(point-normal*pressure)
    local_normal=arm.matrix_world.to_3x3().transposed()@normal;local_normal.normalize()
    hand=arm.pose.bones['Hand_'+side];q=hand.matrix.to_quaternion()
    facing=q@Vector(witness['normal_hand_local']);desired=facing.rotation_difference(-local_normal)@q
    wrist=target-desired@Vector(witness['hand_local'])
    old=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    result=solve_arm(arm,side,wrist,desired)
    actual=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    nearest,norm,idx,separation=tree.find_nearest(actual)
    # Signed mesh-surface distances retain deep clipping as a failure to
    # inspect, even if the single pad witness reaches the intended surface.
    evaluated=bpy.data.objects[witness['mesh']].evaluated_get(bpy.context.evaluated_depsgraph_get());skin=evaluated.to_mesh()
    signed=[]
    for v in skin.vertices[::8]:
        p=evaluated.matrix_world@v.co;near,n,_,dist=tree.find_nearest(p)
        signed.append((p-near).dot(n))
    evaluated.to_mesh_clear()
    result.update(min_hand_surface_signed_m=min(signed),sampled_hand_vertices=len(signed),deep_overlap_sample_count=sum(v<-.003 for v in signed),before_contact_m=(old-point).length,after_contact_m=(actual-point).length,pad_to_surface_m=separation,penetration_target_m=pressure,victim_surface_vertices=count,surface_point=list(point),surface_normal=list(normal),actual_hand_pad=list(actual),pad_vertex=witness['index'],victim_meshes=[o.name for o in victim_objects])
    return result
