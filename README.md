# nexus-app

Sitio estático (`index.html` + `app.jps`).

## Desarrollo

```bash
python3 -m http.server 8321
# http://localhost:8321/index.html
```

## Playwright MCP

El repo trae configurado el servidor MCP de Playwright en [`.mcp.json`](.mcp.json),
que permite a Claude Code abrir la app en un navegador real, inspeccionarla y probarla.

Elige el navegador solo según dónde ejecutes Claude Code:

- **En tu máquina** → se engancha a **tu Chrome abierto**, con tus sesiones y páginas
  guardadas. Solo necesitas instalar la
  [extensión Playwright](https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm).
- **En Claude Code web / contenedor remoto** → Chromium headless preinstalado.

Para dejarlo listo en tu equipo:

```bash
bash scripts/install-local.sh
```

Detalles, modos y flags en [`docs/playwright-mcp.md`](docs/playwright-mcp.md).
