/** Markers that identify the static placeholder page (not a Godot Web export). */
export const GODOT_PLACEHOLDER_MARKERS = [
  "AA_GODOT_PLACEHOLDER",
  "No export artifact is checked in yet",
  "Placeholder export page",
  "Godot CLI not installed",
  "This folder hosts the",
] as const;

export type GodotExportStatus = "ready" | "missing" | "placeholder" | "manifest-missing";

export type GodotBuildManifest = {
  buildId: string;
  commit: string;
  generatedAt: string;
  bootPath: string;
  runtimePath: string;
  rescueRuntimePath: string;
};

export function shortCommitSha(commit: string): string {
  return commit.slice(0, 7);
}

export function godotBootPath(manifest: GodotBuildManifest, baseUrl?: string): string {
  const boot = manifest.bootPath || "index.html";
  return `${godotPublicBase(baseUrl)}${boot}?v=${manifest.buildId}`;
}

export function godotPublicBase(baseUrl = import.meta.env.BASE_URL ?? "/"): string {
  const base = baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;
  return `${base}godot/`;
}

export function godotIndexPath(baseUrl = import.meta.env.BASE_URL ?? "/"): string {
  return `${godotPublicBase(baseUrl)}index.html`;
}

export function godotManifestPath(baseUrl = import.meta.env.BASE_URL ?? "/"): string {
  return `${godotPublicBase(baseUrl)}build-manifest.json`;
}

export function versionedGodotIndexPath(manifest: GodotBuildManifest, baseUrl?: string): string {
  return godotBootPath(manifest, baseUrl);
}

export function classifyGodotExportHtml(html: string): GodotExportStatus {
  if (!html || html.trim().length === 0) {
    return "missing";
  }
  for (const marker of GODOT_PLACEHOLDER_MARKERS) {
    if (html.includes(marker)) {
      return "placeholder";
    }
  }
  const looksLikeBootShell =
    html.includes("runtime/") &&
    html.includes("rescue-runtime.js") &&
    (html.includes("AARescueRuntime") || /rescue runtime/i.test(html));
  if (looksLikeBootShell) {
    return "ready";
  }
  const looksLikeGodot =
    html.includes(".wasm") ||
    html.includes(".pck") ||
    html.includes("createEngine") ||
    html.includes("EngineConfig") ||
    html.includes("godot_js") ||
    html.includes("new Engine(");
  if (!looksLikeGodot) {
    return "placeholder";
  }
  return "ready";
}

export async function fetchGodotBuildManifest(
  baseUrl?: string,
): Promise<GodotBuildManifest | null> {
  const url = `${godotManifestPath(baseUrl)}?ts=${Date.now()}`;
  try {
    const res = await fetch(url, { method: "GET", cache: "no-store" });
    if (!res.ok) {
      return null;
    }
    const data = (await res.json()) as GodotBuildManifest;
    if (!data?.buildId || !data?.runtimePath) {
      return null;
    }
    if (!data.bootPath) {
      data.bootPath = "index.html";
    }
    return data;
  } catch {
    return null;
  }
}

export async function probeGodotExport(baseUrl?: string): Promise<GodotExportStatus> {
  const manifest = await fetchGodotBuildManifest(baseUrl);
  if (!manifest) {
    return "manifest-missing";
  }
  const url = versionedGodotIndexPath(manifest, baseUrl);
  try {
    const res = await fetch(url, { method: "GET", cache: "no-store" });
    if (!res.ok) {
      return "missing";
    }
    const html = await res.text();
    return classifyGodotExportHtml(html);
  } catch {
    return "missing";
  }
}
