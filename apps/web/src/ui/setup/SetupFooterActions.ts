import { ARENA_CLASSES } from "../theme/arenaClasses.ts";

export type SetupFooterOptions = {
  backId: string;
  backLabel: string;
  continueId?: string;
  continueLabel?: string;
  continueDisabled?: boolean;
  extraHtml?: string;
};

export function renderSetupFooterActions(opts: SetupFooterOptions): string {
  const continueBtn = opts.continueId
    ? `<button type="button" id="${opts.continueId}" class="${ARENA_CLASSES.primaryCta}" ${opts.continueDisabled ? "disabled" : ""}>${opts.continueLabel ?? "Continue"}</button>`
    : "";

  return `<footer class="setup-footer-actions">
    ${opts.extraHtml ?? ""}
    <button type="button" id="${opts.backId}" class="${ARENA_CLASSES.secondaryBtn}">${opts.backLabel}</button>
    ${continueBtn}
  </footer>`;
}
