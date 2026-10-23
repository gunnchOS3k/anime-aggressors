"""Explicit rigid, metre-preserving offline stage. No implicit runtime authority.

A selected measured reference camera supplies the art chart. Different native
camera scales remain an error for shipping equivalence, never actor scaling.
Source root placement comes only from captured gameplay roots and the selected
chart, not a contact solver. The two-dimensional simulation plane is declared.
"""
import ast
import math
from projection_contact_8d3 import finite_vector, projection_basis, dot, cross

IDENTITY = [[1.,0.,0.,0.],[0.,1.,0.,0.],[0.,0.,1.,0.],[0.,0.,0.,1.]]
C = [[1.,0.,0.,0.],[0.,0.,1.,0.],[0.,-1.,0.,0.],[0.,0.,0.,1.]]


def rigid(matrix):
    if not isinstance(matrix, list) or len(matrix) != 4:
        raise ValueError('Missing measured4x4 transform')
    rows = [finite_vector(row, 4) for row in matrix]
    if rows[3] != [0,0,0,1]: raise ValueError('Non-affine transform')
    axes = [r[:3] for r in rows[:3]]
    if abs(dot(axes[0], cross(axes[1], axes[2]))-1) > 1e-5 or any(abs(dot(axes[i],axes[j])-int(i==j)) > 1e-5 for i in range(3) for j in range(3)):
        raise ValueError('Scale/shear/reflection is forbidden on source actors')
    return rows


