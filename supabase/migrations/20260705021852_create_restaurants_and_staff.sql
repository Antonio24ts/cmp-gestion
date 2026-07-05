-- =========================================================
-- RESTAURANTES
-- =========================================================

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text not null,

  timezone text not null default 'Europe/Madrid',
  currency_code char(3) not null default 'EUR',

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint restaurants_name_not_blank
    check (
      char_length(btrim(name)) between 2 and 120
    ),

  constraint restaurants_slug_format
    check (
      slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    ),

  constraint restaurants_currency_uppercase
    check (
      currency_code = upper(currency_code)
    )
);

create unique index restaurants_slug_unique
on public.restaurants (slug);

comment on table public.restaurants is
  'Restaurantes gestionados por la plataforma.';

comment on column public.restaurants.slug is
  'Identificador legible utilizado en las URLs públicas.';

-- =========================================================
-- PERFILES DE USUARIO
-- =========================================================

create table public.profiles (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  full_name text not null default '',
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint profiles_full_name_length
    check (
      char_length(full_name) <= 120
    )
);

comment on table public.profiles is
  'Información pública de aplicación asociada a usuarios de Supabase Auth.';

-- =========================================================
-- PERSONAL DE LOS RESTAURANTES
-- =========================================================

create table public.restaurant_staff (
  id uuid primary key default gen_random_uuid(),

  restaurant_id uuid not null
    references public.restaurants(id)
    on delete restrict,

  profile_id uuid not null
    references public.profiles(id)
    on delete cascade,

  role public.staff_role not null,
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint restaurant_staff_unique_membership
    unique (restaurant_id, profile_id)
);

create index restaurant_staff_restaurant_idx
on public.restaurant_staff (restaurant_id);

create index restaurant_staff_profile_idx
on public.restaurant_staff (profile_id);

create index restaurant_staff_active_role_idx
on public.restaurant_staff (
  restaurant_id,
  role
)
where is_active = true;

comment on table public.restaurant_staff is
  'Vincula cada usuario con un restaurante y determina su rol.';

-- =========================================================
-- CREACIÓN AUTOMÁTICA DEL PERFIL
-- =========================================================

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_full_name text;
begin
  resolved_full_name :=
    nullif(
      btrim(new.raw_user_meta_data ->> 'full_name'),
      ''
    );

  if resolved_full_name is null then
    resolved_full_name :=
      split_part(
        coalesce(new.email, 'usuario'),
        '@',
        1
      );
  end if;

  insert into public.profiles (
    id,
    full_name
  )
  values (
    new.id,
    resolved_full_name
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all
on function public.handle_new_auth_user()
from public, anon, authenticated;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

-- =========================================================
-- TRIGGERS updated_at
-- =========================================================

create trigger restaurants_set_updated_at
before update on public.restaurants
for each row
execute function public.set_updated_at();

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger restaurant_staff_set_updated_at
before update on public.restaurant_staff
for each row
execute function public.set_updated_at();

-- =========================================================
-- SEGURIDAD INICIAL
-- =========================================================

alter table public.restaurants
enable row level security;

alter table public.profiles
enable row level security;

alter table public.restaurant_staff
enable row level security;

revoke all
on table public.restaurants
from anon, authenticated;

revoke all
on table public.profiles
from anon, authenticated;

revoke all
on table public.restaurant_staff
from anon, authenticated;