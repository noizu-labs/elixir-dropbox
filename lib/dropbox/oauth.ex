defmodule Noizu.Dropbox.OAuth do
  @moduledoc """
  OAuth2 helpers for Dropbox.

  Supports the modern short-lived access token + refresh token flow.

  ## Authorization URL

      Noizu.Dropbox.OAuth.authorize_url(
        client_id: "APP_KEY",
        redirect_uri: "https://example.com/oauth/callback",
        token_access_type: "offline",
        scope: "files.content.read files.content.write account_info.read"
      )

  ## Exchange code

      Noizu.Dropbox.OAuth.token(
        code: code,
        redirect_uri: redirect_uri,
        client: client
      )

  ## Refresh

      Noizu.Dropbox.OAuth.refresh_token(refresh_token, client: client)
  """

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Error
  alias Noizu.Dropbox.HTTP

  @type options :: keyword() | map()

  @doc """
  Build the user authorization URL.

  ## Options
  * `:client_id` / app key (required unless on client)
  * `:redirect_uri`
  * `:response_type` — default `"code"`
  * `:state`
  * `:token_access_type` — `"offline"` to receive a refresh token
  * `:scope` — space-separated scopes
  * `:include_granted_scopes` — `"user"` | `"team"`
  * `:code_challenge` / `:code_challenge_method` — PKCE
  * `:force_reapprove`, `:disable_signup`, `:require_role`, `:locale`
  """
  @spec authorize_url(options()) :: String.t() | {:error, Error.t()}
  def authorize_url(opts \\ []) do
    opts = normalize(opts)
    client = Keyword.get(opts, :client) || Client.default()
    client_id = Keyword.get(opts, :client_id) || client.app_key

    if is_nil(client_id) or client_id == "" do
      {:error, Error.config("app_key / client_id required for authorize_url")}
    else
      params =
        [
          {"client_id", client_id},
          {"response_type", Keyword.get(opts, :response_type, "code")}
        ]
        |> maybe_put("redirect_uri", Keyword.get(opts, :redirect_uri))
        |> maybe_put("state", Keyword.get(opts, :state))
        |> maybe_put("token_access_type", Keyword.get(opts, :token_access_type))
        |> maybe_put("scope", Keyword.get(opts, :scope))
        |> maybe_put("include_granted_scopes", Keyword.get(opts, :include_granted_scopes))
        |> maybe_put("code_challenge", Keyword.get(opts, :code_challenge))
        |> maybe_put("code_challenge_method", Keyword.get(opts, :code_challenge_method))
        |> maybe_put("force_reapprove", bool_param(Keyword.get(opts, :force_reapprove)))
        |> maybe_put("disable_signup", bool_param(Keyword.get(opts, :disable_signup)))
        |> maybe_put("require_role", Keyword.get(opts, :require_role))
        |> maybe_put("locale", Keyword.get(opts, :locale))

      client.authorize_url <> "?" <> URI.encode_query(params)
    end
  end

  @doc """
  Exchange an authorization code for tokens.

  Returns a map with string keys such as `"access_token"`, `"refresh_token"`,
  `"expires_in"`, `"token_type"`, `"account_id"`, `"uid"`, `"scope"`.
  """
  @spec token(options()) :: {:ok, map()} | {:error, Error.t()}
  def token(opts \\ []) do
    opts = normalize(opts)
    client = Keyword.get(opts, :client) || Client.default()
    code = Keyword.fetch!(opts, :code)

    form =
      [
        grant_type: "authorization_code",
        code: code
      ]
      |> maybe_kw(:redirect_uri, Keyword.get(opts, :redirect_uri))
      |> maybe_kw(:code_verifier, Keyword.get(opts, :code_verifier))
      |> maybe_kw(:client_id, Keyword.get(opts, :client_id) || client.app_key)
      |> maybe_kw(:client_secret, Keyword.get(opts, :client_secret) || client.app_secret)

    url = Client.normalize_base(client.oauth_base) <> "token"
    HTTP.form_post(url, form, client: client, basic_auth: basic?(client, opts))
  end

  @doc """
  Refresh a short-lived access token.
  """
  @spec refresh_token(String.t(), options()) :: {:ok, map()} | {:error, Error.t()}
  def refresh_token(refresh_token, opts \\ []) when is_binary(refresh_token) do
    opts = normalize(opts)
    client = Keyword.get(opts, :client) || Client.default()

    form =
      [
        grant_type: "refresh_token",
        refresh_token: refresh_token
      ]
      |> maybe_kw(:client_id, Keyword.get(opts, :client_id) || client.app_key)
      |> maybe_kw(:client_secret, Keyword.get(opts, :client_secret) || client.app_secret)

    url = Client.normalize_base(client.oauth_base) <> "token"
    HTTP.form_post(url, form, client: client, basic_auth: basic?(client, opts))
  end

  @doc """
  Refresh and return an updated `%Client{}` with the new access token.
  """
  @spec refresh_client(Client.t()) :: {:ok, Client.t(), map()} | {:error, Error.t()}
  def refresh_client(%Client{refresh_token: refresh} = client)
      when is_binary(refresh) and refresh != "" do
    case refresh_token(refresh, client: client) do
      {:ok, %{"access_token" => token} = body} ->
        {:ok, Client.put_access_token(client, token), body}

      {:ok, %{access_token: token} = body} ->
        {:ok, Client.put_access_token(client, token), body}

      other ->
        other
    end
  end

  def refresh_client(%Client{}) do
    {:error, Error.config("refresh_token is not set on client")}
  end

  @doc "Generate a PKCE code_verifier / S256 code_challenge pair."
  @spec pkce_pair() :: %{code_verifier: String.t(), code_challenge: String.t(), method: String.t()}
  def pkce_pair do
    verifier =
      :crypto.strong_rand_bytes(32)
      |> Base.url_encode64(padding: false)

    challenge =
      :crypto.hash(:sha256, verifier)
      |> Base.url_encode64(padding: false)

    %{code_verifier: verifier, code_challenge: challenge, method: "S256"}
  end

  # ---------------------------------------------------------------------------

  defp basic?(client, opts) do
    Keyword.get(opts, :basic_auth, not is_nil(client.app_key) and not is_nil(client.app_secret))
  end

  defp maybe_put(params, _k, nil), do: params
  defp maybe_put(params, _k, ""), do: params
  defp maybe_put(params, k, v), do: params ++ [{k, v}]

  defp maybe_kw(kw, _k, nil), do: kw
  defp maybe_kw(kw, _k, ""), do: kw
  defp maybe_kw(kw, k, v), do: Keyword.put(kw, k, v)

  defp bool_param(nil), do: nil
  defp bool_param(true), do: "true"
  defp bool_param(false), do: "false"
  defp bool_param(other), do: other

  defp normalize(nil), do: []
  defp normalize(opts) when is_list(opts), do: opts
  defp normalize(opts) when is_map(opts), do: Map.to_list(opts)
end
