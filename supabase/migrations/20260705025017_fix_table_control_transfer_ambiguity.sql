create or replace function public.approve_table_control_transfer(
  p_request_id uuid
)
returns table (
  table_session_id uuid,
  request_status public.table_control_request_status,
  controller_version integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_table_id uuid;
  v_session_id uuid;
  v_restaurant_id uuid;

  v_request_type public.table_control_request_type;
  v_request_status public.table_control_request_status;
  v_request_expires_at timestamptz;

  v_device_id uuid;
  v_token_hash bytea;

  v_session_status public.table_session_status;
  v_new_controller_version integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Es necesario iniciar sesión';
  end if;

  select
    tcr.dining_table_id,
    tcr.table_session_id,
    tcr.request_type,
    tcr.status,
    tcr.expires_at,
    tcr.device_id,
    tcr.token_hash,
    dt.restaurant_id
  into
    v_table_id,
    v_session_id,
    v_request_type,
    v_request_status,
    v_request_expires_at,
    v_device_id,
    v_token_hash,
    v_restaurant_id
  from public.table_control_requests as tcr
  join public.dining_tables as dt
    on dt.id = tcr.dining_table_id
  where tcr.id = p_request_id
  for update of tcr, dt;

  if not found then
    raise exception 'La solicitud no existe';
  end if;

  if not private.has_active_staff_role(
    v_restaurant_id,
    array[
      'ADMIN',
      'WAITER'
    ]::public.staff_role[]
  ) then
    raise exception 'No tienes permisos para transferir el control';
  end if;

  if v_request_type <> 'TRANSFER_CONTROL' then
    raise exception 'La solicitud no es de transferencia';
  end if;

  if v_request_status <> 'PENDING' then
    raise exception 'La solicitud ya ha sido resuelta';
  end if;

  if v_request_expires_at <= clock_timestamp() then
    update public.table_control_requests as tcr
    set
      status = 'EXPIRED',
      resolved_at = clock_timestamp(),
      resolution_reason = 'Solicitud caducada'
    where tcr.id = p_request_id;

    return query
    select
      v_session_id,
      'EXPIRED'::public.table_control_request_status,
      null::integer;

    return;
  end if;

  select ts.status
  into v_session_status
  from public.table_sessions as ts
  where ts.id = v_session_id
    and ts.dining_table_id = v_table_id
  for update of ts;

  if not found then
    raise exception 'La sesión de mesa no existe';
  end if;

  if v_session_status not in (
    'ACTIVE',
    'BILL_REQUESTED',
    'PAYMENT_PENDING'
  ) then
    raise exception 'La sesión ya no está abierta';
  end if;

  update public.session_controller_tokens as sct
  set
    status = 'REVOKED',
    invalidated_at = clock_timestamp()
  where sct.table_session_id = v_session_id
    and sct.status = 'ACTIVE';

  update public.table_sessions as ts
  set
    controller_version = ts.controller_version + 1
  where ts.id = v_session_id
  returning ts.controller_version
  into v_new_controller_version;

  insert into public.session_controller_tokens (
    table_session_id,
    device_id,
    token_hash,
    status,
    created_from_request_id,
    expires_at
  )
  values (
    v_session_id,
    v_device_id,
    v_token_hash,
    'ACTIVE',
    p_request_id,
    clock_timestamp() + interval '24 hours'
  );

  update public.table_control_requests as tcr
  set
    status = 'APPROVED',
    resolved_at = clock_timestamp(),
    resolved_by = v_user_id
  where tcr.id = p_request_id;

  return query
  select
    v_session_id,
    'APPROVED'::public.table_control_request_status,
    v_new_controller_version;
end;
$$;

revoke all
on function public.approve_table_control_transfer(uuid)
from public, anon, authenticated;

grant execute
on function public.approve_table_control_transfer(uuid)
to authenticated;