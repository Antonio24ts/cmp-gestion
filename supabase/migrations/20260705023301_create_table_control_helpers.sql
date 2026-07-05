-- =========================================================
-- FUNCIONES CRIPTOGRÁFICAS
-- =========================================================

create or replace function private.generate_controller_token()
returns text
language sql
volatile
set search_path = ''
as $$
  select pg_catalog.encode(
    extensions.gen_random_bytes(32),
    'hex'
  );
$$;

create or replace function private.hash_controller_token(
  p_token text
)
returns bytea
language sql
immutable
strict
set search_path = ''
as $$
  select extensions.digest(
    p_token,
    'sha256'
  );
$$;

revoke all
on function private.generate_controller_token()
from public, anon, authenticated;

revoke all
on function private.hash_controller_token(text)
from public, anon, authenticated;

-- =========================================================
-- VALIDACIÓN DE ROLES DEL PERSONAL
-- =========================================================

create or replace function private.has_active_staff_role(
  p_restaurant_id uuid,
  p_allowed_roles public.staff_role[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.restaurant_staff rs
    where rs.restaurant_id = p_restaurant_id
      and rs.profile_id = auth.uid()
      and rs.is_active = true
      and rs.role = any(p_allowed_roles)
  );
$$;

revoke all
on function private.has_active_staff_role(
  uuid,
  public.staff_role[]
)
from public, anon, authenticated;

-- =========================================================
-- CADUCIDAD DE SOLICITUDES
-- =========================================================

create or replace function private.expire_pending_control_requests(
  p_dining_table_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.table_control_requests
  set
    status = 'EXPIRED',
    resolved_at = clock_timestamp(),
    resolution_reason = 'Solicitud caducada'
  where dining_table_id = p_dining_table_id
    and status = 'PENDING'
    and expires_at <= clock_timestamp();
end;
$$;

revoke all
on function private.expire_pending_control_requests(uuid)
from public, anon, authenticated;

-- =========================================================
-- CONTEXTO PÚBLICO DEL QR
-- =========================================================

create or replace function public.get_public_table_context(
  p_qr_token uuid
)
returns table (
  restaurant_name text,
  restaurant_slug text,
  table_display_name text,
  table_operational_status public.table_operational_status,
  has_open_session boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.name,
    r.slug,
    dt.display_name,
    dt.operational_status,

    exists (
      select 1
      from public.table_sessions ts
      where ts.dining_table_id = dt.id
        and ts.status in (
          'ACTIVE',
          'BILL_REQUESTED',
          'PAYMENT_PENDING'
        )
    )

  from public.table_qr_tokens qr

  join public.dining_tables dt
    on dt.id = qr.dining_table_id

  join public.restaurants r
    on r.id = dt.restaurant_id

  where qr.public_token = p_qr_token
    and qr.is_active = true
    and r.is_active = true;
$$;

revoke all
on function public.get_public_table_context(uuid)
from public, anon, authenticated;

grant execute
on function public.get_public_table_context(uuid)
to anon, authenticated;