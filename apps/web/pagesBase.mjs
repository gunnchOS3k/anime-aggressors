/** Project Pages keeps /anime-aggressors/. A future custom domain sets VITE_BASE_PATH=/. */
export function pagesBase(raw) {
  const value = String(raw ?? "").trim() || "/anime-aggressors/";
  const withSlash = value.endsWith("/") ? value : `${value}/`;
  if (!withSlash.startsWith("/")) {
    throw new Error("VITE_BASE_PATH must be a root-relative path");
  }
  return withSlash;
}
