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

[`.mcp.json`](../.mcp.json) apunta a un script que elige el modo según dónde estés:

```json
{
  "mcpServers": {
    "playwright": { "command": "bash", "args": ["scripts/playwright-mcp.sh"] }
  }
}
```

| Modo | Qué navegador usa | Cuándo se elige |
|---|---|---|
| `extension` | **Tu Chrome ya abierto**: tu perfil real, tus sesiones iniciadas, tus pestañas | Por defecto en tu máquina |
| `container` | Chromium headless preinstalado, perfil aislado en memoria | Por defecto en el contenedor remoto de Claude Code |
| `chrome` | Tu Chrome, pero con un perfil aparte que persiste entre sesiones | Solo si lo fuerzas |

La detección es simple: si existe `/opt/pw-browsers/chromium` estamos en el contenedor
remoto → `container`; si no, `extension`. Para forzar uno:

```bash
export PLAYWRIGHT_MCP_MODE=chrome   # extension | container | chrome
```

### Usar tu Chrome de siempre (modo `extension`)

Es el modo que conserva todo lo que ya tienes guardado: cookies, sesiones abiertas,
extensiones y pestañas. Requiere Claude Code corriendo **en tu máquina** (CLI, app de
escritorio o extensión de IDE); desde Claude Code en la web no hay forma de alcanzar
tu navegador local.

1. Instala la extensión **Playwright Extension** desde la
   [Chrome Web Store](https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm).
2. Abre este repo con Claude Code. No hace falta configurar nada más: el script ya
   elige `extension` fuera del contenedor.
3. La primera vez que el agente toque el navegador, se abre una página para que
   **elijas qué pestaña compartir**. Tú decides a qué accede.

Para saltarte esa aprobación manual en cada sesión, copia el token de la página de
estado de la extensión y expórtalo antes de abrir Claude Code:

```bash
export PLAYWRIGHT_MCP_EXTENSION_TOKEN="tu-token"
```

Si falta la extensión, el error lo dice explícitamente y enlaza a la tienda.

### Alternativa sin extensión (modo `chrome`)

`PLAYWRIGHT_MCP_MODE=chrome` lanza tu Chrome real pero con un perfil propio de
Playwright, guardado en `~/Library/Caches/ms-playwright/mcp-{canal}-{hash}` (macOS),
`~/.cache/ms-playwright/...` (Linux) o `%USERPROFILE%\AppData\Local\ms-playwright\...`
(Windows). No hereda tus sesiones actuales, pero como el perfil persiste, inicias
sesión una vez y se queda. Ojo: un perfil persistente solo admite una instancia a la
vez, así que dos clientes MCP sobre el mismo repo chocan.

**No recomendado**: apuntar `--user-data-dir` a tu carpeta de perfil real de Chrome.
Chrome bloquea el perfil mientras está abierto (tendrías que cerrarlo del todo) y
desde Chrome 136 la depuración remota sobre el perfil por defecto está restringida.
El modo `extension` existe precisamente para cubrir ese caso sin esos problemas.

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
