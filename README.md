# nexus-app

Sitio estático (`index.html` + `app.jps`).

## Desarrollo

```bash
python3 -m http.server 8321
# http://localhost:8321/index.html
```

## Playwright MCP

El repo trae configurado el servidor MCP de Playwright en [`.mcp.json`](.mcp.json), que
permite a Claude Code abrir la app en un navegador real, inspeccionarla y probarla.
Detalles, flags y ejemplos en [`docs/playwright-mcp.md`](docs/playwright-mcp.md).
