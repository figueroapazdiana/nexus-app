# Playwright MCP (`@playwright/mcp`)

## Qué es

Servidor MCP (Model Context Protocol) oficial de Microsoft/Playwright que le da a un
agente de IA control real de un navegador.

La diferencia clave frente a otras herramientas de automatización: **no trabaja con
capturas de pantalla**, sino con el *árbol de accesibilidad* de la página. Eso significa:

- Rápido y ligero: no hay pixeles que procesar.
- Datos estructurados: el agente "ve" roles, nombres y referencias de elementos.
- No necesita modelo de visión.
- Determinista: se hace clic en una referencia concreta, no en una coordenada adivinada.

Versión verificada en este repo: **0.0.79** (Playwright 1.63.0-alpha-2026-08-05),
protocolo MCP `2024-11-05`, **24 herramientas** expuestas.

## Herramientas disponibles

| Grupo | Herramientas |
|---|---|
| Navegación | `browser_navigate`, `browser_navigate_back`, `browser_tabs`, `browser_close`, `browser_resize` |
| Lectura de página | `browser_snapshot`, `browser_find`, `browser_take_screenshot`, `browser_console_messages` |
| Interacción | `browser_click`, `browser_type`, `browser_fill_form`, `browser_press_key`, `browser_hover`, `browser_drag`, `browser_drop`, `browser_select_option`, `browser_file_upload`, `browser_handle_dialog` |
| Red | `browser_network_requests`, `browser_network_request` |
| Código / espera | `browser_evaluate`, `browser_run_code_unsafe`, `browser_wait_for` |

Capacidades extra opcionales con `--caps`: `vision` (clic por coordenadas),
`pdf` (exportar la página a PDF) y `devtools` (traces, video, resaltado de elementos).

## Configuración en este repo

Está en [`.mcp.json`](../.mcp.json), a nivel de proyecto, así que Claude Code lo detecta
automáticamente al abrir el repo (pide aprobación la primera vez):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--headless",
        "--isolated",
        "--executable-path", "${PLAYWRIGHT_CHROMIUM_PATH:-/opt/pw-browsers/chromium}"
      ]
    }
  }
}
```

Por qué cada flag:

- `--headless`: por defecto abre navegador con ventana; en un contenedor sin display hay que forzar headless.
- `--isolated`: perfil en memoria, sin persistir cookies/sesión en disco entre ejecuciones.
- `--executable-path`: sin esto, el server busca el canal `chrome` en `/opt/google/chrome/chrome` y falla.
  `PLAYWRIGHT_CHROMIUM_PATH` permite sobreescribir la ruta; el valor por defecto es el Chromium
  ya preinstalado en el entorno remoto de Claude Code.

En una máquina local, exporta la ruta a tu navegador antes de abrir Claude Code, por ejemplo:

```bash
# macOS con Chrome instalado
export PLAYWRIGHT_CHROMIUM_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

Alta manual equivalente (si prefieres no usar el archivo del repo):

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

## Cómo usarlo con este proyecto

`nexus-app` es un sitio estático (`index.html` + `app.jps`). El acceso a `file://` está
bloqueado por defecto en el server (medida de seguridad), así que sirve la carpeta por HTTP:

```bash
python3 -m http.server 8321
```

y luego pídele al agente algo como *"abre http://localhost:8321/index.html y dime qué
errores de consola hay"*.

Comprobación real hecha durante la instalación: navegación a `http://localhost:8321/index.html`
→ título `NEXUS`, snapshot capturado, y 7 errores de consola detectados (React, Babel, Firebase
y Google Fonts desde CDN, bloqueados por la red del contenedor, más un `favicon.ico` 404).

## Flags útiles adicionales

| Flag | Para qué |
|---|---|
| `--device "iPhone 15"` / `--mobile` | Emular móvil (páginas más ligeras = menos tokens) |
| `--browser firefox\|webkit\|msedge` | Cambiar de navegador |
| `--caps vision,pdf,devtools` | Habilitar capacidades opcionales |
| `--save-trace` / `--output-dir` | Guardar traces y artefactos en una ruta concreta |
| `--storage-state <archivo>` | Arrancar con sesión ya iniciada |
| `--blocked-origins` / `--allowed-origins` | Limitar a qué dominios puede pedir el navegador |
| `--port <n>` | Servir por HTTP en vez de stdio |
| `--allow-unrestricted-file-access` | Permitir `file://` y salir de la carpeta del proyecto (úsalo solo si lo necesitas) |

Listado completo: `npx @playwright/mcp@latest --help`

## Notas

- Las salidas (snapshots, capturas, logs) se escriben en `.playwright-mcp/`, ya ignorado en `.gitignore`.
- `--allowed-origins` y `--blocked-origins` no son una frontera de seguridad real y no afectan a redirecciones.
- `browser_run_code_unsafe` ejecuta código Playwright arbitrario: úsalo con cuidado.
