import type { FastifyInstance } from 'fastify';
import { type Context, Telegraf } from 'telegraf';
import { z } from 'zod';
import { config } from '../config.js';
import { analyzeAuditQuestion, type AnalyzeRequest } from '../services/aiAnalyzer.js';

interface DateRangeFilter {
  from?: string;
  to?: string;
  label?: string;
}

interface ParsedFilters {
  shopId: string;
  tableId?: number;
  sourceApp?: 'cashier' | 'staff';
  dateRange: DateRangeFilter;
}

interface CommandOptions {
  emptyTextHelp: string;
  questionPrefix: string;
  defaultToday?: boolean;
  command?: string;
  eventType?: string;
  textSearch?: string;
  textOverride?: string;
  errorOnly?: boolean;
}

const defaultShopId = '3BWRPFcixo0JZ1qN0bXgzHa2p7x';
const bangkokOffsetMs = 7 * 60 * 60 * 1000;

function isAllowedChat(chatId: string): boolean {
  return config.telegramAllowedChatIds.includes(chatId);
}

function messageText(ctx: Context): string {
  return ctx.message && 'text' in ctx.message ? ctx.message.text : '';
}

function stripCommand(text: string, command: string): string {
  return text.replace(new RegExp(`^/${command}(?:@\\w+)?\\s*`, 'i'), '').trim();
}

