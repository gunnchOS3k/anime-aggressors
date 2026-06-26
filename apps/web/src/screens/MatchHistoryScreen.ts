import { deleteMatchHistory, listMatchHistory } from "../storage/careerStorage.ts";
import { careerNav, formatPlaytime, mountScreenShell } from "./careerScreenShared.ts";
import { navigateTo } from "../router.ts";

export async function mountMatchHistoryScreen(root: HTMLElement): Promise<void> {
  const matches = await listMatchHistory();

  mountScreenShell(
    root,
    { title: "Match History", backRoute: "#/career" },
    `
      ${careerNav()}
      <div id="match-history-list"></div>
    `,
  );

  const listEl = root.querySelector("#match-history-list") as HTMLElement;

  const render = async () => {
    const rows = await listMatchHistory();
    listEl.innerHTML =
      rows.length === 0
        ? "<p>No matches yet. Complete a match to see history.</p>"
        : `<ul class="career-list match-history">${rows
            .map((m) => {
              const winner =
                m.winnerPlayerId !== undefined
                  ? m.players.find((p) => p.playerId === m.winnerPlayerId)?.fighterName
                  : m.winningTeam ?? "Draw";
              const fighters = m.players.map((p) => p.fighterName).join(" vs ");
              const kos = m.players.reduce((s, p) => s + p.kos, 0);
              return `
                <li class="match-row" data-id="${m.id}">
                  <div>
                    <strong>${new Date(m.endedAt).toLocaleString()}</strong>
                    <span>${m.mode} · ${m.stageName}</span>
                    <span>Winner: ${winner} · ${formatPlaytime(m.durationFrames)} · ${kos} KOs</span>
                    <span>${fighters}</span>
                  </div>
                  <div class="row-actions">
                    ${m.replayId ? `<button type="button" class="btn-secondary watch-replay" data-replay="${m.replayId}">Watch Replay</button>` : ""}
                    <button type="button" class="btn-tertiary delete-match">Delete</button>
                  </div>
                </li>
              `;
            })
            .join("")}</ul>`;

    listEl.querySelectorAll(".watch-replay").forEach((btn) => {
      btn.addEventListener("click", () => {
        const replayId = (btn as HTMLElement).dataset.replay;
        if (replayId) navigateTo("replay", { id: replayId });
      });
    });

    listEl.querySelectorAll(".delete-match").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = (btn.closest(".match-row") as HTMLElement).dataset.id;
        if (id) {
          await deleteMatchHistory(id);
          await render();
        }
      });
    });
  };

  await render();
}
