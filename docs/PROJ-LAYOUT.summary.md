# PROJ-LAYOUT (summary)

```
elixir-dropbox/
├── lib/                # Source → layout/lib.md (dropbox core, api/, struct/)
├── config/             # config/dev/test.exs — API bases, tokens default nil
├── test/               # ExUnit; api/ suites + support/finch_stub.exs
├── .claude/worktrees/  # Agent worktrees (gitignored)
├── .formatter.exs
├── .tool-versions      # Elixir 1.20.1-otp-29 / Erlang 29.0.2
├── AGENT.md / AGENTS.md / CLAUDE.md
├── CHANGELOG.md / LICENSE
├── mix.exs / mix.lock  # package :noizu_dropbox v0.1.0; coverage threshold 30
└── README.md
```

Ignored build artifacts: `_build/`, `deps/`, `cover/`, `doc/`, `erl_crash.dump`, `*.tar`.
