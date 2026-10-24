# Official local producer prerequisites

The local recipe and Blender entry point now require a private producer audit.
An executable reporting4.0.2, a filename or a `PASS=true` checkbox is insufficient.
This tool performs **no DMG download, mount, installation or source production**.
Preserve the existing3.3.1application and its configuration.

`tools/authored_animation/audit_blender_402.py` requires the completed official
ARM64DMG, full checksum manifest, its already read-only mounted source app, and
a separate side-by-side4.0.2app copy. Run it only after the safe installation
capacity assessment; this document does not authorize mounting/installing below
the reserve. Output must be a new owner-only receipt outside public Git.

It verifies:

1. Every checksum line, exact ARM64package entry, full official HTTPS manifest
   download and byte equality with the local manifest, plus actualDMGSHA256.
2. If automated retrieval still returns403, permitted official browser downloads
   can supply both files. Their actual macOS download-origin metadata must contain
   the exact officialURLs. This is file-origin evidence, **not** a cryptographic
   signature of the checksum list. No TLS checks, challenge or certificate rules
   are bypassed. HTML challenge pages are never checksums.
3. The source app is inside that exact verified image mounted read-only.
4. Source/copy AppleSiliconarchitecture, strict deep macOS code signatures and
   Gatekeeper assessment; complete file and symlink-target tree equality.
5. Exact installed version4.0.2 after those checks. The private receipt binds the
   package, manifest, app tree, executable and audit-tool hashes.

The producer rechecks the receipt and actual running Blender binary before any
source loads. Receipt validation does not ask for billing, tokens, infrastructure
or broader permissions. The prepared private Actions job remainsdisabled.

Example after prerequisites are genuinely met:

```sh
python3 tools/authored_animation/audit_blender_402.py \
  --package ABSOLUTE_OFFICIAL_DMG \
  --checksums ABSOLUTE_COMPLETE_SHA256_MANIFEST \
  --mounted-app ABSOLUTE_READ_ONLY_IMAGE_APP \
  --installed-app ABSOLUTE_SEPARATE_402_APP \
  --output ABSOLUTE_NEW_PRIVATE_AUDIT_JSON
```

Then supply that receipt with `--blender-audit` to the existing **read-only**
one-case preflight. Do not add`--execute` while any prerequisite fails.

## Unverified measurements, not completed findings

Current automated official checksumGET andDMGHEAD both return403Cloudflare
challenge. No DMG/manifest/application was downloaded or installed. The genuine
package SHA, signature, exact architecture and compatibility are not yet verified.
Actual compressed bytes, expanded app allocation and installation peak remain
unknown. The audit can report package bytes, expanded file/allocation footprint
and image metadata when available; it explicitly does **not** measure a copy/install
peak. A conservative installation forecast and measured operation peak remain
separate work.22GiB is the production minimum AFTER compatible tools are present,
not permission to install using an unknown footprint.

Nine focused synthetic audit tests pass. They test parsing, app-tree change
detection, exact browser-origin matching and fail-closed source boundaries;
they are not an actual vendor-package audit or artistic acceptance.
