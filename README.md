# Snowflake Cortex Agent × MCP

Connect a **Snowflake Cortex Agent** to the outside world using the **Model Context Protocol (MCP)** — in **both directions**:

- **Snowflake as an MCP server** → query your Cortex agent from **VS Code** in plain English.
- **Snowflake as an MCP client** → let a Snowflake agent call an **external tool (GitHub)**.

This repo contains everything needed to reproduce the setup end to end: the SQL, the VS Code config, a full step‑by‑step guide, and the gotchas learned the hard way.

---

## What is this?

MCP is an open standard — think **"USB‑C for AI"** — that lets any AI client talk to any tool/data source through one protocol. Here we:

1. Expose a healthcare Cortex Agent as an **MCP server**, then query it from VS Code Chat (Agent mode) using a scoped access token.
2. Register **GitHub** as an **MCP connector** so a Snowflake agent can answer questions about your repositories.

```
Scenario A:   VS Code  ──►  MCP Server (Snowflake)  ──►  Cortex Agent  ──►  your data
Scenario B:   Snowflake Agent  ──►  MCP Connector  ──►  GitHub
```

---

## Repository contents

> Adjust the file names below to match what you actually committed.

| File | What it is |
|------|------------|
| `README.md` | This overview |
| `healthcare_mcp_setup.sql` | Full, ordered Snowflake setup script (MCP server, `reader_role`, all grants) |
| `.vscode/mcp.json` | Example VS Code MCP config (token redacted — see note) |
| `docs/MCP_Snowflake_VSCode_Guide.docx` | Detailed step‑by‑step student guide (both scenarios) |
| `docs/screenshots/` | Screenshots of each step (optional) |

---

## Quick start

**Prerequisites:** a Snowflake account with Cortex enabled, an existing Cortex Agent, and VS Code with GitHub Copilot.

1. **Snowflake** — run `healthcare_mcp_setup.sql` in a Snowsight worksheet. It creates the MCP server, a least‑privileged `reader_role`, and all the grants.
2. **Token** — Snowsight → **Settings → Authentication → Programmatic access tokens → Generate token** (Single role = `READER_ROLE`).
3. **VS Code** — put the config at `.vscode/mcp.json` (set `type: http`, your account URL, and `Authorization: "Bearer <token>"`), then `Ctrl+Shift+P` → **Developer: Reload Window** → **MCP: List Servers** → **Start**. Look for `Discovered 1 tools`.
4. **Ask** — open Chat in **Agent mode** and ask a data question (e.g. *"count insurance claims by claim status"*).

For the GitHub connector (Scenario B) and every detail, see the **full guide** in `docs/`.

---

## Key gotchas (save yourself hours)

- Use `CREATE ROLE IF NOT EXISTS` — **never** `CREATE OR REPLACE ROLE` (it wipes all grants).
- The `Authorization` header must be `Bearer <token>` with **no leading space**.
- The config file must be at **`.vscode/mcp.json`** exactly.
- Non‑admin roles need `GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER` + `SELECT` on the semantic view.
- Set a **default warehouse** on your user (`ALTER USER … SET DEFAULT_WAREHOUSE`).
- GitHub connector: grant a role with `GRANT USAGE ON EXTERNAL MCP SERVER … TO ROLE …` (not `MCP SERVER`); Client ID must include the leading `O`; the OAuth callback URL can vary by region.

---

## Security

- **Never commit a real token or client secret.** Keep `.vscode/mcp.json` in `.gitignore`, or use VS Code's `inputs` prompt so the secret is entered at runtime.
- Scope tokens to a least‑privileged role — never ship an `ACCOUNTADMIN` token.
- Regenerate any credential that's ever been shared or exposed.

---

## Tech

Snowflake Cortex Agents · Snowflake‑managed MCP Server · Model Context Protocol · VS Code (GitHub Copilot, Agent mode) · GitHub OAuth.

---

*Built as a learning project demonstrating both directions of MCP with Snowflake Cortex.*
