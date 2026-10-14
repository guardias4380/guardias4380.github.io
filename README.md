# 43.80 SVA-E · Guardias

PWA para el cuadrante, el tablón de cambios y (en fases siguientes) avisos, incidencias y procedimientos de la guardia 43.80 SVA-E.

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `index.html` | Toda la app. Arriba está el bloque `CONFIG` |
| `sw.js` | Funcionamiento sin conexión |
| `manifest.json` + `icons/` | Instalación en el móvil |
| `supabase/schema.sql` | Base de datos, permisos y reglas de los cambios |

## Fase A · Probar en modo demo (sin servidor)

1. El código vive en el repositorio `guardias4380/guardias4380.github.io` (organización `guardias4380`) y sube todos los archivos manteniendo las carpetas.
2. Settings → Pages → Branch `main` / carpeta `/ (root)` → Save.
3. Abre `https://guardias4380.github.io/`.

Con `SUPABASE_URL` vacío la app funciona en **modo demo**: los datos se guardan solo en ese móvil y en «Más» puedes cambiar de usuario para simular a cada compañero. No la compartas todavía como herramienta real: en demo cada móvil tiene su propia copia.

## Fase B · Conectar el servidor (Supabase)

1. Crea cuenta en supabase.com → New project. Región: **West EU (Ireland)** o **Central EU (Frankfurt)**. Guarda la contraseña de la base de datos.
2. SQL Editor → New query → pega `supabase/schema.sql` entero → Run.
3. Authentication → Sign In / Providers → Email: activado. Recomendado: desactivar **Confirm email** (el acceso ya lo controla la aprobación del administrador).
4. Project Settings → API: copia **Project URL** y la clave **anon public**, y pégalas en el bloque `CONFIG` de `index.html`. La clave `anon` puede ir en el código: la seguridad la dan las reglas de la base de datos. **Nunca** pegues la clave `service_role`.
5. Sube `index.html` a GitHub.
6. Abre la app, crea tu cuenta con tu nombre exactamente como aparece en el cuadrante.
7. En el SQL Editor ejecuta (con tu nombre tal como lo registraste):
   ```sql
   update public.perfiles set rol = 'admin', aprobado = true
   where nombre = 'Airam Acosta';
   ```
8. Entra, ve a Más → Importar cuadrante y carga noviembre.
9. Pasa el enlace a los compañeros. Cada alta aparece en Más → Usuarios para que la apruebes.

### Plan gratuito de Supabase
Si el proyecto pasa 7 días sin ninguna actividad, Supabase lo pausa y hay que reactivarlo desde su panel. Con uso diario no ocurre.

## Importar el cuadrante cada mes
- En Excel, selecciona desde la fila de cabecera hasta el último día (columnas FECHA a NOCTURNO 12 H), copia y pégalo en la app. Se conservan las columnas.
- O sube el `.xlsx` directamente (necesita conexión la primera vez).
- Regla aplicada: nombre en 24 h → las de 12 h no aplican; nombre en una de 12 h → la otra mitad queda libre; día sin nombres → día completo libre para externos.
- Importar sustituye las guardias de esas fechas y categoría y retira sus ofertas del tablón. Ver la previsualización antes de confirmar.

## Reglas del tablón
- **Ceder**: la primera persona de la misma categoría que acepte se la queda.
- **Cambiar**: los compañeros proponen una guardia suya; quien ofertó elige cuál acepta.
- La aceptación se valida en el servidor en una sola operación: si dos aceptan a la vez, solo una entra.
- No se permiten cambios entre categorías, sobre guardias ya empezadas, ni que dejen a alguien con dos guardias solapadas.
- Todo queda en «Movimientos recientes» y no se puede borrar desde la app.

## Sin conexión
Se consulta el último cuadrante y tablón descargados. Ofertar, aceptar e importar requieren conexión.

## Actualizar la app
`index.html` se actualiza solo la próxima vez que se abre con cobertura. Si cambias `sw.js`, iconos o `manifest.json`, sube `VERSION` en `sw.js` (`sva4380-v2`, `v3`…).
