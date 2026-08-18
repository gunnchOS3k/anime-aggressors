# Pixel 6a session — 2026-08-18T21:15Z

**PIXEL_6A_READY = BLOCKED**

USB-C was connected. `adb devices -l` returned:

```text
27211JEGR06194         unauthorized usb:17825792X transport_id:1
```

An unauthorized session is not a device. Install, launch, logcat, orientation, and uninstall/reinstall were **not** executed.

## Owner action

Unlock the Pixel 6a, accept the USB debugging prompt, re-run `adb devices -l` until the line says `device`. Then execute `docs/PIXEL_6A_ACCEPTANCE.md`.

HUMAN_QA_PENDING remains for fun/usability even after a digital smoke pass.
