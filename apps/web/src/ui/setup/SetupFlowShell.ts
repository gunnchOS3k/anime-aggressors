import type { SetupFlowStep } from "../theme/arenaTheme.ts";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";
import { renderSetupProgressRail } from "./SetupProgressRail.ts";
import { renderSetupHeader } from "./SetupHeader.ts";
import { renderSetupFooterActions, type SetupFooterOptions } from "./SetupFooterActions.ts";

export type SetupFlowShellOptions = {
  step: SetupFlowStep;
  title: string;
  subtitle?: string;
  summary?: string;
  body: string;
  footer: SetupFooterOptions;
};

export function renderSetupFlowShell(opts: SetupFlowShellOptions): string {
  return `<div class="${ARENA_CLASSES.shell}" data-setup-step="${opts.step}">
    ${renderSetupProgressRail(opts.step)}
    ${renderSetupHeader(opts.title, opts.subtitle, opts.summary)}
    <div class="setup-body">${opts.body}</div>
    ${renderSetupFooterActions(opts.footer)}
  </div>`;
}
