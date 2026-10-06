# Project Schema — noizu_dropbox

This is an API-client library: **no relational store, no KV/Redis, no fixture
corpora**. The structured data in this repo is (1) app configuration, (2) OAuth2
wire payloads, (3) typed response structs, and (4) the error contract. Each is
documented below. Code organization: see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## Config schema — `config :noizu_dropbox`

Source: `config/config.exs` (defaults), `config/{dev,test}.exs` (overrides);
consumed by `Noizu.Dropbox.Client`.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `access_token` | String \| nil | `nil` | Short-lived bearer token |
| `refresh_token` | String \| nil | `nil` | Offline refresh token |
| `app_key` | String \| nil | `nil` | Dropbox app key (client_id) |
| `app_secret` | String \| nil | `nil` | Dropbox app secret — never commit |
| `api_base` | String | `https://api.dropboxapi.com/2/` | RPC endpoints |
| `content_base` | String | `https://content.dropboxapi.com/2/` | Upload/download |
| `notify_base` | String | `https://notify.dropboxapi.com/2/` | Webhooks |
| `oauth_base` | String | `https://api.dropboxapi.com/oauth2/` | Token endpoint |
| `authorize_url` | String | `https://www.dropbox.com/oauth2/authorize` | Consent page |
| `receive_timeout` | ms | `120_000` | HTTP receive timeout |
| `pool_timeout` | ms | `60_000` | Finch pool checkout timeout |

All credential keys default to `nil`; secrets live in env/runtime config only.

## OAuth2 payload shapes — `lib/dropbox/oauth.ex`

`token/1` and `refresh_token/2` POST form bodies to `{oauth_base}token`.
Secret goes in the Basic Auth header **or** the form body — never both
(Dropbox rejects the double-send).

**Token response** (string-keyed map):

| Field | Type | Notes |
|-------|------|-------|
| `access_token` | String | Short-lived (~4 h) |
| `refresh_token` | String | Present when `token_access_type=offline` |
| `expires_in` | Integer | Seconds |
| `token_type` | String | `"bearer"` |
| `account_id` / `uid` | String | Account identifiers |
| `scope` | String | Space-separated granted scopes |

`pkce_pair/0` returns `%{code_verifier, code_challenge, method: "S256"}`.

## Typed response structs — `lib/dropbox/struct/`

| Struct | Fields (all nullable except `raw`) | From endpoint |
|--------|------------------------------------|---------------|
| `Account` | `account_id`, `name`(map), `email`, `email_verified`, `disabled`, `is_teammate`, `profile_photo_url`, `country`, `locale`, `referral_link`, `is_paired`, `account_type`(unwrapped from `.tag`), `root_info`(map), `team`(map), `team_member_id`, `raw` | `users/get_account*` |
| `Metadata` | `tag`(from `.tag`), `name`, `path_lower`, `path_display`, `id`, `client_modified`, `server_modified`, `rev`, `size`, `is_downloadable`, `content_hash`, `symlink_info`, `sharing_info`, `property_groups`, `has_explicit_shared_members`, `export_info`, `media_info`, `raw` | Most `files/*` |
| `ListFolderResult` | `entries`([Metadata]), `cursor`, `has_more` (defaults `[]`/`false`) | `files/list_folder{,/continue}` |
| `SpaceUsage` | `used`, `allocation`(map), `raw` | `users/get_space_usage` |

All structs implement `from_json/1` accepting atom- or string-keyed maps,
lists (mapped), or `nil`; unknown fields are preserved verbatim in `raw`.

## Error contract — `lib/dropbox/error.ex`

`Noizu.Dropbox.Error` (exception) — constructors: `from_response/2`
(HTTP error), `transport/1`, `codec/1`, `config/1`.

| Field | Type | Notes |
|-------|------|-------|
| `message` | String | Rendered message |
| `status` | pos_integer \| nil | HTTP status; `nil` for non-HTTP errors |
| `body` | term | Raw response body |
| `reason` | term | `:http_error` \| `:config` \| transport/codec reason |
| `summary` | String \| nil | Dropbox `error_summary` when present |
| `tag` | String \| atom \| nil | `:transport`, `:codec`, `:config`, or Dropbox `.tag` |

## API request convention — `lib/dropbox/api/*`

RPC calls POST JSON to `{api_base}{namespace}/{endpoint}`; content calls hit
`content_base` with the Dropbox-API-Arg header. Endpoint modules return
`{:ok, parsed}` (struct where one exists, else decoded map), or
`{:error, %Noizu.Dropbox.Error{}}`. Endpoint surface: `files`, `sharing`,
`users`, `account`, `auth`, `check`, `contacts`, `file_properties`,
`file_requests`, `openid`, `paper`.
