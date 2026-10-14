-- =====================================================================
-- 43.80 SVA-E · Fase 2: avisos, incidencias, procedimientos, teléfonos,
-- fotos y contraseñas temporales.
-- Requiere haber ejecutado antes schema.sql.
-- Pegar entero en: Supabase > SQL Editor > New query > Run
-- Se puede ejecutar más de una vez.
-- =====================================================================

-- ---------- Tablas ----------
create table if not exists public.avisos (
  id           bigint generated always as identity primary key,
  client_id    uuid not null unique,
  creado       timestamptz not null default now(),
  autor        text not null,
  tipo         text not null check (tipo in ('material','averia','otro')),
  prioridad    text not null default 'normal' check (prioridad in ('urgente','normal')),
  texto        text not null,
  foto         text,
  estado       text not null default 'abierto' check (estado in ('abierto','resuelto')),
  resuelto_por text,
  resuelto_en  timestamptz,
  resolucion   text
);

create table if not exists public.incidencias (
  id        bigint generated always as identity primary key,
  client_id uuid not null unique,
  creado    timestamptz not null default now(),
  autor     text not null,
  fecha     date not null,
  franja    text check (franja in ('24h','D','N')),
  texto     text not null,
  foto      text
);

create table if not exists public.procedimientos (
  id        bigint generated always as identity primary key,
  titulo    text not null,
  categoria text not null default 'General',
  archivo   text not null,
  bytes     integer not null default 0,
  creado    timestamptz not null default now(),
  autor     text not null
);

create table if not exists public.contactos (
  id       bigint generated always as identity primary key,
  nombre   text not null,
  telefono text not null,
  nota     text not null default '',
  orden    integer not null default 0
);

alter table public.avisos         enable row level security;
alter table public.incidencias    enable row level security;
alter table public.procedimientos enable row level security;
alter table public.contactos      enable row level security;
revoke all on public.avisos, public.incidencias, public.procedimientos, public.contactos from anon, authenticated;
grant select on public.avisos, public.incidencias, public.procedimientos, public.contactos to authenticated;

drop policy if exists leer_avisos on public.avisos;
create policy leer_avisos on public.avisos for select using (public.es_aprobado());
drop policy if exists leer_incidencias on public.incidencias;
create policy leer_incidencias on public.incidencias for select using (public.es_aprobado());
drop policy if exists leer_procedimientos on public.procedimientos;
create policy leer_procedimientos on public.procedimientos for select using (public.es_aprobado());
drop policy if exists leer_contactos on public.contactos;
create policy leer_contactos on public.contactos for select using (public.es_aprobado());

-- ---------- Almacenamiento de archivos (fotos y PDF) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('procedimientos', 'procedimientos', false, 52428800, array['application/pdf'])
on conflict (id) do nothing;

drop policy if exists sva_fotos_leer on storage.objects;
create policy sva_fotos_leer on storage.objects for select to authenticated
  using (bucket_id = 'fotos' and public.es_aprobado());
drop policy if exists sva_fotos_subir on storage.objects;
create policy sva_fotos_subir on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and public.es_aprobado());
drop policy if exists sva_fotos_reemplazar on storage.objects;
create policy sva_fotos_reemplazar on storage.objects for update to authenticated
  using (bucket_id = 'fotos' and public.es_aprobado());
drop policy if exists sva_fotos_borrar on storage.objects;
create policy sva_fotos_borrar on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and public.es_admin());
drop policy if exists sva_proc_leer on storage.objects;
create policy sva_proc_leer on storage.objects for select to authenticated
  using (bucket_id = 'procedimientos' and public.es_aprobado());
drop policy if exists sva_proc_subir on storage.objects;
create policy sva_proc_subir on storage.objects for insert to authenticated
  with check (bucket_id = 'procedimientos' and public.es_admin());
drop policy if exists sva_proc_borrar on storage.objects;
create policy sva_proc_borrar on storage.objects for delete to authenticated
  using (bucket_id = 'procedimientos' and public.es_admin());

-- ---------- Avisos de material y averías ----------
create or replace function public.crear_aviso(p_client uuid, p_tipo text, p_prioridad text, p_texto text, p_foto text default null) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if coalesce(trim(p_texto), '') = '' then raise exception 'Describe el aviso.'; end if;
  insert into avisos (client_id, autor, tipo, prioridad, texto, foto)
  values (p_client, me.nombre, p_tipo, p_prioridad, left(trim(p_texto), 1000), nullif(p_foto, ''))
  on conflict (client_id) do nothing;
end $$;

create or replace function public.resolver_aviso(p_id bigint, p_nota text default '') returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); a avisos;
begin
  select * into a from avisos where id = p_id for update;
  if not found then raise exception 'El aviso no existe.'; end if;
  if a.estado = 'resuelto' then raise exception 'Ya lo marcó como resuelto %.', a.resuelto_por; end if;
  update avisos set estado = 'resuelto', resuelto_por = me.nombre, resuelto_en = now(), resolucion = nullif(left(trim(coalesce(p_nota,'')), 500), '')
  where id = p_id;
end $$;

