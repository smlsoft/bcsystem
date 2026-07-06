import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { ZodError } from 'zod';
import { config } from './config.js';
import { closePool } from './db/pool.js';
import { registerAiRoutes } from './routes/aiRoutes.js';
import { registerAuditRoutes } from './routes/auditRoutes.js';
import { registerTelegramRoutes } from './routes/telegramRoutes.js';

const app = Fastify({
  logger: {
    level: config.nodeEnv === 'production' ? 'info' : 'debug'
  }
});

app.setErrorHandler((error, _request, reply) => {
  if (error instanceof ZodError) {
    return reply.code(400).send({
      status: 'error',
      message: 'Validation failed',
      issues: error.issues
    });
  }

  const statusCode = (error as Error & { statusCode?: number }).statusCode ?? 500;
  app.log.error(error);
  const message = error instanceof Error ? error.message : 'Unexpected error';
  return reply.code(statusCode).send({
    status: 'error',
    message: statusCode === 500 ? 'Internal server error' : message
  });
});

await app.register(helmet);
await app.register(cors, { origin: true });

app.get('/health', async () => ({ status: 'ok' }));

await registerAuditRoutes(app);
await registerAiRoutes(app);
await registerTelegramRoutes(app);

const shutdown = async (): Promise<void> => {
  await app.close();
  await closePool();
};

process.on('SIGINT', () => {
  shutdown().finally(() => process.exit(0));
});
process.on('SIGTERM', () => {
  shutdown().finally(() => process.exit(0));
});

await app.listen({ host: '0.0.0.0', port: config.port });
