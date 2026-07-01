/** Milestone 4 production versus stages — exactly three. */
export type ProductionStageId = "training-grid" | "skyline-arena" | "neon-rooftops";

export type ProductionStageMeta = {
  id: ProductionStageId;
  name: string;
  stageType: "flat" | "threePlatform" | "casual";
  description: string;
  layoutDescription: string;
};

export const PRODUCTION_STAGES: ProductionStageMeta[] = [
  {
    id: "training-grid",
    name: "Training Grid",
    stageType: "flat",
    description: "Flat practice floor with clean blast zones.",
    layoutDescription: "Single main platform, no floating platforms.",
  },
  {
    id: "skyline-arena",
    name: "Skyline Arena",
    stageType: "threePlatform",
    description: "Classic three-platform duel stage.",
    layoutDescription: "Main floor plus side platforms and center high platform.",
  },
  {
    id: "neon-rooftops",
    name: "Neon Rooftops",
    stageType: "casual",
    description: "Casual city rooftop with asymmetric platforms.",
    layoutDescription: "Wide main roof, offset catwalks, and a neon sign perch.",
  },
];

const STAGE_IDS = new Set(PRODUCTION_STAGES.map((s) => s.id));

export function isProductionStageId(id: string): id is ProductionStageId {
  return STAGE_IDS.has(id as ProductionStageId);
}

export function getProductionStageMeta(id: string): ProductionStageMeta | undefined {
  return PRODUCTION_STAGES.find((s) => s.id === id);
}

export function listProductionStageIds(): ProductionStageId[] {
  return PRODUCTION_STAGES.map((s) => s.id);
}
