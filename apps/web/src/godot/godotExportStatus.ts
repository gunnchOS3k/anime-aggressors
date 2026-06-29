/** Markers that identify the static placeholder page (not a Godot Web export). */
export const GODOT_PLACEHOLDER_MARKERS = [
  "AA_GODOT_PLACEHOLDER",
  "No export artifact is checked in yet",
  "Placeholder export page",
  "Godot CLI not installed",
  "This folder hosts the",
] as const;

export type GodotExportStatus = "ready" | "missing" | "placeholder";

export function godotIndexPath(baseUrl = import.meta.env.BASE_URL ?? "/"): string {
  const base = baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;
  return `${base}godot/index.html`;
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
  const looksLikeGodot =
    html.includes(".wasm") ||
    html.includes(".pck") ||
    html.includes("createEngine") ||
    html.includes("EngineConfig") ||
    html.includes("godot_js");
  if (!looksLikeGodot) {
    return "placeholder";
  }
  return "ready";
}

export async function probeGodotExport(baseUrl?: string): Promise<GodotExportStatus> {
  const url = godotIndexPath(baseUrl);
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
