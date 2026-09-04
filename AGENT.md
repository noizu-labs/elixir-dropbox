# AGENT.md — elixir-dropbox

Guidance for coding agents (Grok, Codex, Claude, Cursor). Monorepo ops → `../../../../../CLAUDE.md` (trl-infra root).

## Identity

Elixir Dropbox API client. Primary consumer: `Portfolio/Apps/AI/dropbox-mcp` (Dropbox filesystem MCP server). API-contract lib — keep behavior aligned with the live Dropbox REST surface.

## Stack & Commands

Elixir. `mix deps.get && mix compile`; `mix test` (mocked; live calls need a token — never commit one); `mix format`, `mix credo`.

## Universal Rules (compressed)

- **Trinity Protocol REQUIRED**: Orientation → Friction → Response (full text: monorepo `protocols/the-trinity-protocol.md`).
- **No shell in main thread** — delegate to taskers.
- **Worktrees**: all work on worktrees; `epic.<group>` consolidation branches off `develop`; squash-PR provenance into epics.
- MAIN checkout owns `deps/_build`; worktrees symlink deps (absolute path).
