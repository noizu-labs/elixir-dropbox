# PROJ-ARCH (summary)

Elixir client for Dropbox API v2. Thin wrapper over RPC/content/OAuth
endpoints; runtime deps Finch + Jason only. Primary consumer: dropbox-mcp.

**Layers**: Api namespace modules (`lib/dropbox/api/`) and `OAuth` →
`HTTP` (`rpc`/`content_upload`/`content_download`/`notify`/`form_post`) →
`Noizu.Dropbox.Finch` pool (sole child of `Application`) → Dropbox hosts.
`Client` carries config/token/team headers (opts merge over `:noizu_dropbox`
env). Responses decode to structs (`Account`, `Metadata`,
`ListFolderResult`, `SpaceUsage`) or maps; errors are `%Noizu.Dropbox.Error{}`
(`from_response`/`transport`/`codec`/`config`).

**Uniform contract**: `{:ok, term()} | {:error, %Error{}}` everywhere.

**Decisions**: 1:1 REST mirroring (no DSL/codegen); `raw` passthrough on
structs for forward compatibility; single Finch pool for cheap embedding;
OAuth secret via Basic header XOR form body; tests fully mocked via Finch
stub (coverage threshold 30).

Full detail: [PROJ-ARCH.md](PROJ-ARCH.md).
