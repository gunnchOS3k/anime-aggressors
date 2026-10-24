#!/usr/bin/env python3
"""Read-only official package/app audit. NEVER downloads a DMG, mounts or installs.

Run only after capacity permits an owner-provided official package, read-only
mounted source app and separate4.0.2 copy. Existing Blender.app stays untouched.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import urllib.request
import urllib.error
from urllib.parse import parse_qsl, urlsplit

PACKAGE='blender-4.0.2-macos-arm64.dmg'
MANIFEST_URL='https://download.blender.org/release/Blender4.0/blender-4.0.2.sha256'
PACKAGE_URL='https://download.blender.org/release/Blender4.0/'+PACKAGE
SCHEMA='official_blender402_local_audit.v1'
ROOT=Path(__file__).resolve().parents[2]


def sha(path):
    h=hashlib.sha256()
    with Path(path).open('rb')as stream:
        for block in iter(lambda:stream.read(8*1024**2),b''):h.update(block)
    return h.hexdigest()


def parse_manifest(text):
    entries={}
    for line in text.splitlines():
        if not line.strip():continue
        match=re.fullmatch(r'([0-9a-fA-F]{64}) [ *]([^/\\\s]+)',line)
        if not match or match[2]in entries:raise ValueError('Invalid/duplicate line in full official checksum manifest')
        entries[match[2]]=match[1].lower()
    if PACKAGE not in entries:raise ValueError('Official ARM64 package checksum missing')
    return entries


# Observed on the owner-saved 4.0.2 files. utm_source is the only benign
# tracking key. __cf_chl_tk is not accepted; a URL carrying it does not match.
ALLOWED_ORIGIN_QUERY_KEYS=frozenset({'utm_source'})


def canonical_download_url(value,expected):
    """True when value is the canonical HTTPS URL plus only approved tracking keys.

    Host, path, scheme, and port stay exact. A substring of download.blender.org
    is not enough.
    """
    if not isinstance(value,str) or not isinstance(expected,str):
        return False
    try:
        got=urlsplit(value)
        want=urlsplit(expected)
    except ValueError:
        return False
    if got.scheme!='https' or want.scheme!='https':
        return False
    if got.username or got.password or want.username or want.password:
        return False
    if got.hostname!='download.blender.org' or want.hostname!='download.blender.org':
        return False
    if got.port not in (None,443) or want.port not in (None,443):
        return False
    if got.path!=want.path or not got.path.startswith('/release/Blender4.0/'):
        return False
    if got.fragment or want.fragment:
        return False
    for key,query_value in parse_qsl(got.query,keep_blank_values=True):
        if key not in ALLOWED_ORIGIN_QUERY_KEYS:
            return False
        if any(mark in query_value for mark in ('/','\\','..','@',' ','#')):
            return False
    return True


def official_browser_origin(values,expected):
    # Safari/Chromium download-origin metadata is provenance evidence, not a
    # cryptographic source signature. Never infer origin from a filename alone.
    return isinstance(values,list) and any(canonical_download_url(item,expected) for item in values)


def browser_origin(path,expected):
    raw=command(['/usr/bin/xattr','-px','com.apple.metadata:kMDItemWhereFroms',str(path)])
    values=plistlib.loads(bytes.fromhex(raw))
    if not official_browser_origin(values,expected):raise ValueError('Official browser-download origin metadata missing')


def tree_digest(folder):
    """All app files and symlink targets, without following links/config paths."""
    h=hashlib.sha256();total=0
    for path in sorted(folder.rglob('*')):
        name=path.relative_to(folder).as_posix()
        if path.is_symlink():record=['link',name,os.readlink(path)]
        elif path.is_file():
            total+=path.stat().st_size;record=['file',name,path.stat().st_size,sha(path)]
        elif path.is_dir():continue
        else:raise ValueError('Unsupported app filesystem entry')
        h.update(json.dumps(record,separators=(',',':')).encode()+b'\n')
    return h.hexdigest(),total


def command(args):
    r=subprocess.run(args,text=True,capture_output=True,timeout=90)
    if r.returncode:raise ValueError('Audit command failed: '+args[0]+' '+r.stderr.strip())
    return r.stdout+r.stderr


def assess_app(app):
    binary=app/'Contents/MacOS/Blender'
    if app.resolve()==Path('/Applications/Blender.app').resolve():raise ValueError('Preserve installed3.3.1 app')
    architecture=command(['/usr/bin/lipo','-archs',str(binary)]).strip()
    if architecture!='arm64':raise ValueError('Exact Apple Silicon package architecture required')
    command(['/usr/bin/codesign','--verify','--deep','--strict',str(app)])
    signature=command(['/usr/bin/codesign','-d','--verbose=4',str(app)])
    assessment=command(['/usr/sbin/spctl','--assess','--type','execute','--verbose=2',str(app)])
    return {'architecture':architecture,'codesign_verified':True,'signature':signature,'gatekeeper_assessment':assessment}


def audit(package,checksums,mounted_app,installed_app):
    req=urllib.request.Request(MANIFEST_URL)
    # Normal TLS certificate/hostname verification; no alternate binary source.
    try:
        with urllib.request.urlopen(req,timeout=20)as response:
            if response.status!=200 or response.geturl()!=MANIFEST_URL:raise ValueError('Exact official HTTPS manifest required')
            raw=response.read(1024*1024+1)
            length=response.headers.get('Content-Length')
            if len(raw)>1024*1024 or length is not None and len(raw)!=int(length):raise ValueError('Truncated/oversized official manifest')
        origin={'method':'LIVE_OFFICIAL_HTTPS','status':200}
    except urllib.error.HTTPError as error:
        if error.code!=403:raise
        # Permitted owner browser download, not a Cloudflare/TLS workaround.
        # Require actual macOS origin metadata on BOTH completed files.
        browser_origin(checksums,MANIFEST_URL);browser_origin(package,PACKAGE_URL)
        raw=checksums.read_bytes()
        if len(raw)>1024*1024:raise ValueError('Oversized official manifest')
        origin={'method':'OFFICIAL_BROWSER_DOWNLOAD_METADATA','automated_HTTP_status':403,
                'scope':'Downloaded file-origin metadata, not a cryptographic origin signature'}
    if raw!=checksums.read_bytes():raise ValueError('Local manifest differs from full official download')
    entries=parse_manifest(raw.decode('utf-8'))
    if package.name!=PACKAGE or package.is_symlink()or sha(package)!=entries[PACKAGE]:raise ValueError('Actual official DMG hash mismatch')
    image_info=plistlib.loads(subprocess.check_output(['/usr/bin/hdiutil','imageinfo','-plist',str(package)]))
    images=plistlib.loads(subprocess.check_output(['/usr/bin/hdiutil','info','-plist']))
    matches=[i for i in images.get('images',[])if Path(i.get('image-path','')).resolve()==package.resolve()]
    if len(matches)!=1 or matches[0].get('writeable')is not False:raise ValueError('Verified package must already be mounted read-only; this tool never mounts it')
    mounts=[Path(e['mount-point'])for e in matches[0].get('system-entities',[])if e.get('mount-point')]
    if not any(mounted_app.resolve().is_relative_to(p.resolve())for p in mounts):raise ValueError('Source app is not inside that verified mounted package')
    source=assess_app(mounted_app);installed=assess_app(installed_app)
    source_hash,source_bytes=tree_digest(mounted_app);installed_hash,installed_bytes=tree_digest(installed_app)
    if source_hash!=installed_hash:raise ValueError('Separate installed app differs from the verified package contents')
    binary=installed_app/'Contents/MacOS/Blender'
    version=command([str(binary),'--version']).splitlines()[0]
    if version!='Blender 4.0.2':raise ValueError('Exact source-compatible4.0.2 required')
    return {'schema':SCHEMA,'PASS':True,'official_manifest_url':MANIFEST_URL,
            'official_download_origin_evidence':origin,
            'manifest_path':str(checksums.resolve()),'manifest_sha256':sha(checksums),'full_manifest_entries':len(entries),
            'package_path':str(package.resolve()),'package_sha256':entries[PACKAGE],'download_package_bytes':package.stat().st_size,
            'installed_app':str(installed_app.resolve()),'installed_binary':str(binary.resolve()),'binary_sha256':sha(binary),
            'application_tree_sha256':installed_hash,'expanded_application_logical_bytes':installed_bytes,
            'expanded_source_app_allocated_KiB':int(command(['/usr/bin/du','-sk',str(mounted_app)]).split()[0]),
            'package_image_size_metadata':image_info.get('Size Information',{}),
            'exact_version':version,'source_code_signature':source,'installed_code_signature':installed,
            'installation_peak_measured':False,'installation_peak_bytes':None,
            'installation_scope':'Audit performs no copy/install; actual installation peak still requires separate measurement/preflight',
            'audit_tool_sha256':sha(Path(__file__)),'original_331_preserved':True}


def verify_audit(path,binary,probe_version=True):
    path=Path(path)
    info=path.stat()
    if path.is_symlink()or info.st_uid!=os.geteuid()or stat.S_IMODE(info.st_mode)&0o077:
        raise ValueError('Official producer audit must be owner-only, not a symlink')
    record=json.loads(path.read_text())
    if record.get('schema')!=SCHEMA or record.get('PASS')is not True or record.get('official_manifest_url')!=MANIFEST_URL or record.get('audit_tool_sha256')!=sha(Path(__file__)):
        raise ValueError('Missing/current official producer audit required')
    if Path(record['installed_binary']).resolve()!=Path(binary).resolve():raise ValueError('Producer binary differs from audited app')
    manifest=Path(record['manifest_path']);package=Path(record['package_path']);app=Path(record['installed_app'])
    origin=record.get('official_download_origin_evidence',{})
    if origin.get('method')=='OFFICIAL_BROWSER_DOWNLOAD_METADATA':
        browser_origin(manifest,MANIFEST_URL);browser_origin(package,PACKAGE_URL)
    elif origin.get('method')!='LIVE_OFFICIAL_HTTPS' or origin.get('status')!=200:
        raise ValueError('Official download-origin evidence missing')
    if sha(manifest)!=record['manifest_sha256']or parse_manifest(manifest.read_text())[PACKAGE]!=record['package_sha256']or sha(package)!=record['package_sha256']:
        raise ValueError('Official package/manifest provenance changed')
    if sha(binary)!=record['binary_sha256']or tree_digest(app)[0]!=record['application_tree_sha256']:
        raise ValueError('Audited producer app changed')
    assess_app(app)
    if probe_version and command([str(binary),'--version']).splitlines()[0]!='Blender 4.0.2':raise ValueError('Audited producer version changed')
    return record


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ['package','checksums','mounted-app','installed-app','output']:parser.add_argument('--'+name,required=True,type=Path)
    args=parser.parse_args()
    if args.output.exists()or args.output.resolve().is_relative_to(ROOT):parser.error('Use a new private receipt outside public Git')
    record=audit(args.package,args.checksums,args.mounted_app,args.installed_app)
    descriptor=os.open(args.output,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(descriptor,'w')as stream:stream.write(json.dumps(record,indent=2)+'\n')
    print('Official audit saved privately. No download/install/production performed.')
