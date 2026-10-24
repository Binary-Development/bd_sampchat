import { useCallback, useEffect, useLayoutEffect, useMemo, useReducer, useRef, useState } from 'react';
import { ChatInput } from './components/ChatInput';
import { isRecord, post } from './lib/nui';
import { defaultTemplates, hasTemplate, renderMessage } from './lib/render';
import { initialSuggestions, listAvailable, suggestionReducer } from './lib/suggestions';
import type { ChatLine, HideLabels, HideState, NuiEvent, Settings } from './types';

const defaultSettings: Settings = { maxLength: 400, fadeTime: 7, history: 100 };
const defaultLabels: HideLabels = { active: 'When active', always: 'Always visible', hidden: 'Hidden' };
const labelTimeMs = 1500;

export default function App() {
  const [settings, setSettings] = useState<Settings>(defaultSettings);
  const [labels, setLabels] = useState<HideLabels>(defaultLabels);
  const [lines, setLines] = useState<ChatLine[]>([]);
  const [inputOpen, setInputOpen] = useState(false);
  const [hideState, setHideState] = useState<HideState>('active');
  const [forcedHidden, setForcedHidden] = useState(false);
  const [recentlyActive, setRecentlyActive] = useState(false);
  const [stateLabel, setStateLabel] = useState<string | null>(null);
  const [suggestions, dispatchSuggestions] = useReducer(suggestionReducer, initialSuggestions);

  const templates = useRef<Record<string, string>>({ ...defaultTemplates });
  const history = useRef<string[]>([]);
  const draft = useRef('');
  const nextId = useRef(1);
  const fadeTimer = useRef<number>();
  const labelTimer = useRef<number>();
  const messagesRef = useRef<HTMLDivElement>(null);
  const handleEventRef = useRef<(event: NuiEvent) => void>();

  const available = useMemo(() => listAvailable(suggestions), [suggestions]);
  const visible = !forcedHidden && (inputOpen || hideState === 'always' || (hideState === 'active' && recentlyActive));

  const markActive = useCallback(() => {
    window.clearTimeout(fadeTimer.current);
    setRecentlyActive(true);
    fadeTimer.current = window.setTimeout(() => setRecentlyActive(false), settings.fadeTime * 1000);
  }, [settings.fadeTime]);

  function addLine(message: unknown): void {
    if (!isRecord(message)) return;

    const line: ChatLine = {
      id: nextId.current++,
      html: renderMessage(message, templates.current),
      multiline: message.multiline === true
    };

    setLines((previous) => {
      const next = [...previous, line];

      return next.length > settings.history ? next.slice(next.length - settings.history) : next;
    });

    if (hideState !== 'hidden') markActive();
  }

  function showStateLabel(state: HideState): void {
    window.clearTimeout(labelTimer.current);
    setStateLabel(labels[state]);
    labelTimer.current = window.setTimeout(() => setStateLabel(null), labelTimeMs);
  }

  handleEventRef.current = (event: NuiEvent) => {
    switch (event.action) {
      case 'init':
        setSettings(event.settings);
        setHideState(event.hideState);
        setLabels(event.labels);
        break;
      case 'open':
        setInputOpen(true);
        break;
      case 'close':
        closeInput();
        break;
      case 'addMessage':
        addLine(event.message);
        break;
      case 'clear':
        setLines([]);
        history.current = [];
        break;
      case 'clearLines':
        setLines([]);
        break;
      case 'addSuggestions':
        dispatchSuggestions({ type: 'add', suggestions: event.suggestions });
        break;
      case 'removeSuggestion':
        dispatchSuggestions({ type: 'remove', name: event.name });
        break;
      case 'addTemplate':
        if (typeof event.id === 'string' && typeof event.html === 'string' && !hasTemplate(templates.current, event.id)) {
          templates.current[event.id] = event.html;
        }
        break;
      case 'setServerCommands':
        dispatchSuggestions({ type: 'server', names: event.names, suggestions: event.suggestions });
        break;
      case 'setClientCommands':
        dispatchSuggestions({ type: 'client', names: event.names });
        break;
      case 'setHideState':
        setHideState(event.state);
        if (event.announce) showStateLabel(event.state);
        break;
      case 'setForcedHidden':
        setForcedHidden(event.hidden);
        break;
    }
  };

  useEffect(() => {
    function receiveMessage(event: MessageEvent): void {
      if (isRecord(event.data) && typeof event.data.action === 'string') {
        handleEventRef.current?.(event.data as unknown as NuiEvent);
      }
    }

    window.addEventListener('message', receiveMessage);
    post('loaded');

    return () => window.removeEventListener('message', receiveMessage);
  }, []);

  useLayoutEffect(() => {
    const element = messagesRef.current;

    if (element) element.scrollTop = element.scrollHeight;
  }, [lines, inputOpen]);

  function closeInput(): void {
    setInputOpen(false);
    markActive();
  }

  function submitMessage(message: string): void {
    draft.current = '';
    post('submit', { message });
    closeInput();
  }

  function cancelInput(): void {
    post('cancel');
    closeInput();
  }

  function scrollMessages(amount: number): void {
    if (messagesRef.current) messagesRef.current.scrollTop += amount;
  }

  return (
    <div className="chat">
      <div className={visible ? 'chat-window' : 'chat-window is-hidden'}>
        <div className="messages" ref={messagesRef}>
          {lines.map((line) => (
            <div
              key={line.id}
              className={line.multiline ? 'line is-multiline' : 'line'}
              dangerouslySetInnerHTML={{ __html: line.html }}
            />
          ))}
        </div>
      </div>
      {inputOpen && (
        <ChatInput
          maxLength={settings.maxLength}
          available={available}
          history={history}
          draft={draft}
          onSubmit={submitMessage}
          onCancel={cancelInput}
          onScroll={scrollMessages}
        />
      )}
      {stateLabel && <div className="hide-state">{stateLabel}</div>}
    </div>
  );
}
