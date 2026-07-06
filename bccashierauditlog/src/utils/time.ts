export function toUtcDate(value: unknown): Date {
  if (typeof value === 'number') {
    return new Date(value);
  }
  if (typeof value === 'string') {
    const numeric = Number(value);
    if (Number.isFinite(numeric) && value.trim() !== '') {
      return new Date(numeric);
    }
    return new Date(value);
  }
  return new Date();
}

export function bangkokTimestamp(date: Date): string {
  const bangkokDate = new Date(date.getTime() + 7 * 60 * 60 * 1000);
  return bangkokDate.toISOString().replace('T', ' ').replace('Z', '');
}
