export interface AuditRow {
  id?: string | number;
  source_app?: 'cashier' | 'staff';
  device_id?: string | null;
  device_name?: string | null;
  event_type?: string;
  table_id?: number | null;
  command?: string | null;
  trace_id?: string | null;
  user_id?: string | null;
  local_id?: number | null;
  response_time_ms?: number | null;
  timestamp_utc?: string;
  timestamp_bangkok?: string;
  request_body?: unknown;
  response_body?: unknown;
  details?: unknown;
  error_message?: string | null;
  raw?: unknown;
}

export interface EventSummary {
  rowId: string;
  timeBangkok: string | null;
  timestampUtc: string | null;
  sourceApp: string | null;
  deviceId: string | null;
  deviceName: string | null;
  userId: string | null;
  eventType: string | null;
  command: string | null;
  tableId: number | null;
  traceId: string | null;
  localId: number | null;
  responseTimeMs: number | null;
  tableStatus: number | null;
  amount: number | null;
  orderCount: number | null;
  orderServedCount: number | null;
  paymentMode: number | null;
  docNumber: string | null;
  guidpos: string | null;
  tableOpenDateTime: string | null;
  detailDiscountFormula: string | null;
  errorMessage: string | null;
  invoiceOutcome: 'success' | 'failed' | 'unknown' | null;
  evidence: string[];
}

export interface BugSignal {
  type: string;
  severity: 'high' | 'medium' | 'low';
  message: string;
  invariant: string;
  evidenceRowIds: string[];
  gapMinutes?: number | null;
  suggestedFix?: string;
}

export interface TimelineEvent extends EventSummary {
  phase: string;
  riskTags: string[];
}

export interface TableTimeline {
  rowCount: number;
  events: TimelineEvent[];
  bugSignals: BugSignal[];
  state: {
    latestFinalizedRowId: string | null;
    latestFinalizedTimeBangkok: string | null;
    latestFinalizedDocNumber: string | null;
    finalBeforeFirstReopenRowId: string | null;
    finalBeforeFirstReopenTimeBangkok: string | null;
    finalBeforeFirstReopenDocNumber: string | null;
    firstReopenAfterFinalCloseRowId: string | null;
    firstReopenAfterFinalCloseTimeBangkok: string | null;
    invoiceRowIds: string[];
    invoiceDocs: string[];
    pendingCloseRowIds: string[];
    hasReopenAfterFinalClose: boolean;
    reopenAfterFinalCloseRowIds: string[];
  };
}

export interface BusinessEvidenceFact {
  rowId: string;
  timeBangkok: string | null;
  sourceApp: string | null;
  eventType: string | null;
  command: string | null;
  tableId: number | null;
  docNumber: string | null;
  guidpos: string | null;
  traceId: string | null;
  localId: number | null;
  paymentMode: number | null;
  amount: number | null;
  errorMessage: string | null;
  evidence: string[];
}

export interface TableSessionSummary {
  sessionKey: string;
  tableId: number;
  status:
    | 'open'
    | 'pending_cashier'
    | 'final_closed'
    | 'invoice_synced'
    | 'invoice_failed'
    | 'unknown';
  startRowId: string | null;
  startTimeBangkok: string | null;
  endRowId: string | null;
  endTimeBangkok: string | null;
  tableOpenDateTime: string | null;
  rowIds: string[];
  docNumbers: string[];
  guidposValues: string[];
  pendingCloseRowIds: string[];
  finalCloseRowIds: string[];
  invoiceSuccessRowIds: string[];
  invoiceFailureRowIds: string[];
  linkedInvoiceRowIds: string[];
  openUpdateRowIds: string[];
  orderRowIds: string[];
  riskTags: string[];
  notes: string[];
}

export interface BillLifecycleSummary {
  billKey: string;
  docNumber: string | null;
  guidpos: string | null;
  status:
    | 'invoice_synced'
    | 'invoice_failed'
    | 'final_close_without_invoice'
    | 'pending_only'
    | 'unknown';
  tableIds: number[];
  firstRowId: string | null;
  firstTimeBangkok: string | null;
  lastRowId: string | null;
  lastTimeBangkok: string | null;
  pendingCloseRowIds: string[];
  finalCloseRowIds: string[];
  invoiceSuccessRowIds: string[];
  invoiceFailureRowIds: string[];
  orderRowIds: string[];
  evidenceRowIds: string[];
  notes: string[];
}

export interface InvoiceSessionLink {
  invoiceRowId: string;
  invoiceTimeBangkok: string | null;
  docNumber: string | null;
  guidpos: string | null;
  tableId: number | null;
  linkedSessionKey: string | null;
  linkedTableId: number | null;
  confidence: 'high' | 'medium' | 'low' | 'none';
  matchReason: string;
}

export interface PendingInvoiceMatch {
  sessionKey: string;
  tableId: number;
  pendingRowId: string;
  pendingTimeBangkok: string | null;
  matchedFinalCloseRowIds: string[];
  matchedInvoiceRowIds: string[];
  matchStatus: 'matched_invoice' | 'matched_final_close' | 'pending_only';
}

