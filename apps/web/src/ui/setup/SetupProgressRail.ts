import { SETUP_FLOW_STEPS, type SetupFlowStep } from "../theme/arenaTheme.ts";

export function renderSetupProgressRail(current: SetupFlowStep): string {
  const order = SETUP_FLOW_STEPS.map((s) => s.id);
  const currentIdx = order.indexOf(current);

  const steps = SETUP_FLOW_STEPS.map((step, idx) => {
    const done = idx < currentIdx;
    const active = step.id === current;
    const classes = [
      "setup-progress-step",
      done ? "setup-progress-step--done" : "",
      active ? "setup-progress-step--active" : "",
    ]
      .filter(Boolean)
      .join(" ");
    const check = done ? '<span class="setup-progress-check" aria-hidden="true">✓</span>' : "";
    return `<li class="${classes}" data-step="${step.id}">${check}<span>${step.label}</span></li>`;
  }).join("");

  return `<nav class="setup-progress-rail" aria-label="Match setup progress"><ol>${steps}</ol></nav>`;
}
