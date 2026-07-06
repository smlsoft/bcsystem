export function readJson<T>(key: string, fallback: T): T {
  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

export function writeJson<T>(key: string, value: T): void {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Storage can be disabled or full on some mobile browsers.
  }
}

export function removeJson(key: string): void {
  try {
    window.localStorage.removeItem(key);
  } catch {
    // Storage can be disabled or full on some mobile browsers.
  }
}
