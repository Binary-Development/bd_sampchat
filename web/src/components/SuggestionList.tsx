import type { Suggestion } from '../types';

interface SuggestionListProps {
  suggestions: Suggestion[];
  selected?: string;
  activeParam: number;
}

function getParamIndex(suggestion: Suggestion, activeParam: number): number {
  if (activeParam < 0 || suggestion.params.length === 0) return -1;

  return Math.min(activeParam, suggestion.params.length - 1);
}

export function SuggestionList({ suggestions, selected, activeParam }: SuggestionListProps) {
  if (suggestions.length === 0) return null;

  return (
    <ul className="suggestions">
      {suggestions.map((suggestion) => {
        const paramIndex = getParamIndex(suggestion, activeParam);
        const help = paramIndex >= 0 ? suggestion.params[paramIndex].help : suggestion.help;

        return (
          <li key={suggestion.key} className={suggestion.key === selected ? 'suggestion is-selected' : 'suggestion'}>
            <p>
              <span className="suggestion-name">{suggestion.name}</span>
              {suggestion.params.map((param, index) => (
                <span key={index} className={index === paramIndex ? 'param is-active' : 'param'}>
                  {' '}[{param.name}]
                </span>
              ))}
            </p>
            {help && <small className="help">{help}</small>}
          </li>
        );
      })}
    </ul>
  );
}
