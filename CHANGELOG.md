# Changelog

## 0.1.0

- Initial release: full Dropbox API v2 Elixir client
- Finch + Jason HTTP stack with supervised pool
- OAuth2 authorize / token exchange / refresh / PKCE
- API modules: Files, Sharing, Users, Account, Auth, Check, Paper,
  FileRequests, FileProperties, Contacts, OpenID
- Content upload/download with `Dropbox-API-Arg` / `Dropbox-API-Result`
- Team member context (`Dropbox-API-Select-User` / `Select-Admin`)
- Structured `Noizu.Dropbox.Error` and common response structs
