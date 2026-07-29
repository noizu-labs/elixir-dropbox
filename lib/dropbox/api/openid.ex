defmodule Noizu.Dropbox.Api.OpenID do
  @moduledoc """
  Dropbox `openid/*` endpoints.
  """

  use Noizu.Dropbox.Api

  @doc "POST `openid/userinfo` — empty/`null` body."
  @spec userinfo(opts()) :: result()
  def userinfo(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("openid/userinfo",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
