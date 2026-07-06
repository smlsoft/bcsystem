export const systemLogicKnowledge = {
  domain: 'BC Cashier / Dede Staff restaurant table and bill flow',
  timezone: 'Asia/Bangkok GMT+7',
  tableStatus: {
    0: 'empty/free table',
    1: 'open table with active order/session',
    2: 'closing or waiting payment state'
  },
  closeTableRules: [
    'staff.close_table with documentNumber=PAY_AT_CASHIER_PENDING is an intermediate handoff to cashier, not a final persisted sale invoice.',
    'A final close is stronger evidence when TABLE_CLOSED or staff.close_table has a real docNumber, or when cashier sync.sale_invoice succeeds with the same docNumber/guidpos.',
    'After a final close for a table session, the same table session must not be reopened by an older staff.update_table, table_update broadcast, or stale local state.',
    'A table may open again after final close only as a new table session. Evidence should include a deliberate open action/new session, a table_open_datetime after the close, and normally a fresh amount/order state rather than the old amount reappearing.',
    'If a later update has table_status=1 and amount>0 after final close, treat it as suspicious unless there is clear evidence it is a new session.'
  ],
  staleUpdateRules: [
    'staff.update_table is a state push from staff to cashier and must be validated against server/cashier state.',
    'Reject or flag staff.update_table when its table_open_datetime, revision, or trace context is older than the latest close/final invoice for that table.',
    'If close succeeds then a later update restores amount/order_count/table_status from the pre-close state, the most likely bug class is stale update, replay, delayed staff state, or missing revision guard.',
    'Broadcast order_update/table_update should be treated as state propagation, not as authority to overwrite a newer close state without revision checks.'
  ],
  invoiceRules: [
    'sync.sale_invoice success means the bill was persisted/synced as a sale invoice.',
    'If a real docNumber exists but no sync.sale_invoice follows, classify as incomplete evidence or possible sync delay/failure.',
    'If sync.sale_invoice succeeds and a later table update reopens the same old session, classify as a high-severity invariant violation.'
  ],
  investigationStyle: [
    'Answer like a production bug investigator.',
    'Separate facts, invariant violations, and hypotheses.',
    'Always cite rowId/time/sourceApp/command/traceId/localId when available.',
    'Prefer the nearest relevant close before an update, not the first close of the day.',
    'Do not treat PAY_AT_CASHIER_PENDING alone as final proof of a bill; use it as intermediate context.',
    'When evidence is missing, name the exact missing log or field.'
  ]
} as const;

export type SystemLogicKnowledge = typeof systemLogicKnowledge;
