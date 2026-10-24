"""Encrypted external-production gate. No disk image, passphrase, or art is created."""
import os
import stat
import tempfile
import unittest
from pathlib import Path

from private_production_8d4 import (
    ARCHIVE_DEVICE_NODE, ARCHIVE_VOLUME_UUID, EXTERNAL_INTERNAL_OVERHEAD_BYTES,
    EXTERNAL_PEAK_ALLOCATION_BYTES, EXTERNAL_SAFETY_MARGIN_BYTES, EXTERNAL_VOLUME_NAME,
    LOCAL_PEAK_ALLOCATION_BYTES, LOCAL_RESERVE_BYTES, LOCAL_SCOPE, VERIFIED_BACKING_IMAGE,
    VERIFIED_IMAGE_UUID, VERIFIED_VOLUME_UUID, external_production_report,
    live_volume_probe, recheck_external_production, verify_local_context,
)


def identity(**overrides):
    data = {'volume_name': EXTERNAL_VOLUME_NAME, 'volume_uuid': VERIFIED_VOLUME_UUID,
            'image_uuid': VERIFIED_IMAGE_UUID, 'backing_image': str(VERIFIED_BACKING_IMAGE)}
    data.update(overrides)
    return data


def probe_for(mount, **overrides):
    data = {'volume_uuid': VERIFIED_VOLUME_UUID, 'filesystem': 'apfs', 'encrypted': True,
            'image_encrypted': True, 'inner_apfs_encrypted': False, 'owners_enabled': True,
            'image_uuid': VERIFIED_IMAGE_UUID, 'backing_image': str(VERIFIED_BACKING_IMAGE),
            'volume_name': EXTERNAL_VOLUME_NAME, 'mount_point': str(mount), 'device_node': '/dev/disk9s1',
            'parent_whole_disk': 'disk9'}
    data.update(overrides)
    return lambda _path: data


def prepare(root):
    root = Path(root)
    for name in ('source', 'output', 'scratch', 'tmp'):
        directory = root / name
        directory.mkdir(mode=0o700)
        os.chmod(directory, 0o700)
    return root / 'output' / 'pilot-run'


