-- Tabla mínima utilizada para comprobar la conexión de las aplicaciones.
create table public.app_health (
  id smallint primary key,
  status text not null,
  created_at timestamptz not null default now(),

  constraint app_health_single_row
    check (id = 1)
);

-- No concedemos permisos generales.
revoke all
on table public.app_health
from public;

revoke all
on table public.app_health
from anon, authenticated;

-- Las aplicaciones solo pueden consultar esta tabla.
grant select
on table public.app_health
to anon, authenticated;

-- Activamos Row Level Security.
alter table public.app_health
enable row level security;

-- Permitimos leer el estado tanto sin login como con login.
create policy "app_health_can_be_read"
on public.app_health
for select
to anon, authenticated
using (true);

-- Registro inicial.
insert into public.app_health (
  id,
  status
)
values (
  1,
  'ok'
);

comment on table public.app_health is
  'Comprobación técnica de conexión entre las aplicaciones y Supabase.';