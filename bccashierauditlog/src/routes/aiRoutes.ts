import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { analyzeAuditQuestion } from '../services/aiAnalyzer.js';

const analyzeSchema = z.object({
  shopId: z.string().min(1),
  question: z.string().min(1),
  tableId: z.number().int().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  sourceApp: z.enum(['cashier', 'staff']).optional(),
  eventType: z.string().optional(),
  command: z.string().optional(),
  textSearch: z.string().optional(),
  errorOnly: z.boolean().optional(),
  limit: z.number().int().min(1).max(10000).optional()
});

export async function registerAiRoutes(app: FastifyInstance): Promise<void> {
  app.post('/api/ai/analyze', async (request) => {
    const body = analyzeSchema.parse(request.body);
    const result = await analyzeAuditQuestion(body);
    return {
      status: 'success',
      answer: result.answer,
      rowCount: result.rows.length
    };
  });
}
