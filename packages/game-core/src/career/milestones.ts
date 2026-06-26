import type { CareerProfile, FighterCareerStats } from "./types.js";

export type MilestoneId =
  | "first-ko"
  | "first-win"
  | "first-flagline-capture"
  | "first-derby-launch"
  | "kos-100"
  | "matches-10-one-fighter"
  | "win-each-size"
  | "win-each-element";

export type MilestoneDef = {
  id: MilestoneId;
  title: string;
  description: string;
};

export const MILESTONE_DEFS: MilestoneDef[] = [
  { id: "first-ko", title: "First KO", description: "Score your first knockout." },
  { id: "first-win", title: "First Match Win", description: "Win your first match." },
  {
    id: "first-flagline-capture",
    title: "First Flagline Capture",
    description: "Capture a Flag Core in Flagline Clash.",
  },
  {
    id: "first-derby-launch",
    title: "First Derby Launch",
    description: "Complete an Impact Dummy Derby launch.",
  },
  { id: "kos-100", title: "100 Total KOs", description: "Reach 100 career KOs." },
  {
    id: "matches-10-one-fighter",
    title: "Dedicated Fighter",
    description: "Play 10 matches with one fighter.",
  },
  {
    id: "win-each-size",
    title: "Size Spectrum",
    description: "Win with small, medium, and large fighters.",
  },
  {
    id: "win-each-element",
    title: "Element Master",
    description: "Win with each element color.",
  },
];

export function evaluateMilestones(
  career: CareerProfile,
  fighterStats: FighterCareerStats[],
): MilestoneId[] {
  const earned: MilestoneId[] = [];

  if (career.totalKOs >= 1) earned.push("first-ko");
  if (career.totalWins >= 1) earned.push("first-win");
  if (career.totalKOs >= 100) earned.push("kos-100");

  const totalCaptures = fighterStats.reduce((s, f) => s + f.flaglineCoresCaptured, 0);
  if (totalCaptures >= 1) earned.push("first-flagline-capture");

  const derbyLaunches = fighterStats.some((f) => f.derbyBestDistance > 0);
  if (derbyLaunches) earned.push("first-derby-launch");

  if (fighterStats.some((f) => f.matchesPlayed >= 10)) earned.push("matches-10-one-fighter");

  const wonSizes = new Set(
    fighterStats.filter((f) => f.wins > 0).map((f) => f.size),
  );
  if (wonSizes.has("small") && wonSizes.has("medium") && wonSizes.has("large")) {
    earned.push("win-each-size");
  }

  const wonColors = new Set(
    fighterStats.filter((f) => f.wins > 0).map((f) => f.color),
  );
  if (wonColors.size >= 7) earned.push("win-each-element");

  return earned;
}
