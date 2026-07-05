-- =========================================================
-- TIPOS COMUNES DEL SISTEMA
-- =========================================================

create type public.staff_role as enum (
  'ADMIN',
  'WAITER',
  'KITCHEN'
);

create type public.table_operational_status as enum (
  'ACTIVE',
  'OUT_OF_SERVICE'
);

-- =========================================================
-- FUNCIÓN GENÉRICA PARA updated_at
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- La función solo debe ejecutarse mediante triggers internos.
revoke all
on function public.set_updated_at()
from public, anon, authenticated;

comment on type public.staff_role is
  'Roles disponibles para el personal de un restaurante.';

comment on type public.table_operational_status is
  'Indica si una mesa puede utilizarse o está fuera de servicio.';

comment on function public.set_updated_at() is
  'Actualiza automáticamente la columna updated_at antes de modificar una fila.';