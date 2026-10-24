export type HideState = 'active' | 'always' | 'hidden';

export interface Settings {
  maxLength: number;
  fadeTime: number;
  history: number;
}

export interface IncomingMessage {
  args?: unknown;
  template?: unknown;
  templateId?: unknown;
  params?: unknown;
  color?: unknown;
  multiline?: unknown;
}

export interface ChatLine {
  id: number;
  html: string;
  multiline: boolean;
}

export interface SuggestionParam {
  name: string;
  help: string;
}

export interface Suggestion {
  key: string;
  name: string;
  help: string;
  params: SuggestionParam[];
}

export type HideLabels = Record<HideState, string>;

export type NuiEvent =
  | { action: 'init'; settings: Settings; hideState: HideState; labels: HideLabels }
  | { action: 'open' }
  | { action: 'close' }
  | { action: 'addMessage'; message: IncomingMessage }
  | { action: 'clear' }
  | { action: 'clearLines' }
  | { action: 'addSuggestions'; suggestions: unknown }
  | { action: 'removeSuggestion'; name: unknown }
  | { action: 'addTemplate'; id: unknown; html: unknown }
  | { action: 'setServerCommands'; names: unknown; suggestions: unknown }
  | { action: 'setClientCommands'; names: unknown }
  | { action: 'setHideState'; state: HideState; announce: boolean }
  | { action: 'setForcedHidden'; hidden: boolean };
