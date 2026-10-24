import DOMPurify, { type UponSanitizeAttributeHookEvent } from 'dompurify';

const allowedTags = [
  'b', 'strong', 'i', 'em', 'u', 's', 'small', 'span', 'div', 'p', 'br',
  'pre', 'code', 'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4'
];

const allowedStyles = new Set([
  'color',
  'background-color',
  'font-weight',
  'font-style',
  'text-decoration',
  'text-decoration-line',
  'text-decoration-color',
  'text-decoration-style',
  'text-decoration-thickness',
  'text-transform',
  'text-align',
  'text-overflow',
  'vertical-align',
  'line-height',
  'opacity',
  'display',
  'width',
  'min-width',
  'max-width',
  'word-break',
  'overflow-wrap',
  'word-wrap',
  'white-space',
  'white-space-collapse',
  'text-wrap',
  'text-wrap-mode',
  'text-wrap-style',
  'overflow',
  'overflow-x',
  'overflow-y',
  'margin-top',
  'margin-right',
  'margin-bottom',
  'margin-left',
  'padding-top',
  'padding-right',
  'padding-bottom',
  'padding-left',
  'border-top-left-radius',
  'border-top-right-radius',
  'border-bottom-left-radius',
  'border-bottom-right-radius'
]);

const blockedValue = /url\s*\(|image\s*\(|image-set|expression\s*\(|var\s*\(|attr\s*\(/i;
const probe = document.createElement('div');

function filterStyle(value: string): string {
  probe.style.cssText = value;

  const kept: string[] = [];

  for (let index = 0; index < probe.style.length; index += 1) {
    const property = probe.style.item(index);
    const propertyValue = probe.style.getPropertyValue(property);

    if (allowedStyles.has(property) && !blockedValue.test(propertyValue)) {
      kept.push(`${property}: ${propertyValue}`);
    }
  }

  probe.removeAttribute('style');

  return kept.join('; ');
}

function cleanStyleAttribute(_node: Element, data: UponSanitizeAttributeHookEvent): void {
  if (data.attrName !== 'style') return;

  data.attrValue = filterStyle(data.attrValue);

  if (data.attrValue === '') {
    data.keepAttr = false;
  }
}

DOMPurify.addHook('uponSanitizeAttribute', cleanStyleAttribute);

export function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: allowedTags,
    ALLOWED_ATTR: ['class', 'style'],
    ALLOW_DATA_ATTR: false,
    ALLOW_ARIA_ATTR: false
  });
}
