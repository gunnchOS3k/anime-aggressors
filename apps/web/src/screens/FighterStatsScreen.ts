import { listFighterStats } from "../storage/careerStorage.ts";
import { listCreatedFighters } from "../storage/createdFightersStorage.ts";
import { ELEMENTS } from "@anime-aggressors/game-core";
import { careerNav, formatPlaytime, mountScreenShell } from "./careerScreenShared.ts";

export async function mountFighterStatsScreen(root: HTMLElement): Promise<void> {
  const stats = await listFighterStats();
  const created = listCreatedFighters();
  const allFighters = [
    ...created.map((f) => ({
      id: f.id,
      name: f.name,
      size: f.size,
      color: f.color,
      elementName: ELEMENTS[f.color]?.name ?? "Unknown",
    })),
  ];

  const statMap = new Map(stats.map((s) => [s.fighterId, s]));

  mountScreenShell(
    root,
    { title: "Fighter Stats", subtitle: "Per-fighter progression", backRoute: "#/career" },
    `
      ${careerNav()}
      <div class="filter-row">
        <label>Filter size <select id="filter-size"><option value="all">All</option><option value="small">Small</option><option value="medium">Medium</option><option value="large">Large</option></select></label>
        <label>Filter color <select id="filter-color"><option value="all">All</option><option value="red">Red</option><option value="orange">Orange</option><option value="yellow">Yellow</option><option value="green">Green</option><option value="blue">Blue</option><option value="indigo">Indigo</option><option value="violet">Violet</option></select></label>
      </div>
      <div id="fighter-stats-list"></div>
    `,
  );

  const listEl = root.querySelector("#fighter-stats-list") as HTMLElement;
  const sizeFilter = root.querySelector("#filter-size") as HTMLSelectElement;
  const colorFilter = root.querySelector("#filter-color") as HTMLSelectElement;

  const render = () => {
    const size = sizeFilter.value;
    const color = colorFilter.value;
    const rows = allFighters.filter((f) => {
      if (size !== "all" && f.size !== size) return false;
      if (color !== "all" && f.color !== color) return false;
      return true;
    });

    listEl.innerHTML =
      rows.length === 0
        ? "<p>No fighters match filters.</p>"
        : `<div class="fighter-stats-grid">${rows
            .map((f) => {
              const s = statMap.get(f.id);
              return `
                <article class="fighter-stat-card">
                  <h3>${f.name}</h3>
                  <p>${f.size} · ${f.elementName}</p>
                  <ul>
                    <li>Matches: ${s?.matchesPlayed ?? 0}</li>
                    <li>W/L: ${s?.wins ?? 0}/${s?.losses ?? 0}</li>
                    <li>Playtime: ${formatPlaytime(s?.playtimeFrames ?? 0)}</li>
                    <li>KOs: ${s?.kos ?? 0} · Falls: ${s?.falls ?? 0}</li>
                    <li>Damage: ${s?.damageDealt ?? 0} dealt / ${s?.damageTaken ?? 0} taken</li>
                    <li>Accuracy: ${s?.hitAccuracy ?? 0}%</li>
                    <li>Specials: ${s?.specialsUsed ?? 0}</li>
                    <li>Derby best: ${s?.derbyBestDistance ?? 0} dist / ${s?.derbyBestScore ?? 0} score</li>
                    <li>Flagline captures: ${s?.flaglineCoresCaptured ?? 0}</li>
                  </ul>
                </article>
              `;
            })
            .join("")}</div>`;
  };

  sizeFilter.addEventListener("change", render);
  colorFilter.addEventListener("change", render);
  render();
}
