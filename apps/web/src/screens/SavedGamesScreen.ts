import { deleteSavedGame, listSavedGames, renameSavedGame } from "../storage/saveGameStorage.ts";
import { careerNav, mountScreenShell } from "./careerScreenShared.ts";
import { navigateTo } from "../router.ts";

export async function mountSavedGamesScreen(root: HTMLElement): Promise<void> {
  mountScreenShell(
    root,
    { title: "Saved Games", subtitle: "Local game snapshots", backRoute: "#/career" },
    `
      ${careerNav()}
      <div id="saves-list"></div>
    `,
  );

  const listEl = root.querySelector("#saves-list") as HTMLElement;

  const render = async () => {
    const saves = await listSavedGames();
    listEl.innerHTML =
      saves.length === 0
        ? "<p>No saved games yet. Save during Play Match, Flagline Clash, or Impact Dummy Derby.</p>"
        : `<ul class="career-list">${saves
            .map(
              (s) => `
              <li class="save-row" data-id="${s.id}">
                <div>
                  <strong>${s.title}</strong>
                  <span>${s.mode} · frame ${s.currentFrame}</span>
                  <span>${s.fighterNames.join(" vs ")} · ${new Date(s.updatedAt).toLocaleString()}</span>
                </div>
                <div class="row-actions">
                  <button type="button" class="btn-primary resume">Resume</button>
                  <button type="button" class="btn-secondary rename">Rename</button>
                  <button type="button" class="btn-tertiary delete">Delete</button>
                </div>
              </li>
            `,
            )
            .join("")}</ul>`;

    listEl.querySelectorAll(".resume").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = (btn.closest(".save-row") as HTMLElement).dataset.id;
        if (id) navigateTo("match", { saveId: id });
      });
    });

    listEl.querySelectorAll(".rename").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = (btn.closest(".save-row") as HTMLElement).dataset.id!;
        const title = prompt("Save title:");
        if (title) {
          await renameSavedGame(id, title);
          await render();
        }
      });
    });

    listEl.querySelectorAll(".delete").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = (btn.closest(".save-row") as HTMLElement).dataset.id!;
        await deleteSavedGame(id);
        await render();
      });
    });
  };

  await render();
}
