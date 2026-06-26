import { parseGesturePacket, createHapticPacket } from "../../../../packages/edgeio/src/parser.js";
import { DEFAULT_EDGEIO_CONFIG, applyEdgeIOGesture } from "../input/edgeioMapper.js";
import { emptyInputFrame } from "../input/inputFrame.js";
import { navigateHome } from "../router.js";

const SERVICE_UUID = "0000aa10-0000-1000-8000-00805f9b34fb";
const GESTURE_CHAR_UUID = "0000aa11-0000-1000-8000-00805f9b34fb";
const HAPTIC_CHAR_UUID = "0000aa12-0000-1000-8000-00805f9b34fb";

type BleDevice = {
  name?: string;
  gatt?: {
    connected: boolean;
    connect(): Promise<BleServer>;
    getPrimaryService(uuid: string): Promise<BleService>;
  };
};

type BleServer = {
  getPrimaryService(uuid: string): Promise<BleService>;
};

type BleCharacteristic = {
  startNotifications(): Promise<void>;
  addEventListener(type: string, fn: (ev: Event) => void): void;
  writeValue(data: BufferSource): Promise<void>;
};

type BleService = {
  getCharacteristic(uuid: string): Promise<BleCharacteristic>;
};

export function mountEdgeIOLab(root: HTMLElement): void {
  const nav = navigator as Navigator & {
    bluetooth?: {
      requestDevice(options: object): Promise<BleDevice>;
    };
  };
  const bleSupported = !!nav.bluetooth;

  root.innerHTML = `
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Edge-IO Lab</h2>
      <p>Web Bluetooth: ${bleSupported ? "available" : "not available — use simulator"}</p>
      <div class="edgeio-mode">
        <button id="edgeio-connect" type="button" ${bleSupported ? "" : "disabled"}>Connect BLE device</button>
        <button id="edgeio-sim" type="button" class="btn-secondary">Simulator mode</button>
        <button id="edgeio-haptic" type="button">Send test haptic</button>
      </div>
      <div class="edgeio-buttons">
        ${["swipeL", "swipeR", "swipeU", "swipeD", "thrust", "tap", "doubleTap", "block", "shake"]
          .map((g) => `<button type="button" data-gesture="${g}">${g}</button>`)
          .join("")}
      </div>
      <pre id="edgeio-output" class="shell-pre"></pre>
    </div>
  `;

  const out = root.querySelector("#edgeio-output") as HTMLPreElement;
  const log: string[] = [];
  let mode: "idle" | "simulator" | "ble" = "idle";
  let gesture: string | undefined;
  let device: BleDevice | null = null;

  const append = (line: string) => {
    log.unshift(line);
    if (log.length > 40) log.length = 40;
    render();
  };

  root.querySelector("#shell-back")?.addEventListener("click", () => navigateHome());

  root.querySelector("#edgeio-sim")?.addEventListener("click", () => {
    mode = "simulator";
    append("[simulator] enabled — gestures below are simulated packets");
  });

  root.querySelector("#edgeio-connect")?.addEventListener("click", async () => {
    if (!nav.bluetooth) return;
    try {
      device = await nav.bluetooth.requestDevice({
        filters: [{ services: [SERVICE_UUID] }],
        optionalServices: [SERVICE_UUID],
      });
      const server = await device.gatt?.connect();
      append(`[ble] connected: ${device.name ?? "device"}`);
      mode = "ble";
      const service = await server?.getPrimaryService(SERVICE_UUID);
      const gestureChar = await service?.getCharacteristic(GESTURE_CHAR_UUID);
      await gestureChar?.startNotifications();
      gestureChar?.addEventListener("characteristicvaluechanged", (ev: Event) => {
        const target = ev.target as { value?: DataView };
        const value = target.value;
        if (!value) return;
        try {
          const parsed = parseGesturePacket(value);
          append(`[ble] gesture packet: ${JSON.stringify(parsed)}`);
        } catch (err) {
          append(`[ble] parse error: ${String(err)}`);
        }
      });
    } catch (err) {
      append(`[ble] connect failed: ${String(err)}`);
      mode = "idle";
    }
  });

  root.querySelector("#edgeio-haptic")?.addEventListener("click", async () => {
    const packet = createHapticPacket({ effectId: 1, intensity: 200, durationMs: 120 });
    append(`[haptic] encoded ${packet.length} bytes`);
    if (mode === "ble" && device?.gatt?.connected) {
      try {
        const service = await device.gatt.getPrimaryService(SERVICE_UUID);
        const hapticChar = await service.getCharacteristic(HAPTIC_CHAR_UUID);
        await hapticChar.writeValue(new Uint8Array(packet));
        append("[ble] haptic sent");
      } catch (err) {
        append(`[ble] haptic failed: ${String(err)}`);
      }
    }
  });

  root.querySelector(".edgeio-buttons")?.addEventListener("click", (e) => {
    const btn = (e.target as HTMLElement).closest("button");
    if (!btn?.dataset.gesture) return;
    gesture = btn.dataset.gesture;
    if (mode === "simulator") {
      append(`[simulator] gesture: ${gesture}`);
    }
    render();
  });

  const render = () => {
    let frame = emptyInputFrame(0, 0);
    if (gesture) {
      frame = applyEdgeIOGesture(frame, gesture as never, DEFAULT_EDGEIO_CONFIG);
    }
    out.textContent = [
      `mode: ${mode}`,
      `service: ${SERVICE_UUID}`,
      `gesture char: ${GESTURE_CHAR_UUID}`,
      `config: ${JSON.stringify(DEFAULT_EDGEIO_CONFIG)}`,
      `gesture: ${gesture ?? "(none)"}`,
      `mapped: ${JSON.stringify(frame, null, 2)}`,
      "",
      "log:",
      ...log,
    ].join("\n");
  };
  render();
}