function extractTableId(text: string): number | undefined {
  const match = text.match(/(?:โต๊ะ|table)\s*#?\s*(\d+)/i);
  return match ? Number.parseInt(match[1], 10) : undefined;
}

function extractLeadingNumber(text: string): number | undefined {
  const match = text.trim().match(/^#?\s*(\d+)\b/);
  return match ? Number.parseInt(match[1], 10) : undefined;
}

function extractShopId(text: string): string {
  const match = text.match(/(?:shop\s*id|shopid|shop|ร้าน)\s*[:=]?\s*([A-Za-z0-9_-]+)/i);
  return match?.[1] ?? defaultShopId;
}

function extractSourceApp(text: string): 'cashier' | 'staff' | undefined {
  if (/(staff|dedestaff|kiosk|พนักงาน|เด็กเสิร์ฟ|สตาฟ)/i.test(text)) return 'staff';
  if (/(cashier|dedecashier|แคชเชียร์|แคชเชีย|pos|หน้าแอพ)/i.test(text)) return 'cashier';
  return undefined;
}

function extractBillToken(text: string): string | undefined {
  const guid = text.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i);
  if (guid) return guid[0];

  const doc = text.match(/\b[A-Z]?\d{6,}[-]?\d*\b/i);
  return doc?.[0];
}

function bangkokDateParts(date: Date): { year: number; month: number; day: number } {
  const bangkok = new Date(date.getTime() + bangkokOffsetMs);
  return {
    year: bangkok.getUTCFullYear(),
    month: bangkok.getUTCMonth() + 1,
    day: bangkok.getUTCDate()
  };
}

function bangkokDayRange(
  year: number,
  month: number,
  day: number,
  label: string
): DateRangeFilter {
  const startUtcMs = Date.UTC(year, month - 1, day) - bangkokOffsetMs;
  const endUtcMs = startUtcMs + 24 * 60 * 60 * 1000 - 1;
  return {
    from: new Date(startUtcMs).toISOString(),
    to: new Date(endUtcMs).toISOString(),
    label
  };
}

function todayBangkokRange(now = new Date()): DateRangeFilter {
  const today = bangkokDateParts(now);
  return bangkokDayRange(today.year, today.month, today.day, 'วันนี้');
}

function bangkokTimeWindowRange(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number,
  label: string,
  windowMinutes = 60
): DateRangeFilter {
  const centerUtcMs = Date.UTC(year, month - 1, day, hour, minute) - bangkokOffsetMs;
  return {
    from: new Date(centerUtcMs - windowMinutes * 60 * 1000).toISOString(),
    to: new Date(centerUtcMs + windowMinutes * 60 * 1000).toISOString(),
    label
  };
}

function bangkokExactTimeRange(
  year: number,
  month: number,
  day: number,
  startHour: number,
  startMinute: number,
  endHour: number,
  endMinute: number,
  label: string
): DateRangeFilter {
  const startUtcMs = Date.UTC(year, month - 1, day, startHour, startMinute) - bangkokOffsetMs;
  let endUtcMs = Date.UTC(year, month - 1, day, endHour, endMinute) - bangkokOffsetMs;
  if (endUtcMs < startUtcMs) endUtcMs += 24 * 60 * 60 * 1000;
  return {
    from: new Date(startUtcMs).toISOString(),
    to: new Date(endUtcMs).toISOString(),
    label
  };
}

function extractApproxTime(text: string): { hour: number; minute: number; raw: string } | undefined {
  const match = text.match(/(?:time|at|around|เวลา|ประมาณ)?\s*(\d{1,2})[.:](\d{2})/i);
  if (!match) return undefined;

  const hour = Number.parseInt(match[1], 10);
  const minute = Number.parseInt(match[2], 10);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return undefined;

  return { hour, minute, raw: match[0].trim() };
}

function extractTimeRange(
  text: string
):
  | {
      startHour: number;
      startMinute: number;
      endHour: number;
      endMinute: number;
      raw: string;
    }
  | undefined {
  const match = text.match(
    /(\d{1,2})[.:](\d{2})\s*(?:-|–|—|ถึง|to)\s*(\d{1,2})[.:](\d{2})/i
  );
  if (!match) return undefined;

  const startHour = Number.parseInt(match[1], 10);
  const startMinute = Number.parseInt(match[2], 10);
  const endHour = Number.parseInt(match[3], 10);
  const endMinute = Number.parseInt(match[4], 10);
  const valid =
    startHour >= 0 &&
    startHour <= 23 &&
    endHour >= 0 &&
    endHour <= 23 &&
    startMinute >= 0 &&
    startMinute <= 59 &&
    endMinute >= 0 &&
    endMinute <= 59;
  if (!valid) return undefined;

  return { startHour, startMinute, endHour, endMinute, raw: match[0].trim() };
}

function extractDateRange(text: string, now = new Date()): DateRangeFilter {
  if (/(เมื่อวาน|yesterday)/i.test(text)) {
    const today = bangkokDateParts(now);
    const yesterdayUtc = new Date(
      Date.UTC(today.year, today.month - 1, today.day) - 24 * 60 * 60 * 1000
    );
    const yesterday = bangkokDateParts(yesterdayUtc);
    return bangkokDayRange(yesterday.year, yesterday.month, yesterday.day, 'เมื่อวาน');
  }

  if (/(วันนี้|today)/i.test(text)) return todayBangkokRange(now);

  const explicit = text.match(/(?:วันที่\s*)?(\d{1,2})[/-](\d{1,2})[/-](\d{4})/i);
  if (explicit) {
    const day = Number.parseInt(explicit[1], 10);
    const month = Number.parseInt(explicit[2], 10);
    const year = Number.parseInt(explicit[3], 10);
    return bangkokDayRange(year, month, day, explicit[0]);
  }

  return {};
}

function extractDateRangeWithApproxTime(text: string, now = new Date()): DateRangeFilter {
  const baseRange = extractDateRange(text, now);
  const timeRange = extractTimeRange(text);
  const approxTime = extractApproxTime(text);
  if (!timeRange && !approxTime) return baseRange;

  const dateParts =
    baseRange.from || baseRange.to
      ? bangkokDateParts(new Date(baseRange.from ?? baseRange.to ?? now))
      : bangkokDateParts(now);

  const baseLabel = baseRange.label ?? 'วันนี้';
  if (timeRange) {
    return bangkokExactTimeRange(
      dateParts.year,
      dateParts.month,
      dateParts.day,
      timeRange.startHour,
      timeRange.startMinute,
      timeRange.endHour,
      timeRange.endMinute,
      `${baseLabel} ${timeRange.raw}`
    );
  }

  if (!approxTime) return baseRange;
  return bangkokTimeWindowRange(
    dateParts.year,
    dateParts.month,
    dateParts.day,
    approxTime.hour,
    approxTime.minute,
    `${baseLabel} ${approxTime.raw}`
  );
}

function parsedFilters(text: string, defaultToday = false): ParsedFilters {
  const extractedRange = extractDateRangeWithApproxTime(text);
  const dateRange =
    defaultToday && !extractedRange.from && !extractedRange.to
      ? todayBangkokRange()
      : extractedRange;

  return {
    shopId: extractShopId(text),
    tableId: extractTableId(text),
    sourceApp: extractSourceApp(text),
    dateRange
  };
}

function filterSummary(filters: ParsedFilters): string {
  const parts = [`shop=${filters.shopId}`];
  if (filters.tableId !== undefined) parts.push(`โต๊ะ ${filters.tableId}`);
  if (filters.sourceApp) parts.push(`ฝั่ง ${filters.sourceApp}`);
  if (filters.dateRange.label) parts.push(filters.dateRange.label);
  return parts.join(', ');
}

function computeAdaptiveLimit(filters: ParsedFilters): number {
  const hasDateRange = Boolean(filters.dateRange.from || filters.dateRange.to);

  if (filters.tableId !== undefined) {
    return hasDateRange ? config.maxAnalysisRows : Math.min(5000, config.maxAnalysisRows);
  }

  if (filters.sourceApp) {
    return hasDateRange ? Math.min(5000, config.maxAnalysisRows) : 2000;
  }

  return hasDateRange ? Math.min(3000, config.maxAnalysisRows) : 1000;
}

function helpText(): string {
  return [
    'คำสั่งที่ใช้ได้',
    '',
    '/analyze <คำถาม> - วิเคราะห์แบบละเอียด',
    'ตัวอย่าง: /analyze วันนี้เวลา 21:00 - 21:10 สถานการณ์โต๊ะกับบิลเป็นยังไงบ้าง',
    '',
    '/summary <ช่วงเวลา> - สรุปสถานการณ์โต๊ะ/บิลแบบเร็ว',
    'ตัวอย่าง: /summary วันนี้ 21:00 - 21:10',
    '',
    '/table <เลขโต๊ะ> <ช่วงเวลา> - เจาะ session ของโต๊ะ',
    'ตัวอย่าง: /table 32 เมื่อวาน',
    '',
    '/bill <docNumber หรือ guidpos> - เจาะบิล',
    'ตัวอย่าง: /bill R012606020014',
    '',
    '/errors <ช่วงเวลา> - ดู error ล่าสุด',
    'ตัวอย่าง: /errors วันนี้',
    '',
    '/pending <ช่วงเวลา> - หา PAY_AT_CASHIER_PENDING ที่ต้องตรวจต่อ',
    'ตัวอย่าง: /pending วันนี้',
    '',
    '/syncfail <ช่วงเวลา> - หา sync.sale_invoice ที่ fail',
    'ตัวอย่าง: /syncfail วันนี้',
    '',
    '/reopen <ช่วงเวลา> - หา pattern โต๊ะกลับมาเปิดหลังปิดบิล',
    'ตัวอย่าง: /reopen เมื่อวาน โต๊ะ 32'
  ].join('\n');
}

async function ensureAllowed(ctx: Context): Promise<boolean> {
  const chatId = String(ctx.chat?.id ?? '');
  if (isAllowedChat(chatId)) return true;
  await ctx.reply('chat นี้ยังไม่ได้รับสิทธิ์ใช้งาน audit analyzer');
  return false;
}

async function runAnalysisCommand(
  app: FastifyInstance,
  ctx: Context,
  commandName: string,
  options: CommandOptions
): Promise<void> {
  try {
    if (!(await ensureAllowed(ctx))) return;

    const text = options.textOverride ?? stripCommand(messageText(ctx), commandName);
    if (!text && commandName !== 'errors' && commandName !== 'syncfail' && commandName !== 'pending') {
      await ctx.reply(options.emptyTextHelp);
      return;
    }

    const filters = parsedFilters(text, options.defaultToday);
    const limit = computeAdaptiveLimit(filters);
    const question = `${options.questionPrefix}${text ? `: ${text}` : ''}`;
    const request: AnalyzeRequest = {
      shopId: filters.shopId,
      question,
      tableId: filters.tableId,
      sourceApp: filters.sourceApp,
      eventType: options.eventType,
      command: options.command,
      textSearch: options.textSearch,
      errorOnly: options.errorOnly,
      from: filters.dateRange.from,
      to: filters.dateRange.to,
      limit
    };

    await ctx.reply(
      `กำลังตรวจ audit log (${filterSummary(filters)}, limit=${limit})...`
    );

    const result = await analyzeAuditQuestion(request);
    await ctx.reply(result.answer.slice(0, 3900));
  } catch (error) {
    app.log.error(error, `Telegram /${commandName} failed`);
    await ctx.reply(
      `วิเคราะห์ /${commandName} ไม่สำเร็จ ลองระบุช่วงเวลา/โต๊ะเพิ่ม เช่น /${commandName} วันนี้ โต๊ะ 12`
    );
  }
}

export async function registerTelegramRoutes(app: FastifyInstance): Promise<void> {
  if (!config.telegramBotToken) {
    app.log.warn('TELEGRAM_BOT_TOKEN is empty; Telegram webhook is disabled.');
    return;
  }

  const bot = new Telegraf(config.telegramBotToken);

  bot.command('help', async (ctx) => {
    if (!(await ensureAllowed(ctx))) return;
    await ctx.reply(helpText());
  });

  bot.command('analyze', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'analyze', {
      emptyTextHelp: 'พิมพ์คำถามหลัง /analyze เช่น /analyze โต๊ะ 32 เมื่อวานบิลหาย',
      questionPrefix: 'วิเคราะห์ audit log แบบละเอียด'
    });
  });

  bot.command('summary', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'summary', {
      emptyTextHelp: 'พิมพ์ช่วงเวลาหลัง /summary เช่น /summary วันนี้ 21:00 - 21:10',
      questionPrefix: 'สรุปสถานการณ์โต๊ะและบิลแบบเร็ว',
      defaultToday: true
    });
  });

  bot.command('table', async (ctx) => {
    const text = stripCommand(messageText(ctx), 'table');
    const tableId = extractTableId(text) ?? extractLeadingNumber(text);
    if (!text || tableId === undefined) {
      await ctx.reply('พิมพ์เลขโต๊ะหลัง /table เช่น /table 32 วันนี้');
      return;
    }
    const normalizedText =
      text && tableId !== undefined && !/(โต๊ะ|table)/i.test(text)
        ? `โต๊ะ ${tableId} ${text.replace(/^#?\s*\d+\b/, '').trim()}`.trim()
        : undefined;
    await runAnalysisCommand(app, ctx, 'table', {
      emptyTextHelp: 'พิมพ์เลขโต๊ะหลัง /table เช่น /table 32 วันนี้',
      questionPrefix: 'เจาะ session และสถานะของโต๊ะนี้',
      defaultToday: true,
      textOverride: normalizedText
    });
  });

  bot.command('bill', async (ctx) => {
    const text = stripCommand(messageText(ctx), 'bill');
    const billToken = extractBillToken(text);
    if (text && !billToken) {
      await ctx.reply('ไม่พบเลขบิลหรือ guidpos ที่ชัดเจน ตัวอย่าง: /bill R012606020014');
      return;
    }
    await runAnalysisCommand(app, ctx, 'bill', {
      emptyTextHelp: 'พิมพ์เลขบิลหรือ guidpos หลัง /bill เช่น /bill R012606020014',
      questionPrefix: 'เจาะ lifecycle ของบิล/docNumber/guidpos นี้',
      textSearch: billToken,
      defaultToday: false
    });
  });

  bot.command('errors', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'errors', {
      emptyTextHelp: 'ดู error เช่น /errors วันนี้',
      questionPrefix: 'สรุป error และผลกระทบจาก audit log',
      errorOnly: true,
      defaultToday: true
    });
  });

  bot.command('pending', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'pending', {
      emptyTextHelp: 'หา pending เช่น /pending วันนี้',
      questionPrefix: 'หา PAY_AT_CASHIER_PENDING และตรวจว่ามี invoice ตามมาหรือไม่',
      textSearch: 'PAY_AT_CASHIER_PENDING',
      defaultToday: true
    });
  });

  bot.command('syncfail', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'syncfail', {
      emptyTextHelp: 'หา sync fail เช่น /syncfail วันนี้',
      questionPrefix: 'หา sync.sale_invoice ที่ fail และผลกระทบต่อบิล',
      command: 'sync.sale_invoice',
      errorOnly: true,
      defaultToday: true
    });
  });

  bot.command('reopen', async (ctx) => {
    await runAnalysisCommand(app, ctx, 'reopen', {
      emptyTextHelp: 'หาโต๊ะกลับมาเปิด เช่น /reopen เมื่อวาน โต๊ะ 32',
      questionPrefix: 'หา pattern โต๊ะกลับมาเปิดหลัง final close หรือ sale invoice sync',
      defaultToday: true
    });
  });

  app.post('/api/telegram/webhook/:secret', async (request, reply) => {
    const params = z.object({ secret: z.string() }).parse(request.params);
    if (params.secret !== config.telegramWebhookSecret) {
      return reply.code(401).send({ status: 'error', message: 'Unauthorized' });
    }

    await bot.handleUpdate(request.body as Parameters<typeof bot.handleUpdate>[0]);
    return { status: 'success' };
  });
}
