/** Unregister legacy service workers that can serve stale Godot/Pages assets. */
export async function unregisterStaleServiceWorkers(): Promise<void> {
  if (typeof navigator === "undefined" || !("serviceWorker" in navigator)) {
    return;
  }
  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  } catch {
    /* ignore — route still works without SW cleanup */
  }
}
