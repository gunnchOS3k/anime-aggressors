# Input System

**Scope:** `apps/web/src/input/*`, `packages/edgeio/src/inputMapper.ts`  
**Boundary:** Simulation accepts only `InputFrame` from `@anime-aggressors/game-core`  
**Last updated:** 2026-06-24

---

## Architecture overview

```text
Physical devices          Input layer                    Simulation
─────────────────         ───────────                    ──────────
Keyboard ────────┐
Gamepad ─────────┼──► deviceAssignment ──► InputFrame[] ──► RollbackSession
Edge-IO (future) ┘         ▲
                           │
                    edgeioMapper (gestures)
```

Raw events never enter `packages/game-core`.

---

## InputFrame schema

```typescript
export type InputFrame = {
  frame: number;
  playerId: number;
  left: boolean;
  right: boolean;
  up: boolean;
  down: boolean;
  jump: boolean;
  attack: boolean;
  special: boolean;
  shield: boolean;
  dodge: boolean;
  grab: boolean;
  wearableGesture?: GestureName;
};
```

- **frame:** Simulation frame index (matches rollback session).
- **playerId:** 0 or 1 in v0.1 (0-indexed).
- **wearableGesture:** Audit trail only; actions are mapped to boolean flags before sim.

---

## Keyboard

**Implementation:** `apps/web/src/input/keyboard.ts`  
**Lifecycle:** Singleton — `keydown` / `keyup` listeners attached once via `ensureKeyboard()`.  
**Blur safety:** `window blur` clears key set (prevents stuck inputs).

### Player 1 (default)

| Action | Key(s) |
|--------|--------|
| Move left | `ArrowLeft` |
| Move right | `ArrowRight` |
| Move up / jump | `ArrowUp`, `Space` |
| Move down | `ArrowDown` |
| Attack | `Z` |
| Special | `X` |
| Shield | `C` |
| Dodge | `V` |
| Grab | `B` |

### Player 2 (keyboard fallback)

| Action | Key(s) |
|--------|--------|
| Move left | `A` |
| Move right | `D` |
| Move up / jump | `W` |
| Move down | `S` |
| Attack | `1` |
| Special | `2` |
| Shield | `3` |
| Dodge | `4` |
| Grab | `5` |

**Acceptance (INP-05):** Playing 10+ minutes does not multiply listeners (verify in DevTools Event Listeners panel).

---

## Gamepad

**Implementation:** `apps/web/src/input/gamepad.ts`  
**API:** Standard Gamepad API polling each sim frame (not event-driven for sim boundary).

### Default mapping

| Action | Control |
|--------|---------|
| Movement | Left stick or D-pad (dominant axis) |
| Jump | Bottom face button (A / Cross) |
| Attack | Left face (X / Square) |
| Special | Right face (B / Circle) |
| Shield | Left shoulder / trigger |
| Dodge | Right shoulder / trigger |
| Grab | Top face (Y / Triangle) |

**Deadzone:** Apply 0.15 normalized deadzone on sticks before digital direction flags.

---

## Device assignment

**Implementation:** `apps/web/src/input/deviceAssignment.ts`

| Slot | Priority |
|------|----------|
| Player 1 | Gamepad index 0 if connected, else keyboard P1 |
| Player 2 | Gamepad index 1 if connected, else keyboard P2 |

```typescript
export function pollAllInputs(
  frame: number,
  edgeGestures?: Partial<Record<0 | 1, GestureName>>,
  edgeConfig?: EdgeIOMapperConfig,
): InputFrame[];
```

**Future (v0.5):** Manual assignment UI override stored in localStorage.

---

## Edge-IO wearable (future integration)

**Protocol:** `docs/EDGE_IO_PROTOCOL.md`  
**Mapper:** `apps/web/src/input/edgeioMapper.ts`, `packages/edgeio/src/inputMapper.ts`

Gestures merge into polled keyboard/gamepad state — **not** a separate sim path.

### Default gesture → action mapping

| Gesture | Mapped actions |
|---------|----------------|
| `swipeL` | left + dodge |
| `swipeR` | right + dodge |
| `swipeU` | up + jump |
| `swipeD` | down + shield |
| `thrust` | attack (or special if `thrustAsSpecial`) |
| `tap` | attack |
| `doubleTap` | special |
| `block` | shield |
| `shake` | grab |

**Config:**

```typescript
type EdgeIOMapperConfig = {
  thrustAsSpecial?: boolean;  // default false
};
```

**Latency target:** Gesture packet received → reflected in next `InputFrame` within 1 sim frame (16.67 ms) after host processing; end-to-end wearable p50 < 50 ms (hardware).

---

## Touch (future)

**Milestone:** v0.5 mobile web  
**Planned layout:**

- Virtual D-pad (left third)
- Jump / attack / special buttons (right third)
- Shield + dodge as secondary buttons or gestures

Touch will produce the same `InputFrame` flags via a new `touch.ts` module.

**Acceptance:** Complete one stock match on 375px-wide viewport without external controller.

---

## Input mapping & remapping

**v0.1:** Hard-coded defaults only.  
**v0.5:** Settings panel writes JSON schema:

```typescript
type PlayerBindings = {
  moveLeft: string;   // Key code or gamepad button id
  moveRight: string;
  jump: string;
  attack: string;
  special: string;
  shield: string;
  dodge: string;
  grab: string;
};
```

**Validation:** Every action must bind to exactly one control per player before match start.

---

## Input buffering

**v0.1:** No buffer — edge-triggered actions apply on exact frame of poll.  
**v0.5:** 1–3 frame buffer for attack/jump/special:

- Pressed inputs queued with expiration frame = current + bufferDepth.
- Consumed on first frame action can start.

**Measurement:** Buffered jump pressed 2 frames before landing executes on first airborne frame ≥ 95% of test trials.

---

## Accessibility

| Requirement | v0.1 | v0.5 |
|-------------|------|------|
| Full keyboard play | Yes | Yes |
| Single-hand preset | No | P1 compact layout |
| Toggle hold vs toggle shield | No | Option |
| Reduce simultaneous buttons | No | Macro-free assist: hold attack → repeat |
| Wearable not required | Yes | Yes |
| Remapping | No | Yes |
| Visual input display | Debug overlay | Training mode |

---

## Module reference

| File | Responsibility |
|------|----------------|
| `inputFrame.ts` | `emptyInputFrame()` helper |
| `keyboard.ts` | Singleton key state, P1/P2 polls |
| `gamepad.ts` | Gamepad discovery + poll |
| `deviceAssignment.ts` | Slot assignment + `pollAllInputs` |
| `edgeioMapper.ts` | Apply gesture to InputFrame |

---

## Testing

| Test | Command / method |
|------|------------------|
| Edge-IO gesture mapping | `npm run test -w packages/edgeio` |
| Keyboard singleton | Manual DevTools listener count |
| Gamepad assign | Connect 2 pads; verify playerId in debug overlay |
| Sim boundary | No `document` imports in game-core (grep audit) |

---

## Related documents

- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- [ROLLBACK_DESIGN.md](./ROLLBACK_DESIGN.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) §15
