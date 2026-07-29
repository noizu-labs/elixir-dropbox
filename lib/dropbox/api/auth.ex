defmodule Noizu.Dropbox.Api.Auth do
  @moduledoc """
  Dropbox `auth/*` endpoints.
  """

  use Noizu.Dropbox.Api

  @doc "POST `auth/token/revoke` — empty/`null` body."
  @spec token_revoke(opts()) :: result()
  def token_revoke(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("auth/token/revoke",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `auth/token/from_oauth1`."
  @spec token_from_oauth1(String.t(), String.t(), opts()) :: result()
  def token_from_oauth1(oauth1_token, oauth1_token_secret, opts \\ [])
      when is_binary(oauth1_token) and is_binary(oauth1_token_secret) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("auth/token/from_oauth1",
      body: %{
        oauth1_token: oauth1_token,
        oauth1_token_secret: oauth1_token_secret
      },
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
