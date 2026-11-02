-- =====================================================================
-- 43.80 SVA-E · Fase 3: dividir una guardia de 24 h en diurno + nocturno
-- (y volver a unirla), para ceder o cambiar solo 12 h desde el tablón.
-- Requiere haber ejecutado antes schema.sql.
-- Pegar entero en: Supabase > SQL Editor > New query > Run
-- Se puede ejecutar más de una vez. No crea tablas nuevas.
-- =====================================================================

create or replace function public.dividir_guardia(p_guardia bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); g guardias;
begin
  select * into g from guardias where id = p_guardia for update;
  if not found then raise exception 'La guardia no existe.'; end if;
  if g.franja <> '24h' then raise exception 'Solo se pueden dividir las guardias de 24 h.'; end if;
  if me.rol <> 'admin' and g.titular is distinct from me.nombre then raise exception 'Esta guardia no es tuya.'; end if;
  if ha_empezado(g) then raise exception 'La guardia ya ha empezado o ha pasado.'; end if;
  if exists (select 1 from ofertas where guardia_id = g.id and estado = 'abierta') then
    raise exception 'Está publicada en el tablón: retírala antes de dividirla.'; end if;
  update propuestas set estado = 'descartada' where estado = 'pendiente' and guardia_id = g.id;
  -- La fila de 24 h pasa a ser el diurno (conserva su historial de ofertas) y se crea el nocturno
  update guardias set franja = 'D' where id = g.id;
  insert into guardias (fecha, franja, categoria, titular) values (g.fecha, 'N', g.categoria, g.titular);
  insert into historial (actor, texto) values (me.nombre, 'Divide en diurno y nocturno la ' || desc_g(g));
end $$;

create or replace function public.unir_guardia(p_guardia bigint) returns void
language plpgsql security definer set search_path = public as $$
declare me perfiles := yo_aprobado(); g guardias; d guardias; n guardias;
begin
  select * into g from guardias where id = p_guardia;
  if not found then raise exception 'La guardia no existe.'; end if;
  if g.franja = '24h' then raise exception 'Ya es una guardia de 24 h.'; end if;
  select * into d from guardias where fecha = g.fecha and categoria = g.categoria and franja = 'D' for update;
  select * into n from guardias where fecha = g.fecha and categoria = g.categoria and franja = 'N' for update;
  if d.id is null or n.id is null then raise exception 'Falta el otro turno de 12 h de ese día.'; end if;
  if d.titular is distinct from n.titular then raise exception 'Los dos turnos tienen titulares distintos.'; end if;
  if me.rol <> 'admin' and d.titular is distinct from me.nombre then raise exception 'Estos turnos no son tuyos.'; end if;
  if ha_empezado(d) then raise exception 'El turno ya ha empezado o ha pasado.'; end if;
  if exists (select 1 from ofertas where guardia_id in (d.id, n.id) and estado = 'abierta') then
    raise exception 'Algún turno está publicado en el tablón: retíralo antes.'; end if;
  update propuestas set estado = 'descartada' where estado = 'pendiente' and guardia_id in (d.id, n.id);
  delete from guardias where id = n.id;
  update guardias set franja = '24h' where id = d.id returning * into d;
  insert into historial (actor, texto) values (me.nombre, 'Une en una ' || desc_g(d));
end $$;

revoke execute on function public.dividir_guardia(bigint) from public, anon;
revoke execute on function public.unir_guardia(bigint) from public, anon;
grant execute on function public.dividir_guardia(bigint) to authenticated;
grant execute on function public.unir_guardia(bigint) to authenticated;
