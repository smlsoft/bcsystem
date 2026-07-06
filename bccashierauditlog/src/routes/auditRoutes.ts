import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { config } from '../config.js';
import { searchAuditLogs, syncAuditLogs } from '../services/auditRepository.js';
import {
  type AuditRow,
  buildTableTimeline,
  detectBugSignals,
  buildEventSummary
} from '../services/auditAnalysis.js';
import { sourceCodeLogicKnowledge } from '../services/sourceCodeLogicKnowledge.js';
import { systemLogicKnowledge } from '../services/systemLogicKnowledge.js';

const auditLogSchema = z
  .object({
    eventType: z.string().min(1),
    timestamp: z.union([z.number(), z.string()]),
    tableId: z.union([z.number(), z.string()]).nullable().optional(),
    command: z.string().nullable().optional(),
    traceId: z.string().nullable().optional(),
    userId: z.string().nullable().optional(),
    requestBody: z.unknown().optional(),
    responseBody: z.unknown().optional(),
    details: z.unknown().optional(),
    errorMessage: z.string().nullable().optional(),
    dedupeKey: z.string().nullable().optional(),
    localId: z.union([z.number(), z.string()]).nullable().optional(),
    responseTimeMs: z.union([z.number(), z.string()]).nullable().optional()
  })
  .passthrough();

const syncSchema = z.object({
  shopId: z.string().min(1),
  sourceApp: z.enum(['cashier', 'staff']),
  deviceId: z.string().optional(),
  deviceName: z.string().optional(),
  logs: z.array(auditLogSchema).min(1).max(5000)
});

function requireApiKey(authorization: string | undefined): void {
  const token = authorization?.replace(/^Bearer\s+/i, '').trim();
  if (!token || !config.auditApiKeys.includes(token)) {
    const error = new Error('Unauthorized');
    (error as Error & { statusCode?: number }).statusCode = 401;
    throw error;
  }
}

export async function registerAuditRoutes(app: FastifyInstance): Promise<void> {
  app.post('/api/audit/sync', async (request, reply) => {
    requireApiKey(request.headers.authorization);
    const body = syncSchema.parse(request.body);
    const result = await syncAuditLogs(body);
    return reply.send({ status: 'success', ...result });
  });

  app.get('/api/audit/search', async (request) => {
    const query = z
      .object({
        shopId: z.string().min(1),
        sourceApp: z.enum(['cashier', 'staff']).optional(),
        tableId: z.coerce.number().int().optional(),
        eventType: z.string().optional(),
        command: z.string().optional(),
        traceId: z.string().optional(),
        from: z.string().optional(),
        to: z.string().optional(),
        limit: z.coerce.number().int().min(1).max(5000).default(500),
        offset: z.coerce.number().int().min(0).default(0)
      })
      .parse(request.query);

    const rows = await searchAuditLogs(query);
    return { status: 'success', rows };
  });

  app.get('/api/audit/table-timeline', async (request) => {
    const query = z
      .object({
        shopId: z.string().min(1),
        tableId: z.coerce.number().int(),
        sourceApp: z.enum(['cashier', 'staff']).optional(),
        from: z.string().optional(),
        to: z.string().optional(),
        limit: z.coerce.number().int().min(1).max(5000).default(2000),
        offset: z.coerce.number().int().min(0).default(0)
      })
      .parse(request.query);

    const rows = (await searchAuditLogs(query)) as AuditRow[];
    const timeline = buildTableTimeline(rows);
    return { status: 'success', ...timeline };
  });

  app.get('/api/audit/bug-signals', async (request) => {
    const query = z
      .object({
        shopId: z.string().min(1),
        sourceApp: z.enum(['cashier', 'staff']).optional(),
        tableId: z.coerce.number().int().optional(),
        eventType: z.string().optional(),
        command: z.string().optional(),
        traceId: z.string().optional(),
        from: z.string().optional(),
        to: z.string().optional(),
        limit: z.coerce.number().int().min(1).max(5000).default(2000),
        offset: z.coerce.number().int().min(0).default(0)
      })
      .parse(request.query);

    const rows = (await searchAuditLogs(query)) as AuditRow[];
    const events = rows.map(buildEventSummary);
    const bugSignals = detectBugSignals(events);
    return {
      status: 'success',
      rowCount: rows.length,
      signalCount: bugSignals.length,
      bugSignals,
      events
    };
  });

  app.get('/api/audit/logic-knowledge', async () => ({
    status: 'success',
    systemLogicKnowledge,
    sourceCodeLogicKnowledge
  }));
}