def mul(a,b):
    return [[sum(a[i][k]*b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def inverse(matrix):
    matrix = rigid(matrix)
    r = [[matrix[j][i] for j in range(3)]+[0.] for i in range(3)]+[[0.,0.,0.,1.]]
    for i in range(3): r[i][3] = -dot(r[i][:3], [matrix[j][3] for j in range(3)])
    return r


def point(matrix,p):
    p = finite_vector(p,3)
    return [dot(row[:3],p)+row[3] for row in matrix[:3]]


def length(a,b): return math.sqrt(sum((x-y)**2 for x,y in zip(a,b)))


def validate_observation(observation, expected_source_hash):
    if observation['source_sha256'] != expected_source_hash: raise ValueError('Wrong saved source')
    projection = observation['projection']
    if projection.get('projection_version') != 3: raise ValueError('Measured3D camera observation required')
    projection_basis(projection)
    rigid(projection['rig_world_transform']); rigid(projection['camera_world_transform'])
    actual = mul(inverse(projection['camera_world_transform']), projection['rig_world_transform'])
    reported = projection['rig_to_camera_transform']
    if max(abs(actual[i][j]-reported[i][j]) for i in range(4) for j in range(4)) > 1e-5:
        raise ValueError('Rig/camera transform chain does not roundtrip')
    size=projection.get('camera_size',0)
    viewport=finite_vector(projection.get('viewport_size'),2)
    display=projection.get('display_scale')
    if isinstance(display,str):display=ast.literal_eval(display)
    display=finite_vector(display,2)
    if not isinstance(size,(int,float)) or not math.isfinite(size) or size<=0 or min(viewport+display)<=0:
        raise ValueError('Invalid measured camera/display allocation')
    scale=viewport[1]*display[1]/size
    if abs(display[0]-display[1])>1e-6:
        raise ValueError('Anisotropic display cannot preserve source metres')
    source_to_camera=mul(actual,C)
    expected=[[scale*source_to_camera[0][j] for j in range(3)],[-scale*source_to_camera[1][j] for j in range(3)]]
    measured,_=projection_basis(projection)
    if max(abs(expected[i][j]-measured[i][j]) for i in range(2) for j in range(3))>scale*1e-5:
        raise ValueError('Measured projection disagrees with camera/rig/source axes')
    finite_vector(observation['gameplay_root_px'],2)
    finite_vector(projection['origin'],2)
    return projection


def measured_scale(projection):
    rows,_ = projection_basis(projection)
    sx,sy = [math.sqrt(dot(r,r)) for r in rows]
    if abs(sx-sy)/max(sx,sy) > 1e-5 or abs(dot(*rows))/(sx*sy) > 1e-5:
        raise ValueError('Native chart is not an isotropic orthographic metre projection')
    return (sx+sy)*.5


def make_stage(policy, actors, source_hashes):
    if policy.get('status') != 'OWNER_SELECTED_OFFLINE_REFERENCE' or not policy.get('owner_selection_receipt'):
        raise ValueError('Missing authority for the offline metric calibration; no guessed scale')
    if policy.get('runtime_equivalence_claim') is not False or policy.get('depth_policy') != 'declared_2d_simulation_plane_zero':
        raise ValueError('Offline chart must not claim native3D depth or shipping equivalence')
    if policy.get('source_unit_metres') != 1:
        raise ValueError('Original source metre authority required')
    if len(actors)!=2: raise ValueError('Exactly two source actors required')
    reference = policy['reference_observation']
    ref_key = reference['fighter']+':'+reference['body']
    rp = validate_observation(reference, source_hashes[ref_key])
    scale = measured_scale(rp)
    # Camera-aligned source-metre frame; no actor scale is introduced.
    view = inverse(rp['camera_world_transform'])
    view[0][3]=view[1][3]=view[2][3]=0.
    origin = actors[0]['gameplay_root_px']
    transforms=[];errors=[]
    for actor in actors:
        key=actor['fighter']+':'+actor['body'];p=validate_observation(actor,source_hashes[key])
        t=mul(view,p['rig_world_transform'])
        t[0][3]=(actor['gameplay_root_px'][0]-origin[0])/scale
        t[1][3]=-(actor['gameplay_root_px'][1]-origin[1])/scale
        t[2][3]=0. # Explicit offline authoring plane, not recovered hidden depth.
        rigid(t)
        transforms.append({'fighter':actor['fighter'],'body':actor['body'],'facing':actor['facing'],
                           'source_sha256':actor['source_sha256'],'rig_godot_metres_to_stage':t,
                           'rig_blender_metres_to_stage':mul(t,C),'native_projection':p,
                           'gameplay_root_px':actor['gameplay_root_px']})
        errors.append({'fighter':actor['fighter'],'native_px_per_metre':measured_scale(p),
                       'reference_px_per_metre':scale,'native_scale_relative_error':measured_scale(p)/scale-1})
    return {'schema':'offline_metric_art_stage_8d4.v1','units':'metres','axes':['view_right','view_up','toward_viewer'],
            'depth_authority':'OWNER_SELECTED_2D_PLANE_FOR_OFFLINE_ART_ONLY',
            'reference_source_sha256':reference['source_sha256'],'reference_px_per_metre':scale,
            'source_ground_plane_y_m':0.,'actors':transforms,'native_scale_mismatches':errors,
            'actor_roots_solver_owned':False,'actor_scale_changed':False,
            'offline_chart_verified':True,'shipping_alignment_verified':False,'human_approved':False}


def source_to_native(actor, blender_point):
    p=point(C,blender_point);projection=actor['native_projection']
    basis,_=projection_basis(projection);o=projection['origin']
    return [o[i]+dot(basis[i],blender_point) for i in range(2)]


def source_to_reference(stage,actor,blender_point):
    p=point(actor['rig_blender_metres_to_stage'],blender_point)
    first=stage['actors'][0];o=first['native_projection']['origin'];s=stage['reference_px_per_metre']
    return [o[0]+s*p[0],o[1]-s*p[1]]


def feasibility(shoulder, elbow, wrist, target):
    a,b=length(shoulder,elbow),length(elbow,wrist);d=length(shoulder,target)
    if min(a,b)<1e-8: raise ValueError('Degenerate anatomical segments')
    return {'reachable':abs(a-b)<d<a+b,'distance_m':d,'segment_lengths_m':[a,b],
            'reach_excess_m':max(0.,d-a-b,abs(a-b)-d),'stretch_permitted':False}
