defmodule Noizu.Dropbox.Api.Check do
  @moduledoc """
  Dropbox `check/*` endpoints — connectivity / echo helpers.
  """

  use Noizu.Dropbox.Api

  @doc "POST `check/user` (user auth)."
  @spec user(String.t(), opts()) :: result()
  def user(query \\ "", opts \\ [])

  def user(query, opts) when is_binary(query) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("check/user",
      body: %{query: query},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `check/app` (app key/secret auth)."
  @spec app(String.t(), opts()) :: result()
  def app(query \\ "", opts \\ [])

  def app(query, opts) when is_binary(query) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("check/app",
      body: %{query: query},
      decode: Api.decode_opt(opts),
      auth: :app,
      client: client
    )
  end
end
