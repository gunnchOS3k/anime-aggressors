const DISMISS_KEY = "aa-demo-onboarding-dismissed";

export function isDemoOnboardingDismissed(): boolean {
  try {
    return localStorage.getItem(DISMISS_KEY) === "1";
  } catch {
    return false;
  }
}

export function dismissDemoOnboarding(): void {
  try {
    localStorage.setItem(DISMISS_KEY, "1");
  } catch {
    /* storage optional */
  }
}

export function resetDemoOnboarding(): void {
  try {
    localStorage.removeItem(DISMISS_KEY);
  } catch {
    /* storage optional */
  }
}

export function renderDemoOnboardingHtml(): string {
  return `<div class="demo-onboarding" data-testid="demo-onboarding" role="dialog" aria-labelledby="demo-onboarding-title">
    <div class="demo-onboarding__panel">
      <h2 id="demo-onboarding-title">Welcome to Anime Aggressors</h2>
      <p class="demo-onboarding__lead">Knock your opponent out of the arena. Higher damage means stronger knockback.</p>
      <ul class="demo-onboarding__list">
        <li><strong>Stocks:</strong> Lose all stocks and you are out.</li>
        <li><strong>Movement:</strong> Run, jump, fast-fall, and recover from ledges.</li>
        <li><strong>Attack / Special:</strong> J and K (P1) — build damage and launch rivals.</li>
        <li><strong>Shield / Grab / Dodge:</strong> L block, U grab, Shift dodge.</li>
        <li><strong>H</strong> — reopen controls overlay anytime.</li>
        <li><strong>F2</strong> — hitbox debug (developer tool only).</li>
      </ul>
      <div class="demo-onboarding__actions">
        <button type="button" id="demo-onboarding-dismiss" class="btn-primary">Got it — Fight!</button>
      </div>
    </div>
  </div>`;
}

export function mountDemoOnboarding(root: HTMLElement, onDismiss?: () => void): () => void {
  if (isDemoOnboardingDismissed()) return () => undefined;

  const host = document.createElement("div");
  host.innerHTML = renderDemoOnboardingHtml();
  const overlay = host.firstElementChild as HTMLElement;
  root.appendChild(overlay);

  const dismiss = () => {
    dismissDemoOnboarding();
    overlay.remove();
    onDismiss?.();
  };

  overlay.querySelector("#demo-onboarding-dismiss")?.addEventListener("click", dismiss);

  return () => overlay.remove();
}
