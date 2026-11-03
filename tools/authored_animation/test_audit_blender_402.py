"""Synthetic checksum/app-boundary tests; no real Blender/vendor approval implied."""
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from audit_blender_402 import PACKAGE, MANIFEST_URL, PACKAGE_URL, parse_manifest, tree_digest, verify_audit, official_browser_origin
from private_production_8d4 import current_context, LOCAL_SCOPE


class OfficialProducerBoundary(unittest.TestCase):
    def test_full_checksum_manifest_parses_every_line(self):
        entries=parse_manifest('a'*64+'  '+PACKAGE+'\n'+'b'*64+' *blender-4.0.2-linux-x64.tar.xz\n')
        self.assertEqual(len(entries),2);self.assertEqual(entries[PACKAGE],'a'*64)

    def test_cloudflare_HTML_is_not_a_checksum(self):
        with self.assertRaises(ValueError):parse_manifest('<html>Cloudflare challenge</html>')

    def test_duplicate_or_bad_other_entry_rejects_full_manifest(self):
        valid='a'*64+'  '+PACKAGE+'\n'
        for rest in [valid,'not-a-sha256  OTHER\n','b'*64+'  ../other.dmg\n']:
            with self.assertRaises(ValueError):parse_manifest(valid+rest)

    def test_missing_exact_ARM_package_fails_closed(self):
        with self.assertRaises(ValueError):parse_manifest('a'*64+'  blender-4.0.2-macos-x64.dmg\n')

    def test_browser_origin_requires_exact_official_URL_not_similar_name(self):
        self.assertTrue(official_browser_origin([MANIFEST_URL],MANIFEST_URL))
        for values in [[],[MANIFEST_URL+'.evil'],['https://example.com/'+PACKAGE],MANIFEST_URL]:
            self.assertFalse(official_browser_origin(values,MANIFEST_URL))

    def test_browser_origin_accepts_observed_utm_source_and_rejects_other_variations(self):
        dmg=PACKAGE_URL+'?utm_source=chatgpt.com'
        manifest=MANIFEST_URL+'?utm_source=chatgpt.com'
        cloudflare=PACKAGE_URL+'?utm_source=chatgpt.com&__cf_chl_tk=synthetic'
        self.assertTrue(official_browser_origin([dmg,cloudflare],PACKAGE_URL))
        self.assertTrue(official_browser_origin([manifest],MANIFEST_URL))
        self.assertFalse(official_browser_origin([cloudflare],PACKAGE_URL))
        rejected=[
            'https://evil.example/release/Blender4.0/blender-4.0.2-macos-arm64.dmg?utm_source=chatgpt.com',
            'https://download.blender.org.evil.com/release/Blender4.0/blender-4.0.2-macos-arm64.dmg',
            'https://user@download.blender.org/release/Blender4.0/blender-4.0.2-macos-arm64.dmg',
            'https://download.blender.org:8443/release/Blender4.0/blender-4.0.2-macos-arm64.dmg',
            'https://download.blender.org/release/Blender4.0/other.dmg?utm_source=chatgpt.com',
            PACKAGE_URL+'?utm_source=chatgpt.com&next=/tmp/other',
            PACKAGE_URL+'?utm_source=chatgpt.com#fragment',
            'https://evil.example/redirect?url=https://download.blender.org/release/Blender4.0/blender-4.0.2-macos-arm64.dmg',
        ]
        for value in rejected:
            self.assertFalse(official_browser_origin([value],PACKAGE_URL),value)

    def test_application_tree_compares_bytes_and_link_targets(self):
        root=Path(tempfile.mkdtemp(prefix='anime_audit_app_fixture_'))
        (root/'Contents').mkdir();(root/'Contents/binary').write_bytes(b'SYNTHETIC_NOT_EXECUTABLE')
        (root/'link').symlink_to('Contents/binary')
        initial,size=tree_digest(root);self.assertEqual(size,len(b'SYNTHETIC_NOT_EXECUTABLE'))
        (root/'Contents/binary').write_bytes(b'CHANGED_SYNTHETIC')
        self.assertNotEqual(tree_digest(root)[0],initial)

    def test_plain_approval_boolean_is_not_an_official_audit(self):
        root=Path(tempfile.mkdtemp(prefix='anime_audit_receipt_fixture_'));receipt=root/'receipt.json'
        receipt.write_text(json.dumps({'PASS':True}));receipt.chmod(0o600)
        with self.assertRaises(ValueError):verify_audit(receipt,root/'nonexistent_blender')

    def test_shared_audit_receipt_cannot_authorize_producer(self):
        root=Path(tempfile.mkdtemp(prefix='anime_audit_shared_fixture_'));receipt=root/'receipt.json'
        receipt.write_text('{}');receipt.chmod(0o644)
        with self.assertRaisesRegex(ValueError,'owner-only'):verify_audit(receipt,root/'nonexistent_blender')

    def test_direct_local_source_context_cannot_skip_binary_audit(self):
        root=Path(tempfile.mkdtemp(prefix='anime_local_context_fixture_')).resolve();root.chmod(0o700)
        receipt=root/'context.json'
        receipt.write_text(json.dumps({'scope':LOCAL_SCOPE,'execution_environment':'OWNER_LOCAL_OFFLINE',
            'paid_usage_authorized':False,'network_artifact_uploads':False,'producer_sha':'a'*40,
            'execution_recipe_sha':'a'*40,'private_workspace':str(root),
            'peak_internal_allocation_bytes':4*1024**3,'output_path':str(root/'metric-stage-8d4')}))
        receipt.chmod(0o600)
        with patch.dict(os.environ,{'AA_8D4_LOCAL_CONTEXT':str(receipt)}),\
             patch('private_production_8d4.subprocess.run',return_value=SimpleNamespace(returncode=1)),\
             patch('private_production_8d4.subprocess.check_output',return_value='a'*40+'\n'),\
             patch('private_production_8d4.shutil.disk_usage',return_value=SimpleNamespace(free=22*1024**3)):
            with self.assertRaisesRegex(ValueError,'Actual Blender executable'):current_context(Path(__file__).resolve().parents[2])


if __name__=='__main__':unittest.main()
