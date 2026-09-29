/**
 * Story Director — data-driven seven-route campaign (V1.5).
 * Combat launches reuse the authoritative simulation; narrative is DRAFT_NARRATIVE_COPY.
 */

import {
  SPECTRUM_STORY_FIGHTER_IDS,
  completeGrayRoute,
  normalizeEssenceTier,
  type EssenceTier,
  type StoryProgressState,
  type StoryPuppetForm,
  type StoryRouteId,
} from "./storyProgression.js";

export type StoryNodeKind =
  | "intro"
  | "combat"
  | "beat"
  | "puppet_combat"
  | "release"
  | "essence"
  | "escalation"
  | "transform"
  | "gray_finale"
  | "route_complete";

export type StoryNode = {
  id: string;
  kind: StoryNodeKind;
  title: string;
  body: string;
  /** Opponent for combat nodes */
  opponentId?: StoryRouteId;
  storyForm?: StoryPuppetForm;
  requireWin?: boolean;
  awardEssence?: EssenceTier;
  unlockGray?: boolean;
};

export type StoryRouteGraph = {
  routeId: StoryRouteId;
  isRoot: boolean;
  nodes: StoryNode[];
};

function draft(s: string): string {
  return `DRAFT_NARRATIVE_COPY: ${s}`;
}

function buildRouteGraph(routeId: StoryRouteId): StoryRouteGraph {
  const isRoot = routeId === "kaia-windrow";
  const name = routeId;
  return {
    routeId,
    isRoot,
    nodes: [
      {
        id: `${routeId}:intro`,
        kind: "intro",
        title: isRoot ? "Root Current" : `${name} Perspective`,
        body: draft(`You step onto the ${name} path. Listen before you strike.`),
      },
      {
        id: `${routeId}:combat1`,
        kind: "combat",
        title: "First Encounter",
        body: draft(`Face a reflection of ${name} in normal form.`),
        opponentId: routeId,
        storyForm: "NORMAL",
        requireWin: true,
      },
      {
        id: `${routeId}:beat1`,
        kind: "beat",
        title: "Aftershock",
        body: draft("The ally's essence flickers. Something else wears their silhouette."),
      },
      {
        id: `${routeId}:puppet_black`,
        kind: "puppet_combat",
        title: "Black Puppet",
        body: draft("Secondary motion collapses inward. Break the black mask without losing the person."),
        opponentId: routeId,
        storyForm: "BLACK_PUPPET",
        requireWin: true,
      },
      {
        id: `${routeId}:release_black`,
        kind: "release",
        title: "Release",
        body: draft("The black puppet loosens. A white seed of self remains."),
      },
      {
        id: `${routeId}:puppet_white`,
        kind: "puppet_combat",
        title: "White Puppet",
        body: draft("Exact trajectories overwrite identity. Leave one dark imperfect truth."),
        opponentId: routeId,
        storyForm: "WHITE_PUPPET",
        requireWin: true,
      },
      {
        id: `${routeId}:essence`,
        kind: "essence",
        title: "Essence",
        body: draft("You keep what you refused to erase."),
        awardEssence: undefined, // computed by director from route count
      },
      {
        id: `${routeId}:escalation`,
        kind: "escalation",
        title: "Escalation",
        body: draft("The path densifies. One more fight under rising Essence."),
        opponentId: routeId,
        storyForm: "NORMAL",
        requireWin: true,
      },
      {
        id: `${routeId}:transform`,
        kind: "transform",
        title: "Prismatic Approach",
        body: draft("Colors refuse dominance. Graphite waits beneath the spectrum."),
      },
      {
        id: `${routeId}:gray_finale`,
        kind: "gray_finale",
        title: "Prismatic Gray",
        body: draft("Fight as / against the Gray refraction of this route."),
        opponentId: routeId,
        storyForm: "NORMAL",
        requireWin: true,
        unlockGray: true,
      },
      {
        id: `${routeId}:complete`,
        kind: "route_complete",
        title: "Route Complete",
        body: draft(`${name} Gray route sealed. Seven seals unlock Yin and Yang.`),
      },
    ],
  };
}

export const STORY_ROUTE_GRAPHS: Record<StoryRouteId, StoryRouteGraph> = Object.fromEntries(
  SPECTRUM_STORY_FIGHTER_IDS.map((id) => [id, buildRouteGraph(id)]),
) as Record<StoryRouteId, StoryRouteGraph>;

export type StoryDirectorState = StoryProgressState & {
  schema: "story_progress_v1_5" | "story_progress_v1_3";
  activeNodeId: string | null;
  completedNodeIds: string[];
  pendingRetryNodeId: string | null;
};

