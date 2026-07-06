import OpenAI from 'openai';
import { config } from '../config.js';
import { countAuditLogs, searchAuditLogs } from './auditRepository.js';
import {
  type AuditRow,
  buildBusinessEvidenceSummary,
  buildTableTimeline,
  compactRawRows
} from './auditAnalysis.js';
import { sourceCodeLogicKnowledge } from './sourceCodeLogicKnowledge.js';
import { systemLogicKnowledge } from './systemLogicKnowledge.js';

export interface AnalyzeRequest {
  shopId: string;
  question: string;
  tableId?: number;
  from?: string;
  to?: string;
  sourceApp?: 'cashier' | 'staff';
  eventType?: string;
  command?: string;
  textSearch?: string;
  errorOnly?: boolean;
  limit?: number;
}

function buildFallbackAnswer(
  timeline: ReturnType<typeof buildTableTimeline>,
  businessEvidence: ReturnType<typeof buildBusinessEvidenceSummary>,
  question: string
): string {
  const signalLines = timeline.bugSignals.length
    ? timeline.bugSignals
        .slice(0, 8)
        .map((signal, index) => `${index + 1}. [${signal.severity}] ${signal.message}`)
    : ['ไม่พบ pattern bug ชัดเจนจาก deterministic detector เบื้องต้น'];

  const invoiceLines = businessEvidence.invoices.length
    ? businessEvidence.invoices.map(
        (invoice) =>
          `- row ${invoice.rowId} ${invoice.timeBangkok} table=${invoice.tableId ?? '-'} ` +
          `doc=${invoice.docNumber ?? '-'} guidpos=${invoice.guidpos ?? '-'}`
      )
    : ['- ไม่พบ sync.sale_invoice success ในช่วงข้อมูลที่เลือก'];

  const timelineLines = timeline.events.slice(0, 15).map((event) => {
    const risk = event.riskTags.length ? ` risk=${event.riskTags.join('|')}` : '';
    return (
      `- row ${event.rowId} ${event.timeBangkok} ${event.sourceApp} ` +
      `${event.eventType}/${event.command ?? '-'} phase=${event.phase}${risk} ` +
      event.evidence.join(', ')
    );
  });

  return [
    'ยังไม่ได้ตั้งค่า OPENAI_API_KEY จึงสรุปจาก deterministic detector แบบไม่ใช้ AI',
    `คำถาม: ${question}`,
    `จำนวน audit events ที่พบ: ${timeline.rowCount}`,
    '',
    'Deterministic conclusions:',
    ...businessEvidence.deterministicConclusions,
    '',
    'Sale invoice success:',
    ...invoiceLines,
    '',
    'Bug signals:',
    ...signalLines,
    '',
    'Timeline sample:',
    ...timelineLines
  ].join('\n');
}

