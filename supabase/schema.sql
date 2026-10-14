-- =====================================================================
-- 43.80 SVA-E · Esquema de base de datos para Supabase
-- Pegar entero en: Supabase > SQL Editor > New query > Run
-- Se puede ejecutar más de una vez (crea o reemplaza).
-- =====================================================================

-- ---------- Tablas ----------
create table if not exists public.perfiles (
  id        uuid primary key references auth.users on delete cascade,
  nombre    text not null unique,
  categoria text not null check (categoria in ('ENF','TES')),
  externo   boolean not null default false,
  rol       text not null default 'usuario' check (rol in ('usuario','admin')),
  aprobado  boolean not null default false,
  creado    timestamptz not null default now()
);

create table if not exists public.guardias (
  id        bigint generated always as identity primary key,
  fecha     date not null,
  franja    text not null check (franja in ('24h','D','N')),
  categoria text not null check (categoria in ('ENF','TES')),
  titular   text,
  unique (fecha, franja, categoria)
);

create table if not exists public.ofertas (
  id         bigint generated always as identity primary key,
  guardia_id bigint not null references public.guardias on delete cascade,
  ofertante  text not null,
  tipo       text not null check (tipo in ('cesion','cambio')),
  nota       text not null default '',
  estado     text not null default 'abierta' check (estado in ('abierta','aceptada','cancelada')),
  aceptante  text,
  creada     timestamptz not null default now(),
  resuelta   timestamptz
);
create unique index if not exists una_oferta_abierta on public.ofertas (guardia_id) where estado = 'abierta';

create table if not exists public.propuestas (
  id         bigint generated always as identity primary key,
  oferta_id  bigint not null references public.ofertas on delete cascade,
  proponente text not null,
  guardia_id bigint not null references public.guardias on delete cascade,
  estado     text not null default 'pendiente' check (estado in ('pendiente','aceptada','descartada','retirada')),
  creada     timestamptz not null default now()
);

-- Registro de movimientos: solo se escribe desde las funciones; nadie puede editarlo ni borrarlo desde la app.
create table if not exists public.historial (
  id     bigint generated always as identity primary key,
  creado timestamptz not null default now(),
  actor  text not null,
  texto  text not null
);

-- ---------- Seguridad (RLS): solo usuarios aprobados leen; nadie escribe directamente ----------
alter table public.perfiles   enable row level security;
alter table public.guardias   enable row level security;
alter table public.ofertas    enable row level security;
alter table public.propuestas enable row level security;
alter table public.historial  enable row level security;
revoke all on public.perfiles, public.guardias, public.ofertas, public.propuestas, public.historial from anon, authenticated;
grant select on public.perfiles, public.guardias, public.ofertas, public.propuestas, public.historial to authenticated;

create or replace function public.es_aprobado() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select aprobado from perfiles where id = auth.uid()), false)
$$;
create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select aprobado and rol = 'admin' from perfiles where id = auth.uid()), false)
$$;

drop policy if exists leer_perfiles on public.perfiles;
create policy leer_perfiles on public.perfiles for select using (id = auth.uid() or public.es_admin());
drop policy if exists leer_guardias on public.guardias;
create policy leer_guardias on public.guardias for select using (public.es_aprobado());
drop policy if exists leer_ofertas on public.ofertas;
create policy leer_ofertas on public.ofertas for select using (public.es_aprobado());
drop policy if exists leer_propuestas on public.propuestas;
create policy leer_propuestas on public.propuestas for select using (public.es_aprobado());
drop policy if exists leer_historial on public.historial;
create policy leer_historial on public.historial for select using (public.es_aprobado());

-- ---------- Alta automática del perfil al registrarse ----------
create or replace function public.nuevo_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into perfiles (id, nombre, categoria, externo)
  values (new.id,
          regexp_replace(trim(coalesce(new.raw_user_meta_data->>'nombre', new.email)), '\s+', ' ', 'g'),
          coalesce(nullif(new.raw_user_meta_data->>'categoria',''), 'ENF'),
          coalesce((new.raw_user_meta_data->>'externo')::boolean, false));
  return new;
end $$;
drop trigger if exists al_registrarse on auth.users;
create trigger al_registrarse after insert on auth.users for each row execute function public.nuevo_usuario();

