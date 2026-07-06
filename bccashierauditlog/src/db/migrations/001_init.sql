create table if not exists audit_logs (
  id bigserial primary key,
  shop_id text not null,
  source_app text not null check (source_app in ('cashier', 'staff')),
  device_id text,
  device_name text,
  event_type text not null,
  table_id integer,
  command text,
  trace_id text,
  user_id text,
  dedupe_key text not null unique,
  timestamp_utc timestamptz not null,
  timestamp_bangkok timestamp not null,
  request_body jsonb,
  response_body jsonb,
  details jsonb,
  error_message text,
  raw jsonb not null,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_shop_time_idx
  on audit_logs (shop_id, timestamp_utc desc);

create index if not exists audit_logs_shop_table_time_idx
  on audit_logs (shop_id, table_id, timestamp_utc desc);

create index if not exists audit_logs_shop_event_time_idx
  on audit_logs (shop_id, event_type, timestamp_utc desc);

create index if not exists audit_logs_trace_idx
  on audit_logs (shop_id, trace_id)
  where trace_id is not null;

create index if not exists audit_logs_raw_gin_idx
  on audit_logs using gin (raw);

create table if not exists telegram_questions (
  id bigserial primary key,
  chat_id text not null,
  message_id text,
  shop_id text,
  question text not null,
  answer text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  answered_at timestamptz
);
