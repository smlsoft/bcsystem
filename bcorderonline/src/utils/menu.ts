import type {
  CartLine,
  LocalizedName,
  ProductBarcode,
  ProductChoice,
  ProductOption,
} from '../types';
import { currentIntlLocale, languageCodeCandidates } from '../i18n';

export function nameOf(value: LocalizedName[] | string | undefined): string {
  if (!value) return '';
  if (typeof value === 'string') {
    const text = value.trim();
    if (!text) return '';
    try {
      return nameOf(JSON.parse(text));
    } catch {
      return text;
    }
  }
  const candidates = languageCodeCandidates();
  for (const code of candidates) {
    const found = value.find((item) => localizedCode(item) === code);
    const text = found ? localizedText(found) : '';
    if (text) return text;
  }
  return value.map((item) => localizedText(item)).find(Boolean) ?? '';
}

export function productName(product: ProductBarcode): string {
  return nameOf(product.names) || product.name || product.barcode;
}

export function unitName(product: ProductBarcode): string {
  return (
    nameOf(product.unitnames) ||
    nameOf(product.itemunitnames) ||
    nameOf(product.item_unit_names) ||
    ''
  );
}

export function imageOf(product: ProductBarcode): string {
  return (
    product.imageuri ||
    product.imageurl ||
    product.images_url ||
    product.image_url ||
    ''
  );
}

export function priceOf(product: ProductBarcode): number {
  const prices = product.prices ?? [];
  const keyOne = prices.find((price) => price.keynumber === 1 || price.keyNumber === 1);
  return Number((keyOne ?? prices[0])?.price ?? 0);
}

export function parseOptions(product: ProductBarcode): ProductOption[] {
  if (Array.isArray(product.options)) {
    return cloneOptions(product.options);
  }
  if (!product.options_json || product.options_json === 'null') {
    return [];
  }
  try {
    const parsed = JSON.parse(product.options_json);
    return Array.isArray(parsed) ? cloneOptions(parsed) : [];
  } catch {
    return [];
  }
}

export function cloneOptions(options: ProductOption[]): ProductOption[] {
  return options.map((option) => ({
    ...option,
    minselect: option.minselect ?? 0,
    maxselect: Number(option.maxselect ?? 0),
    choices: (option.choices ?? []).map((choice) => normalizeChoice(choice)),
  }));
}

export function normalizeChoice(choice: ProductChoice): ProductChoice {
  const rawPrice = Number(choice.priceValue ?? choice.price ?? 0);
  return {
    ...choice,
    guid: choice.guid,
    price: choice.price ?? rawPrice,
    priceValue: Number.isFinite(rawPrice) ? rawPrice : 0,
    qty: Number(choice.qty ?? 1),
    selected: Boolean(choice.selected ?? choice.isdefault ?? false),
  };
}

export function lineOptionsAmount(line: CartLine): number {
  return line.options.reduce((sum, option) => {
    const choices = option.choices ?? [];
    const selected = choices.filter((choice) => choice.selected);
    return (
      sum +
      selected.reduce((choiceSum, choice) => {
        return choiceSum + Number(choice.priceValue ?? choice.price ?? 0);
      }, 0)
    );
  }, 0);
}

export function lineAmount(line: CartLine): number {
  return (priceOf(line.product) + lineOptionsAmount(line)) * line.qty;
}

export function money(value: number): string {
  return new Intl.NumberFormat(currentIntlLocale.value, {
    style: 'currency',
    currency: 'THB',
    maximumFractionDigits: 0,
  }).format(value || 0);
}

export function selectedOptionText(options: ProductOption[]): string {
  return options
    .flatMap((option) => option.choices.filter((choice) => choice.selected))
    .map((choice) => nameOf(choice.names))
    .filter(Boolean)
    .join(', ');
}

function localizedCode(item: LocalizedName): string {
  return String(item.code ?? item.lang ?? '').trim().toLowerCase();
}

function localizedText(item: LocalizedName): string {
  const value = item.name ?? item.names ?? item.text ?? '';
  if (typeof value !== 'string') return '';
  const text = value.trim();
  if (!text) return '';
  try {
    return nameOf(JSON.parse(text));
  } catch {
    return text;
  }
}
