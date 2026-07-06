import 'dotenv/config';

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function list(name: string): string[] {
  return (process.env[name] ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

function intValue(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export const config = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: intValue('PORT', 8088),
  databaseUrl: required('DATABASE_URL'),
  auditApiKeys: list('AUDIT_API_KEYS'),
  telegramBotToken: process.env.TELEGRAM_BOT_TOKEN ?? '',
  telegramWebhookSecret: process.env.TELEGRAM_WEBHOOK_SECRET ?? '',
  telegramAllowedChatIds: list('TELEGRAM_ALLOWED_CHAT_IDS'),
  openAiApiKey: process.env.OPENAI_API_KEY ?? '',
  openAiModel: process.env.OPENAI_MODEL ?? 'gpt-4.1-mini',
  defaultTimezone: process.env.DEFAULT_TIMEZONE ?? 'Asia/Bangkok',
  maxAnalysisRows: intValue('MAX_ANALYSIS_ROWS', 2000)
};
