import type { InputProfile } from "../input/inputProfiles.ts";
import {
  cloneProfile,
  createProfileId,
  DEFAULT_PROFILES,
  getDefaultProfileForSlot,
} from "../input/inputProfiles.ts";

const PROFILES_KEY = "aa-input-profiles";
const SLOT_KEY = "aa-input-slot-assignments";
const ACTIVE_KEY = "aa-input-active-profile";

export type SlotAssignments = Record<"1" | "2" | "3" | "4", string>;

const defaultSlots = (): SlotAssignments => ({
  "1": "keyboard-p1",
  "2": "keyboard-p2",
  "3": "keyboard-p1",
  "4": "keyboard-p2",
});

export function listInputProfiles(): InputProfile[] {
  if (typeof localStorage === "undefined") return DEFAULT_PROFILES.map(cloneProfile);
  try {
    const raw = localStorage.getItem(PROFILES_KEY);
    if (!raw) return DEFAULT_PROFILES.map(cloneProfile);
    const ids = JSON.parse(raw) as string[];
    const profiles = ids
      .map((id) => localStorage.getItem(`${PROFILES_KEY}:${id}`))
      .filter((v): v is string => !!v)
      .map((json) => JSON.parse(json) as InputProfile);
    return profiles.length ? profiles : DEFAULT_PROFILES.map(cloneProfile);
  } catch {
    return DEFAULT_PROFILES.map(cloneProfile);
  }
}

export function saveInputProfile(profile: InputProfile): InputProfile {
  const updated = { ...profile, updatedAt: new Date().toISOString() };
  localStorage.setItem(`${PROFILES_KEY}:${updated.id}`, JSON.stringify(updated));
  const ids = new Set(listInputProfiles().map((p) => p.id));
  ids.add(updated.id);
  localStorage.setItem(PROFILES_KEY, JSON.stringify([...ids]));
  return updated;
}

export function deleteInputProfile(id: string): void {
  localStorage.removeItem(`${PROFILES_KEY}:${id}`);
  const remaining = listInputProfiles().filter((p) => p.id !== id).map((p) => p.id);
  localStorage.setItem(PROFILES_KEY, JSON.stringify(remaining));
  const slots = getSlotAssignments();
  for (const slot of ["1", "2", "3", "4"] as const) {
    if (slots[slot] === id) slots[slot] = slot === "1" || slot === "3" ? "keyboard-p1" : "keyboard-p2";
  }
  setSlotAssignments(slots);
}

export function duplicateInputProfile(id: string): InputProfile | null {
  const source = getInputProfile(id);
  if (!source) return null;
  const copy: InputProfile = {
    ...cloneProfile(source),
    id: createProfileId(),
    name: `${source.name} Copy`,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  return saveInputProfile(copy);
}

export function getInputProfile(id: string): InputProfile | null {
  const fromList = listInputProfiles().find((p) => p.id === id);
  if (fromList) return cloneProfile(fromList);
  const builtin = DEFAULT_PROFILES.find((p) => p.id === id);
  return builtin ? cloneProfile(builtin) : null;
}

export function getSlotAssignments(): SlotAssignments {
  if (typeof localStorage === "undefined") return defaultSlots();
  try {
    const raw = localStorage.getItem(SLOT_KEY);
    if (!raw) return defaultSlots();
    return { ...defaultSlots(), ...(JSON.parse(raw) as SlotAssignments) };
  } catch {
    return defaultSlots();
  }
}

export function setSlotAssignments(slots: SlotAssignments): void {
  localStorage.setItem(SLOT_KEY, JSON.stringify(slots));
}

export function assignProfileToSlot(slot: 1 | 2 | 3 | 4, profileId: string): void {
  const slots = getSlotAssignments();
  slots[String(slot) as keyof SlotAssignments] = profileId;
  setSlotAssignments(slots);
}

export function getProfileForSlot(slot: 1 | 2 | 3 | 4): InputProfile {
  const slots = getSlotAssignments();
  const id = slots[String(slot) as keyof SlotAssignments];
  return getInputProfile(id) ?? getDefaultProfileForSlot(slot);
}

export function setActiveProfileId(id: string): void {
  localStorage.setItem(ACTIVE_KEY, id);
}

export function getActiveProfileId(): string {
  return localStorage.getItem(ACTIVE_KEY) ?? "keyboard-p1";
}

export function resetInputProfilesToDefaults(): void {
  localStorage.removeItem(PROFILES_KEY);
  localStorage.removeItem(SLOT_KEY);
  localStorage.removeItem(ACTIVE_KEY);
}

export function ensureDefaultProfilesSaved(): void {
  for (const p of DEFAULT_PROFILES) {
    if (!localStorage.getItem(`${PROFILES_KEY}:${p.id}`)) {
      saveInputProfile(cloneProfile(p));
    }
  }
}
