defmodule Noizu.Dropbox do
  @moduledoc """
  Noizu Dropbox — full Dropbox API v2 client for Elixir.

  ## Quick start

      # config/runtime.exs
      config :noizu_dropbox,
        access_token: System.get_env("DROPBOX_ACCESS_TOKEN"),
        app_key: System.get_env("DROPBOX_APP_KEY"),
        app_secret: System.get_env("DROPBOX_APP_SECRET")

      client = Noizu.Dropbox.client()

      {:ok, account} = Noizu.Dropbox.Api.Users.get_current_account(client: client)
      {:ok, listing} = Noizu.Dropbox.Api.Files.list_folder("", client: client)
      {:ok, meta} = Noizu.Dropbox.Api.Files.upload("/hello.txt", "hi", client: client)

  ## Architecture

  * `Noizu.Dropbox.Client` — credentials + base URLs + team select headers
  * `Noizu.Dropbox.HTTP` — RPC / content-upload / content-download / notify
  * `Noizu.Dropbox.OAuth` — authorize URL, code exchange, refresh, PKCE
  * `Noizu.Dropbox.Api.*` — endpoint modules mirroring Dropbox namespaces
  * `Noizu.Dropbox.Error` — structured errors

  ## API namespaces

  | Module | Dropbox namespace |
  |--------|------------------|
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

  Pass `%Client{}` via `opts[:client]` (or omit to use application config defaults).
  """

  alias Noizu.Dropbox.Client

  @doc "Build a client from options / application config."
  @spec client(keyword() | map()) :: Client.t()
  def client(opts \\ []), do: Client.new(opts)

  @doc "Default API base URL."
  def api_base, do: Client.default().api_base

  @doc "Default content base URL."
  def content_base, do: Client.default().content_base

  @doc "Default notify base URL."
  def notify_base, do: Client.default().notify_base
end
