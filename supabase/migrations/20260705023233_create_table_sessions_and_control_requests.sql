-- =========================================================
-- EXTENSIONES Y ESQUEMA PRIVADO
-- =========================================================

create schema if not exists extensions;
create schema if not exists private;

revoke all
on schema private
from public;

create extension if not exists pgcrypto
with schema extensions;

-- =========================================================
-- TIPOS DE SESIÓN Y CONTROL
-- =========================================================

create type public.table_session_status as enum (
  'ACTIVE',
  'BILL_REQUESTED',
  'PAYMENT_PENDING',
  'CLOSED',
  'CANCELLED'
);

create type public.table_control_request_type as enum (
  'ACTIVATE_TABLE',
  'TRANSFER_CONTROL'
);

create type public.table_control_request_status as enum (
  'PENDING',
  'APPROVED',
  'REJECTED',
  'EXPIRED',
  'CANCELLED'
);

create type public.controller_token_status as enum (
  'ACTIVE',
  'REVOKED',
  'EXPIRED'
);

-- =========================================================
-- SESIONES DE MESA
-- =========================================================

create table public.table_sessions (
  id uuid primary key default gen_random_uuid(),

  dining_table_id uuid not null
    references public.dining_tables(id)
    on delete restrict,

  status public.table_session_status
    not null
    default 'ACTIVE',

  controller_version integer
    not null
    default 1,

  opened_by uuid not null
    references public.profiles(id)
    on delete restrict,

  opened_at timestamptz
    not null
    default now(),

  closed_by uuid
    references public.profiles(id)
    on delete restrict,

  closed_at timestamptz,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now(),

  constraint table_sessions_controller_version_positive
    check (
      controller_version > 0
    ),

  constraint table_sessions_closed_fields_consistency
    check (
      (
        status in ('CLOSED', 'CANCELLED')
        and closed_at is not null
      )
      or
      (
        status not in ('CLOSED', 'CANCELLED')
        and closed_at is null
        and closed_by is null
      )
    )
);

-- Solo puede existir una sesión abierta por mesa.
create unique index table_sessions_one_open_per_table
on public.table_sessions (dining_table_id)
where status in (
  'ACTIVE',
  'BILL_REQUESTED',
  'PAYMENT_PENDING'
);

create index table_sessions_table_idx
on public.table_sessions (dining_table_id);

create index table_sessions_status_idx
on public.table_sessions (status);

comment on table public.table_sessions is
  'Sesiones de consumo abiertas para las mesas del restaurante.';

comment on column public.table_sessions.controller_version is
  'Aumenta cada vez que el control de la sesión se transfiere a otro dispositivo.';

-- =========================================================
-- SOLICITUDES DE ACTIVACIÓN O TRANSFERENCIA
-- =========================================================

create table public.table_control_requests (
  id uuid primary key default gen_random_uuid(),

  dining_table_id uuid not null
    references public.dining_tables(id)
    on delete restrict,

  table_session_id uuid
    references public.table_sessions(id)
    on delete restrict,

  request_type public.table_control_request_type
    not null,

  status public.table_control_request_status
    not null
    default 'PENDING',

  device_id uuid not null,

  confirmation_code text not null,

  -- Nunca almacenamos el token controlador en texto plano.
  token_hash bytea not null,

  requested_at timestamptz
    not null
    default now(),

  expires_at timestamptz
    not null,

  resolved_at timestamptz,

  resolved_by uuid
    references public.profiles(id)
    on delete restrict,

  resolution_reason text,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now(),

  constraint table_control_requests_code_format
    check (
      confirmation_code ~ '^[0-9]{6}$'
    ),

  constraint table_control_requests_expiration_valid
    check (
      expires_at > requested_at
    ),

  constraint table_control_requests_reason_length
    check (
      resolution_reason is null
      or char_length(resolution_reason) <= 500
    ),

  constraint table_control_requests_resolution_consistency
    check (
      (
        status = 'PENDING'
        and resolved_at is null
        and resolved_by is null
      )
      or
      (
        status <> 'PENDING'
        and resolved_at is not null
        and (
          status not in ('APPROVED', 'REJECTED')
          or resolved_by is not null
        )
      )
    ),

  constraint table_control_requests_session_consistency
    check (
      (
        request_type = 'ACTIVATE_TABLE'
        and (
          status <> 'APPROVED'
          or table_session_id is not null
        )
      )
      or
      (
        request_type = 'TRANSFER_CONTROL'
        and table_session_id is not null
      )
    )
);

