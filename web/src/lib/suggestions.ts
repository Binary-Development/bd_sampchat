import { isRecord } from './nui';
import type { Suggestion, SuggestionParam } from '../types';

export interface SuggestionState {
  known: Map<string, Suggestion>;
  removed: Set<string>;
  server: Set<string>;
  client: Set<string>;
}

export type SuggestionAction =
  | { type: 'add'; suggestions: unknown }
  | { type: 'remove'; name: unknown }
  | { type: 'server'; names: unknown; suggestions: unknown }
  | { type: 'client'; names: unknown };

export const initialSuggestions: SuggestionState = {
  known: new Map(),
  removed: new Set(),
  server: new Set(),
  client: new Set()
};

function toKey(name: unknown): string {
  return typeof name === 'string' ? name.trim().replace(/^\//, '').toLowerCase() : '';
}

function toParam(value: unknown): SuggestionParam | undefined {
  if (!isRecord(value) || typeof value.name !== 'string') return undefined;

  return { name: value.name, help: typeof value.help === 'string' ? value.help : '' };
}

function toSuggestion(value: unknown): Suggestion | undefined {
  if (!isRecord(value)) return undefined;

  const key = toKey(value.name);
  if (!key) return undefined;

  const params = Array.isArray(value.params)
    ? value.params.map(toParam).filter((param): param is SuggestionParam => param !== undefined)
    : [];

  return { key, name: `/${key}`, help: typeof value.help === 'string' ? value.help : '', params };
}

function toKeySet(names: unknown): Set<string> {
  const keys = new Set<string>();

  if (!Array.isArray(names)) return keys;

  for (const name of names) {
    const key = toKey(name);

    if (key) keys.add(key);
  }

  return keys;
}

function mergeSuggestions(state: SuggestionState, list: unknown): SuggestionState {
  if (!Array.isArray(list) || list.length === 0) return state;

  const known = new Map(state.known);
  const removed = new Set(state.removed);

  for (const entry of list) {
    const suggestion = toSuggestion(entry);
    if (!suggestion) continue;

    const existing = known.get(suggestion.key);

    removed.delete(suggestion.key);

    if (!existing || suggestion.help || suggestion.params.length > 0) {
      known.set(suggestion.key, suggestion);
    }
  }

  return { ...state, known, removed };
}

export function suggestionReducer(state: SuggestionState, action: SuggestionAction): SuggestionState {
  switch (action.type) {
    case 'add':
      return mergeSuggestions(state, action.suggestions);
    case 'remove': {
      const key = toKey(action.name);
      if (!key) return state;

      const removed = new Set(state.removed);

      removed.add(key);

      return { ...state, removed };
    }
    case 'server':
      return { ...mergeSuggestions(state, action.suggestions), server: toKeySet(action.names) };
    case 'client':
      return { ...state, client: toKeySet(action.names) };
  }
}

export function listAvailable(state: SuggestionState): Suggestion[] {
  const keys = new Set([...state.server, ...state.client]);
  const available: Suggestion[] = [];

  for (const key of keys) {
    if (state.removed.has(key)) continue;

    available.push(state.known.get(key) ?? { key, name: `/${key}`, help: '', params: [] });
  }

  return available.sort((a, b) => a.key.localeCompare(b.key));
}

export function findMatches(available: Suggestion[], typed: string): Suggestion[] {
  if (!typed.startsWith('/') || /\s/.test(typed)) return [];

  const prefix = typed.slice(1).toLowerCase();

  return available.filter((suggestion) => suggestion.key.startsWith(prefix));
}
