import { listCharacters } from "@anime-aggressors/game-core";

export type CharacterSelectResult = {
  p1CharacterId: string;
  p2CharacterId: string;
};

export function showCharacterSelect(
  root: HTMLElement,
  onStart: (result: CharacterSelectResult) => void,
): void {
  const chars = listCharacters();

  root.innerHTML = `
    <div class="vs-select">
      <h2>Select Fighters</h2>
      <div class="vs-select-row">
        <div class="vs-select-col">
          <h3>Player 1</h3>
          ${chars.map((c) => `<button type="button" class="vs-char-btn" data-player="0" data-id="${c.id}" style="border-color:${c.color}">${c.name}</button>`).join("")}
        </div>
        <div class="vs-select-col">
          <h3>Player 2</h3>
          ${chars.map((c) => `<button type="button" class="vs-char-btn" data-player="1" data-id="${c.id}" style="border-color:${c.color}">${c.name}</button>`).join("")}
        </div>
      </div>
      <button id="vs-start" type="button" disabled>Start Match</button>
    </div>
  `;

  const picks: string[] = ["ember", "tide"];
  const startBtn = root.querySelector("#vs-start") as HTMLButtonElement;

  root.querySelectorAll(".vs-char-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const el = btn as HTMLButtonElement;
      const player = Number(el.dataset.player);
      const id = el.dataset.id!;
      picks[player] = id;

      root.querySelectorAll(`.vs-char-btn[data-player="${player}"]`).forEach((b) => {
        b.classList.remove("selected");
      });
      el.classList.add("selected");
      startBtn.disabled = false;
    });
  });

  startBtn.addEventListener("click", () => {
    onStart({ p1CharacterId: picks[0], p2CharacterId: picks[1] });
  });
}
