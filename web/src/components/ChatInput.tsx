import { useEffect, useLayoutEffect, useMemo, useRef, useState, type ChangeEvent, type KeyboardEvent, type MutableRefObject } from 'react';
import { findMatches } from '../lib/suggestions';
import { SuggestionList } from './SuggestionList';
import type { Suggestion } from '../types';

interface ChatInputProps {
  maxLength: number;
  available: Suggestion[];
  history: MutableRefObject<string[]>;
  draft: MutableRefObject<string>;
  onSubmit: (message: string) => void;
  onCancel: () => void;
  onScroll: (amount: number) => void;
}

interface Completion {
  matches: Suggestion[];
  index: number;
  filled: string;
}

const historyLimit = 50;
const scrollStep = 100;

function clampLength(value: string, maxLength: number): string {
  if (value.length <= maxLength) return value;

  const clipped = value.slice(0, maxLength);
  const last = clipped.charCodeAt(clipped.length - 1);

  return last >= 0xd800 && last <= 0xdbff ? clipped.slice(0, -1) : clipped;
}

function getActiveParam(value: string): number {
  const typedArgs = value.trim().split(/\s+/).length - 1;

  return /\s$/.test(value) ? typedArgs : typedArgs - 1;
}

export function ChatInput({ maxLength, available, history, draft, onSubmit, onCancel, onScroll }: ChatInputProps) {
  const [value, setValue] = useState(() => clampLength(draft.current, maxLength));
  const [completion, setCompletion] = useState<Completion | null>(null);
  const historyIndex = useRef(-1);
  const typedBeforeHistory = useRef('');
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const cycling = completion !== null && completion.filled === value;
  const matches = useMemo(() => findMatches(available, value), [available, value]);
  const ghost = !cycling && matches.length > 0 ? matches[0].name.slice(value.length) : '';

  const listed = useMemo(() => {
    if (cycling && completion) {
      const start = Math.max(0, Math.min(completion.index - 2, completion.matches.length - 5));

      return completion.matches.slice(start, start + 5);
    }

    if (matches.length > 0) return matches.slice(0, 5);

    if (!value.startsWith('/') || !/\s/.test(value)) return [];

    const key = value.slice(1).split(/\s/)[0].toLowerCase();

    return available.filter((suggestion) => suggestion.key === key);
  }, [cycling, completion, matches, value, available]);

  const selected = cycling && completion ? completion.matches[completion.index].key : listed[0]?.key;

  useLayoutEffect(() => {
    const input = inputRef.current;
    if (!input) return;

    input.style.height = 'auto';
    input.style.height = `${input.scrollHeight}px`;
  }, [value]);

  useLayoutEffect(() => {
    const input = inputRef.current;
    if (!input) return;

    input.focus();
    input.setSelectionRange(input.value.length, input.value.length);
  }, []);

  useEffect(() => {
    draft.current = value;
  }, [draft, value]);

  function updateValue(next: string): void {
    setValue(clampLength(next.replace(/[\r\n\t]+/g, ' '), maxLength));
    setCompletion(null);
  }

  function handleChange(event: ChangeEvent<HTMLTextAreaElement>): void {
    historyIndex.current = -1;
    updateValue(event.target.value);
  }

  function applyCompletion(list: Suggestion[], index: number): void {
    const filled = `${list[index].name} `;

    setCompletion({ matches: list, index, filled });
    setValue(filled);
  }

  function completeCommand(step: 1 | -1): void {
    if (cycling && completion) {
      const count = completion.matches.length;

      applyCompletion(completion.matches, (completion.index + step + count) % count);
      return;
    }

    if (matches.length === 0) return;

    applyCompletion(matches, step === 1 ? 0 : matches.length - 1);
  }

  function moveHistory(step: 1 | -1): void {
    const next = historyIndex.current + step;

    if (next < -1 || next >= history.current.length) return;

    if (historyIndex.current === -1) typedBeforeHistory.current = value;

    historyIndex.current = next;
    updateValue(next === -1 ? typedBeforeHistory.current : history.current[next]);
  }

  function submit(): void {
    const message = value.trim();

    if (message === '') {
      onCancel();
      return;
    }

    history.current.unshift(message);
    history.current.length = Math.min(history.current.length, historyLimit);
    onSubmit(message);
  }

  function handleKeyDown(event: KeyboardEvent<HTMLTextAreaElement>): void {
    switch (event.key) {
      case 'Enter':
        event.preventDefault();
        submit();
        break;
      case 'Escape':
        event.preventDefault();
        onCancel();
        break;
      case 'Tab':
        event.preventDefault();
        completeCommand(event.shiftKey ? -1 : 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        moveHistory(1);
        break;
      case 'ArrowDown':
        event.preventDefault();
        moveHistory(-1);
        break;
      case 'PageUp':
        event.preventDefault();
        onScroll(-scrollStep);
        break;
      case 'PageDown':
        event.preventDefault();
        onScroll(scrollStep);
        break;
    }
  }

  return (
    <div className="chat-input">
      <div className="input-row">
        <div className="input-box">
          {ghost && (
            <div className="input-ghost" aria-hidden="true">
              <span className="ghost-typed">{value}</span>
              <span className="ghost-rest">{ghost}</span>
            </div>
          )}
          <textarea
            ref={inputRef}
            value={value}
            rows={1}
            spellCheck={false}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
          />
        </div>
        <div className={value.length >= maxLength ? 'counter is-full' : 'counter'}>
          {value.length}/{maxLength}
        </div>
      </div>
      <SuggestionList suggestions={listed} selected={selected} activeParam={getActiveParam(value)} />
    </div>
  );
}
