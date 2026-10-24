"""Rest-frame arm geometry shared by original-source authoring and inspection.

No Blender dependency, body dimensions, gameplay units, imported motion or
retargeting aliases. Inputs must be measured in ONE rigid coordinate space.
An invalid target/pole is rejected; it never changes limb lengths or roots.
"""
import math


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def mul(a, s):
    return tuple(x * s for x in a)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def length(a):
    return math.sqrt(dot(a, a))


def unit(a):
    n = length(a)
    if not math.isfinite(n) or n < 1e-10:
        raise ValueError('Undefined anatomical axis')
    return mul(a, 1/n)


def body_frame(left_shoulder, right_shoulder, chest, head):
    """Right is the actual R-labelled shoulder, not a hardcoded X sign.

    R cross up supplies forward for these verified original rigs. This is
    Blender -Y / exported +Z, and commutes with proper actor facing rotations.
    Caller must verify front against original source face/foot landmarks.
    """
    right = unit(sub(right_shoulder, left_shoulder))
    up = sub(head, chest)
    up = unit(sub(up, mul(right, dot(up, right))))
    return {'right': right, 'up': up, 'forward': unit(cross(right, up))}


def pole_direction(frame, side, *, outward=.65, down=.75, forward=.10):
    if side not in ('L', 'R'):
        raise ValueError('Explicit L/R identity required')
    if outward <= 0 or down < 0 or not all(math.isfinite(x) for x in (outward, down, forward)):
        raise ValueError('Invalid authored elbow direction')
    return unit(add(add(mul(frame['right'], outward * (1 if side == 'R' else -1)),
                        mul(frame['up'], -down)), mul(frame['forward'], forward)))


def solve_two_bone(shoulder, wrist, upper_length, forearm_length, pole):
    """Exact, nonstretching reach. No inherited elbow or arbitrary fallback.

    The pole is an anatomical direction in the same space as the target.
    At a pole singularity the author must choose an explicit new direction.
    """
    if not all(math.isfinite(x) for x in (*shoulder, *wrist, *pole, upper_length, forearm_length)):
        raise ValueError('Non-finite arm input')
    if min(upper_length, forearm_length) <= 0:
        raise ValueError('Invalid original limb length')
    delta = sub(wrist, shoulder)
    distance = length(delta)
    if not abs(upper_length-forearm_length) + 1e-8 < distance < upper_length+forearm_length - 1e-8:
        return {'reachable': False, 'reason': 'outside_original_reach',
                'distance': distance, 'maximum_reach': upper_length+forearm_length}
    axis = unit(delta)
    bend = sub(pole, mul(axis, dot(pole, axis)))
    if length(bend) < 1e-8:
        return {'reachable': False, 'reason': 'explicit_pole_parallel_to_reach'}
    bend = unit(bend)
    along = (upper_length**2 - forearm_length**2 + distance**2)/(2*distance)
    height = math.sqrt(max(0., upper_length**2-along**2))
    elbow = add(add(shoulder, mul(axis, along)), mul(bend, height))
    cosine = (upper_length**2 + forearm_length**2-distance**2)/(2*upper_length*forearm_length)
    return {'reachable': True, 'elbow': elbow, 'wrist': tuple(wrist),
            'bend_direction': bend, 'flexion_radians': math.pi-math.acos(max(-1., min(1., cosine)))}


def qmul(a, b):
    x, y, z, w = a
    u, v, s, t = b
    return (w*u+x*t+y*s-z*v, w*v-x*s+y*t+z*u,
            w*s+x*v-y*u+z*t, w*t-x*u-y*v-z*s)


def qrotate(q, v):
    n = sum(x*x for x in q)
    if not math.isfinite(n) or n < 1e-12:
        raise ValueError('Invalid rotation')
    q = tuple(x/math.sqrt(n) for x in q)
    return qmul(qmul(q, (*v, 0.)), (-q[0], -q[1], -q[2], q[3]))[:3]


def rigid_inverse_column_major(values):
    """glTF inverse bind -> original bind matrix. Reject nonrigid sources."""
    if len(values) != 16 or not all(math.isfinite(x) for x in values):
        raise ValueError('Invalid inverse bind matrix')
    if any(abs(values[i]-v) > 1e-7 for i, v in zip((3, 7, 11, 15), (0, 0, 0, 1))):
        raise ValueError('Projective inverse bind is unsupported')
    columns = [tuple(values[c*4+r] for r in range(3)) for c in range(3)]
    if any(abs(dot(a, b)-float(i == j)) > 2e-5
           for i, a in enumerate(columns) for j, b in enumerate(columns)):
        raise ValueError('Original inverse bind contains scale/shear')
    if dot(cross(columns[0], columns[1]), columns[2]) < .99998:
        raise ValueError('Mirrored original skin is unsupported')
    # Inverse of [R,t] = [R^T,-R^T t]. Return a row-major rigid matrix.
    t = tuple(values[12:15])
    return tuple(tuple(columns[r][c] for c in range(3)) + (-dot(columns[r], t),)
                 for r in range(3)) + ((0., 0., 0., 1.),)
