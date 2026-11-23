-- v3: entitas baru dari dokumen SSOT baru: Pinjam Cash (loans), Buku Titipan Nomor (saved_numbers), Barang Dicari Tapi Kosong (lost_sales, log append-only).
-- CREATE OR REPLACE mempertahankan izin execute yang sudah ada pada sync_push.
create or replace function public.sync_push(p_store uuid, p_events jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  ev jsonb; v_id text; v_entity text; v_eid text; v_op text; v_ts bigint; v_log boolean; n int := 0;
  v_known text[] := array['products','customers','suppliers','employees','shifts','payables','consigns','sales','ppob','settings',
                          'stock_moves','cash_moves','ledger','returns','audit','prive','deposit_moves',
                          'loans','saved_numbers','lost_sales'];
begin
  if not public.is_member(p_store) then raise exception 'akses ditolak' using errcode = '42501'; end if;
  if jsonb_typeof(p_events) <> 'array' then raise exception 'p_events harus array'; end if;
  if jsonb_array_length(p_events) > 500 then raise exception 'maksimal 500 peristiwa per panggilan'; end if;
  for ev in select * from jsonb_array_elements(p_events) loop
    v_id := ev->>'id'; v_entity := ev->>'entity'; v_eid := ev->>'entity_id'; v_op := ev->>'op'; v_ts := (ev->>'ts')::bigint;
    if v_id is null or v_entity is null or v_eid is null or v_ts is null then raise exception 'peristiwa tidak lengkap'; end if;
    if not (v_entity = any (v_known)) then raise exception 'entitas tidak dikenal: %', v_entity; end if;
    insert into public.sync_events(id, store_id) values (v_id, p_store) on conflict (id) do nothing;
    if not found then continue; end if;
    v_log := v_entity in ('stock_moves','cash_moves','ledger','returns','audit','prive','deposit_moves','lost_sales');
    if v_log then
      insert into public.sync_entities(store_id, entity, entity_id, data, ts) values (p_store, v_entity, v_eid, ev->'data', v_ts)
      on conflict (store_id, entity, entity_id) do nothing;
    else
      insert into public.sync_entities as t(store_id, entity, entity_id, data, deleted, ts)
      values (p_store, v_entity, v_eid, case when v_op = 'delete' then null else ev->'data' end, v_op = 'delete', v_ts)
      on conflict (store_id, entity, entity_id) do update
        set data = excluded.data, deleted = excluded.deleted, ts = excluded.ts, seq = nextval('public.sync_seq')
        where t.ts <= excluded.ts;
    end if;
    n := n + 1;
  end loop;
  return jsonb_build_object('accepted', n);
end $$;
