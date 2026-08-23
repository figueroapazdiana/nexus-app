#!/usr/bin/env bash
# Instala Playwright MCP en TU equipo y lo deja listo para usar tu Chrome.
# Uso:  bash scripts/install-local.sh
set -uo pipefail

EXT_ID="mmlmfjhmonkocbjadbfplnigmagldckm"
EXT_URL="https://chromewebstore.google.com/detail/playwright-extension/$EXT_ID"
ok=0; fail=0
say()  { printf '\n\033[1m%s\033[0m\n' "$1"; }
good() { printf '  \033[32mOK\033[0m  %s\n' "$1"; ok=$((ok+1)); }
bad()  { printf '  \033[31mX\033[0m   %s\n' "$1"; fail=$((fail+1)); }
warn() { printf '  \033[33m!\033[0m   %s\n' "$1"; }

say "1. Requisitos"
if command -v node >/dev/null 2>&1; then
  major=$(node -p 'process.versions.node.split(".")[0]')
  if [ "$major" -ge 18 ]; then good "Node $(node -v)"; else bad "Node $(node -v): hace falta 18 o superior"; fi
else
  bad "Node no encontrado. Instálalo desde https://nodejs.org"
fi
command -v npx >/dev/null 2>&1 && good "npx disponible" || bad "npx no encontrado"

say "2. Descargando @playwright/mcp@latest"
ver=$(npx -y @playwright/mcp@latest --version 2>/dev/null | head -1)
[ -n "$ver" ] && good "Playwright MCP $ver en la caché de npx" || bad "No se pudo descargar el paquete (¿red o proxy?)"

say "3. Chrome y extensión"
case "$(uname -s)" in
  Darwin) CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"
          CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; OPEN=open ;;
  Linux)  CHROME_DIR="$HOME/.config/google-chrome"
          CHROME_BIN=$(command -v google-chrome || command -v google-chrome-stable || true); OPEN=xdg-open ;;
  *)      CHROME_DIR="$LOCALAPPDATA/Google/Chrome/User Data"
          CHROME_BIN=$(command -v chrome || true); OPEN=start ;;
esac
[ -n "${CHROME_BIN:-}" ] && [ -e "${CHROME_BIN:-/nonexistent}" ] && good "Chrome instalado" || warn "No localicé el ejecutable de Chrome (no es bloqueante si Chrome está instalado)"

if [ -d "$CHROME_DIR" ] && find "$CHROME_DIR" -maxdepth 3 -type d -name "$EXT_ID" 2>/dev/null | grep -q .; then
  good "Extensión Playwright ya instalada en Chrome"
else
  warn "Falta la extensión Playwright. Ábrela e instálala:"
  printf '      %s\n' "$EXT_URL"
  command -v "$OPEN" >/dev/null 2>&1 && "$OPEN" "$EXT_URL" >/dev/null 2>&1 &
fi

say "4. Comprobando que el servidor MCP arranca"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tools=$({
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"install","version":"1"}}}'
  sleep 2
  echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
  sleep 3
} | bash "$here/playwright-mcp.sh" 2>/dev/null \
  | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{for(const l of d.trim().split("\n")){try{const m=JSON.parse(l);if(m.id===2)return console.log((m.result?.tools||[]).length)}catch(e){}}console.log(0)})')
[ "${tools:-0}" -gt 0 ] && good "Servidor OK: $tools herramientas disponibles" || bad "El servidor no respondió"

say "Resultado: $ok correctos, $fail fallos"
if [ "$fail" -eq 0 ]; then
  cat <<'TXT'

  Ya está. Abre este repo con Claude Code en tu equipo y aprueba el servidor
  "playwright" cuando lo pregunte (o ejecuta /mcp para verlo).

  La primera vez que Claude toque el navegador, Chrome abrirá una página para
  que elijas qué pestaña compartir.
TXT
else
  printf '\n  Revisa los puntos marcados con X y vuelve a ejecutar este script.\n\n'
fi
exit "$fail"
