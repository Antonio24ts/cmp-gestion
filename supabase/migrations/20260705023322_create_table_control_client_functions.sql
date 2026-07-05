-- =========================================================
-- SOLICITAR ACTIVACIÓN DE MESA
-- =========================================================

create or replace function public.request_table_activation(
  p_qr_token uuid,
  p_device_id uuid
)
returns table (
  request_id uuid,
  confirmation_code text,
  controller_token text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_table_id uuid;
  v_table_status public.table_operational_status;

  v_request_id uuid;
  v_confirmation_code text;
  v_controller_token text;
  v_token_hash bytea;
  v_expires_at timestamptz;
begin
  if p_qr_token is null then
    raise exception 'El token QR es obligatorio';
  end if;

  if p_device_id is null then
    raise exception 'El identificador del dispositivo es obligatorio';
  end if;

  select
    dt.id,
    dt.operational_status
  into
    v_table_id,
    v_table_status
  from public.table_qr_tokens qr

  join public.dining_tables dt
    on dt.id = qr.dining_table_id

  join public.restaurants r
    on r.id = dt.restaurant_id

  where qr.public_token = p_qr_token
    and qr.is_active = true
    and r.is_active = true

  for update of dt;

  if not found then
    raise exception 'El código QR no es válido o está desactivado';
  end if;

  if v_table_status <> 'ACTIVE' then
    raise exception 'La mesa está fuera de servicio';
  end if;

  perform private.expire_pending_control_requests(
    v_table_id
  );

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

  if exists (
    select 1
    from public.table_control_requests tcr
    where tcr.dining_table_id = v_table_id
      and tcr.status = 'PENDING'
  ) then
    raise exception 'La mesa ya tiene una solicitud pendiente';
  end if;

  v_controller_token :=
    private.generate_controller_token();

  v_token_hash :=
    private.hash_controller_token(
      v_controller_token
    );

  v_confirmation_code :=
    pg_catalog.lpad(
      (
        (
          pg_catalog.floor(
            pg_catalog.random() * 900000
          )::integer
          + 100000
        )
      )::text,
      6,
      '0'
    );

  v_expires_at :=
    clock_timestamp() + interval '5 minutes';

  insert into public.table_control_requests (
    dining_table_id,
    request_type,
    status,
    device_id,
    confirmation_code,
    token_hash,
    expires_at
  )
  values (
    v_table_id,
    'ACTIVATE_TABLE',
    'PENDING',
    p_device_id,
    v_confirmation_code,
    v_token_hash,
    v_expires_at
  )
  returning id
  into v_request_id;

  return query
  select
    v_request_id,
    v_confirmation_code,
    v_controller_token,
    v_expires_at;
end;
$$;

revoke all
on function public.request_table_activation(uuid, uuid)
from public, anon, authenticated;

grant execute
on function public.request_table_activation(uuid, uuid)
to anon, authenticated;

-- =========================================================
-- SOLICITAR TRANSFERENCIA DE CONTROL
-- =========================================================

create or replace function public.request_table_control_transfer(
  p_qr_token uuid,
  p_device_id uuid
)
returns table (
  request_id uuid,
  confirmation_code text,
  controller_token text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_table_id uuid;
  v_table_status public.table_operational_status;
  v_session_id uuid;

  v_request_id uuid;
  v_confirmation_code text;
  v_controller_token text;
  v_token_hash bytea;
  v_expires_at timestamptz;
begin
  if p_qr_token is null then
    raise exception 'El token QR es obligatorio';
  end if;

  if p_device_id is null then
    raise exception 'El identificador del dispositivo es obligatorio';
  end if;

  select
    dt.id,
    dt.operational_status,
    ts.id
  into
    v_table_id,
    v_table_status,
    v_session_id
  from public.table_qr_tokens qr

  join public.dining_tables dt
    on dt.id = qr.dining_table_id

  join public.restaurants r
    on r.id = dt.restaurant_id

  join public.table_sessions ts
    on ts.dining_table_id = dt.id
   and ts.status in (
     'ACTIVE',
     'BILL_REQUESTED',
     'PAYMENT_PENDING'
   )

  where qr.public_token = p_qr_token
    and qr.is_active = true
    and r.is_active = true

  for update of dt, ts;

  if not found then
    raise exception 'No existe una sesión activa para esta mesa';
  end if;

  if v_table_status <> 'ACTIVE' then
    raise exception 'La mesa está fuera de servicio';
  end if;

  perform private.expire_pending_control_requests(
    v_table_id
  );

  if exists (
    select 1
    from public.table_control_requests tcr
    where tcr.dining_table_id = v_table_id
      and tcr.status = 'PENDING'
  ) then
    raise exception 'La mesa ya tiene una solicitud pendiente';
  end if;

  v_controller_token :=
    private.generate_controller_token();

  v_token_hash :=
    private.hash_controller_token(
      v_controller_token
    );

  v_confirmation_code :=
    pg_catalog.lpad(
      (
        (
          pg_catalog.floor(
            pg_catalog.random() * 900000
          )::integer
          + 100000
        )
      )::text,
      6,
      '0'
    );

  v_expires_at :=
    clock_timestamp() + interval '5 minutes';

  insert into public.table_control_requests (
    dining_table_id,
    table_session_id,
    request_type,
    status,
    device_id,
    confirmation_code,
    token_hash,
    expires_at
  )
  values (
    v_table_id,
    v_session_id,
    'TRANSFER_CONTROL',
    'PENDING',
    p_device_id,
    v_confirmation_code,
    v_token_hash,
    v_expires_at
  )
  returning id
  into v_request_id;

  return query
  select
    v_request_id,
    v_confirmation_code,
    v_controller_token,
    v_expires_at;
end;
$$;

revoke all
on function public.request_table_control_transfer(uuid, uuid)
from public, anon, authenticated;

grant execute
on function public.request_table_control_transfer(uuid, uuid)
to anon, authenticated;

-- =========================================================
-- CONSULTAR ESTADO DE UNA SOLICITUD
-- =========================================================

create or replace function public.get_table_control_request_status(
  p_request_id uuid,
  p_controller_token text
)
returns table (
  request_status public.table_control_request_status,
  request_type public.table_control_request_type,
  table_session_id uuid,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_table_id uuid;
  v_token_hash bytea;
begin
  if p_request_id is null
     or p_controller_token is null
     or char_length(p_controller_token) = 0 then
    return;
  end if;

  v_token_hash :=
    private.hash_controller_token(
      p_controller_token
    );

  select tcr.dining_table_id
  into v_table_id
  from public.table_control_requests tcr
  where tcr.id = p_request_id
    and tcr.token_hash = v_token_hash;

  if not found then
    return;
  end if;

  perform private.expire_pending_control_requests(
    v_table_id
  );

  return query
  select
    tcr.status,
    tcr.request_type,
    tcr.table_session_id,
    tcr.expires_at
  from public.table_control_requests tcr
  where tcr.id = p_request_id
    and tcr.token_hash = v_token_hash;
end;
$$;

revoke all
on function public.get_table_control_request_status(uuid, text)
from public, anon, authenticated;

grant execute
on function public.get_table_control_request_status(uuid, text)
to anon, authenticated;

-- =========================================================
-- VALIDAR SI EL NAVEGADOR ES EL CONTROLADOR
-- =========================================================

create or replace function public.get_controller_session(
  p_qr_token uuid,
  p_controller_token text
)
returns table (
  table_session_id uuid,
  session_status public.table_session_status,
  controller_version integer,
  restaurant_name text,
  restaurant_slug text,
  table_display_name text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token_hash bytea;
begin
  if p_qr_token is null
     or p_controller_token is null
     or char_length(p_controller_token) = 0 then
    return;
  end if;

  v_token_hash :=
    private.hash_controller_token(
      p_controller_token
    );

  update public.session_controller_tokens sct
  set
    status = 'EXPIRED',
    invalidated_at = clock_timestamp()
  where sct.token_hash = v_token_hash
    and sct.status = 'ACTIVE'
    and sct.expires_at <= clock_timestamp();

  return query
  select
    ts.id,
    ts.status,
    ts.controller_version,
    r.name,
    r.slug,
    dt.display_name

  from public.session_controller_tokens sct

  join public.table_sessions ts
    on ts.id = sct.table_session_id

  join public.dining_tables dt
    on dt.id = ts.dining_table_id

  join public.table_qr_tokens qr
    on qr.dining_table_id = dt.id
   and qr.is_active = true

  join public.restaurants r
    on r.id = dt.restaurant_id
   and r.is_active = true

  where qr.public_token = p_qr_token
    and sct.token_hash = v_token_hash
    and sct.status = 'ACTIVE'
    and sct.expires_at > clock_timestamp()
    and ts.status in (
      'ACTIVE',
      'BILL_REQUESTED',
      'PAYMENT_PENDING'
    );
end;
$$;

revoke all
on function public.get_controller_session(uuid, text)
from public, anon, authenticated;

grant execute
on function public.get_controller_session(uuid, text)
to anon, authenticated;