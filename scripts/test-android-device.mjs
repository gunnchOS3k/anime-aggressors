#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const apkPath = path.join(root, "builds/android/anime-aggressors-debug.apk");
const packageName = "com.gunnchos.animeaggressors";
const sdk = process.env.ANDROID_SDK_ROOT
  ?? process.env.ANDROID_HOME
  ?? path.join(os.homedir(), "Library", "Android", "sdk");
const adb = path.join(sdk, "platform-tools", process.platform === "win32" ? "adb.exe" : "adb");

function run(args, options = {}) {
  return execFileSync(adb, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], ...options }).trim();
}

if (!fs.existsSync(adb)) {
  console.error(`adb not found at ${adb}`);
  process.exit(2);
}
if (!fs.existsSync(apkPath)) {
  console.error(`APK not found: ${apkPath}. Run npm run godot:export:android first.`);
  process.exit(2);
}

const lines = run(["devices", "-l"]).split(/\r?\n/).slice(1).filter(Boolean);
const unauthorized = lines.filter((line) => /\tunauthorized\b/.test(line));
const devices = lines.filter((line) => /\tdevice\b/.test(line));
if (unauthorized.length) {
  console.error("Android device is connected but unauthorized. Unlock it and accept the USB-debugging prompt.");
  process.exit(3);
}
if (devices.length !== 1) {
  console.error(`Expected exactly one authorized Android device; found ${devices.length}.`);
  console.error("Enable Developer options + USB debugging, use a data-capable USB cable, then run adb devices -l.");
  process.exit(3);
}

console.log(devices[0]);
console.log(run(["install", "-r", "-t", apkPath]));
run(["logcat", "-c"]);
console.log(run(["shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1"]));
await new Promise((resolve) => setTimeout(resolve, 4000));
const pid = run(["shell", "pidof", packageName]);
if (!pid) {
  console.error("App did not remain running after launch.");
  console.error(run(["logcat", "-d", "-t", "200", "AndroidRuntime:E", "Godot:E", "*:S"]));
  process.exit(1);
}
console.log(`Android smoke test passed; ${packageName} is running as PID ${pid}.`);
