alter table audit_logs
  add column if not exists local_id integer,
  add column if not exists response_time_ms integer;

create index if not exists audit_logs_shop_source_local_idx
  on audit_logs (shop_id, source_app, device_id, local_id)
  where local_id is not null;

create index if not exists audit_logs_shop_response_time_idx
  on audit_logs (shop_id, response_time_ms desc)
  where response_time_ms is not null;
