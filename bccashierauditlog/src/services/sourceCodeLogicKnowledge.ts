export const sourceCodeLogicKnowledge = {
  domain: 'Observed cashier/staff source-code logic paths',
  lastReviewed: '2026-06-01',
  sourceReferences: [
    {
      file: 'dedecashier/lib/api/network/server_post.dart',
      lines: '50-160, 1406-1888, 2253-2505',
      topic: 'HTTP terminal handlers for staff.close_table and staff.update_table'
    },
    {
      file: 'dedecashier/lib/api/network/websocket_server.dart',
      lines: '697-715, 1883-2052',
      topic: 'WebSocket table command broadcast and update-table handling'
    },
    {
      file: 'dedestaff2/lib/utility/api.dart',
      lines: '841-883, 1144-1220',
      topic: 'Staff app HTTP calls to terminal for update_table and close_table'
    },
    {
      file: 'dedecashier/lib/api/sync/sync_bill.dart',
      lines: '80-100, 117-157, 596-610, 841-968',
      topic: 'Sale invoice sync audit, guidpos dedupe, and idempotency'
    },
    {
      file: 'dedestaff2/lib/api/websocket_client.dart',
      lines: '477-486',
      topic: 'Staff receives order_update/table_update broadcasts'
    }
  ],
  closeTableFlow: [
    'dedestaff2 closeTableToTerminal sends an HTTP POST command=staff.close_table with CloseTableModel data and traceId to the cashier terminal.',
    'dedecashier websocket_server intentionally rejects staff.close_table and returns a message that staff.close_table must use the HTTP close flow.',
    'dedecashier server_post rebuilds the hold bill before processing close_table, then reads the cashier local table and active unpaid OrderTemp rows.',
    'If staff close payload has no details while cashier has active unpaid local OrderTemp rows, cashier refuses the close and logs an API error.',
    'If close payload has no details and there are no active items, cashier sets table_status=0, saves an empty-order temp sync log, logs TABLE_CLOSED, and returns EMPTY_ORDER_CLOSED.',
    'If cashier table is already status 0 and has no active unpaid OrderTemp rows, cashier returns ALREADY_CLOSED.',
    'For payMode=0, cashier sets table_status=2 and returns PAY_AT_CASHIER_PENDING. This is waiting payment at cashier and not a final sale invoice.',
    'For payMode=1, payMode=2, or payMode=3, cashier sets table_status=3, runs posCompileProcess/saveBill, assigns a real docNumber, saves OrderTemp sync temp log with docNumber/guidPos, removes OrderTemp and PosLog hold rows, sets the table back to table_status=0, clears QR/payment state, and returns the real docNumber.',
    'Therefore a real docNumber from staff.close_table plus a later sync.sale_invoice is strong evidence that the table was actually billed and should no longer accept stale open updates for the same session.'
  ],
  updateTableFlow: [
    'dedestaff2 updateTableToTerminal sends command=staff.update_table over HTTP with the serialized TableProcessObjectBoxStruct.',
    'dedecashier server_post and websocket_server both contain stale update protection before applying staff.update_table.',
    'The stale guard rejects when the current cashier table is table_status=2 waiting payment and the incoming table_status differs from the current status.',
    'The stale guard also rejects generic incoming isUpdate=true or incoming table_status 0/1 with reason staff_table_intent_required, forcing callers to use explicit table intent flows instead of blind state overwrite.',
    'When rejected, HTTP server_post logs event STALE_TABLE_UPDATE_REJECTED, logs the API call with errorMessage, returns HTTP 409, and response body STALE_TABLE_UPDATE_REJECTED.',
    'If accepted as a legacy open, cashier applies editable/open fields, resets amount/order counters to zero, sets table_status=1, sets table_open_datetime=DateTime.now(), generates a new qr_code, removes old OrderTemp for the table, prints table info/QR, rebuilds hold bill, and writes ClickHouse table update.',
    'For update-only accepted changes, cashier applies only editable fields such as people counts, buffet/customer flags, and make_food_immediately, then marks isUpdate=true.',
    'For cancel_close_table, cashier requires current table_status=2 and matching table_open_datetime; otherwise it rejects with TABLE_REVISION_MISMATCH or current_table_not_waiting_payment.'
  ],
  broadcastFlow: [
    'websocket_server maps order commands to broadcastType=order_update and table commands such as staff.close_table, staff.update_table, cancel_close_table, move_table, and merge_table to broadcastType=table_update.',
    'dedestaff2 websocket_client deduplicates broadcasts by broadcastId before handling them.',
    'Staff receives table_update and order_update broadcasts and now writes audit events BROADCAST_TABLE_UPDATE_RECEIVED and BROADCAST_ORDER_UPDATE_RECEIVED.',
    'Broadcasts should be interpreted as propagation evidence, not as final authority. If a broadcast or follow-up state write reopens a table after final close, it should be treated as stale/replay unless a new session is clearly present.'
  ],
  invoiceSyncFlow: [
    'dedecashier sync_bill runs periodically at about 30 second intervals and selects bills where is_sync=false.',
    'sync.sale_invoice audit logs docNumber, guidpos, docMode, isSyncBefore, success/failed status, and response time.',
    'During one sync cycle, guidpos values are deduped so the same guidpos is not synced twice in that cycle.',
    'Before saving a transaction, sync checks /transaction/sale-invoice/guidpos/{guidpos}; if the same guidpos exists it updates, if not found it creates.',
    'When posting sale invoice, the request uses X-Idempotency-Key=guidpos, making guidpos the strongest identity for duplicate/invoice analysis.',
    'If docno collides with a different guidpos, sync may mutate docno with x suffix and update local bill/detail doc numbers. Therefore guidpos is stronger than docNumber for tracing one bill.'
  ],
  auditInterpretationRules: [
    'When rows show accepted staff.update_table after a final close in older audit files, compare with current source guard behavior. Current code expects such stale opens to be rejected with STALE_TABLE_UPDATE_REJECTED.',
    'Absence of STALE_TABLE_UPDATE_REJECTED in an incident can mean the event happened before the guard existed, came from a path not covered by the guard, or the log range missed the rejection.',
    'For QR/table payment incidents, distinguish payMode=2/3 final staff close flow from payMode=0 cashier handoff. Only payMode=1/2/3 creates a bill in server_post close flow.',
    'For bill disappeared then returned, prioritize checking whether sync.sale_invoice succeeded later, whether the table was temporarily reopened by stale staff.update_table, and whether the cashier local bill existed before remote sync completed.',
    'When docNumber changes but guidpos is the same, explain it as invoice sync duplicate docno handling rather than a separate sale unless evidence shows a different guidpos.'
  ]
} as const;

export type SourceCodeLogicKnowledge = typeof sourceCodeLogicKnowledge;
