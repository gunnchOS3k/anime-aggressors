export function renderSetupHeader(title: string, subtitle?: string, summary?: string): string {
  return `<header class="setup-header">
    <h1 class="setup-header__title">${title}</h1>
    ${subtitle ? `<p class="setup-header__subtitle">${subtitle}</p>` : ""}
    ${summary ? `<p class="setup-header__summary">${summary}</p>` : ""}
  </header>`;
}