-- ---------- Utilidades ----------
create or replace function public.rango(f date, fr text) returns tsrange
language sql immutable as $$
  select case fr
    when '24h' then tsrange(f + time '09:00', (f + 1) + time '09:00')
    when 'D'   then tsrange(f + time '09:00', f + time '21:00')
    else            tsrange(f + time '21:00', (f + 1) + time '09:00') end
$$;

create or replace function public.desc_g(g public.guardias) returns text
language sql immutable as $$
  select (case g.franja when '24h' then 'guardia de 24 h' when 'D' then 'guardia diurna' else 'guardia nocturna' end)
    || ' del ' || (array['dom','lun','mar','mié','jue','vie','sáb'])[extract(dow from g.fecha)::int + 1]
    || ' ' || to_char(g.fecha, 'DD/MM')
$$;

create or replace function public.ha_empezado(g public.guardias) returns boolean
language sql stable as $$
  select lower(public.rango(g.fecha, g.franja)) <= (now() at time zone 'Atlantic/Canary')
$$;

-- ¿Tiene "p_nombre" otra guardia que se solape con p_guardia (ignorando p_excluir)?
create or replace function public.solapa(p_nombre text, p_guardia bigint, p_excluir bigint default null) returns public.guardias
language sql stable security definer set search_path = public as $$
  select g.* from guardias g, guardias x
  where x.id = p_guardia and g.titular = p_nombre and g.id <> p_guardia and g.id <> coalesce(p_excluir, -1)
    and rango(g.fecha, g.franja) && rango(x.fecha, x.franja)
  limit 1
$$;

create or replace function public.yo_aprobado() returns public.perfiles
language plpgsql stable security definer set search_path = public as $$
declare me perfiles;
begin
  select * into me from perfiles where id = auth.uid() and aprobado;
  if not found then raise exception 'Tu usuario no está autorizado.'; end if;
  return me;
end $$;

-- ---------- Acciones del tablón (cada una es una operación única y bloqueante) ----------
create or replace function public.publicar_oferta(p_guardia bigint, p_tipo text, p_nota text default '') returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); g guardias;
begin
  select * into g from guardias where id = p_guardia for update;
  if not found then raise exception 'La guardia no existe.'; end if;
  if g.titular is distinct from me.nombre then raise exception 'Esta guardia no es tuya.'; end if;
  if ha_empezado(g) then raise exception 'La guardia ya ha empezado o ha pasado.'; end if;
  if exists (select 1 from ofertas where guardia_id = g.id and estado = 'abierta') then raise exception 'Ya está publicada en el tablón.'; end if;
  insert into ofertas (guardia_id, ofertante, tipo, nota) values (g.id, me.nombre, p_tipo, left(trim(coalesce(p_nota,'')), 300));
  insert into historial (actor, texto) values (me.nombre, case when p_tipo = 'cesion' then 'Ofrece ceder su ' else 'Ofrece cambiar su ' end || desc_g(g));
end $$;

create or replace function public.cancelar_oferta(p_oferta bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); o ofertas; g guardias;
begin
  select * into o from ofertas where id = p_oferta for update;
  if not found or o.estado <> 'abierta' then raise exception 'La oferta ya está cerrada.'; end if;
  if o.ofertante <> me.nombre and me.rol <> 'admin' then raise exception 'Solo quien la publicó puede retirarla.'; end if;
  update ofertas set estado = 'cancelada', resuelta = now() where id = o.id;
  update propuestas set estado = 'descartada' where oferta_id = o.id and estado = 'pendiente';
  select * into g from guardias where id = o.guardia_id;
  insert into historial (actor, texto) values (me.nombre, 'Retira del tablón la ' || desc_g(g));
end $$;

create or replace function public.aceptar_cesion(p_oferta bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); o ofertas; g guardias; c guardias;
begin
  select * into o from ofertas where id = p_oferta for update;
  if not found or o.estado <> 'abierta' then raise exception 'Otra persona se ha adelantado: la oferta ya está cerrada.'; end if;
  if o.tipo <> 'cesion' then raise exception 'Esta oferta es un cambio: tienes que proponer una guardia tuya.'; end if;
  if o.ofertante = me.nombre then raise exception 'No puedes aceptar tu propia oferta.'; end if;
  select * into g from guardias where id = o.guardia_id for update;
  if g.titular is distinct from o.ofertante then raise exception 'La guardia ya no pertenece a quien la ofertó.'; end if;
  if g.categoria <> me.categoria then raise exception 'Solo puede cubrirla alguien de la misma categoría.'; end if;
  if ha_empezado(g) then raise exception 'La guardia ya ha empezado.'; end if;
  c := solapa(me.nombre, g.id);
  if c.id is not null then raise exception 'Se solapa con tu %.', desc_g(c); end if;
  update guardias set titular = me.nombre where id = g.id;
  update ofertas set estado = 'aceptada', aceptante = me.nombre, resuelta = now() where id = o.id;
  update propuestas set estado = 'descartada' where guardia_id = g.id and estado = 'pendiente';
  insert into historial (actor, texto) values (me.nombre, 'Se queda la ' || desc_g(g) || ' de ' || o.ofertante);