-- Solo puede existir una solicitud pendiente por mesa.
create unique index table_control_requests_one_pending_per_table
on public.table_control_requests (dining_table_id)
where status = 'PENDING';

create index table_control_requests_table_idx
on public.table_control_requests (dining_table_id);

create index table_control_requests_session_idx
on public.table_control_requests (table_session_id);

create index table_control_requests_status_expiration_idx
on public.table_control_requests (
  status,
  expires_at
);

comment on table public.table_control_requests is
  'Solicitudes para activar una mesa o transferir su dispositivo controlador.';

comment on column public.table_control_requests.token_hash is
  'Hash SHA-256 del token secreto conservado únicamente por el navegador solicitante.';

-- =========================================================
-- CREDENCIALES DEL DISPOSITIVO CONTROLADOR
-- =========================================================

create table public.session_controller_tokens (
  id uuid primary key default gen_random_uuid(),

  table_session_id uuid not null
    references public.table_sessions(id)
    on delete restrict,

  device_id uuid not null,

  token_hash bytea not null,

  status public.controller_token_status
    not null
    default 'ACTIVE',

  created_from_request_id uuid not null
    references public.table_control_requests(id)
    on delete restrict,

  issued_at timestamptz
    not null
    default now(),

  expires_at timestamptz
    not null,

  invalidated_at timestamptz,

  created_at timestamptz
    not null
    default now(),

  constraint session_controller_tokens_hash_unique
    unique (token_hash),

  constraint session_controller_tokens_request_unique
    unique (created_from_request_id),

  constraint session_controller_tokens_expiration_valid
    check (
      expires_at > issued_at
    ),

  constraint session_controller_tokens_status_consistency
    check (
      (
        status = 'ACTIVE'
        and invalidated_at is null
      )
      or
      (
        status in ('REVOKED', 'EXPIRED')
        and invalidated_at is not null
      )
    )
);

-- Solo puede haber un dispositivo controlador activo.
create unique index session_controller_tokens_one_active_per_session
on public.session_controller_tokens (table_session_id)
where status = 'ACTIVE';

create index session_controller_tokens_session_idx
on public.session_controller_tokens (table_session_id);

create index session_controller_tokens_status_expiration_idx
on public.session_controller_tokens (
  status,
  expires_at
);

comment on table public.session_controller_tokens is
  'Tokens que conceden a un único dispositivo permiso para controlar la sesión de mesa.';

-- =========================================================
-- HISTORIAL DE ESTADOS
-- =========================================================

create table public.table_session_status_history (
  id bigint generated always as identity primary key,

  table_session_id uuid not null
    references public.table_sessions(id)
    on delete restrict,

  previous_status public.table_session_status,

  new_status public.table_session_status
    not null,

  changed_by uuid
    references public.profiles(id)
    on delete set null,

  changed_at timestamptz
    not null
    default now()
);

create index table_session_status_history_session_idx
on public.table_session_status_history (
  table_session_id,
  changed_at
);

comment on table public.table_session_status_history is
  'Historial inmutable de los cambios de estado de cada sesión de mesa.';

-- =========================================================
-- TRIGGERS updated_at
-- =========================================================

create trigger table_sessions_set_updated_at
before update on public.table_sessions
for each row
execute function public.set_updated_at();

create trigger table_control_requests_set_updated_at
before update on public.table_control_requests
for each row
execute function public.set_updated_at();

-- =========================================================
-- HISTORIAL AUTOMÁTICO
-- =========================================================

create or replace function private.record_table_session_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.table_session_status_history (
      table_session_id,
      previous_status,
      new_status,
      changed_by
    )
    values (
      new.id,
      null,
      new.status,
      auth.uid()
    );

  elsif new.status is distinct from old.status then
    insert into public.table_session_status_history (
      table_session_id,
      previous_status,
      new_status,
      changed_by
    )
    values (
      new.id,
      old.status,
      new.status,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

revoke all
on function private.record_table_session_status()
from public, anon, authenticated;

create trigger table_sessions_record_status
after insert or update of status
on public.table_sessions
for each row
execute function private.record_table_session_status();

-- =========================================================
-- SEGURIDAD
-- =========================================================

alter table public.table_sessions
enable row level security;

alter table public.table_control_requests
enable row level security;

alter table public.session_controller_tokens
enable row level security;

alter table public.table_session_status_history
enable row level security;

revoke all
on table public.table_sessions
from anon, authenticated;

revoke all
on table public.table_control_requests
from anon, authenticated;

revoke all
on table public.session_controller_tokens
from anon, authenticated;

revoke all
on table public.table_session_status_history
from anon, authenticated;