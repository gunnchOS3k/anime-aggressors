/** Simulation tick rate — fixed 60 Hz. */
export const SIM_HZ = 60;

/** Fixed-point scale: positions/velocities stored as integers × FP_SCALE. */
export const FP_SCALE = 256;

/** Stage dimensions (fixed-point). */
export const STAGE_WIDTH = 2400 * FP_SCALE;
export const STAGE_HEIGHT = 1350 * FP_SCALE;
export const FLOOR_Y = 900 * FP_SCALE;

/** Blast zones (fixed-point). */
export const BLAST_LEFT = -200 * FP_SCALE;
export const BLAST_RIGHT = STAGE_WIDTH + 200 * FP_SCALE;
export const BLAST_TOP = -300 * FP_SCALE;
export const BLAST_BOTTOM = STAGE_HEIGHT + 300 * FP_SCALE;

/** Physics (fixed-point per frame at 60 Hz). */
export const GRAVITY = (12 * FP_SCALE) / SIM_HZ;
export const MAX_FALL_SPEED = (18 * FP_SCALE) / SIM_HZ;
export const RUN_SPEED = (6 * FP_SCALE) / SIM_HZ;
export const JUMP_VELOCITY = -(14 * FP_SCALE) / SIM_HZ;
export const AIR_CONTROL = (3 * FP_SCALE) / SIM_HZ;
export const DODGE_SPEED = (10 * FP_SCALE) / SIM_HZ;
export const DODGE_FRAMES = 12;
export const ATTACK_FRAMES = 8;
export const SPECIAL_FRAMES = 16;
export const HITSTUN_BASE = 12;
export const SHIELD_MAX = 100;
export const DEFAULT_STOCKS = 3;
export const DEFAULT_MATCH_SECONDS = 180;
export const DEFAULT_MATCH_FRAMES = DEFAULT_MATCH_SECONDS * SIM_HZ;
export const COUNTDOWN_FRAMES = 3 * SIM_HZ;

/** Player hurtbox size (fixed-point). */
export const HURTBOX_W = 48 * FP_SCALE;
export const HURTBOX_H = 64 * FP_SCALE;

/** Attack hitbox size (fixed-point). */
export const ATTACK_HITBOX_W = 40 * FP_SCALE;
export const ATTACK_HITBOX_H = 32 * FP_SCALE;
export const SPECIAL_HITBOX_W = 56 * FP_SCALE;
export const SPECIAL_HITBOX_H = 48 * FP_SCALE;