export function migrateStoryProgress(raw: unknown): StoryDirectorState {
  const base = (raw ?? {}) as Partial<StoryDirectorState>;
  const fromV13 = base as StoryProgressState;
  const routes = fromV13.routes ?? ({} as StoryProgressState["routes"]);
  // Ensure all routes exist
  const initialRoutes = { ...routes };
  for (const id of SPECTRUM_STORY_FIGHTER_IDS) {
    if (!initialRoutes[id]) {
      initialRoutes[id] = {
        routeId: id,
        isRoot: id === "kaia-windrow",
        completed: false,
        grayFormUnlocked: false,
        draftTitle: id,
        draftSummary: draft("migrated"),
      };
    }
  }
  return {
    schema: "story_progress_v1_5",
    activeRouteId: fromV13.activeRouteId ?? "kaia-windrow",
    essenceCount: normalizeEssenceTier(fromV13.essenceCount ?? 0),
    puppetForm: fromV13.puppetForm ?? "NORMAL",
    grayRoutesCompleted: [...(fromV13.grayRoutesCompleted ?? [])],
    yinUnlocked: !!fromV13.yinUnlocked,
    yangUnlocked: !!fromV13.yangUnlocked,
    cosmicDevOverride: !!fromV13.cosmicDevOverride,
    routes: initialRoutes,
    activeNodeId: base.activeNodeId ?? `${fromV13.activeRouteId ?? "kaia-windrow"}:intro`,
    completedNodeIds: [...(base.completedNodeIds ?? [])],
    pendingRetryNodeId: base.pendingRetryNodeId ?? null,
  };
}

export function getActiveNode(state: StoryDirectorState): StoryNode | null {
  if (!state.activeRouteId || !state.activeNodeId) return null;
  const graph = STORY_ROUTE_GRAPHS[state.activeRouteId];
  return graph.nodes.find((n) => n.id === state.activeNodeId) ?? null;
}

export function startRoute(state: StoryDirectorState, routeId: StoryRouteId): StoryDirectorState {
  const first = STORY_ROUTE_GRAPHS[routeId].nodes[0]!;
  return {
    ...state,
    activeRouteId: routeId,
    activeNodeId: first.id,
    pendingRetryNodeId: null,
    puppetForm: "NORMAL",
  };
}

export function advanceAfterWin(state: StoryDirectorState): StoryDirectorState {
  if (!state.activeRouteId || !state.activeNodeId) return state;
  const graph = STORY_ROUTE_GRAPHS[state.activeRouteId];
  const idx = graph.nodes.findIndex((n) => n.id === state.activeNodeId);
  if (idx < 0) return state;
  const node = graph.nodes[idx]!;
  let next: StoryDirectorState = {
    ...state,
    completedNodeIds: state.completedNodeIds.includes(node.id)
      ? state.completedNodeIds
      : [...state.completedNodeIds, node.id],
    pendingRetryNodeId: null,
  };
  if (node.unlockGray) {
    const progressed = completeGrayRoute(next, state.activeRouteId);
    next = {
      ...progressed,
      schema: "story_progress_v1_5",
      activeNodeId: next.activeNodeId,
      completedNodeIds: next.completedNodeIds,
      pendingRetryNodeId: null,
    };
  }
  if (node.kind === "essence") {
    const earned = Math.max(next.essenceCount, next.grayRoutesCompleted.length);
    next = { ...next, essenceCount: normalizeEssenceTier(earned) };
  }
  if (node.storyForm) {
    next = { ...next, puppetForm: "NORMAL" }; // release after puppet win
  }
  const nextNode = graph.nodes[idx + 1];
  if (!nextNode) {
    return { ...next, activeNodeId: null };
  }
  return {
    ...next,
    activeNodeId: nextNode.id,
    puppetForm: nextNode.storyForm ?? next.puppetForm,
  };
}

export function recordLoss(state: StoryDirectorState): StoryDirectorState {
  return {
    ...state,
    pendingRetryNodeId: state.activeNodeId,
  };
}

export function encounterConfig(state: StoryDirectorState): {
  playerHint: string;
  opponentId: StoryRouteId;
  storyForm: StoryPuppetForm;
  essenceTier: EssenceTier;
  prismaticGray: boolean;
} | null {
  const node = getActiveNode(state);
  if (!node || (node.kind !== "combat" && node.kind !== "puppet_combat" && node.kind !== "escalation" && node.kind !== "gray_finale")) {
    return null;
  }
  return {
    playerHint: "story-player",
    opponentId: node.opponentId ?? (state.activeRouteId as StoryRouteId),
    storyForm: node.storyForm ?? state.puppetForm,
    essenceTier: state.essenceCount,
    prismaticGray: node.kind === "gray_finale" || state.essenceCount === 6,
  };
}