export interface BusinessEvidenceSummary {
  hardRules: string[];
  totals: {
    rows: number;
    tableIds: number[];
    invoiceSuccessCount: number;
    invoiceFailureCount: number;
    finalCloseCount: number;
    pendingCloseCount: number;
    openUpdateCount: number;
    errorCount: number;
    tableSessionCount: number;
    billLifecycleCount: number;
  };
  tableSessions: TableSessionSummary[];
  billLifecycles: BillLifecycleSummary[];
  invoiceSessionLinks: InvoiceSessionLink[];
  pendingInvoiceMatches: PendingInvoiceMatch[];
  invoices: BusinessEvidenceFact[];
  invoiceFailures: BusinessEvidenceFact[];
  finalCloses: BusinessEvidenceFact[];
  pendingCloses: BusinessEvidenceFact[];
  openUpdates: BusinessEvidenceFact[];
  errors: BusinessEvidenceFact[];
  missingEvidenceChecklist: string[];
  knownPatternMatches: string[];
  deterministicConclusions: string[];
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function parseJsonText(value: string): unknown {
  const text = value.trim();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function unwrap(value: unknown): unknown {
  const record = asRecord(value);
  if (record && typeof record.text === 'string' && Object.keys(record).length === 1) {
    return parseJsonText(record.text);
  }
  if (typeof value === 'string') return parseJsonText(value);
  return value ?? null;
}

function numberOrNull(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function stringOrNull(value: unknown): string | null {
  if (value === null || value === undefined || value === '') return null;
  return String(value);
}

function firstStringByKeys(value: unknown, keys: string[], maxDepth = 5): string | null {
  const seen = new Set<unknown>();
  const normalizedKeys = new Set(keys.map((key) => key.toLowerCase()));

  function visit(current: unknown, depth: number): string | null {
    if (depth > maxDepth || current === null || current === undefined) return null;
    if (typeof current !== 'object') return null;
    if (seen.has(current)) return null;
    seen.add(current);

    if (Array.isArray(current)) {
      for (const item of current) {
        const result = visit(item, depth + 1);
        if (result) return result;
      }
      return null;
    }

    const record = current as Record<string, unknown>;
    for (const [key, nestedValue] of Object.entries(record)) {
      if (normalizedKeys.has(key.toLowerCase())) {
        const text = stringOrNull(nestedValue);
        if (text) return text;
      }
    }
    for (const nestedValue of Object.values(record)) {
      const result = visit(unwrap(nestedValue), depth + 1);
      if (result) return result;
    }

    return null;
  }

  return visit(unwrap(value), 0);
}

function nestedData(requestBody: unknown): unknown {
  const body = unwrap(requestBody);
  const bodyRecord = asRecord(body);
  if (!bodyRecord) return body;
  const data = bodyRecord.data;
  return data === undefined ? body : unwrap(data);
}

function tableSnapshotFromData(data: unknown): Record<string, unknown> | null {
  const record = asRecord(data);
  if (!record) return null;
  const table = asRecord(record.table);
  return table ?? record;
}

function responseDocNumber(responseBody: unknown): string | null {
  const response = unwrap(responseBody);
  if (typeof response === 'string') return response;
  const record = asRecord(response);
  return stringOrNull(record?.docNumber ?? record?.docno ?? record?.documentNumber);
}

function detailsDocNumber(details: unknown): string | null {
  const record = asRecord(unwrap(details));
  return stringOrNull(record?.documentNumber ?? record?.docNumber ?? record?.docno);
}

function extractDocNumber(...values: unknown[]): string | null {
  for (const value of values) {
    const docNumber = firstStringByKeys(value, [
      'documentNumber',
      'docNumber',
      'docNo',
      'docno',
      'doc_number'
    ]);
    if (docNumber) return docNumber;
  }
  return null;
}

function extractGuidpos(...values: unknown[]): string | null {
  for (const value of values) {
    const guidpos = firstStringByKeys(value, [
      'guidpos',
      'guidPos',
      'guid_pos',
      'guidPOS'
    ]);
    if (guidpos) return guidpos;
  }
  return null;
}

function valueLooksFailed(value: unknown): boolean {
  const text = String(value ?? '').toLowerCase();
  return ['fail', 'failed', 'failure', 'error', 'exception', 'rejected'].some((word) =>
    text.includes(word)
  );
}

function valueLooksSuccess(value: unknown): boolean {
  const text = String(value ?? '').toLowerCase();
  return ['success', 'succeeded', 'ok', 'true'].some((word) => text === word || text.includes(word));
}

function invoiceOutcomeFor(row: AuditRow, responseBody: unknown, details: unknown): EventSummary['invoiceOutcome'] {
  if (row.command !== 'sync.sale_invoice') return null;
  if (row.event_type === 'API_CALL_FAILED' || row.error_message) return 'failed';

  const response = unwrap(responseBody);
  const detailValue = unwrap(details);
  const status =
    firstStringByKeys(response, ['status', 'result', 'state']) ??
    firstStringByKeys(detailValue, ['status', 'result', 'state']);
  if (valueLooksFailed(status)) return 'failed';
  if (valueLooksSuccess(status)) return 'success';
  if (row.event_type === 'API_CALL_SUCCESS') return 'success';

  return 'unknown';
}

export function buildEventSummary(row: AuditRow): EventSummary {
  const requestBody = unwrap(row.request_body);
  const responseBody = unwrap(row.response_body);
  const details = unwrap(row.details);
  const raw = asRecord(row.raw);
  const data = nestedData(requestBody);
  const table = tableSnapshotFromData(data);
  const dataRecord = asRecord(data);
  const detailsRecord = asRecord(details);
  const requestRecord = asRecord(requestBody);
  const responseRecord = asRecord(responseBody);

  const tableStatus = numberOrNull(table?.table_status);
  const amount = numberOrNull(table?.amount ?? detailsRecord?.amount);
  const orderCount = numberOrNull(table?.order_count);
  const orderServedCount = numberOrNull(table?.order_served_count);
  const paymentMode = numberOrNull(dataRecord?.payMode ?? detailsRecord?.paymentMode);
  const docNumber =
    detailsDocNumber(details) ??
    responseDocNumber(responseBody) ??
    stringOrNull(requestRecord?.docNumber ?? responseRecord?.docNumber) ??
    extractDocNumber(details, responseBody, requestBody, data, row.raw);
  const guidpos =
    stringOrNull(requestRecord?.guidpos ?? responseRecord?.guidpos) ??
    extractGuidpos(requestBody, responseBody, details, data, row.raw);
  const invoiceOutcome = invoiceOutcomeFor(row, responseBody, details);

  const evidence = [
    tableStatus !== null ? `table_status=${tableStatus}` : null,
    amount !== null ? `amount=${amount}` : null,
    orderCount !== null ? `order_count=${orderCount}` : null,
    orderServedCount !== null ? `order_served_count=${orderServedCount}` : null,
    paymentMode !== null ? `paymentMode=${paymentMode}` : null,
    docNumber ? `doc=${docNumber}` : null,
    guidpos ? `guidpos=${guidpos}` : null,
    invoiceOutcome ? `invoiceOutcome=${invoiceOutcome}` : null,
    row.error_message ? `error=${row.error_message}` : null,
    raw?.legacyFile ? `file=${raw.legacyFile}` : null
  ].filter(Boolean) as string[];

  return {
    rowId: String(row.id ?? ''),
    timeBangkok: stringOrNull(row.timestamp_bangkok),
    timestampUtc: stringOrNull(row.timestamp_utc),
    sourceApp: stringOrNull(row.source_app),
    deviceId: stringOrNull(row.device_id),
    deviceName: stringOrNull(row.device_name),
    userId: stringOrNull(row.user_id),
    eventType: stringOrNull(row.event_type),
    command: stringOrNull(row.command),
    tableId: numberOrNull(row.table_id),
    traceId: stringOrNull(row.trace_id),
    localId: numberOrNull(row.local_id),
    responseTimeMs: numberOrNull(row.response_time_ms),
    tableStatus,
    amount,
    orderCount,
    orderServedCount,
    paymentMode,
    docNumber,
    guidpos,
    tableOpenDateTime: stringOrNull(table?.table_open_datetime),
    detailDiscountFormula: stringOrNull(table?.detail_discount_formula),
    errorMessage: stringOrNull(row.error_message),
    invoiceOutcome,
    evidence
  };
}

export function minutesBetween(a: string | null, b: string | null): number | null {
  if (!a || !b) return null;
  const first = new Date(a).getTime();
  const second = new Date(b).getTime();
  if (!Number.isFinite(first) || !Number.isFinite(second)) return null;
  return Math.round(((second - first) / 60000) * 10) / 10;
}

export function isCloseEvent(event: EventSummary): boolean {
  return (
    event.eventType === 'TABLE_CLOSED' ||
    event.command === 'staff.close_table' ||
    event.command === 'cashier.close_table'
  );
}

export function isPendingCloseEvent(event: EventSummary): boolean {
  return isCloseEvent(event) && event.docNumber === 'PAY_AT_CASHIER_PENDING';
}

const nonBillDocNumbers = new Set([
  'PAY_AT_CASHIER_PENDING',
  'EMPTY_ORDER_CLOSED',
  'ALREADY_CLOSED',
  'TABLE_REVISION_MISMATCH',
  'STALE_TABLE_UPDATE_REJECTED'
]);

export function isFinalCloseEvent(event: EventSummary): boolean {
  return (
    isCloseEvent(event) &&
    !!event.docNumber &&
    !nonBillDocNumbers.has(event.docNumber)
  );
}

export function isSaleInvoiceEvent(event: EventSummary): boolean {
  return event.command === 'sync.sale_invoice';
}

export function isSuccessfulSaleInvoiceEvent(event: EventSummary): boolean {
  return isSaleInvoiceEvent(event) && event.invoiceOutcome === 'success';
}

export function isFailedSaleInvoiceEvent(event: EventSummary): boolean {
  return isSaleInvoiceEvent(event) && event.invoiceOutcome === 'failed';
}

export function isFinalizedEvent(event: EventSummary): boolean {
  return isFinalCloseEvent(event) || isSuccessfulSaleInvoiceEvent(event);
}

export function isOpenLikeUpdate(event: EventSummary): boolean {
  return (
    event.eventType === 'TABLE_OPENED' ||
    event.command === 'staff.update_table' ||
    event.eventType === 'BROADCAST_TABLE_UPDATE_RECEIVED'
  );
}

function isReopenUpdate(event: EventSummary): boolean {
  return (
    isOpenLikeUpdate(event) &&
    event.tableStatus === 1 &&
    (event.amount ?? 0) > 0
  );
}

function tableOpenTimeIsNotNewer(update: EventSummary, finalEvent: EventSummary): boolean {
  if (!update.tableOpenDateTime || !finalEvent.timeBangkok) return false;
  const openTime = new Date(update.tableOpenDateTime).getTime();
  const finalTime = new Date(finalEvent.timeBangkok).getTime();
  if (!Number.isFinite(openTime) || !Number.isFinite(finalTime)) return false;
  return openTime <= finalTime;
}

function findPreviousSameTable(
  events: EventSummary[],
  target: EventSummary,
  predicate: (event: EventSummary) => boolean
): EventSummary | undefined {
  return events
    .filter((event) => {
      if (event.rowId === target.rowId || event.tableId !== target.tableId) return false;
      if (!predicate(event)) return false;
      const gap = minutesBetween(event.timeBangkok, target.timeBangkok);
      return gap !== null && gap >= 0;
    })
    .at(-1);
}

function sortBugSignals(signals: BugSignal[]): BugSignal[] {
  const severityScore = { high: 0, medium: 1, low: 2 };
  const typeScore = new Map<string, number>([
    ['STALE_SESSION_UPDATE_AFTER_FINAL_CLOSE', 0],
    ['FINAL_CLOSE_THEN_TABLE_REOPENED_OR_UPDATED', 1],
    ['PENDING_CLOSE_THEN_TABLE_UPDATED', 2],
    ['PAY_AT_CASHIER_PENDING_CLOSE', 3],
    ['DUPLICATE_FINAL_CLOSE_FOR_TABLE_RANGE', 4],
    ['CLOSE_THEN_SALE_INVOICE_SYNCED', 5],
    ['LOCAL_ID_ORDER_REGRESSION', 6]
  ]);

  return [...signals].sort((a, b) => {
    const severity = severityScore[a.severity] - severityScore[b.severity];
    if (severity !== 0) return severity;
    const type =
      (typeScore.get(a.type) ?? Number.MAX_SAFE_INTEGER) -
      (typeScore.get(b.type) ?? Number.MAX_SAFE_INTEGER);
    if (type !== 0) return type;
    return (a.gapMinutes ?? 0) - (b.gapMinutes ?? 0);
  });
}

export function detectBugSignals(events: EventSummary[]): BugSignal[] {
  const signals: BugSignal[] = [];
  const closes = events.filter(isCloseEvent);
  const finalizedEvents = events.filter(isFinalizedEvent);
  const openUpdates = events.filter(isReopenUpdate);

  for (const update of openUpdates) {
    const previousFinal = findPreviousSameTable(events, update, isFinalizedEvent);
    if (previousFinal) {
      const gap = minutesBetween(previousFinal.timeBangkok, update.timeBangkok);
      const staleSession = tableOpenTimeIsNotNewer(update, previousFinal);
      signals.push({
        type: staleSession
          ? 'STALE_SESSION_UPDATE_AFTER_FINAL_CLOSE'
          : 'FINAL_CLOSE_THEN_TABLE_REOPENED_OR_UPDATED',
        severity: 'high',
        invariant:
          'After final close or successful sale invoice sync, the same table session must not be reopened by staff.update_table, TABLE_OPENED, or broadcast table_update.',
        message:
          `After finalized row ${previousFinal.rowId}, row ${update.rowId} reopens/updates table ` +
          `${update.tableId ?? '-'} to table_status=1 amount=${update.amount ?? '-'} after ${gap} minutes.`,
        evidenceRowIds: [previousFinal.rowId, update.rowId],
        gapMinutes: gap,
        suggestedFix:
          'Reject stale table updates after final close using server revision/closed_at guard, and require a new table_open_datetime/session id for a new sale.'
      });
      continue;
    }

    const previousPending = findPreviousSameTable(events, update, isCloseEvent);
    if (previousPending) {
      const gap = minutesBetween(previousPending.timeBangkok, update.timeBangkok);
      signals.push({
        type: 'PENDING_CLOSE_THEN_TABLE_UPDATED',
        severity: 'medium',
        invariant:
          'PAY_AT_CASHIER_PENDING is only an intermediate state, but later open updates should still be checked until the final close/invoice is found.',
        message:
          `After close/pending row ${previousPending.rowId}, row ${update.rowId} updates table ` +
          `${update.tableId ?? '-'} to table_status=1 amount=${update.amount ?? '-'} after ${gap} minutes.`,
        evidenceRowIds: [previousPending.rowId, update.rowId],
        gapMinutes: gap,
        suggestedFix:
          'Keep tracing until a real docNumber or sync.sale_invoice confirms final close; if no final record exists, inspect cashier close flow.'
      });
    }
  }

  const pendingCloses = closes.filter(isPendingCloseEvent);
  if (pendingCloses.length > 0) {
    signals.push({
      type: 'PAY_AT_CASHIER_PENDING_CLOSE',
      severity: 'medium',
      invariant:
        'PAY_AT_CASHIER_PENDING means the table is waiting for cashier payment, not fully closed.',
      message:
        `Found ${pendingCloses.length} pending cashier close event(s). They must be paired with a later real docNumber or sale invoice sync.`,
      evidenceRowIds: pendingCloses.slice(0, 8).map((close) => close.rowId),
      suggestedFix:
        'When answering incidents, do not treat PAY_AT_CASHIER_PENDING as the final close point.'
    });
  }

  const saleInvoices = events.filter(isSaleInvoiceEvent);
  for (const invoice of saleInvoices) {
    const matchingClose = findPreviousSameTable(events, invoice, isCloseEvent);
    if (matchingClose) {
      signals.push({
        type: 'CLOSE_THEN_SALE_INVOICE_SYNCED',
        severity: 'low',
        invariant:
          'A successful sale invoice sync is strong evidence that the bill was persisted.',
        message:
          `Invoice sync row ${invoice.rowId} follows close row ${matchingClose.rowId}; doc=${invoice.docNumber ?? matchingClose.docNumber ?? 'unknown'}.`,
        evidenceRowIds: [matchingClose.rowId, invoice.rowId],
        gapMinutes: minutesBetween(matchingClose.timeBangkok, invoice.timeBangkok)
      });
    }
  }

  const finalCloses = events.filter(isFinalCloseEvent);
  if (finalCloses.length > 1) {
    signals.push({
      type: 'DUPLICATE_FINAL_CLOSE_FOR_TABLE_RANGE',
      severity: 'medium',
      invariant:
        'The same table range should normally have one final close per session unless a new session is clearly opened.',
      message:
        `Found ${finalCloses.length} final close rows in the selected range. Confirm whether they are separate table sessions.`,
      evidenceRowIds: finalCloses.slice(0, 8).map((close) => close.rowId),
      suggestedFix:
        'Group future analysis by table session id or table_open_datetime, not only by table id/date.'
    });
  }

  for (let index = 1; index < events.length; index += 1) {
    const previous = events[index - 1];
    const current = events[index];
    if (
      previous.sourceApp === current.sourceApp &&
      previous.deviceId === current.deviceId &&
      previous.localId !== null &&
      current.localId !== null &&
      current.localId < previous.localId
    ) {
      signals.push({
        type: 'LOCAL_ID_ORDER_REGRESSION',
        severity: 'low',
        invariant:
          'Within the same app/device stream, local audit ids should generally increase over time.',
        message:
          `Local id decreased from row ${previous.rowId} localId=${previous.localId} to row ${current.rowId} localId=${current.localId}.`,
        evidenceRowIds: [previous.rowId, current.rowId],
        suggestedFix:
          'Check device clock/order and sync batching if this repeats for the same device.'
      });
    }
  }

  return sortBugSignals(signals);
}

export function classifyPhase(event: EventSummary): string {
  if (isSuccessfulSaleInvoiceEvent(event)) return 'invoice_success';
  if (isFailedSaleInvoiceEvent(event)) return 'invoice_failed';
  if (isSaleInvoiceEvent(event)) return 'invoice_attempt';
  if (isFinalCloseEvent(event)) return 'final_close';
  if (isPendingCloseEvent(event)) return 'pending_close';
  if (isReopenUpdate(event)) return 'open_update';
  if (isOpenLikeUpdate(event)) return 'table_update';
  if (event.tableStatus === 0) return 'table_empty';
  if (event.eventType?.includes('BROADCAST')) return 'broadcast';
  if (event.command?.includes('order')) return 'order';
  return 'other';
}

export function buildTableTimeline(rows: AuditRow[]): TableTimeline {
  const events = rows.map(buildEventSummary);
  const bugSignals = detectBugSignals(events);
  const riskByRowId = new Map<string, string[]>();

  for (const signal of bugSignals) {
    for (const rowId of signal.evidenceRowIds) {
      const tags = riskByRowId.get(rowId) ?? [];
      tags.push(signal.type);
      riskByRowId.set(rowId, tags);
    }
  }

  const timelineEvents = events.map((event) => ({
    ...event,
    phase: classifyPhase(event),
    riskTags: riskByRowId.get(event.rowId) ?? []
  }));

  const finalEvents = timelineEvents.filter(isFinalizedEvent);
  const latestFinalEvent = finalEvents.at(-1);
  const reopenSignals = bugSignals.filter((signal) =>
      ['FINAL_CLOSE_THEN_TABLE_REOPENED_OR_UPDATED', 'STALE_SESSION_UPDATE_AFTER_FINAL_CLOSE'].includes(
        signal.type
      )
  );
  const firstReopenSignal = reopenSignals[0];
  const finalBeforeFirstReopen = timelineEvents.find(
    (event) => event.rowId === firstReopenSignal?.evidenceRowIds[0]
  );
  const firstReopenAfterFinalClose = timelineEvents.find(
    (event) => event.rowId === firstReopenSignal?.evidenceRowIds[1]
  );
  const reopenAfterFinalCloseRowIds = reopenSignals
    .map((signal) => signal.evidenceRowIds.at(-1))
    .filter(Boolean) as string[];

  return {
    rowCount: rows.length,
    events: timelineEvents,
    bugSignals,
    state: {
      latestFinalizedRowId: latestFinalEvent?.rowId ?? null,
      latestFinalizedTimeBangkok: latestFinalEvent?.timeBangkok ?? null,
      latestFinalizedDocNumber: latestFinalEvent?.docNumber ?? null,
      finalBeforeFirstReopenRowId: finalBeforeFirstReopen?.rowId ?? null,
      finalBeforeFirstReopenTimeBangkok: finalBeforeFirstReopen?.timeBangkok ?? null,
      finalBeforeFirstReopenDocNumber: finalBeforeFirstReopen?.docNumber ?? null,
      firstReopenAfterFinalCloseRowId: firstReopenAfterFinalClose?.rowId ?? null,
      firstReopenAfterFinalCloseTimeBangkok: firstReopenAfterFinalClose?.timeBangkok ?? null,
      invoiceRowIds: timelineEvents
        .filter(isSuccessfulSaleInvoiceEvent)
        .map((event) => event.rowId),
      invoiceDocs: [
        ...new Set(
          timelineEvents
            .filter(isSuccessfulSaleInvoiceEvent)
            .map((event) => event.docNumber)
            .filter(Boolean) as string[]
        )
      ],
      pendingCloseRowIds: timelineEvents.filter(isPendingCloseEvent).map((event) => event.rowId),
      hasReopenAfterFinalClose: reopenAfterFinalCloseRowIds.length > 0,
      reopenAfterFinalCloseRowIds
    }
  };
}

function toBusinessFact(event: TimelineEvent): BusinessEvidenceFact {
  return {
    rowId: event.rowId,
    timeBangkok: event.timeBangkok,
    sourceApp: event.sourceApp,
    eventType: event.eventType,
    command: event.command,
    tableId: event.tableId,
    docNumber: event.docNumber,
    guidpos: event.guidpos,
    traceId: event.traceId,
    localId: event.localId,
    paymentMode: event.paymentMode,
    amount: event.amount,
    errorMessage: event.errorMessage,
    evidence: event.evidence
  };
}

function eventTimeMs(event: TimelineEvent): number {
  const time = new Date(event.timeBangkok ?? event.timestampUtc ?? '').getTime();
  return Number.isFinite(time) ? time : 0;
}

function uniqueStrings(values: Array<string | null | undefined>): string[] {
  return [...new Set(values.filter(Boolean) as string[])];
}

function eventLooksLikeSessionOpen(event: TimelineEvent): boolean {
  return (
    event.eventType === 'TABLE_OPENED' ||
    event.command === 'staff.open_table' ||
    (isOpenLikeUpdate(event) && event.tableStatus === 1)
  );
}

function eventLooksLikeOrder(event: TimelineEvent): boolean {
  return !!event.command?.includes('order');
}

function isRealBillDocNumber(docNumber: string | null): docNumber is string {
  if (!docNumber) return false;
  return !nonBillDocNumbers.has(docNumber);
}

function summarizeSessionStatus(events: TimelineEvent[]): TableSessionSummary['status'] {
  if (events.some(isSuccessfulSaleInvoiceEvent)) return 'invoice_synced';
  if (events.some(isFailedSaleInvoiceEvent)) return 'invoice_failed';
  if (events.some(isFinalCloseEvent)) return 'final_closed';
  if (events.some(isPendingCloseEvent)) return 'pending_cashier';
  if (events.some(eventLooksLikeSessionOpen)) return 'open';
  return 'unknown';
}

function buildSessionFromEvents(
  tableId: number,
  index: number,
  events: TimelineEvent[]
): TableSessionSummary {
  const sortedEvents = [...events].sort((a, b) => eventTimeMs(a) - eventTimeMs(b));
  const first = sortedEvents[0];
  const last = sortedEvents.at(-1);
  const riskTags = uniqueStrings(sortedEvents.flatMap((event) => event.riskTags));
  const tableOpenDateTime =
    sortedEvents.find((event) => event.tableOpenDateTime)?.tableOpenDateTime ?? null;
  const status = summarizeSessionStatus(sortedEvents);
  const pendingCloseRowIds = sortedEvents.filter(isPendingCloseEvent).map((event) => event.rowId);
  const finalCloseRowIds = sortedEvents.filter(isFinalCloseEvent).map((event) => event.rowId);
  const invoiceSuccessRowIds = sortedEvents
    .filter(isSuccessfulSaleInvoiceEvent)
    .map((event) => event.rowId);
  const invoiceFailureRowIds = sortedEvents
    .filter(isFailedSaleInvoiceEvent)
    .map((event) => event.rowId);
  const openUpdateRowIds = sortedEvents.filter(isOpenLikeUpdate).map((event) => event.rowId);
  const orderRowIds = sortedEvents.filter(eventLooksLikeOrder).map((event) => event.rowId);
  const docNumbers = uniqueStrings(
    sortedEvents.map((event) =>
      isRealBillDocNumber(event.docNumber) ? event.docNumber : null
    )
  );
  const guidposValues = uniqueStrings(sortedEvents.map((event) => event.guidpos));
  const notes: string[] = [];

  if (pendingCloseRowIds.length > 0 && invoiceSuccessRowIds.length > 0) {
    notes.push('pending cashier handoff is followed by successful sale invoice sync');
  }
  if (pendingCloseRowIds.length > 0 && invoiceSuccessRowIds.length === 0) {
    notes.push('pending cashier handoff exists but no sale invoice success in this session evidence');
  }
  if (finalCloseRowIds.length > 0 && invoiceSuccessRowIds.length === 0) {
    notes.push('real final close exists but sale invoice success is not present in this session evidence');
  }
  if (riskTags.some((tag) => tag.includes('REOPEN') || tag.includes('STALE'))) {
    notes.push('session has reopen/stale-update risk tags');
  }

  return {
    sessionKey: `table:${tableId}:session:${index}`,
    tableId,
    status,
    startRowId: first?.rowId ?? null,
    startTimeBangkok: first?.timeBangkok ?? null,
    endRowId: last?.rowId ?? null,
    endTimeBangkok: last?.timeBangkok ?? null,
    tableOpenDateTime,
    rowIds: sortedEvents.map((event) => event.rowId),
    docNumbers,
    guidposValues,
    pendingCloseRowIds,
    finalCloseRowIds,
    invoiceSuccessRowIds,
    invoiceFailureRowIds,
    linkedInvoiceRowIds: [],
    openUpdateRowIds,
    orderRowIds,
    riskTags,
    notes
  };
}

function buildTableSessions(events: TimelineEvent[]): TableSessionSummary[] {
  const byTableId = new Map<number, TimelineEvent[]>();
  for (const event of events) {
    if (event.tableId === null) continue;
    const tableEvents = byTableId.get(event.tableId) ?? [];
    tableEvents.push(event);
    byTableId.set(event.tableId, tableEvents);
  }

  const sessions: TableSessionSummary[] = [];
  for (const [tableId, tableEvents] of byTableId.entries()) {
    const sortedEvents = [...tableEvents].sort((a, b) => eventTimeMs(a) - eventTimeMs(b));
    let current: TimelineEvent[] = [];
    let sessionIndex = 1;
    let finalized = false;

    for (const event of sortedEvents) {
      const startsAfterFinal =
        finalized &&
        eventLooksLikeSessionOpen(event) &&
        (!event.tableOpenDateTime ||
          !current.some(
            (currentEvent) => currentEvent.tableOpenDateTime === event.tableOpenDateTime
          ));

      if (current.length > 0 && startsAfterFinal) {
        sessions.push(buildSessionFromEvents(tableId, sessionIndex, current));
        sessionIndex += 1;
        current = [];
        finalized = false;
      }

      current.push(event);
      if (isFinalizedEvent(event)) finalized = true;
    }

    if (current.length > 0) {
      sessions.push(buildSessionFromEvents(tableId, sessionIndex, current));
    }
  }

  return sessions.sort((a, b) => {
    const aTime = new Date(a.startTimeBangkok ?? '').getTime();
    const bTime = new Date(b.startTimeBangkok ?? '').getTime();
    return (Number.isFinite(aTime) ? aTime : 0) - (Number.isFinite(bTime) ? bTime : 0);
  });
}

function timeWithinSessionWindow(event: TimelineEvent, session: TableSessionSummary): boolean {
  const eventMs = eventTimeMs(event);
  const startMs = new Date(session.startTimeBangkok ?? '').getTime();
  const endMs = new Date(session.endTimeBangkok ?? '').getTime();
  if (!Number.isFinite(eventMs) || !Number.isFinite(startMs)) return false;
  const effectiveEndMs = Number.isFinite(endMs) ? endMs : startMs;
  return eventMs >= startMs - 5 * 60 * 1000 && eventMs <= effectiveEndMs + 45 * 60 * 1000;
}

function findInvoiceSessionLink(
  invoice: TimelineEvent,
  sessions: TableSessionSummary[]
): InvoiceSessionLink {
  const sameRowSession = sessions.find((session) => session.rowIds.includes(invoice.rowId));
  if (sameRowSession) {
    return {
      invoiceRowId: invoice.rowId,
      invoiceTimeBangkok: invoice.timeBangkok,
      docNumber: invoice.docNumber,
      guidpos: invoice.guidpos,
      tableId: invoice.tableId,
      linkedSessionKey: sameRowSession.sessionKey,
      linkedTableId: sameRowSession.tableId,
      confidence: 'high',
      matchReason: 'invoice row already belongs to table session'
    };
  }

  const identitySession = sessions.find(
    (session) =>
      (invoice.docNumber && session.docNumbers.includes(invoice.docNumber)) ||
      (invoice.guidpos && session.guidposValues.includes(invoice.guidpos))
  );
  if (identitySession) {
    return {
      invoiceRowId: invoice.rowId,
      invoiceTimeBangkok: invoice.timeBangkok,
      docNumber: invoice.docNumber,
      guidpos: invoice.guidpos,
      tableId: invoice.tableId,
      linkedSessionKey: identitySession.sessionKey,
      linkedTableId: identitySession.tableId,
      confidence: 'high',
      matchReason: 'matched by docNumber/guidpos'
    };
  }

  if (invoice.tableId !== null) {
    const timeSession = sessions.find(
      (session) => session.tableId === invoice.tableId && timeWithinSessionWindow(invoice, session)
    );
    if (timeSession) {
      return {
        invoiceRowId: invoice.rowId,
        invoiceTimeBangkok: invoice.timeBangkok,
        docNumber: invoice.docNumber,
        guidpos: invoice.guidpos,
        tableId: invoice.tableId,
        linkedSessionKey: timeSession.sessionKey,
        linkedTableId: timeSession.tableId,
        confidence: 'medium',
        matchReason: 'matched by tableId and session time window'
      };
    }
  }

  return {
    invoiceRowId: invoice.rowId,
    invoiceTimeBangkok: invoice.timeBangkok,
    docNumber: invoice.docNumber,
    guidpos: invoice.guidpos,
    tableId: invoice.tableId,
    linkedSessionKey: null,
    linkedTableId: null,
    confidence: 'none',
    matchReason: 'no matching session by row, identity, table, or time window'
  };
}

function buildInvoiceSessionLinks(
  events: TimelineEvent[],
  sessions: TableSessionSummary[]
): InvoiceSessionLink[] {
  return events.filter(isSaleInvoiceEvent).map((invoice) =>
    findInvoiceSessionLink(invoice, sessions)
  );
}

function applyInvoiceSessionLinks(
  sessions: TableSessionSummary[],
  events: TimelineEvent[],
  links: InvoiceSessionLink[]
): TableSessionSummary[] {
  const eventByRowId = new Map(events.map((event) => [event.rowId, event]));
  const sessionsByKey = new Map(sessions.map((session) => [session.sessionKey, { ...session }]));

  for (const link of links) {
    if (!link.linkedSessionKey) continue;
    const session = sessionsByKey.get(link.linkedSessionKey);
    const invoice = eventByRowId.get(link.invoiceRowId);
    if (!session || !invoice) continue;

    if (!session.rowIds.includes(invoice.rowId)) {
      session.linkedInvoiceRowIds = uniqueStrings([
        ...session.linkedInvoiceRowIds,
        invoice.rowId
      ]);
    }
    if (isSuccessfulSaleInvoiceEvent(invoice)) {
      session.invoiceSuccessRowIds = uniqueStrings([
        ...session.invoiceSuccessRowIds,
        invoice.rowId
      ]);
      session.status = 'invoice_synced';
      session.notes = session.notes.filter(
        (note) =>
          note !== 'real final close exists but sale invoice success is not present in this session evidence' &&
          note !== 'pending cashier handoff exists but no sale invoice success in this session evidence'
      );
      if (
        session.pendingCloseRowIds.length > 0 &&
        !session.notes.includes('pending cashier handoff is followed by successful sale invoice sync')
      ) {
        session.notes.push('pending cashier handoff is followed by successful sale invoice sync');
      }
    }
    if (isFailedSaleInvoiceEvent(invoice)) {
      session.invoiceFailureRowIds = uniqueStrings([
        ...session.invoiceFailureRowIds,
        invoice.rowId
      ]);
      if (session.status !== 'invoice_synced') session.status = 'invoice_failed';
    }
    session.docNumbers = uniqueStrings([
      ...session.docNumbers,
      isRealBillDocNumber(invoice.docNumber) ? invoice.docNumber : null
    ]);
    session.guidposValues = uniqueStrings([...session.guidposValues, invoice.guidpos]);
    if (!session.notes.includes(`invoice link: ${link.matchReason}`)) {
      session.notes.push(`invoice link: ${link.matchReason}`);
    }
  }

  return [...sessionsByKey.values()].sort((a, b) => {
    const aTime = new Date(a.startTimeBangkok ?? '').getTime();
    const bTime = new Date(b.startTimeBangkok ?? '').getTime();
    return (Number.isFinite(aTime) ? aTime : 0) - (Number.isFinite(bTime) ? bTime : 0);
  });
}

function buildPendingInvoiceMatches(
  sessions: TableSessionSummary[],
  events: TimelineEvent[]
): PendingInvoiceMatch[] {
  const eventByRowId = new Map(events.map((event) => [event.rowId, event]));

  return sessions.flatMap((session) =>
    session.pendingCloseRowIds.map((pendingRowId) => {
      const pending = eventByRowId.get(pendingRowId);
      const pendingMs = pending ? eventTimeMs(pending) : 0;
      const afterPending = (rowId: string): boolean => {
        const event = eventByRowId.get(rowId);
        if (!event || !pendingMs) return true;
        return eventTimeMs(event) >= pendingMs;
      };
      const matchedInvoiceRowIds = session.invoiceSuccessRowIds.filter(afterPending);
      const matchedFinalCloseRowIds = session.finalCloseRowIds.filter(afterPending);

      return {
        sessionKey: session.sessionKey,
        tableId: session.tableId,
        pendingRowId,
        pendingTimeBangkok: pending?.timeBangkok ?? null,
        matchedFinalCloseRowIds,
        matchedInvoiceRowIds,
        matchStatus:
          matchedInvoiceRowIds.length > 0
            ? 'matched_invoice'
            : matchedFinalCloseRowIds.length > 0
              ? 'matched_final_close'
              : 'pending_only'
      };
    })
  );
}

function billKeyForEvent(
  event: TimelineEvent,
  docToGuidposKey: Map<string, string>
): string | null {
  if (isRealBillDocNumber(event.docNumber)) {
    return docToGuidposKey.get(event.docNumber) ?? `doc:${event.docNumber}`;
  }
  if (event.guidpos) return `guidpos:${event.guidpos}`;
  return null;
}

function summarizeBillStatus(events: TimelineEvent[]): BillLifecycleSummary['status'] {
  if (events.some(isSuccessfulSaleInvoiceEvent)) return 'invoice_synced';
  if (events.some(isFailedSaleInvoiceEvent)) return 'invoice_failed';
  if (events.some(isFinalCloseEvent)) return 'final_close_without_invoice';
  if (events.some(isPendingCloseEvent)) return 'pending_only';
  return 'unknown';
}

function buildBillLifecycles(events: TimelineEvent[]): BillLifecycleSummary[] {
  const byBillKey = new Map<string, TimelineEvent[]>();
  const docToGuidposKey = new Map<string, string>();

  for (const event of events) {
    if (event.guidpos && isRealBillDocNumber(event.docNumber)) {
      docToGuidposKey.set(event.docNumber, `guidpos:${event.guidpos}`);
    }
  }

  for (const event of events) {
    const key = billKeyForEvent(event, docToGuidposKey);
    if (!key) continue;
    const billEvents = byBillKey.get(key) ?? [];
    billEvents.push(event);
    byBillKey.set(key, billEvents);
  }

  return [...byBillKey.entries()]
    .map(([billKey, billEvents]) => {
      const sortedEvents = [...billEvents].sort((a, b) => eventTimeMs(a) - eventTimeMs(b));
      const first = sortedEvents[0];
      const last = sortedEvents.at(-1);
      const docNumber =
        sortedEvents.find((event) => isRealBillDocNumber(event.docNumber))?.docNumber ??
        null;
      const guidpos = sortedEvents.find((event) => event.guidpos)?.guidpos ?? null;
      const pendingCloseRowIds = sortedEvents
        .filter(isPendingCloseEvent)
        .map((event) => event.rowId);
      const finalCloseRowIds = sortedEvents.filter(isFinalCloseEvent).map((event) => event.rowId);
      const invoiceSuccessRowIds = sortedEvents
        .filter(isSuccessfulSaleInvoiceEvent)
        .map((event) => event.rowId);
      const invoiceFailureRowIds = sortedEvents
        .filter(isFailedSaleInvoiceEvent)
        .map((event) => event.rowId);
      const orderRowIds = sortedEvents.filter(eventLooksLikeOrder).map((event) => event.rowId);
      const status = summarizeBillStatus(sortedEvents);
      const notes: string[] = [];

      if (status === 'invoice_synced') {
        notes.push('sale invoice sync succeeded; this is strong persisted-bill evidence');
      }
      if (pendingCloseRowIds.length > 0 && invoiceSuccessRowIds.length > 0) {
        notes.push('pending cashier handoff later reached invoice success');
      }
      if (status === 'final_close_without_invoice') {
        notes.push('check nearby sync.sale_invoice rows because invoice success is missing in this filter');
      }

      return {
        billKey,
        docNumber,
        guidpos,
        status,
        tableIds: [
          ...new Set(
            sortedEvents
              .map((event) => event.tableId)
              .filter((tableId): tableId is number => tableId !== null)
          )
        ].sort((a, b) => a - b),
        firstRowId: first?.rowId ?? null,
        firstTimeBangkok: first?.timeBangkok ?? null,
        lastRowId: last?.rowId ?? null,
        lastTimeBangkok: last?.timeBangkok ?? null,
        pendingCloseRowIds,
        finalCloseRowIds,
        invoiceSuccessRowIds,
        invoiceFailureRowIds,
        orderRowIds,
        evidenceRowIds: sortedEvents.map((event) => event.rowId),
        notes
      };
    })
    .sort((a, b) => {
      const aTime = new Date(a.firstTimeBangkok ?? '').getTime();
      const bTime = new Date(b.firstTimeBangkok ?? '').getTime();
      return (Number.isFinite(aTime) ? aTime : 0) - (Number.isFinite(bTime) ? bTime : 0);
    });
}

function buildMissingEvidenceChecklist(timeline: TableTimeline): string[] {
  const checklist: string[] = [];
  const hasClose = timeline.events.some(isCloseEvent);
  const hasPendingClose = timeline.events.some(isPendingCloseEvent);
  const hasInvoice = timeline.events.some(isSuccessfulSaleInvoiceEvent);
  const hasInvoiceFailure = timeline.events.some(isFailedSaleInvoiceEvent);
  const hasOrderSend = timeline.events.some((event) =>
    event.command?.includes('send_order')
  );
  const hasOpen = timeline.events.some(eventLooksLikeSessionOpen);

  if (!hasOpen) checklist.push('Missing table open evidence in the selected range.');
  if (!hasOrderSend) checklist.push('Missing send-order evidence in the selected range.');
  if (!hasClose) checklist.push('Missing close-table evidence in the selected range.');
  if (hasPendingClose && !hasInvoice) {
    checklist.push(
      'Pending cashier close exists but no successful sync.sale_invoice is present in the selected range.'
    );
  }
  if (hasInvoiceFailure && !hasInvoice) {
    checklist.push('Invoice sync failed and no later successful invoice sync is present in the selected range.');
  }
  if (checklist.length === 0) {
    checklist.push('No obvious missing lifecycle evidence from this selected range.');
  }

  return checklist;
}

function buildKnownPatternMatches(
  timeline: TableTimeline,
  billLifecycles: BillLifecycleSummary[],
  invoiceSessionLinks: InvoiceSessionLink[],
  pendingInvoiceMatches: PendingInvoiceMatch[]
): string[] {
  const matches = new Set<string>();

  for (const signal of timeline.bugSignals) {
    matches.add(signal.type);
  }
  for (const bill of billLifecycles) {
    if (bill.status === 'invoice_synced') matches.add('BILL_LIFECYCLE_INVOICE_SYNCED');
    if (bill.status === 'final_close_without_invoice') {
      matches.add('BILL_LIFECYCLE_FINAL_CLOSE_WITHOUT_INVOICE_IN_FILTER');
    }
    if (bill.invoiceFailureRowIds.length > 0) matches.add('BILL_LIFECYCLE_INVOICE_FAILURE');
  }
  if (timeline.events.some(isPendingCloseEvent)) matches.add('TABLE_SESSION_HAS_PENDING_HANDOFF');
  if (invoiceSessionLinks.some((link) => link.confidence === 'none')) {
    matches.add('UNLINKED_SALE_INVOICE');
  }
  if (pendingInvoiceMatches.some((match) => match.matchStatus === 'pending_only')) {
    matches.add('PENDING_WITHOUT_MATCHED_INVOICE_IN_SESSION');
  }

  if (matches.size === 0) matches.add('NO_KNOWN_PATTERN_MATCHED');
  return [...matches];
}

export function buildBusinessEvidenceSummary(
  timeline: TableTimeline
): BusinessEvidenceSummary {
  const initialTableSessions = buildTableSessions(timeline.events);
  const invoiceSessionLinks = buildInvoiceSessionLinks(timeline.events, initialTableSessions);
  const tableSessions = applyInvoiceSessionLinks(
    initialTableSessions,
    timeline.events,
    invoiceSessionLinks
  );
  const pendingInvoiceMatches = buildPendingInvoiceMatches(tableSessions, timeline.events);
  const billLifecycles = buildBillLifecycles(timeline.events);
  const invoiceSuccesses = timeline.events.filter(isSuccessfulSaleInvoiceEvent);
  const invoiceFailures = timeline.events.filter(isFailedSaleInvoiceEvent);
  const finalCloses = timeline.events.filter(isFinalCloseEvent);
  const pendingCloses = timeline.events.filter(isPendingCloseEvent);
  const openUpdates = timeline.events.filter(isReopenUpdate);
  const errors = timeline.events.filter(
    (event) => !!event.errorMessage || event.eventType === 'API_CALL_FAILED'
  );
  const missingEvidenceChecklist = buildMissingEvidenceChecklist(timeline);
  const knownPatternMatches = buildKnownPatternMatches(
    timeline,
    billLifecycles,
    invoiceSessionLinks,
    pendingInvoiceMatches
  );
  const tableIds = [
    ...new Set(
      timeline.events
        .map((event) => event.tableId)
        .filter((tableId): tableId is number => tableId !== null)
    )
  ].sort((a, b) => a - b);

  const deterministicConclusions: string[] = [];
  if (invoiceSuccesses.length > 0) {
    const docs = [
      ...new Set(invoiceSuccesses.map((event) => event.docNumber).filter(Boolean))
    ].join(', ');
    deterministicConclusions.push(
      `FOUND_SALE_INVOICE_SUCCESS: found ${invoiceSuccesses.length} successful sync.sale_invoice row(s); docs=${docs || 'unknown'}. Do not answer that no bill was recorded for those docNumber(s).`
    );
  }
  const matchedPendingCount = pendingInvoiceMatches.filter(
    (match) => match.matchStatus === 'matched_invoice'
  ).length;
  const pendingOnlyCount = pendingInvoiceMatches.filter(
    (match) => match.matchStatus === 'pending_only'
  ).length;
  if (matchedPendingCount > 0) {
    deterministicConclusions.push(
      `SESSION_PENDING_THEN_INVOICE: ${matchedPendingCount} pending close row(s) are matched to later invoice success within their own table session.`
    );
  }
  if (pendingOnlyCount > 0) {
    deterministicConclusions.push(
      `SESSION_PENDING_ONLY: ${pendingOnlyCount} pending close row(s) have no matched invoice success in their own table session evidence.`
    );
  }
  if (finalCloses.length > 0 && invoiceSuccesses.length === 0) {
    deterministicConclusions.push(
      'FINAL_CLOSE_WITHOUT_INVOICE_IN_RANGE: real final close exists, but no successful sync.sale_invoice was found in this filter range; check adjacent sync logs before saying sync failed.'
    );
  }
  if (invoiceFailures.length > 0) {
    deterministicConclusions.push(
      `SALE_INVOICE_FAILURE: found ${invoiceFailures.length} failed sync.sale_invoice row(s); inspect errorMessage and retry/sync status.`
    );
  }
  if (timeline.state.hasReopenAfterFinalClose) {
    deterministicConclusions.push(
      `REOPEN_AFTER_FINAL_CLOSE: finalized row ${timeline.state.finalBeforeFirstReopenRowId ?? '-'} is followed by open/update row ${timeline.state.firstReopenAfterFinalCloseRowId ?? '-'}; treat as stale update/replay risk unless a new session is proven.`
    );
  }
  if (deterministicConclusions.length === 0) {
    deterministicConclusions.push(
      'NO_STRONG_BILL_CONCLUSION: no successful invoice, final close, pending close, or reopen-after-final-close signal was detected in this selected evidence.'
    );
  }

  return {
    hardRules: [
      'If invoices contains a row, the answer must say a sale invoice was recorded/synced for that docNumber.',
      'Never summarize PAY_AT_CASHIER_PENDING as a final bill; it is only a cashier-payment handoff.',
      'If both pendingCloses and invoices exist in the same filtered range, summarize the sequence as pending first, then final invoice success.',
      'If wasTruncated is false, do not blame missing evidence on limit.',
      'Use tableId, docNumber, guidpos, rowId, and timeBangkok from this summary as higher-priority facts than broad narrative inference.',
      'Use tableSessions to separate different visits on the same table, especially when the user asks by table and time.',
      'Use billLifecycles for bill/docNumber/guidpos questions, and prefer guidpos as the strongest identity when it exists.'
    ],
    totals: {
      rows: timeline.rowCount,
      tableIds,
      invoiceSuccessCount: invoiceSuccesses.length,
      invoiceFailureCount: invoiceFailures.length,
      finalCloseCount: finalCloses.length,
      pendingCloseCount: pendingCloses.length,
      openUpdateCount: openUpdates.length,
      errorCount: errors.length,
      tableSessionCount: tableSessions.length,
      billLifecycleCount: billLifecycles.length
    },
    tableSessions,
    billLifecycles,
    invoiceSessionLinks,
    pendingInvoiceMatches,
    invoices: invoiceSuccesses.map(toBusinessFact),
    invoiceFailures: invoiceFailures.map(toBusinessFact),
    finalCloses: finalCloses.map(toBusinessFact),
    pendingCloses: pendingCloses.map(toBusinessFact),
    openUpdates: openUpdates.map(toBusinessFact),
    errors: errors.slice(0, 30).map(toBusinessFact),
    missingEvidenceChecklist,
    knownPatternMatches,
    deterministicConclusions
  };
}

export function compactRawRows(rows: AuditRow[], evidenceIds: Set<string>): unknown[] {
  return rows
    .filter((row) => evidenceIds.has(String(row.id ?? '')))
    .slice(0, 120)
    .map((row) => ({
      id: row.id,
      source_app: row.source_app,
      event_type: row.event_type,
      table_id: row.table_id,
      command: row.command,
      trace_id: row.trace_id,
      local_id: row.local_id,
      response_time_ms: row.response_time_ms,
      timestamp_bangkok: row.timestamp_bangkok,
      request_body: row.request_body,
      response_body: row.response_body,
      details: row.details,
      error_message: row.error_message
    }));
}