end $$;

create or replace function public.proponer_cambio(p_oferta bigint, p_guardia bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); o ofertas; mia guardias; suya guardias; c guardias;
begin
  select * into o from ofertas where id = p_oferta;
  if not found or o.estado <> 'abierta' or o.tipo <> 'cambio' then raise exception 'La oferta ya no admite propuestas.'; end if;
  if o.ofertante = me.nombre then raise exception 'No puedes proponerte un cambio a ti mismo.'; end if;
  select * into mia from guardias where id = p_guardia;
  select * into suya from guardias where id = o.guardia_id;
  if mia.titular is distinct from me.nombre then raise exception 'Esa guardia no es tuya.'; end if;
  if mia.categoria <> suya.categoria then raise exception 'El cambio tiene que ser entre la misma categoría.'; end if;
  if ha_empezado(mia) or ha_empezado(suya) then raise exception 'Una de las guardias ya ha empezado.'; end if;
  if exists (select 1 from propuestas where oferta_id = o.id and guardia_id = mia.id and estado = 'pendiente') then raise exception 'Ya has propuesto esa guardia.'; end if;
  c := solapa(me.nombre, suya.id, mia.id);
  if c.id is not null then raise exception 'Su guardia se solapa con tu %.', desc_g(c); end if;
  c := solapa(o.ofertante, mia.id, suya.id);
  if c.id is not null then raise exception 'Tu guardia se solapa con otra de %.', o.ofertante; end if;
  insert into propuestas (oferta_id, proponente, guardia_id) values (o.id, me.nombre, mia.id);
  insert into historial (actor, texto) values (me.nombre, 'Propone a ' || o.ofertante || ' su ' || desc_g(mia) || ' por la ' || desc_g(suya));
end $$;

create or replace function public.retirar_propuesta(p_propuesta bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); p propuestas;
begin
  select * into p from propuestas where id = p_propuesta for update;
  if not found or p.proponente <> me.nombre then raise exception 'Solo puedes retirar tus propuestas.'; end if;
  if p.estado <> 'pendiente' then raise exception 'La propuesta ya no está pendiente.'; end if;
  update propuestas set estado = 'retirada' where id = p.id;
end $$;

create or replace function public.aceptar_propuesta(p_propuesta bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); p propuestas; o ofertas; g1 guardias; g2 guardias; c guardias;
begin
  select * into p from propuestas where id = p_propuesta for update;
  if not found or p.estado <> 'pendiente' then raise exception 'La propuesta ya no está pendiente.'; end if;
  select * into o from ofertas where id = p.oferta_id for update;
  if o.ofertante <> me.nombre then raise exception 'Solo quien publicó la oferta puede aceptar propuestas.'; end if;
  if o.estado <> 'abierta' then raise exception 'La oferta ya está cerrada.'; end if;
  select * into g1 from guardias where id = o.guardia_id for update;
  select * into g2 from guardias where id = p.guardia_id for update;
  if g1.titular is distinct from o.ofertante or g2.titular is distinct from p.proponente then
    raise exception 'Alguna de las guardias ha cambiado de titular. Recarga.'; end if;
  if ha_empezado(g1) or ha_empezado(g2) then raise exception 'Una de las guardias ya ha empezado.'; end if;
  c := solapa(o.ofertante, g2.id, g1.id);
  if c.id is not null then raise exception 'Esa guardia se solapa con otra tuya.'; end if;
  c := solapa(p.proponente, g1.id, g2.id);
  if c.id is not null then raise exception 'Tu guardia se solapa con otra de %.', p.proponente; end if;
  update guardias set titular = p.proponente where id = g1.id;
  update guardias set titular = o.ofertante  where id = g2.id;
  update ofertas set estado = 'aceptada', aceptante = p.proponente, resuelta = now() where id = o.id;
  update propuestas set estado = 'aceptada' where id = p.id;
  update propuestas set estado = 'descartada' where estado = 'pendiente' and (oferta_id = o.id or guardia_id in (g1.id, g2.id));
  update ofertas set estado = 'cancelada', resuelta = now() where guardia_id = g2.id and estado = 'abierta';
  update propuestas set estado = 'descartada' where estado = 'pendiente' and oferta_id in (select id from ofertas where guardia_id = g2.id);
  insert into historial (actor, texto) values (me.nombre, 'Cambio cerrado: ' || o.ofertante || ' hace la ' || desc_g(g2) || ' y ' || p.proponente || ' la ' || desc_g(g1));
