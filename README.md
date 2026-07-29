# Noizu Dropbox

Full **Dropbox API v2** client for Elixir.

Covers RPC endpoints, content upload/download, OAuth2 (short-lived tokens +
refresh + PKCE), and the main user namespaces: files, sharing, users, account,
auth, check, paper, file requests, file properties, contacts, and OpenID.

## Installation

```elixir
def deps do
  [
    {:noizu_dropbox, "~> 0.1.0"}
    # monorepo:
    # {:noizu_dropbox, path: "libs/integrations/elixir-dropbox"}
  ]
end
```

### Hex package checklist

| Field | Status |
|-------|--------|
| `app` / package name `noizu_dropbox` | ✓ |
| `version`, `description`, `licenses` | ✓ |
| `maintainers`, `links` (GitHub, Changelog, API) | ✓ |
| `files` (`lib`, mix, README, LICENSE, CHANGELOG) | ✓ |
| `source_url` / docs extras | ✓ |
| Runtime deps: Finch, Jason only | ✓ |

```sh
mix test
mix test --cover
mix hex.build          # builds tarball; does not publish
# mix hex.publish       # when ready
```

## Configuration

```elixir
# config/runtime.exs
config :noizu_dropbox,
  access_token: System.get_env("DROPBOX_ACCESS_TOKEN"),
  refresh_token: System.get_env("DROPBOX_REFRESH_TOKEN"),
  app_key: System.get_env("DROPBOX_APP_KEY"),
  app_secret: System.get_env("DROPBOX_APP_SECRET")
```

Or build a client explicitly:

```elixir
client = Noizu.Dropbox.client(
  access_token: "...",
  app_key: "...",
  app_secret: "..."
)
```

Pass the client on each call via `client:`:

```elixir
Noizu.Dropbox.Api.Files.list_folder("", client: client)
```

## Quick examples

### Account

```elixir
{:ok, account} = Noizu.Dropbox.Api.Users.get_current_account()
{:ok, usage} = Noizu.Dropbox.Api.Users.get_space_usage()
```

### Files

```elixir
{:ok, listing} = Noizu.Dropbox.Api.Files.list_folder("")
{:ok, meta} = Noizu.Dropbox.Api.Files.upload("/hello.txt", "hello world")
{:ok, %{metadata: meta, body: body}} = Noizu.Dropbox.Api.Files.download("/hello.txt")
{:ok, _} = Noizu.Dropbox.Api.Files.create_folder("/projects")
{:ok, _} = Noizu.Dropbox.Api.Files.move("/hello.txt", "/projects/hello.txt")
```

Large uploads (chunked sessions):

```elixir
{:ok, meta} = Noizu.Dropbox.Api.Files.upload_large("/big.bin", File.read!("big.bin"))
```

### Sharing

```elixir
{:ok, link} =
  Noizu.Dropbox.Api.Sharing.create_shared_link_with_settings("/projects/hello.txt")
```

### OAuth2

```elixir
url = Noizu.Dropbox.OAuth.authorize_url(
  client_id: app_key,
  redirect_uri: "https://example.com/callback",
  token_access_type: "offline",
  scope: "files.content.read files.content.write account_info.read"
)

{:ok, tokens} =
  Noizu.Dropbox.OAuth.token(
    code: code,
    redirect_uri: "https://example.com/callback",
    client: client
  )

{:ok, client, _} = Noizu.Dropbox.OAuth.refresh_client(client)
```

PKCE:

```elixir
%{code_verifier: verifier, code_challenge: challenge, method: method} =
  Noizu.Dropbox.OAuth.pkce_pair()

url =
  Noizu.Dropbox.OAuth.authorize_url(
    client_id: app_key,
    redirect_uri: redirect_uri,
    code_challenge: challenge,
    code_challenge_method: method,
    token_access_type: "offline"
  )
```

### Team member context

```elixir
client =
  Noizu.Dropbox.client(access_token: team_token)
  |> Noizu.Dropbox.Client.as_user(member_id)

Noizu.Dropbox.Api.Files.list_folder("", client: client)
```

## Architecture

| Module | Role |
|--------|------|
| `Noizu.Dropbox` | Entry helpers |
| `Noizu.Dropbox.Client` | Tokens, bases, team headers |
| `Noizu.Dropbox.HTTP` | RPC / content / notify / form POST |
| `Noizu.Dropbox.OAuth` | Authorize, token, refresh, PKCE |
| `Noizu.Dropbox.Error` | Structured errors |
| `Noizu.Dropbox.Api.*` | Endpoint namespaces |
| `Noizu.Dropbox.Struct.*` | Common response shapes |

HTTP stack: **Finch** + **Jason**.

## API namespaces

| Elixir module | Dropbox paths |
|---------------|---------------|
| `Api.Files` | `files/*` |
| `Api.Sharing` | `sharing/*` |
| `Api.Users` | `users/*` |
| `Api.Account` | `account/*` |
| `Api.Auth` | `auth/*` |
| `Api.Check` | `check/*` |
| `Api.Paper` | `paper/*` |
| `Api.FileRequests` | `file_requests/*` |
| `Api.FileProperties` | `file_properties/*` |
| `Api.Contacts` | `contacts/*` |
| `Api.OpenID` | `openid/*` |

Official Dropbox HTTP docs: https://www.dropbox.com/developers/documentation/http/documentation

## License

MIT
