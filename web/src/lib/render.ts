import { isRecord } from './nui';
import { sanitizeHtml } from './sanitize';
import type { IncomingMessage } from '../types';

export const defaultTemplates: Record<string, string> = {
  default: '<b>{0}</b>: {1}',
  defaultAlt: '{0}',
  print: '<pre>{0}</pre>'
};

const placeholderPattern = /\{\{(\w+)\}\}|\{(\w+)\}/g;
const colorCodePattern = /\^#([0-9a-f]{6}|[0-9a-f]{3})|\^([0-9])|~([a-z])~|\^[*_~=r/]/gi;
const hexColor = /^#[0-9a-f]{3,8}$/i;
const rgbColor = /^rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*(0|1|0?\.\d+)\s*)?\)$/i;
const escapes: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#039;'
};

function escapeCharacter(character: string): string {
  return escapes[character];
}

export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, escapeCharacter);
}

function isByte(value: unknown): boolean {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 && value <= 255;
}

function toCssColor(value: unknown): string | undefined {
  if (typeof value === 'string' && (hexColor.test(value) || rgbColor.test(value))) {
    return value;
  }

  if (Array.isArray(value) && value.length >= 3 && isByte(value[0]) && isByte(value[1]) && isByte(value[2])) {
    return `rgb(${value[0]}, ${value[1]}, ${value[2]})`;
  }

  return undefined;
}

function paramToHtml(value: unknown): string | undefined {
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return escapeHtml(String(value));
  }

  if (!isRecord(value) || value.text === undefined) return undefined;

  const inner = escapeHtml(String(value.text));
  const color = toCssColor(value.color);

  return color ? `<span style="color: ${color}">${inner}</span>` : inner;
}

export function colorize(input: string): string {
  let open = false;

  const output = input.replace(colorCodePattern, (_match: string, hex?: string, digit?: string, game?: string) => {
    let tag: string;

    if (hex) {
      tag = `<span style="color: #${hex}">`;
    } else if (digit) {
      tag = `<span class="color-${digit}">`;
    } else if (game) {
      tag = `<span class="game-${game.toLowerCase()}">`;
    } else {
      return '';
    }

    const prefix = open ? '</span>' : '';

    open = true;

    return prefix + tag;
  });

  return open ? `${output}</span>` : output;
}

export function hasTemplate(templates: Record<string, string>, id: string): boolean {
  return Object.prototype.hasOwnProperty.call(templates, id) && typeof templates[id] === 'string';
}

function pickTemplate(message: IncomingMessage, templates: Record<string, string>, argCount: number): string {
  if (typeof message.template === 'string') return message.template;

  const id = message.templateId;

  if (typeof id === 'string' && id !== 'default' && hasTemplate(templates, id)) {
    return templates[id];
  }

  return templates[argCount > 1 ? 'default' : 'defaultAlt'];
}

export function renderMessage(message: IncomingMessage, templates: Record<string, string>): string {
  const args = Array.isArray(message.args) ? message.args : [];
  const params = isRecord(message.params) ? message.params : {};
  const template = pickTemplate(message, templates, args.length);
  const legacyColor = Array.isArray(message.color) ? toCssColor(message.color) : undefined;

  const filled = template.replace(placeholderPattern, (match: string, doubleKey?: string, singleKey?: string) => {
    const key = doubleKey ?? singleKey ?? '';
    const isIndex = /^\d+$/.test(key);
    const html = paramToHtml(isIndex ? args[Number(key)] : params[key]);

    if (html === undefined) return match;

    return key === '0' && legacyColor ? `<span style="color: ${legacyColor}">${html}</span>` : html;
  });

  const colored = colorize(filled);
  const lineColor = typeof message.color === 'string' ? toCssColor(message.color) : undefined;

  return sanitizeHtml(lineColor ? `<div style="color: ${lineColor}">${colored}</div>` : colored);
}
