#!/usr/bin/env bash
# Actualiza la copia de la Guía Rápida de Perfusión que va dentro de la app (carpeta perfusion/).
# Uso: bash scripts/actualizar-perfusion.sh   (desde la raíz del repositorio; necesita git, node 22 y npm)
# Luego: revisar, commit y push.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone -q --depth 1 https://github.com/jaacos/guia-perfusion "$TMP/gp"
cd "$TMP/gp"
COMMIT="$(git log -1 --format='%h %ci')"

# 1) El service worker se registra relativo a su carpeta (perfusion/), no en la raíz del dominio.
grep -q "register('/service-worker.js')" src/main.tsx && sed -i "s#register('/service-worker.js')#register('./service-worker.js')#" src/main.tsx
grep -q "register('./service-worker.js')" src/main.tsx || { echo "ERROR: no encuentro el registro del service worker"; exit 1; }

# 2) Al actualizarse, la guía solo borra SUS cachés (no las de la app de la 43.80: comparten dominio).
grep -q "k => k !== CACHE_NAME" public/service-worker.js && sed -i "s#k => k !== CACHE_NAME#k => k.startsWith('guia-perfusion') \&\& k !== CACHE_NAME#" public/service-worker.js
grep -q "k.startsWith('guia-perfusion')" public/service-worker.js || { echo "ERROR: no puedo limitar el borrado de cachés"; exit 1; }

npm ci --no-audit --no-fund >/dev/null
npm run build >/dev/null
rm -rf "$RAIZ/perfusion"
cp -r dist "$RAIZ/perfusion"
echo "Copia de github.com/jaacos/guia-perfusion · commit $COMMIT · generada $(date -u +%F)" > "$RAIZ/perfusion/ORIGEN.txt"
echo "Listo: perfusion/ actualizada ($COMMIT)"
