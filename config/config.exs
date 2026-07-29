import Config

config :noizu_dropbox,
  access_token: nil,
  refresh_token: nil,
  app_key: nil,
  app_secret: nil,
  api_base: "https://api.dropboxapi.com/2/",
  content_base: "https://content.dropboxapi.com/2/",
  notify_base: "https://notify.dropboxapi.com/2/",
  oauth_base: "https://api.dropboxapi.com/oauth2/",
  authorize_url: "https://www.dropbox.com/oauth2/authorize",
  receive_timeout: 120_000,
  pool_timeout: 60_000

import_config "#{config_env()}.exs"
