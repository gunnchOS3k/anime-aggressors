const DB_NAME = "anime-aggressors-career";
const DB_VERSION = 1;

export type StoreName =
  | "matchHistory"
  | "replays"
  | "savedGames"
  | "fighterStats";

type MemoryDb = Map<string, Map<string, unknown>>;

const memoryStores: MemoryDb = new Map([
  ["matchHistory", new Map()],
  ["replays", new Map()],
  ["savedGames", new Map()],
  ["fighterStats", new Map()],
]);

let dbPromise: Promise<IDBDatabase> | null = null;
let forceMemory = false;

function keyFor<T extends { id?: string; fighterId?: string }>(value: T): string {
  return value.id ?? value.fighterId ?? "";
}

function useMemory(): boolean {
  return forceMemory || typeof indexedDB === "undefined";
}

function openDb(): Promise<IDBDatabase> {
  if (useMemory()) {
    return Promise.reject(new Error("memory-mode"));
  }
  if (!dbPromise) {
    dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains("matchHistory")) {
          db.createObjectStore("matchHistory", { keyPath: "id" });
        }
        if (!db.objectStoreNames.contains("replays")) {
          db.createObjectStore("replays", { keyPath: "id" });
        }
        if (!db.objectStoreNames.contains("savedGames")) {
          db.createObjectStore("savedGames", { keyPath: "id" });
        }
        if (!db.objectStoreNames.contains("fighterStats")) {
          db.createObjectStore("fighterStats", { keyPath: "fighterId" });
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error ?? new Error("IndexedDB open failed"));
    });
  }
  return dbPromise;
}

export async function idbGet<T>(store: StoreName, key: string): Promise<T | null> {
  if (useMemory()) {
    return (memoryStores.get(store)?.get(key) as T) ?? null;
  }
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store, "readonly");
    const req = tx.objectStore(store).get(key);
    req.onsuccess = () => resolve((req.result as T) ?? null);
    req.onerror = () => reject(req.error);
  });
}

export async function idbPut<T extends { id?: string; fighterId?: string }>(
  store: StoreName,
  value: T,
): Promise<T> {
  if (useMemory()) {
    memoryStores.get(store)?.set(keyFor(value), value);
    return value;
  }
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store, "readwrite");
    const req = tx.objectStore(store).put(value);
    req.onsuccess = () => resolve(value);
    req.onerror = () => reject(req.error);
  });
}

export async function idbDelete(store: StoreName, key: string): Promise<void> {
  if (useMemory()) {
    memoryStores.get(store)?.delete(key);
    return;
  }
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store, "readwrite");
    const req = tx.objectStore(store).delete(key);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

export async function idbList<T>(store: StoreName): Promise<T[]> {
  if (useMemory()) {
    return [...(memoryStores.get(store)?.values() ?? [])] as T[];
  }
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store, "readonly");
    const req = tx.objectStore(store).getAll();
    req.onsuccess = () => resolve((req.result as T[]) ?? []);
    req.onerror = () => reject(req.error);
  });
}

export async function resetCareerDbForTests(): Promise<void> {
  forceMemory = true;
  dbPromise = null;
  for (const store of memoryStores.values()) {
    store.clear();
  }
}
