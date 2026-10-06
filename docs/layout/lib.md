# lib/ — Source Breakdown

## Top level

| File | Contents |
|------|----------|
| `lib/noizu_dropbox.ex` | Top-level `Noizu.Dropbox` convenience/entry module |
| `lib/application.ex` | `Noizu.Dropbox.Application` — starts Finch pool supervisor |

## lib/dropbox/ — core plumbing

| File | Contents |
|------|----------|
| `client.ex` | Request builder: base config, headers, token injection |
| `http.ex` | Finch-backed transport (RPC + content upload/download) |
| `oauth.ex` | OAuth2: short-lived tokens, refresh flow, PKCE |
| `error.ex` | Typed error struct for API failures |

## lib/dropbox/api/ — one module per Dropbox namespace

| File | Namespace |
|------|-----------|
| `api.ex` | Shared API helper/dispatch |
| `files.ex` | Files: list_folder, upload/download content, search, … |
| `sharing.ex` | Shared folders/links, member management |
| `users.ex` | User profile, space usage |
| `account.ex` | Account info endpoints |
| `auth.ex` | Token revocation/introspection |
| `check.ex` | Connectivity check (echo) |
| `contacts.ex` | Contacts |
| `file_properties.ex` | Custom file properties/templates |
| `file_requests.ex` | File requests |
| `openid.ex` | OpenID Connect profile/claims |
| `paper.ex` | Paper docs |

## lib/dropbox/struct/ — typed responses

| File | Struct |
|------|--------|
| `account.ex` | `Account` |
| `metadata.ex` | `Metadata` (file/folder union) |
| `list_folder_result.ex` | `ListFolderResult` (entries + cursor) |
| `space_usage.ex` | `SpaceUsage` |