export async function analyzeAuditQuestion(
  request: AnalyzeRequest
): Promise<{ answer: string; rows: unknown[] }> {
  const searchParams = {
    shopId: request.shopId,
    sourceApp: request.sourceApp,
    tableId: request.tableId,
    eventType: request.eventType,
    command: request.command,
    textSearch: request.textSearch,
    errorOnly: request.errorOnly,
    from: request.from,
    to: request.to,
    limit: Math.min(request.limit ?? config.maxAnalysisRows, config.maxAnalysisRows),
    offset: 0
  };
  const [rows, totalMatchingRows] = await Promise.all([
    searchAuditLogs(searchParams) as Promise<AuditRow[]>,
    countAuditLogs(searchParams)
  ]);
  const wasTruncated = totalMatchingRows > rows.length;

  const timeline = buildTableTimeline(rows);
  const businessEvidence = buildBusinessEvidenceSummary(timeline);
  const evidenceIds = new Set([
    ...timeline.bugSignals.flatMap((signal) => signal.evidenceRowIds),
    ...businessEvidence.invoices.map((event) => event.rowId),
    ...businessEvidence.invoiceFailures.map((event) => event.rowId),
    ...businessEvidence.finalCloses.map((event) => event.rowId),
    ...businessEvidence.pendingCloses.map((event) => event.rowId),
    ...businessEvidence.errors.map((event) => event.rowId),
    ...businessEvidence.openUpdates.map((event) => event.rowId),
    ...businessEvidence.billLifecycles.flatMap((bill) => bill.evidenceRowIds),
    ...businessEvidence.invoiceSessionLinks.map((link) => link.invoiceRowId),
    ...businessEvidence.pendingInvoiceMatches.flatMap((match) => [
      match.pendingRowId,
      ...match.matchedFinalCloseRowIds,
      ...match.matchedInvoiceRowIds
    ])
  ]);
  const rawEvidenceRows = compactRawRows(rows, evidenceIds);

  if (!config.openAiApiKey) {
    return {
      answer: buildFallbackAnswer(timeline, businessEvidence, request.question),
      rows
    };
  }

  const client = new OpenAI({ apiKey: config.openAiApiKey });
  const completion = await client.chat.completions.create({
    model: config.openAiModel,
    temperature: 0.05,
    messages: [
      {
        role: 'system',
        content: [
          'You are a senior POS bug investigator for a restaurant system.',
          'Answer in Thai as an engineer investigating a production bug, not as customer support.',
          'Use only the provided businessEvidenceSummary, tableTimeline, deterministicBugSignals, and raw evidence rows.',
          'Use businessEvidenceSummary as the highest-priority factual summary. It contains deterministic conclusions derived from the audit rows.',
          'Use businessEvidenceSummary.tableSessions to separate different visits/sessions on the same table. Do not mix old bills from the same table into a newer table session unless the session summary links them.',
          'Use businessEvidenceSummary.billLifecycles to answer bill/docNumber/guidpos questions. Prefer guidpos over docNumber when both exist.',
          'Use businessEvidenceSummary.invoiceSessionLinks to explain whether each sync.sale_invoice was linked to a table session; call out unlinked invoices explicitly.',
          'Use businessEvidenceSummary.pendingInvoiceMatches to decide whether each PAY_AT_CASHIER_PENDING row reached a final close or invoice within the same session.',
          'Use businessEvidenceSummary.missingEvidenceChecklist to say exactly what logs are missing before forming a hypothesis.',
          'Use businessEvidenceSummary.knownPatternMatches as the bug-pattern library for concise diagnosis.',
          'Treat deterministicBugSignals as the primary diagnosis scaffold; explain them clearly instead of ignoring them.',
          'Apply the provided systemLogicKnowledge as business rules for interpreting the logs.',
          'Apply sourceCodeLogicKnowledge as the current source-code behavior. If old logs conflict with current source behavior, call that out explicitly.',
          'Before writing the answer, check businessEvidenceSummary.deterministicConclusions, invoices, finalCloses, pendingCloses, errors, invoiceSessionLinks, and pendingInvoiceMatches.',
          'If businessEvidenceSummary.invoices is non-empty, you must state that sale invoice sync succeeded for those docNumber/guidpos values. Do not answer that there is no bill or no final evidence for those invoices.',
          'Only say PAY_AT_CASHIER_PENDING became an invoice when pendingInvoiceMatches shows matched_invoice for that same session.',
          'If multiple tableSessions exist for the same table, answer session by session and identify which session best matches the user question by time/docNumber.',
          'If wasTruncated=false, do not say the answer may be wrong because of limit. If wasTruncated=true, explicitly warn that the matching data exceeded the provided rows.',
          'Always cite evidence using rowId, timeBangkok, sourceApp, command/eventType, traceId/localId when available.',
          'Focus on invariant violations such as a closed table receiving a later stale update, duplicate close, missing invoice sync, delayed staff update, or broadcast replay.',
          'Separate facts from hypotheses. If evidence is insufficient, say exactly what log is missing.',
          'Required Thai sections: ข้อสรุป, Timeline หลักฐาน, จุดที่ผิดจาก logic ปกติ, Hypothesis บัค, จุดที่ควรแก้/ตรวจต่อ.',
          'Do not invent rows, code paths, timestamps, or causes.'
        ].join(' ')
      },
      {
        role: 'user',
        content: JSON.stringify(
          {
            question: request.question,
            timezone: config.defaultTimezone,
            systemLogicKnowledge,
            sourceCodeLogicKnowledge,
            filters: {
              shopId: request.shopId,
              tableId: request.tableId ?? null,
              sourceApp: request.sourceApp ?? null,
              eventType: request.eventType ?? null,
              command: request.command ?? null,
              textSearch: request.textSearch ?? null,
              errorOnly: request.errorOnly ?? null,
              from: request.from ?? null,
              to: request.to ?? null
            },
            rowCount: rows.length,
            totalMatchingRows,
            limit: searchParams.limit,
            wasTruncated,
            businessEvidenceSummary: businessEvidence,
            tableTimeline: timeline,
            deterministicBugSignals: timeline.bugSignals,
            rawEvidenceRows
          },
          null,
          2
        )
      }
    ]
  });

  return {
    answer: completion.choices[0]?.message.content ?? 'AI ไม่สามารถสรุปผลได้',
    rows
  };
}