end $$;

-- ---------- Administración ----------
create or replace function public.importar_cuadrante(p_categoria text, p_desde date, p_hasta date, p_filas jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede importar el cuadrante.'; end if;
  delete from guardias where categoria = p_categoria and fecha between p_desde and p_hasta;
  insert into guardias (fecha, franja, categoria, titular)
  select x.fecha, x.franja, p_categoria, nullif(trim(x.titular), '')
  from jsonb_to_recordset(p_filas) as x(fecha date, franja text, titular text);
  insert into historial (actor, texto) values (me.nombre,
    'Importa el cuadrante ' || case when p_categoria = 'ENF' then 'de enfermería' else 'de TES' end
    || ' del ' || to_char(p_desde, 'DD/MM') || ' al ' || to_char(p_hasta, 'DD/MM'));
end $$;

create or replace function public.asignar_guardia(p_guardia bigint, p_nombre text) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); g guardias; c guardias; n text := nullif(trim(coalesce(p_nombre,'')), ''); antes text;
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede asignar guardias.'; end if;
  select * into g from guardias where id = p_guardia for update;
  if not found then raise exception 'La guardia no existe.'; end if;
  if n is not null then
    c := solapa(n, g.id);
    if c.id is not null then raise exception '% ya tiene la % en ese horario.', n, desc_g(c); end if;
  end if;
  antes := g.titular;
  update ofertas set estado = 'cancelada', resuelta = now() where guardia_id = g.id and estado = 'abierta';
  update propuestas set estado = 'descartada' where estado = 'pendiente' and guardia_id = g.id;
  update guardias set titular = n where id = g.id;
  insert into historial (actor, texto) values (me.nombre,
    case when n is null then 'Deja libre la ' || desc_g(g) else 'Asigna la ' || desc_g(g) || ' a ' || n end
    || case when antes is not null then ' (antes: ' || antes || ')' else '' end);
end $$;

create or replace function public.gestionar_usuario(p_id uuid, p_nombre text, p_categoria text, p_externo boolean, p_rol text, p_aprobado boolean) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado();
begin
  if me.rol <> 'admin' then raise exception 'Solo un administrador puede gestionar usuarios.'; end if;
  if p_id = me.id and (not p_aprobado or p_rol <> 'admin') then raise exception 'No puedes quitarte a ti mismo el acceso de administrador.'; end if;
  update perfiles set nombre = regexp_replace(trim(p_nombre), '\s+', ' ', 'g'), categoria = p_categoria, externo = p_externo, rol = p_rol, aprobado = p_aprobado
  where id = p_id;
end $$;

-- Solo usuarios con sesión pueden llamar a las funciones
do $$ declare f text; begin
  foreach f in array array['publicar_oferta(bigint,text,text)','cancelar_oferta(bigint)','aceptar_cesion(bigint)',
    'proponer_cambio(bigint,bigint)','retirar_propuesta(bigint)','aceptar_propuesta(bigint)',
    'importar_cuadrante(text,date,date,jsonb)','asignar_guardia(bigint,text)',
    'gestionar_usuario(uuid,text,text,boolean,text,boolean)','solapa(text,bigint,bigint)','yo_aprobado()'] loop
    execute 'revoke execute on function public.' || f || ' from public, anon';
    execute 'grant execute on function public.' || f || ' to authenticated';
  end loop;
end $$;

-- =====================================================================
-- PRIMER ADMINISTRADOR: después de registrarte en la app, ejecuta esto
-- (cambia el correo por el tuyo):
--
--   update public.perfiles set rol = 'admin', aprobado = true
--   where id = (select id from auth.users where email = 'TU_CORREO@ejemplo.com');
-- =====================================================================
