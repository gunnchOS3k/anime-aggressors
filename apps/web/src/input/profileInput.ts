import type { InputFrame } from "./inputFrame.ts";
import { emptyInputFrame } from "./inputFrame.ts";
import type { GameAction } from "./actions.ts";
import type { InputProfile } from "./inputProfiles.ts";
import { isBindingActive } from "./inputBindings.ts";

export type ResolvedActions = Partial<Record<GameAction, boolean>>;

export function resolveProfileActions(
  profile: InputProfile,
  keyboard: ReadonlySet<string>,
  gamepad: { buttons: boolean[]; axes: number[] } | null,
  edgeGesture?: string,
): ResolvedActions {
  const actions: ResolvedActions = {};
  for (const [action, binding] of Object.entries(profile.bindings) as [GameAction, NonNullable<InputProfile["bindings"][GameAction]>][]) {
    if (!binding) continue;
    actions[action] = isBindingActive(binding, keyboard, gamepad, profile.deadzone, edgeGesture);
  }
  if (profile.tapJumpEnabled) {
    if (actions.moveUp) actions.jump = true;
  }
  return actions;
}

export function actionsToInputFrame(
  frame: number,
  playerId: number,
  actions: ResolvedActions,
): InputFrame {
  const base = emptyInputFrame(frame, playerId);
  return {
    ...base,
    left: !!actions.moveLeft,
    right: !!actions.moveRight,
    up: !!actions.moveUp,
    down: !!actions.moveDown,
    jump: !!actions.jump,
    attack: !!actions.attack,
    special: !!actions.special,
    shield: !!actions.shield,
    dodge: !!actions.dodge,
    grab: !!actions.grab,
  };
}

export function profileToInputFrame(
  frame: number,
  playerId: number,
  profile: InputProfile,
  keyboard: ReadonlySet<string>,
  gamepad: { buttons: boolean[]; axes: number[] } | null,
  edgeGesture?: string,
): InputFrame {
  const actions = resolveProfileActions(profile, keyboard, gamepad, edgeGesture);
  return actionsToInputFrame(frame, playerId, actions);
}

export function actionFromRawInput(
  profiles: InputProfile[],
  keyboard: ReadonlySet<string>,
  gamepad: { buttons: boolean[]; axes: number[] } | null,
  edgeGesture?: string,
): { profile: InputProfile; action: GameAction } | null {
  for (const profile of profiles) {
    const actions = resolveProfileActions(profile, keyboard, gamepad, edgeGesture);
    for (const [action, pressed] of Object.entries(actions) as [GameAction, boolean][]) {
      if (pressed) return { profile, action };
    }
  }
  return null;
}
