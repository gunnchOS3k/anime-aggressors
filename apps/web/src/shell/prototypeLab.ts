import { bootstrapMiniGames } from "../minigames/bootstrap.js";

export function mountPrototypeLab(root: HTMLElement): void {
  root.innerHTML = `
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Prototype Lab</h2>
      <p class="shell-muted">Early mechanic experiments — not the main Anime Aggressors product.</p>
    </div>
    <div id="prototype-lab-games"></div>
  `;

  root.querySelector("#shell-back")?.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("aa:navigate-home"));
  });

  const gamesRoot = root.querySelector("#prototype-lab-games") as HTMLElement;
  bootstrapMiniGames(gamesRoot);
}
