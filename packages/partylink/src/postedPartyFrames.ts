import type { PartySimInput } from "./hostAuthoritativeParty.js";
import type { PartyRoomSession } from "./partyRoom.js";
import type { ControllerInput } from "./types.js";

/**
 * Map a posted controller payload into the host frame.
 * grab is the posted semantic bit. stepState does not resolve combat from it.
 */
export function partySimInputsFromControllerInputs(
  batch: ControllerInput[],
  frameNumber: number,
): PartySimInput[] {
  return batch.map((i) => ({
    seatIndex: i.seatIndex,
    sequence: i.sequence,
    frame: {
      frame: frameNumber,
      playerId: i.seatIndex,
      left: Boolean(i.semantic.left ?? i.semantic.steerLeft),
      right: Boolean(i.semantic.right ?? i.semantic.steerRight),
      up: Boolean(i.semantic.up),
      down: Boolean(i.semantic.down),
      jump: Boolean(i.semantic.jump),
      attack: Boolean(i.semantic.attack),
      special: Boolean(i.semantic.special),
      shield: Boolean(i.semantic.shield),
      dodge: Boolean(i.semantic.dodge),
      grab: Boolean(i.semantic.grab),
    },
  }));
}

/** Drain inputs accepted from the other client and record the host frame. */
export function consumePostedPartyFrames(
  session: PartyRoomSession,
  frameNumber: number,
  extra: ControllerInput[] = [],
): PartySimInput[] {
  const inputs = partySimInputsFromControllerInputs(
    [...session.drainPendingInputs(), ...extra],
    frameNumber,
  );
  session.noteServedInputs(inputs);
  return inputs;
}
