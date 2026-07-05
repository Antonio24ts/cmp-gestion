-- =========================================================
-- APROBAR ACTIVACIÓN DE MESA
-- =========================================================

create or replace function public.approve_table_activation(
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
  v_restaurant_id uuid;
  v_table_status public.table_operational_status;

  v_request_type public.table_control_request_type;
  v_request_status public.table_control_request_status;
  v_request_expires_at timestamptz;

  v_device_id uuid;
  v_token_hash bytea;

  v_session_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Es necesario iniciar sesión';
  end if;

  select
    tcr.dining_table_id,
    tcr.request_type,
    tcr.status,
    tcr.expires_at,
    tcr.device_id,
    tcr.token_hash,
    dt.restaurant_id,
    dt.operational_status
  into
    v_table_id,
    v_request_type,
    v_request_status,
    v_request_expires_at,
    v_device_id,
    v_token_hash,
    v_restaurant_id,
    v_table_status
  from public.table_control_requests tcr

  join public.dining_tables dt
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
    raise exception 'No tienes permisos para activar esta mesa';
  end if;

  if v_request_type <> 'ACTIVATE_TABLE' then
    raise exception 'La solicitud no es de activación';
  end if;

  if v_request_status <> 'PENDING' then
    raise exception 'La solicitud ya ha sido resuelta';
  end if;

  if v_request_expires_at <= clock_timestamp() then
    update public.table_control_requests
    set
      status = 'EXPIRED',
      resolved_at = clock_timestamp(),
      resolution_reason = 'Solicitud caducada'
    where id = p_request_id;

    return query
    select
      null::uuid,
      'EXPIRED'::public.table_control_request_status,
      null::integer;

    return;
  end if;

  if v_table_status <> 'ACTIVE' then
    raise exception 'La mesa está fuera de servicio';
  end if;

  if exists (
    select 1
    from public.table_sessions ts
    where ts.dining_table_id = v_table_id
      and ts.status in (
        'ACTIVE',
        'BILL_REQUESTED',
        'PAYMENT_PENDING'
      )
  ) then
    raise exception 'La mesa ya tiene una sesión activa';
  end if;

  insert into public.table_sessions (
    dining_table_id,
    status,
    controller_version,
    opened_by
  )
  values (
    v_table_id,
    'ACTIVE',
    1,
    v_user_id
  )
  returning id
  into v_session_id;

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

  update public.table_control_requests
  set
    table_session_id = v_session_id,
    status = 'APPROVED',
    resolved_at = clock_timestamp(),
    resolved_by = v_user_id
  where id = p_request_id;

  return query
  select
    v_session_id,
    'APPROVED'::public.table_control_request_status,
    1;
end;
$$;

revoke all
on function public.approve_table_activation(uuid)
from public, anon, authenticated;

grant execute
on function public.approve_table_activation(uuid)
to authenticated;

-- =========================================================
-- APROBAR TRANSFERENCIA DE CONTROL
-- =========================================================

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
  from public.table_control_requests tcr

  join public.dining_tables dt
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
    update public.table_control_requests
    set
      status = 'EXPIRED',
      resolved_at = clock_timestamp(),
      resolution_reason = 'Solicitud caducada'
    where id = p_request_id;

    return query
    select
      v_session_id,
      'EXPIRED'::public.table_control_request_status,
      null::integer;

    return;
  end if;

  select ts.status
  into v_session_status
  from public.table_sessions ts
  where ts.id = v_session_id
    and ts.dining_table_id = v_table_id
  for update;

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

  update public.session_controller_tokens
  set
    status = 'REVOKED',
    invalidated_at = clock_timestamp()
  where table_session_id = v_session_id
    and status = 'ACTIVE';

  update public.table_sessions
  set
    controller_version = controller_version + 1
  where id = v_session_id
  returning controller_version
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

  update public.table_control_requests
  set
    status = 'APPROVED',
    resolved_at = clock_timestamp(),
    resolved_by = v_user_id
  where id = p_request_id;

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

-- =========================================================
-- RECHAZAR SOLICITUD
-- =========================================================

create or replace function public.reject_table_control_request(
  p_request_id uuid,
  p_reason text default null
)
returns public.table_control_request_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_restaurant_id uuid;
  v_request_status public.table_control_request_status;
  v_expires_at timestamptz;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Es necesario iniciar sesión';
  end if;

  select
    dt.restaurant_id,
    tcr.status,
    tcr.expires_at
  into
    v_restaurant_id,
    v_request_status,
    v_expires_at
  from public.table_control_requests tcr

  join public.dining_tables dt
    on dt.id = tcr.dining_table_id

  where tcr.id = p_request_id

  for update of tcr;

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
    raise exception 'No tienes permisos para rechazar la solicitud';
  end if;

  if v_request_status <> 'PENDING' then
    raise exception 'La solicitud ya ha sido resuelta';
  end if;

  if v_expires_at <= clock_timestamp() then
    update public.table_control_requests
    set
      status = 'EXPIRED',
      resolved_at = clock_timestamp(),
      resolution_reason = 'Solicitud caducada'
    where id = p_request_id;

    return 'EXPIRED';
  end if;

  update public.table_control_requests
  set
    status = 'REJECTED',
    resolved_at = clock_timestamp(),
    resolved_by = v_user_id,
    resolution_reason = nullif(
      btrim(p_reason),
      ''
    )
  where id = p_request_id;

  return 'REJECTED';
end;
$$;

revoke all
on function public.reject_table_control_request(uuid, text)
from public, anon, authenticated;

grant execute
on function public.reject_table_control_request(uuid, text)
to authenticated;

-- =========================================================
-- CERRAR SESIÓN DE MESA
-- =========================================================

create or replace function public.close_table_session(
  p_table_session_id uuid
)
returns public.table_session_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;

  v_table_id uuid;
  v_restaurant_id uuid;
  v_session_status public.table_session_status;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Es necesario iniciar sesión';
  end if;

  select
    ts.dining_table_id,
    ts.status,
    dt.restaurant_id
  into
    v_table_id,
    v_session_status,
    v_restaurant_id
  from public.table_sessions ts

  join public.dining_tables dt
    on dt.id = ts.dining_table_id

  where ts.id = p_table_session_id

  for update of ts, dt;

  if not found then
    raise exception 'La sesión no existe';
  end if;

  if not private.has_active_staff_role(
    v_restaurant_id,
    array[
      'ADMIN',
      'WAITER'
    ]::public.staff_role[]
  ) then
    raise exception 'No tienes permisos para cerrar la sesión';
  end if;

  if v_session_status in (
    'CLOSED',
    'CANCELLED'
  ) then
    return v_session_status;
  end if;

  update public.table_sessions
  set
    status = 'CLOSED',
    closed_by = v_user_id,
    closed_at = clock_timestamp()
  where id = p_table_session_id;

  update public.session_controller_tokens
  set
    status = 'REVOKED',
    invalidated_at = clock_timestamp()
  where table_session_id = p_table_session_id
    and status = 'ACTIVE';

  update public.table_control_requests
  set
    status = 'CANCELLED',
    resolved_at = clock_timestamp(),
    resolution_reason = 'Sesión de mesa cerrada'
  where dining_table_id = v_table_id
    and status = 'PENDING';

  return 'CLOSED';
end;
$$;

revoke all
on function public.close_table_session(uuid)
from public, anon, authenticated;

grant execute
on function public.close_table_session(uuid)
to authenticated;