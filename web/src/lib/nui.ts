declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'bd_sampchat';

function ignoreFailure(): void {}

export function post(callback: string, data: unknown = {}): void {
  fetch(`https://${resourceName}/${callback}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).catch(ignoreFailure);
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