create or replace function public.reabrir_aviso(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  update avisos set estado = 'abierto', resuelto_por = null, resuelto_en = null,
    resolucion = 'Reabierto por ' || me.nombre || ' el ' || to_char(now() at time zone 'Atlantic/Canary', 'DD/MM HH24:MI')
  where id = p_id and estado = 'resuelto';
  if not found then raise exception 'El aviso no existe o ya está abierto.'; end if;
end $$;

create or replace function public.borrar_aviso(p_id bigint) returns text
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); f text;
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede borrar avisos.'; end if;
  delete from avisos where id = p_id returning foto into f;
  return f;
end $$;

-- ---------- Incidencias de turno ----------
create or replace function public.crear_incidencia(p_client uuid, p_fecha date, p_franja text, p_texto text, p_foto text default null) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if coalesce(trim(p_texto), '') = '' then raise exception 'Describe la incidencia.'; end if;
  insert into incidencias (client_id, autor, fecha, franja, texto, foto)
  values (p_client, me.nombre, p_fecha, nullif(p_franja, ''), left(trim(p_texto), 2000), nullif(p_foto, ''))
  on conflict (client_id) do nothing;
end $$;

create or replace function public.borrar_incidencia(p_id bigint) returns text
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); i incidencias;
begin
  select * into i from incidencias where id = p_id;
  if not found then raise exception 'La incidencia no existe.'; end if;
  if me.rol <> 'admin' and (i.autor <> me.nombre or i.creado < now() - interval '24 hours') then
    raise exception 'Solo puedes borrar tus incidencias durante las primeras 24 horas.';
  end if;
  delete from incidencias where id = p_id;
  return i.foto;
end $$;

-- ---------- Procedimientos (PDF) ----------
create or replace function public.guardar_procedimiento(p_titulo text, p_categoria text, p_archivo text, p_bytes integer) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede añadir procedimientos.'; end if;
  insert into procedimientos (titulo, categoria, archivo, bytes, autor)
  values (trim(p_titulo), coalesce(nullif(trim(p_categoria), ''), 'General'), p_archivo, coalesce(p_bytes, 0), me.nombre);
end $$;

create or replace function public.borrar_procedimiento(p_id bigint) returns text
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); f text;
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede borrar procedimientos.'; end if;
  delete from procedimientos where id = p_id returning archivo into f;
  return f;
end $$;

-- ---------- Teléfonos útiles ----------
create or replace function public.guardar_contacto(p_id bigint, p_nombre text, p_telefono text, p_nota text, p_orden integer) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede editar los teléfonos.'; end if;
  if coalesce(trim(p_nombre), '') = '' or coalesce(trim(p_telefono), '') = '' then raise exception 'Faltan el nombre o el teléfono.'; end if;
  if p_id is null then
    insert into contactos (nombre, telefono, nota, orden) values (trim(p_nombre), trim(p_telefono), trim(coalesce(p_nota,'')), coalesce(p_orden, 0));
  else
    update contactos set nombre = trim(p_nombre), telefono = trim(p_telefono), nota = trim(coalesce(p_nota,'')), orden = coalesce(p_orden, 0) where id = p_id;
  end if;
end $$;

create or replace function public.borrar_contacto(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede editar los teléfonos.'; end if;
  delete from contactos where id = p_id;
end $$;

-- ---------- Contraseña temporal (sin depender del correo) ----------
create or replace function public.contrasena_temporal(p_id uuid) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare me perfiles := yo_aprobado(); pw text;
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede generar contraseñas temporales.'; end if;
  if p_id = me.id then raise exception 'Para tu propia cuenta usa «Cambiar mi contraseña».'; end if;
  pw := 'SVA-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4)) || '-' || substr(md5(random()::text), 1, 4);
  update auth.users set encrypted_password = extensions.crypt(pw, extensions.gen_salt('bf')), updated_at = now() where id = p_id;
  if not found then raise exception 'Usuario no encontrado.'; end if;
  return pw;
end $$;

-- Permisos de ejecución
do $$ declare f text; begin
  foreach f in array array['crear_aviso(uuid,text,text,text,text)','resolver_aviso(bigint,text)','reabrir_aviso(bigint)',
    'borrar_aviso(bigint)','crear_incidencia(uuid,date,text,text,text)','borrar_incidencia(bigint)',
    'guardar_procedimiento(text,text,text,integer)','borrar_procedimiento(bigint)',
    'guardar_contacto(bigint,text,text,text,integer)','borrar_contacto(bigint)','contrasena_temporal(uuid)'] loop
    execute 'revoke execute on function public.' || f || ' from public, anon';
    execute 'grant execute on function public.' || f || ' to authenticated';
  end loop;
end $$;

-- Teléfonos de ejemplo (solo si la tabla está vacía). Edítalos o bórralos desde la app.
insert into public.contactos (nombre, telefono, nota, orden)
select * from (values
  ('Emergencias', '112', 'Centro coordinador 1-1-2 Canarias', 1),
  ('Información toxicológica', '91 562 04 20', 'Servicio de Información Toxicológica (24 h)', 2)
) v(nombre, telefono, nota, orden)
where not exists (select 1 from public.contactos);