class ExternalProductionGuard(unittest.TestCase):
    def assert_check(self, report, name, passed):
        match = [item for item in report['checks'] if item['check'] == name]
        self.assertEqual(len(match), 1, name)
        self.assertEqual(match[0]['pass'], passed, match[0]['detail'])

    def test_live_probe_reads_mount_from_a_directory_inside_it(self):
        inside=Path('/Volumes/gunnchos-private-art/output')
        if not inside.is_dir():
            self.skipTest('verified private volume is not mounted')
        info=live_volume_probe(inside)
        self.assertEqual(info['mount_point'], '/Volumes/gunnchos-private-art')
        self.assertEqual(str(info['volume_uuid']).lower(), VERIFIED_VOLUME_UUID.lower())
        self.assertEqual(str(info['image_uuid']).lower(), VERIFIED_IMAGE_UUID.lower())
        self.assertTrue(info['image_encrypted'])
        self.assertTrue(info['owners_enabled'])
        self.assertFalse(info['inner_apfs_encrypted'])

    def test_legacy_constants_and_bare_18gib_guard_remain(self):
        self.assertEqual(LOCAL_RESERVE_BYTES, 18 * 1024 ** 3)
        self.assertEqual(LOCAL_PEAK_ALLOCATION_BYTES, 4 * 1024 ** 3)
        self.assertGreater(EXTERNAL_INTERNAL_OVERHEAD_BYTES, 0)
        workspace = Path('/SYNTHETIC_PRIVATE_FIXTURE')
        record = {'scope': LOCAL_SCOPE, 'execution_environment': 'OWNER_LOCAL_OFFLINE', 'producer_sha': 'a' * 40,
                  'execution_recipe_sha': 'a' * 40, 'private_workspace': str(workspace),
                  'output_path': str(workspace / 'metric-stage-8d4'),
                  'peak_internal_allocation_bytes': LOCAL_PEAK_ALLOCATION_BYTES,
                  'paid_usage_authorized': False, 'network_artifact_uploads': False}
        with self.assertRaisesRegex(ValueError, '18GiB AFTER'):
            verify_local_context(record, checkout_sha='a' * 40, workspace=workspace, directory_mode=0o700,
                                 directory_owned=True, internal_free_bytes=LOCAL_RESERVE_BYTES, github_actions=False)

    def test_verified_encrypted_volume_passes_capacity_and_confinement(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as raw:
            mount = Path(raw)
            workspace = prepare(mount)
            report = external_production_report(
                workspace, identity=identity(),
                internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                tmpdir=mount / 'tmp', probe=probe_for(mount), output_path=mount / 'output' / 'metric-stage-8d4')
            self.assertTrue(report['PASS'], report['reasons'])
            self.assert_check(report, 'encryption_on', True)
            self.assertFalse(report['inner_apfs_encrypted'])
            self.assertTrue(report['image_layer_encrypted'])
            recheck_external_production(
                workspace, identity(), internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                tmpdir=mount / 'tmp', probe=probe_for(mount), output_path=mount / 'output' / 'metric-stage-8d4')

    def test_wrong_uuid_unencrypted_or_owners_off_rejected(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as raw:
            mount = Path(raw)
            workspace = prepare(mount)
            common = dict(internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                          external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                          tmpdir=mount / 'tmp')
            wrong_uuid = external_production_report(workspace, identity=identity(), probe=probe_for(mount, volume_uuid='BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEEE'), **common)
            self.assert_check(wrong_uuid, 'volume_uuid_matches_recorded', False)
            unencrypted = external_production_report(workspace, identity=identity(), probe=probe_for(mount, encrypted=False, image_encrypted=False), **common)
            self.assert_check(unencrypted, 'encryption_on', False)
            owners_off = external_production_report(workspace, identity=identity(), probe=probe_for(mount, owners_enabled=False), **common)
            self.assert_check(owners_off, 'owners_on', False)
            wrong_image = external_production_report(
                workspace, identity=identity(), probe=probe_for(mount, image_uuid='BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEEE'), **common)
            self.assert_check(wrong_image, 'image_uuid_matches_recorded', False)
            wrong_backing = external_production_report(
                workspace, identity=identity(), probe=probe_for(mount, backing_image='/tmp/other.sparsebundle'), **common)
            self.assert_check(wrong_backing, 'backing_image_matches', False)
            image_off = external_production_report(
                workspace, identity=identity(),
                probe=probe_for(mount, image_encrypted=False, encrypted=True, inner_apfs_encrypted=True), **common)
            self.assert_check(image_off, 'encryption_on', False)
            self.assertFalse(image_off['PASS'])

    def test_unencrypted_archive_path_rejected(self):
        archive = Path('/Volumes/gunnchOS-Archives/gunnchos-active-dev/tmp')
        if not archive.is_dir():
            self.skipTest('active-dev tmp is absent')
        report = external_production_report(
            archive / 'not-a-protected-workspace', identity=identity(),
            internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
            external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
            tmpdir=archive, probe=probe_for(archive, volume_uuid=ARCHIVE_VOLUME_UUID, encrypted=False, image_encrypted=False,
                                            owners_enabled=False, volume_name='gunnchOS-Archives',
                                            device_node=ARCHIVE_DEVICE_NODE, parent_whole_disk='disk5',
                                            mount_point='/Volumes/gunnchOS-Archives'))
        self.assert_check(report, 'not_archive_volume', False)
        self.assert_check(report, 'encryption_on', False)
        self.assertFalse(report['PASS'])

    def test_low_internal_and_low_external_space_rejected(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as raw:
            mount = Path(raw)
            workspace = prepare(mount)
            low_internal = external_production_report(
                workspace, identity=identity(), internal_free_bytes=LOCAL_RESERVE_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                tmpdir=mount / 'tmp', probe=probe_for(mount))
            self.assert_check(low_internal, 'internal_reserve_plus_overhead', False)
            detail = next(item['detail'] for item in low_internal['checks'] if item['check'] == 'internal_reserve_plus_overhead')
            self.assertIn('18GiB', detail)
            low_external = external_production_report(
                workspace, identity=identity(),
                internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES - 1,
                tmpdir=mount / 'tmp', probe=probe_for(mount))
            self.assert_check(low_external, 'external_peak_plus_margin', False)

    def test_symlink_escape_and_unmounted_volume_rejected(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as raw, tempfile.TemporaryDirectory(dir="/private/tmp") as outside:
            mount = Path(raw)
            prepare(mount)
            link = mount / 'output' / 'escape'
            link.symlink_to(outside, target_is_directory=True)
            escaped = external_production_report(
                link, identity=identity(),
                internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                tmpdir=mount / 'tmp', probe=probe_for(mount))
            self.assert_check(escaped, 'no_symlink_escape', False)
            self.assert_check(escaped, 'workspace_confined', False)

            def unmounted(_path):
                raise OSError('Encrypted volume is not mounted')

            missing = external_production_report(
                mount / 'output' / 'pilot-run', identity=identity(),
                internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=None, tmpdir=mount / 'tmp', probe=unmounted)
            self.assert_check(missing, 'encrypted_volume_mounted', False)
            with self.assertRaisesRegex(ValueError, 'External production stopped'):
                recheck_external_production(
                    mount / 'output' / 'pilot-run', identity(),
                    internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                    external_free_bytes=None, tmpdir=mount / 'tmp', probe=unmounted)

    def test_loose_directory_mode_rejected(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as raw:
            mount = Path(raw)
            workspace = prepare(mount)
            os.chmod(mount / 'output', 0o755)
            self.assertTrue(stat.S_IMODE((mount / 'output').stat().st_mode) & 0o077)
            report = external_production_report(
                workspace, identity=identity(),
                internal_free_bytes=LOCAL_RESERVE_BYTES + EXTERNAL_INTERNAL_OVERHEAD_BYTES,
                external_free_bytes=EXTERNAL_PEAK_ALLOCATION_BYTES + EXTERNAL_SAFETY_MARGIN_BYTES,
                tmpdir=mount / 'tmp', probe=probe_for(mount))
            self.assert_check(report, 'owner_only_mode', False)


if __name__ == '__main__':
    unittest.main()
