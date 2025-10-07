import { z } from "zod";

export const SensorFrameSchema = z.object({
  t: z.number(),
  ax: z.number(), ay: z.number(), az: z.number(),
  gx: z.number(), gy: z.number(), gz: z.number()
});
export type SensorFrame = z.infer<typeof SensorFrameSchema>;

export const GestureSchema = z.object({
  type: z.enum(["swipeL","swipeR","thrust","block","tap","doubleTap","shake","spin"]),
  t: z.number()
});
export type GestureEvent = z.infer<typeof GestureSchema>;

export const HapticCommandSchema = z.object({
  effectId: z.number(),
  intensity: z.number(),
  durationMs: z.number()
});
export type HapticCommand = z.infer<typeof HapticCommandSchema>;

export const DeviceInfoSchema = z.object({
  serial: z.string(),
  fwVersion: z.string(),
  battery: z.number()
});
export type DeviceInfo = z.infer<typeof DeviceInfoSchema>;
