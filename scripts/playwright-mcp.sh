#!/usr/bin/env bash
# Arranca @playwright/mcp adaptándose al entorno donde corre Claude Code.
#
#   extension  -> se engancha a TU Chrome ya abierto (perfil real, sesiones
#                 iniciadas, pestañas). Requiere la extensión "Playwright
#                 Extension" instalada. Es el modo por defecto en local.
#   container  -> Chromium headless preinstalado. Modo por defecto en el
#                 contenedor remoto de Claude Code (no hay display ni Chrome).
#   chrome     -> lanza tu Chrome con un perfil aparte que persiste entre
#                 sesiones (inicias sesión una vez). Sin extensión.
#
# Fuerza un modo con: PLAYWRIGHT_MCP_MODE=extension|container|chrome
set -euo pipefail

CONTAINER_CHROMIUM="/opt/pw-browsers/chromium"
MODE="${PLAYWRIGHT_MCP_MODE:-auto}"

if [ "$MODE" = "auto" ]; then
  if [ -x "$CONTAINER_CHROMIUM" ]; then
    MODE="container"
  else
    MODE="extension"
  fi
fi

case "$MODE" in
  extension)
    exec npx -y @playwright/mcp@latest --extension "$@"
    ;;
  container)
    exec npx -y @playwright/mcp@latest \
      --headless \
      --isolated \
      --executable-path "${PLAYWRIGHT_CHROMIUM_PATH:-$CONTAINER_CHROMIUM}" "$@"
    ;;
  chrome)
    exec npx -y @playwright/mcp@latest --browser chrome "$@"
    ;;
  *)
    echo "PLAYWRIGHT_MCP_MODE no válido: '$MODE' (usa extension, container o chrome)" >&2
    exit 1
    ;;
esac
