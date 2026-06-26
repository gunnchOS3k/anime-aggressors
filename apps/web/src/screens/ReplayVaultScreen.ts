import { deleteReplay, listReplays, renameReplay } from "../storage/replayStorage.ts";
import { downloadReplay } from "../replay/replayExport.ts";
import { importReplayFromFile } from "../replay/replayImport.ts";
import { careerNav, formatPlaytime, mountScreenShell } from "./careerScreenShared.ts";
import { navigateTo } from "../router.ts";

export async function mountReplayVaultScreen(root: HTMLElement): Promise<void> {
  mountScreenShell(
    root,
    { title: "Replay Vault", subtitle: "Deterministic match replays", backRoute: "#/career" },
    `
      ${careerNav()}
      <div class="vault-actions">
        <label class="btn-secondary">Import Replay <input type="file" id="import-replay" accept="application/json,.json" hidden /></label>
      </div>
      <div id="replay-list"></div>
    `,
  );

  const listEl = root.querySelector("#replay-list") as HTMLElement;
  const importInput = root.querySelector("#import-replay") as HTMLInputElement;

  const render = async () => {
    const replays = await listReplays();
    listEl.innerHTML =
      replays.length === 0
        ? "<p>No replays saved yet. Complete a match with replay recording enabled.</p>"
        : `<ul class="career-list">${replays
            .map(
              (r) => `
              <li class="replay-row" data-id="${r.id}">
                <div>
                  <strong>${r.title}</strong>
                  <span>${r.mode} · ${new Date(r.createdAt).toLocaleString()} · ${formatPlaytime(r.durationFrames)}</span>
                  <span>${r.fighterNames.join(" vs ")} · hash ${r.finalStateHash}</span>
                </div>
                <div class="row-actions">
                  <button type="button" class="btn-primary watch">Watch</button>
                  <button type="button" class="btn-secondary rename">Rename</button>
                  <button type="button" class="btn-secondary export">Export</button>
                  <button type="button" class="btn-tertiary delete">Delete</button>
                </div>
              </li>
            `,
            )
            .join("")}</ul>`;

    listEl.querySelectorAll(".watch").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = (btn.closest(".replay-row") as HTMLElement).dataset.id;
        if (id) navigateTo("replay", { id });
      });
    });

    listEl.querySelectorAll(".rename").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const row = btn.closest(".replay-row") as HTMLElement;
        const id = row.dataset.id!;
        const title = prompt("Replay title:");
        if (title) {
          await renameReplay(id, title);
          await render();
        }
      });
    });

    listEl.querySelectorAll(".export").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = (btn.closest(".replay-row") as HTMLElement).dataset.id!;
        const replays = await listReplays();
        const record = replays.find((r) => r.id === id);
        if (record) downloadReplay(record);
      });
    });

    listEl.querySelectorAll(".delete").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = (btn.closest(".replay-row") as HTMLElement).dataset.id!;
        await deleteReplay(id);
        await render();
      });
    });
  };

  importInput?.addEventListener("change", async () => {
    const file = importInput.files?.[0];
    if (file) {
      await importReplayFromFile(file);
      importInput.value = "";
      await render();
    }
  });

  await render();
}
