defmodule Noizu.Dropbox.Api.FileRequests do
  @moduledoc """
  Dropbox `file_requests/*` endpoints.
  """

  use Noizu.Dropbox.Api

  @doc "POST `file_requests/create`."
  @spec create(String.t(), String.t(), opts()) :: result()
  def create(title, destination, opts \\ []) when is_binary(title) and is_binary(destination) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{title: title, destination: destination}
      |> Api.put_opt_if(:deadline, opts)
      |> Api.put_opt_if(:open, opts)
      |> Api.put_opt_if(:description, opts)

    HTTP.rpc("file_requests/create", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `file_requests/get`."
  @spec get(String.t(), opts()) :: result()
  def get(id, opts \\ []) when is_binary(id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/get",
      body: %{id: id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_requests/list_v2`."
  @spec list_v2(opts()) :: result()
  def list_v2(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{} |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("file_requests/list_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `file_requests/list/continue`."
  @spec list_continue(String.t(), opts()) :: result()
  def list_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/list/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_requests/list` (legacy)."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/list",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_requests/update`."
  @spec update(String.t(), opts()) :: result()
  def update(id, opts \\ []) when is_binary(id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{id: id}
      |> Api.put_opt_if(:title, opts)
      |> Api.put_opt_if(:destination, opts)
      |> Api.put_opt_if(:deadline, opts)
      |> Api.put_opt_if(:open, opts)
      |> Api.put_opt_if(:description, opts)

    HTTP.rpc("file_requests/update", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `file_requests/delete`."
  @spec delete([String.t()], opts()) :: result()
  def delete(ids, opts \\ []) when is_list(ids) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/delete",
      body: %{ids: ids},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_requests/delete_all_closed` — empty/`null` body."
  @spec delete_all_closed(opts()) :: result()
  def delete_all_closed(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/delete_all_closed",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_requests/count` — empty/`null` body."
  @spec count(opts()) :: result()
  def count(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_requests/count",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
