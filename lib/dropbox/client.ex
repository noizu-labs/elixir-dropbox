defmodule Noizu.Dropbox.Client do
  @moduledoc """
  Client configuration for Dropbox API calls.

  Prefer building a client once and passing it via opts:

      client = Noizu.Dropbox.Client.new(access_token: System.fetch_env!("DROPBOX_ACCESS_TOKEN"))
      Noizu.Dropbox.Api.Users.get_current_account(client: client)

  When `client` is omitted, a default client is built from application config
  (`:noizu_dropbox`).
  """

  alias Noizu.Dropbox.Error

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          app_key: String.t() | nil,
          app_secret: String.t() | nil,
          select_user: String.t() | nil,
          select_admin: String.t() | nil,
          path_root: map() | String.t() | nil,
          api_base: String.t(),
          content_base: String.t(),
          notify_base: String.t(),
          oauth_base: String.t(),
          authorize_url: String.t(),
          receive_timeout: pos_integer(),
          pool_timeout: pos_integer(),
          finch: atom()
        }

  defstruct access_token: nil,
            refresh_token: nil,
            app_key: nil,
            app_secret: nil,
            select_user: nil,
            select_admin: nil,
            path_root: nil,
            api_base: "https://api.dropboxapi.com/2/",
            content_base: "https://content.dropboxapi.com/2/",
            notify_base: "https://notify.dropboxapi.com/2/",
            oauth_base: "https://api.dropboxapi.com/oauth2/",
            authorize_url: "https://www.dropbox.com/oauth2/authorize",
            receive_timeout: 120_000,
            pool_timeout: 60_000,
            finch: Noizu.Dropbox.Finch

  @doc """
  Build a client from keyword options merged over application env defaults.
  """
  @spec new(keyword() | map()) :: t()
  def new(opts \\ []) do
    opts = Map.new(opts)

    %__MODULE__{
      access_token: pick(opts, :access_token),
      refresh_token: pick(opts, :refresh_token),
      app_key: pick(opts, :app_key),
      app_secret: pick(opts, :app_secret),
      select_user: pick(opts, :select_user),
      select_admin: pick(opts, :select_admin),
      path_root: pick(opts, :path_root),
      api_base: pick(opts, :api_base, "https://api.dropboxapi.com/2/"),
      content_base: pick(opts, :content_base, "https://content.dropboxapi.com/2/"),
      notify_base: pick(opts, :notify_base, "https://notify.dropboxapi.com/2/"),
      oauth_base: pick(opts, :oauth_base, "https://api.dropboxapi.com/oauth2/"),
      authorize_url: pick(opts, :authorize_url, "https://www.dropbox.com/oauth2/authorize"),
      receive_timeout: pick(opts, :receive_timeout, 120_000),
      pool_timeout: pick(opts, :pool_timeout, 60_000),
      finch: pick(opts, :finch, Noizu.Dropbox.Finch)
    }
  end

  @doc "Default client from application config."
  @spec default() :: t()
  def default, do: new()

  @doc "Return a client with an updated access token."
  @spec put_access_token(t(), String.t()) :: t()
  def put_access_token(%__MODULE__{} = client, token) when is_binary(token) do
    %{client | access_token: token}
  end

  @doc "Return a client acting as a team member (`Dropbox-API-Select-User`)."
  @spec as_user(t(), String.t()) :: t()
  def as_user(%__MODULE__{} = client, member_id) when is_binary(member_id) do
    %{client | select_user: member_id, select_admin: nil}
  end

  @doc "Return a client acting as a team admin (`Dropbox-API-Select-Admin`)."
  @spec as_admin(t(), String.t()) :: t()
  def as_admin(%__MODULE__{} = client, team_member_id) when is_binary(team_member_id) do
    %{client | select_admin: team_member_id, select_user: nil}
  end

  @doc """
  Ensure the client has an access token.

  Returns `{:ok, client}` or `{:error, %Noizu.Dropbox.Error{}}`.
  """
  @spec require_token(t()) :: {:ok, t()} | {:error, Error.t()}
  def require_token(%__MODULE__{access_token: token} = client)
      when is_binary(token) and token != "" do
    {:ok, client}
  end

  def require_token(%__MODULE__{}) do
    {:error, Error.config("Dropbox access_token is not configured")}
  end

  @doc "Normalize API base URL (trailing slash)."
  @spec normalize_base(String.t()) :: String.t()
  def normalize_base(base) when is_binary(base) do
    if String.ends_with?(base, "/"), do: base, else: base <> "/"
  end

  defp pick(opts, key, default \\ nil) do
    case Map.fetch(opts, key) do
      {:ok, value} -> value
      :error -> Application.get_env(:noizu_dropbox, key, default)
    end
  end
end
