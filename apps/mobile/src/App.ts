/** Mobile companion scaffold — not in CI quality gate. */
export type CompanionScreen = "home" | "controller" | "status";

export function getCompanionScreens(): CompanionScreen[] {
  return ["home", "controller", "status"];
}
