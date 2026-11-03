"""Fail-closed handoff validation for privately produced original game art.

No gameplay writes, asset installation, network or automatic quality approval.
Existing five hand clips cannot masquerade as a complete 24-move export.
"""
import hashlib
import re
from pathlib import Path

FIGHTERS = ('ember-vale', 'rook-ironside', 'juno-spark', 'kaia-windrow', 'nix-calder',
            'orion-vell', 'vesper-nyx', 'yin', 'yang')
BODIES = ('male', 'female')
CANONICAL = ('Root', 'Hips', 'Spine', 'Chest', 'Neck', 'Head',
             'Shoulder_L', 'UpperArm_L', 'LowerArm_L', 'Hand_L',
             'Shoulder_R', 'UpperArm_R', 'LowerArm_R', 'Hand_R',
             'UpperLeg_L', 'LowerLeg_L', 'Foot_L', 'Toes_L',
             'UpperLeg_R', 'LowerLeg_R', 'Foot_R', 'Toes_R')


def checked_file(base, declaration):
    """Private paths must resolve inside the supplied secure bundle root."""
    root = Path(base).resolve()
    relative = Path(declaration['path'])
    path = (root/relative).resolve()
    if relative.is_absolute() or not path.is_relative_to(root) or not path.is_file():
        raise ValueError('Art source/export escapes the verified private bundle')
    if not re.fullmatch('[0-9a-f]{64}', declaration.get('sha256', '')):
        raise ValueError('Exact original asset SHA-256 required')
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''):
            h.update(block)
    if h.hexdigest() != declaration['sha256']:
        raise ValueError('Art source/export hash changed')
    return path


def validate_row(row, move_ids, forms, *, full_move_export=False):
    if row.get('fighter') not in FIGHTERS or row.get('body') not in BODIES:
        raise ValueError('Original fighter/body identity required')
    rig = row['rig']
    bones = rig['bones']
    if len(bones) != len(set(bones)) or not set(CANONICAL).issubset(bones):
        raise ValueError('Canonical original skeleton changed or omitted')
    if (rig.get('forward') != '+Z' or rig.get('up') != '+Y'
            or rig.get('rest_policy') != 'PRESERVE_ORIGINAL_BIND'
            or rig.get('facing_policy') != 'PROPER_ACTOR_ROTATION_NO_BONE_MIRROR'):
        raise ValueError('Unreviewed original rig convention')
    if row.get('root_motion') != 'PRESENTATION_ONLY_GAMEPLAY_ROOT_UNCHANGED':
        raise ValueError('Art does not own gameplay displacement')
    mapping = row['moves']
    if len(move_ids) != 24 or set(mapping) != set(move_ids):
        raise ValueError('All24 actual authored move IDs must be accounted for')
    exported = set(row['exported_clips'])
    if len(exported) != len(row['exported_clips']):
        raise ValueError('Duplicate exported clip identity')
    for move, record in mapping.items():
        if (record.get('clock_owner') != 'RESOLVED_RUNTIME_MOVE_PHASE'
                or record.get('contact_owner') != 'CONFIRMED_COMBAT_COLLISION'
                or record.get('cancel_owner') != 'EXISTING_GAMEPLAY_STATE'
                or record.get('facings') != [-1, 1]):
            raise ValueError(('Unresolved gameplay/animation interface', move))
        clip = record.get('exported_clip')
        if clip is not None and clip not in exported:
            raise ValueError(('Move maps to an unexported animation', move))
        if full_move_export and (clip is None or record.get('native_verified') is not True):
            raise ValueError(('Full original move export/native proof missing', move))
    if set(row['forms']) != set(forms):
        raise ValueError('Form bindings differ from existing fighter authority')
    if row['fighter'] in ('yin', 'yang') and any(x in row['forms'] for x in ('BLACK_PUPPET','WHITE_PUPPET','PRISMATIC_GRAY')):
        raise ValueError('Cosmic fighters cannot inherit ordinary Story forms')
    gates = row['acceptance']
    if any(gates.get(k) is not False for k in ('HUMAN_ART_APPROVED', 'RUNTIME_PAIRED_CONTACT_VERIFIED', 'RC2_READY', 'V1_0_0_RELEASE_AUTHORIZED')):
        raise ValueError('Engineering handoff cannot promote human/release acceptance')
    if type(row.get('integration_ready')) is not bool:
        raise ValueError('Explicit boolean integration readiness required')
    if row.get('integration_ready') is True and any(gates.get(k) is not True for k in
            ('new_arm_blender_saved', 'native_skin_reviewed', 'runtime_event_alignment_verified')):
        raise ValueError('Unsaved/unreviewed source candidate is not a runtime replacement')
    return {'identity': [row['fighter'], row['body']], 'move_ids_accounted': len(mapping),
            'moves_with_exported_clips': sum(x.get('exported_clip') is not None for x in mapping.values()),
            'full_move_export_verified': full_move_export,
            'integration_ready': row.get('integration_ready') is True,
            'human_approved': False}


def validate_roster(rows, move_manifests, form_manifests):
    expected = {(fid, body) for fid in FIGHTERS for body in BODIES}
    if len(rows) != 18 or {(r['fighter'], r['body']) for r in rows} != expected:
        raise ValueError('Complete9fighter/18body inventory required')
    return [validate_row(row, [m['move_id'] for m in move_manifests[row['fighter']]['moves']],
                         form_manifests[row['fighter']]['forms']) for row in rows]
