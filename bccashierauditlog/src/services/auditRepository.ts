import crypto from 'node:crypto';
import { pool } from '../db/pool.js';
import { bangkokTimestamp, toUtcDate } from '../utils/time.js';

export type SourceApp = 'cashier' | 'staff';

export interface AuditSyncLog {
  eventType: string;
  timestamp: number | string;
  tableId?: number | string | null;
  command?: string | null;
  traceId?: string | null;
  userId?: string | null;
  requestBody?: unknown;
  responseBody?: unknown;
  details?: unknown;
  errorMessage?: string | null;
  dedupeKey?: string | null;
  localId?: number | string | null;
  responseTimeMs?: number | string | null;
  [key: string]: unknown;
}

export interface AuditSyncRequest {
  shopId: string;
  sourceApp: SourceApp;
  deviceId?: string;
  deviceName?: string;
  logs: AuditSyncLog[];
}

export interface AuditSearchParams {
  shopId: string;
  sourceApp?: SourceApp;
  tableId?: number;
  eventType?: string;
  command?: string;
  traceId?: string;
  textSearch?: string;
  errorOnly?: boolean;
  from?: string;
  to?: string;
  limit: number;
  offset: number;
}

function parseOptionalJson(value: unknown): unknown {
  if (typeof value !== 'string') return value ?? null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  try {
    return JSON.parse(trimmed);
  } catch {
    return { text: trimmed };
  }
}

function makeDedupeKey(
  request: AuditSyncRequest,
  log: AuditSyncLog,
  timestampUtc: Date
): string {
  if (log.dedupeKey) return String(log.dedupeKey);
  const stable = JSON.stringify({
    shopId: request.shopId,
    sourceApp: request.sourceApp,
    deviceId: request.deviceId ?? '',
    eventType: log.eventType,
    tableId: log.tableId ?? null,
    command: log.command ?? null,
    traceId: log.traceId ?? null,
    timestamp: timestampUtc.toISOString(),
    requestBody: log.requestBody ?? null,
    responseBody: log.responseBody ?? null,
    details: log.details ?? null,
    errorMessage: log.errorMessage ?? null
  });
  return crypto.createHash('sha256').update(stable).digest('hex');
}

export async function syncAuditLogs(
  request: AuditSyncRequest
): Promise<{ inserted: number; duplicates: number; total: number }> {
  let inserted = 0;
  let duplicates = 0;

  const client = await pool.connect();
  try {
    await client.query('begin');
    for (const log of request.logs) {
      const timestampUtc = toUtcDate(log.timestamp);
      const dedupeKey = makeDedupeKey(request, log, timestampUtc);
      const tableId =
        log.tableId === null || log.tableId === undefined || log.tableId === ''
          ? null
          : Number.parseInt(String(log.tableId), 10);
      const localId =
        log.localId === null || log.localId === undefined || log.localId === ''
          ? null
          : Number.parseInt(String(log.localId), 10);
      const responseTimeMs =
        log.responseTimeMs === null ||
        log.responseTimeMs === undefined ||
        log.responseTimeMs === ''
          ? null
          : Number.parseInt(String(log.responseTimeMs), 10);

      const result = await client.query(
        `
          insert into audit_logs (
            shop_id, source_app, device_id, device_name, event_type, table_id,
            command, trace_id, user_id, dedupe_key, timestamp_utc,
            timestamp_bangkok, request_body, response_body, details,
            error_message, local_id, response_time_ms, raw
          )
          values (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11,
            $12, $13, $14, $15,
            $16, $17, $18, $19
          )
          on conflict (dedupe_key) do nothing
        `,
        [
          request.shopId,
          request.sourceApp,
          request.deviceId ?? null,
          request.deviceName ?? null,
          log.eventType,
          Number.isFinite(tableId) ? tableId : null,
          log.command ?? null,
          log.traceId ?? null,
          log.userId ?? null,
          dedupeKey,
          timestampUtc,
          bangkokTimestamp(timestampUtc),
          parseOptionalJson(log.requestBody),
          parseOptionalJson(log.responseBody),
          parseOptionalJson(log.details),
          log.errorMessage ?? null,
          Number.isFinite(localId) ? localId : null,
          Number.isFinite(responseTimeMs) ? responseTimeMs : null,
          log
        ]
      );

      if (result.rowCount === 1) {
        inserted += 1;
      } else {
        duplicates += 1;
      }
    }
    await client.query('commit');
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally {
    client.release();
  }

  return { inserted, duplicates, total: request.logs.length };
}

export async function searchAuditLogs(params: AuditSearchParams): Promise<unknown[]> {
  const { where, values } = buildAuditWhere(params);

  values.push(params.limit);
  const limitIndex = values.length;
  values.push(params.offset);
  const offsetIndex = values.length;

  const result = await pool.query(
    `
      select
        id, shop_id, source_app, device_id, device_name, event_type, table_id,
        command, trace_id, user_id, dedupe_key, local_id, response_time_ms,
        timestamp_utc, timestamp_bangkok,
        request_body, response_body, details, error_message, raw, synced_at
      from audit_logs
      where ${where.join(' and ')}
      order by timestamp_utc asc, id asc
      limit $${limitIndex}
      offset $${offsetIndex}
    `,
    values
  );

  return result.rows;
}

function buildAuditWhere(params: Omit<AuditSearchParams, 'limit' | 'offset'>): {
  where: string[];
  values: unknown[];
} {
  const where: string[] = ['shop_id = $1'];
  const values: unknown[] = [params.shopId];

  function add(condition: string, value: unknown): void {
    values.push(value);
    where.push(condition.replace('?', `$${values.length}`));
  }

  if (params.sourceApp) add('source_app = ?', params.sourceApp);
  if (params.tableId !== undefined) add('table_id = ?', params.tableId);
  if (params.eventType) add('event_type = ?', params.eventType);
  if (params.command) add('command = ?', params.command);
  if (params.traceId) add('trace_id = ?', params.traceId);
  if (params.errorOnly) {
    where.push("(error_message is not null or event_type = 'API_CALL_FAILED')");
  }
  if (params.textSearch) {
    const searchValue = `%${params.textSearch}%`;
    const placeholders = Array.from({ length: 8 }, () => {
      values.push(searchValue);
      return `$${values.length}`;
    });
    where.push(
      `(
        coalesce(command, '') ilike ${placeholders[0]}
        or coalesce(event_type, '') ilike ${placeholders[1]}
        or coalesce(trace_id, '') ilike ${placeholders[2]}
        or coalesce(error_message, '') ilike ${placeholders[3]}
        or request_body::text ilike ${placeholders[4]}
        or response_body::text ilike ${placeholders[5]}
        or details::text ilike ${placeholders[6]}
        or raw::text ilike ${placeholders[7]}
      )`
    );
  }
  if (params.from) add('timestamp_utc >= ?', new Date(params.from));
  if (params.to) add('timestamp_utc <= ?', new Date(params.to));

  return { where, values };
}

export async function countAuditLogs(
  params: Omit<AuditSearchParams, 'limit' | 'offset'>
): Promise<number> {
  const { where, values } = buildAuditWhere(params);
  const result = await pool.query(
    `
      select count(*)::int as total
      from audit_logs
      where ${where.join(' and ')}
    `,
    values
  );

  return Number(result.rows[0]?.total ?? 0);
}
