"""Original non-deforming support authoring tools for the preserved 22-bone rigs.

Controls are objects, not extra deform bones. No generic FK-copy rig is installed:
that would override the 147 original actions. Operations explicitly bake a pose
onto existing bones using the established offline two-bone constraint. Merely
installing controls changes no mesh, weight, rest bone, action or runtime GLB.
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]
C = Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))

def matrix_array(m): return [[float(x) for x in row] for row in m]

def install(arm, fighter, body):
    """Measured sole/heel/ball controls, knee poles and pelvis support handle."""
    collection=bpy.data.collections.get('ANI_P1_SOURCE_CONTROLS')
    if collection is None:
        collection=bpy.data.collections.new('ANI_P1_SOURCE_CONTROLS')
        bpy.context.scene.collection.children.link(collection)
    controls={};soles={}
    def control(name, point, role):
        ob=bpy.data.objects.get('ANI_P1_'+name)
        if ob is None:
            ob=bpy.data.objects.new('ANI_P1_'+name,None);collection.objects.link(ob)
        assert ob.type=='EMPTY' and (not ob.get('owner') or ob['owner']=='ANI_P1')
        ob['owner']='ANI_P1';ob['role']=role;ob['fighter']=fighter;ob['body']=body
        ob['not_final_acting']=True
        ob.empty_display_type='PLAIN_AXES';ob.empty_display_size=.025
        ob.matrix_world=Matrix.Translation(arm.matrix_world@point)
        controls[name]=ob
        return ob
    for side in ('L','R'):
        boot=bpy.data.objects.get('Boot '+side)
        assert boot is not None, (fighter,body,side,'original weighted boot')
        assert boot.vertex_groups.get('Foot_'+side) is not None
        vertices=[arm.matrix_world.inverted()@boot.matrix_world@v.co for v in boot.data.vertices]
        low=min(p.z for p in vertices)
        bottom=[p for p in vertices if abs(p.z-low)<1e-5]
        sole=sum(bottom,Vector())/len(bottom)
        # Godot forward +Z is Blender -Y. Use actual sole geometry, not ankles.
        front=min(p.y for p in bottom);back=max(p.y for p in bottom)
        ball_points=[p for p in bottom if abs(p.y-front)<1e-5]
        heel_points=[p for p in bottom if abs(p.y-back)<1e-5]
        ball=sum(ball_points,Vector())/len(ball_points)
        heel=sum(heel_points,Vector())/len(heel_points)
        rest=arm.data.bones['Foot_'+side].matrix_local
        soles[side]={'sole_rig_blender_m':list(sole),'ball_rig_blender_m':list(ball),'heel_rig_blender_m':list(heel),
                     'foot_local_m':list(rest.inverted()@sole),'weighted_bottom_vertices':len(bottom)}
        for label,point in [('Sole',sole),('Ball',ball),('Heel',heel)]:
            control(label+'_'+side,point,'measured original weighted Boot; source pivot')
        control('KneePole_'+side,arm.data.bones['LowerLeg_'+side].head_local+Vector((0,-.25,0)),'live +Z knee plane')
    control('Pelvis',arm.data.bones['Hips'].head_local,'authored load/support exchange; no Root channel')
    hair=[]
    for ob in bpy.data.objects:
        if ob.type!='MESH' or not (ob.name.startswith('Hair ') or ob.name.startswith('Cloth ') or ob.name.startswith('Ribbon')): continue
        # Independent offset controls are source-only. Existing Head weights are
        # retained; final articulated hair weighting and object-track export remain open.
        control('Accessory_'+ob.name,arm.data.bones['Head'].head_local,'independent rigid accessory offset; not reweighting')
        hair.append(ob.name)
    return {'controls':controls,'soles':soles,'accessories':hair}

def authored_support_pose(arm, fighter, body, targets, pelvis_delta=(0,0,0), roll_degrees=None):
    """Bake finite animator targets onto original bones; never change lengths.

    Targets are ankle matrices in armature space, derived from measured pivots.
    The shared OFFLINE solver already used for original choreography is reused.
    No runtime IK, action regeneration or root translation is introduced.
    """
    sys.path.insert(0,str(ROOT/'tools/v1_closure'))
    from build_combat_choreography import rig, solve, matrix
    import numpy as np
    r,_=rig(fighter,body)
    rots={};positions={}
    for name in r:
        pb=arm.pose.bones[name]
        world=C@pb.matrix
        local=(C@pb.parent.matrix).inverted()@world if pb.parent else world
        p,q,_=local.decompose();rots[name]=matrix([q.x,q.y,q.z,q.w]);positions[name]=np.array(p)
    positions['Hips']+=np.array(pelvis_delta)
    for side,target in targets.items():
        desired=C@target
        g=solve(r,rots,positions,'UpperLeg_'+side,'LowerLeg_'+side,'Foot_'+side,np.array(desired.translation),np.array((0,0,1.)))
        parent=r['Foot_'+side]['parent']
        rots['Foot_'+side]=g[parent][0].T@np.array([list(row) for row in desired.to_3x3()])
    from build_combat_choreography import fk
    pose=fk(r,rots,positions)
    # Assign existing local basis without adding constraints to saved actions.
    names=['Hips']+[n+'_'+s for s in ('L','R') for n in ('UpperLeg','LowerLeg','Foot')]
    for name in names:
        rotation,position=pose[name]
        desired=Matrix.Identity(4)
        for i in range(3):
            for j in range(3):desired[i][j]=rotation[i][j]
            desired[i][3]=position[i]
        desired=C.inverted()@desired
        bone=arm.pose.bones[name];rest=bone.bone.matrix_local
        chain=rest
        if bone.parent:
            pr,pp=pose[bone.parent.name];pm=Matrix.Identity(4)
            for i in range(3):
                for j in range(3):pm[i][j]=pr[i][j]
                pm[i][3]=pp[i]
            chain=C.inverted()@pm@bone.parent.bone.matrix_local.inverted()@rest
        bone.matrix_basis=chain.inverted()@desired
    bpy.context.view_layer.update()

def roll_foot(arm, fighter, body, installed, side, degrees, pivot='ball'):
    assert side in ('L','R') and pivot in ('ball','heel') and abs(degrees)<=20
    origin=Vector(installed['soles'][side][pivot+'_rig_blender_m'])
    old=arm.pose.bones['Foot_'+side].matrix.copy()
    rotation=Matrix.Rotation(math.radians(degrees),4,'X')
    target=Matrix.Translation(origin)@rotation@Matrix.Translation(-origin)@old
    authored_support_pose(arm,fighter,body,{side:target})
    return target

def replant(arm,fighter,body,targets,pelvis_delta):
    authored_support_pose(arm,fighter,body,targets,pelvis_delta)

def accessory_offset(arm, installed, name, degrees):
    """Finite rigid source follow-through about the actual Head pivot.

    Explicit source edit only; does not claim final hair deformation or runtime
    object-animation transport. Canonical meshes/weights are never replaced.
    """
    assert name in installed['accessories'] and abs(degrees)<=8
    ob=bpy.data.objects[name]
    pivot=arm.matrix_world@arm.pose.bones['Head'].matrix.translation
    ob.matrix_world=Matrix.Translation(pivot)@Matrix.Rotation(math.radians(degrees),4,'X')@Matrix.Translation(-pivot)@ob.matrix_world
    return ob
