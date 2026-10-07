# Project Layout — noizu_dropbox

Elixir client for the Dropbox API v2 (RPC + content endpoints, OAuth2 with
refresh + PKCE). Runtime deps: Finch, Jason only. See `README.md` for usage.

```
elixir-dropbox/
├── lib/                            # Source → [layout/lib.md](layout/lib.md)
│   ├── noizu_dropbox.ex            #   Top-level convenience/entry module
│   ├── application.ex              #   OTP app (Finch pool supervisor)
│   └── dropbox/                    #   Client core + api/ + struct/
├── config/                         # Compile/runtime config
│   ├── config.exs                  #   Defaults: API bases, timeouts, token nils
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides (stub-friendly)
├── test/                           # ExUnit suites
│   ├── api/                        #   Per-namespace endpoint tests (files, sharing, …)
│   ├── support/finch_stub.exs      #   Finch transport stub for offline tests
│   └── test_helper.exs
├── .claude/worktrees/              # Agent worktrees (gitignored)
├── .formatter.exs                  # `mix format` config
├── .tool-versions                  # Elixir 1.20.1-otp-29 / Erlang 29.0.2 (asdf/mise)
├── AGENT.md / AGENTS.md            # Agent guidance (kept aligned)
├── CHANGELOG.md
├── CLAUDE.md                       # Claude Code instructions for this repo
├── LICENSE
├── mix.exs                         # Package metadata; coverage threshold 30
├── mix.lock
└── README.md                       # Start here — install, Hex checklist
```

## Key details

- `lib/dropbox/api/` holds one module per Dropbox namespace (`files`, `sharing`,
  `users`, `account`, `auth`, `check`, `contacts`, `file_properties`,
  `file_requests`, `openid`, `paper`); `lib/dropbox/struct/` holds typed
  response structs (`account`, `metadata`, `list_folder_result`, `space_usage`).
- Core plumbing lives in `lib/dropbox/`: `client.ex` (request builder),
  `http.ex` (Finch transport), `oauth.ex` (token + PKCE flows), `error.ex`.
- Credentials are injected via config (`:noizu_dropbox` → `access_token`,
  `refresh_token`, `app_key`, `app_secret`); all default to `nil` — never
  committed.
- Generated/local artifacts (`_build/`, `deps/`, `cover/`, `doc/`,
  `erl_crash.dump`, `*.tar`) are gitignored.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `config/dev.exs` | Provide local `app_key`/`app_secret`/tokens (never commit) |
| `.tool-versions` | Ensure matching Elixir/Erlang via asdf or mise |
