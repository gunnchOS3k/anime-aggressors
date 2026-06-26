import { evaluateMilestones, MILESTONE_DEFS } from "@anime-aggressors/game-core";
import { getCareerSummary } from "../storage/careerStorage.ts";
import { careerNav, mountScreenShell } from "./careerScreenShared.ts";

export async function mountMilestonesScreen(root: HTMLElement): Promise<void> {
  const { career, fighterStats } = await getCareerSummary();
  const earned = new Set(evaluateMilestones(career, fighterStats));

  mountScreenShell(
    root,
    { title: "Milestones", backRoute: "#/career" },
    `
      ${careerNav()}
      <ul class="milestone-grid">
        ${MILESTONE_DEFS.map(
          (m) => `
          <li class="milestone-card ${earned.has(m.id) ? "earned" : "locked"}">
            <h3>${m.title}</h3>
            <p>${m.description}</p>
            <span>${earned.has(m.id) ? "✓ Earned" : "Locked"}</span>
          </li>
        `,
        ).join("")}
      </ul>
    `,
  );
}
