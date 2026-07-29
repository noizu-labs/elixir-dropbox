defmodule Noizu.Dropbox.Api do
  @moduledoc false

  alias Noizu.Dropbox.Client

  defmacro __using__(_opts) do
    quote do
      alias Noizu.Dropbox.Client
      alias Noizu.Dropbox.HTTP
      alias Noizu.Dropbox.Api

      @type opts :: keyword() | map()
      @type result :: {:ok, term()} | {:error, Noizu.Dropbox.Error.t()}
    end
  end

  @doc false
  def normalize_opts(nil), do: []
  def normalize_opts(opts) when is_list(opts), do: opts
  def normalize_opts(opts) when is_map(opts), do: Map.to_list(opts)

  @doc false
  def client(opts) do
    opts = normalize_opts(opts)

    case Keyword.get(opts, :client) do
      %Client{} = c -> c
      _ -> Client.default()
    end
  end

  @doc "Put key from opts into body when present."
  def put_opt_if(body, key, opts) do
    opts = normalize_opts(opts)

    case Keyword.fetch(opts, key) do
      {:ok, value} -> Map.put(body, key, value)
      :error -> body
    end
  end

  @doc "Put key with default when not in opts."
  def put_opt(body, key, opts, default \\ nil) do
    opts = normalize_opts(opts)

    cond do
      Keyword.has_key?(opts, key) -> Map.put(body, key, Keyword.get(opts, key))
      not is_nil(default) -> Map.put(body, key, default)
      true -> body
    end
  end

  @doc false
  def decode_opt(opts, default \\ :atoms) do
    Keyword.get(normalize_opts(opts), :decode, default)
  end

  @doc false
  def http_opts(client, opts) do
    opts
    |> normalize_opts()
    |> Keyword.put(:client, client)
    |> Keyword.take([:client, :decode, :auth, :headers, :timeout, :pool_timeout, :method])
  end
end
