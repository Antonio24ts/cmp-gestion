-- =========================================================
-- MESAS FÍSICAS
-- =========================================================

create table public.dining_tables (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete restrict,

  code text not null,
  display_name text not null,

  capacity smallint,
  sort_order integer not null default 0,

  operational_status public.table_operational_status
    not null
    default 'ACTIVE',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint dining_tables_code_not_blank
    check (
      char_length(btrim(code)) between 1 and 30
    ),

  constraint dining_tables_display_name_not_blank
    check (
      char_length(btrim(display_name)) between 1 and 80
    ),

  constraint dining_tables_capacity_positive
    check (
      capacity is null
      or capacity > 0
    ),

  constraint dining_tables_sort_order_non_negative
    check (
      sort_order >= 0
    )
);

create unique index dining_tables_restaurant_code_unique
on public.dining_tables (
  restaurant_id,
  lower(code)
);

create index dining_tables_restaurant_idx
on public.dining_tables (restaurant_id);

create index dining_tables_operational_status_idx
on public.dining_tables (
  restaurant_id,
  operational_status
);

comment on table public.dining_tables is
  'Mesas físicas pertenecientes a cada restaurante.';

comment on column public.dining_tables.code is
  'Código interno único de la mesa dentro del restaurante.';

comment on column public.dining_tables.display_name is
  'Nombre mostrado al personal y a los clientes, por ejemplo Mesa 1.';

comment on column public.dining_tables.operational_status is
  'Estado operativo; la ocupación se deduce de la sesión activa.';

-- =========================================================
-- IDENTIFICADORES PÚBLICOS PARA LOS QR
-- =========================================================

create table public.table_qr_tokens (
  id uuid primary key default gen_random_uuid(),

  dining_table_id uuid not null
    references public.dining_tables(id)
    on delete cascade,

  public_token uuid not null default gen_random_uuid(),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  revoked_at timestamptz,

  constraint table_qr_tokens_public_token_unique
    unique (public_token),

  constraint table_qr_tokens_revocation_consistency
    check (
      (
        is_active = true
        and revoked_at is null
      )
      or
      (
        is_active = false
        and revoked_at is not null
      )
    )
);

-- Una mesa solo puede tener un QR activo.
create unique index table_qr_tokens_one_active_per_table
on public.table_qr_tokens (dining_table_id)
where is_active = true;

create index table_qr_tokens_table_idx
on public.table_qr_tokens (dining_table_id);

comment on table public.table_qr_tokens is
  'Tokens públicos utilizados para generar y rotar los códigos QR de las mesas.';

comment on column public.table_qr_tokens.public_token is
  'Identificador público incluido en la URL del QR; no concede permiso para pedir.';

-- =========================================================
-- TRIGGERS updated_at
-- =========================================================

create trigger dining_tables_set_updated_at
before update on public.dining_tables
for each row
execute function public.set_updated_at();

-- =========================================================
-- SEGURIDAD INICIAL
-- =========================================================

alter table public.dining_tables
enable row level security;

alter table public.table_qr_tokens
enable row level security;

revoke all
on table public.dining_tables
from anon, authenticated;

revoke all
on table public.table_qr_tokens
from anon, authenticated;