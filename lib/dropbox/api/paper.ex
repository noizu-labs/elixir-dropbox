defmodule Noizu.Dropbox.Api.Paper do
  @moduledoc """
  Legacy Dropbox Paper API (`paper/*`).

  Prefer `files/paper/*` for new Paper docs stored in Dropbox filesystem.
  """

  use Noizu.Dropbox.Api

  # ---------------------------------------------------------------------------
  # Docs metadata / list
  # ---------------------------------------------------------------------------

  @doc "POST `paper/docs/get_metadata`."
  @spec docs_get_metadata(String.t(), opts()) :: result()
  def docs_get_metadata(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/get_metadata",
      body: %{doc_id: doc_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/list`."
  @spec docs_list(opts()) :: result()
  def docs_list(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{}
      |> Api.put_opt_if(:filter_by, opts)
      |> Api.put_opt_if(:sort_by, opts)
      |> Api.put_opt_if(:sort_order, opts)
      |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("paper/docs/list", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `paper/docs/list/continue`."
  @spec docs_list_continue(String.t(), opts()) :: result()
  def docs_list_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/list/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Docs content create / update / download
  # ---------------------------------------------------------------------------

  @doc """
  POST `paper/docs/create` (content upload).

  ## Options
  * `:import_format` (required) — e.g. `"markdown"`, `"html"`, `"plain_text"`
  * `:parent_folder_id`
  """
  @spec docs_create(binary(), opts()) :: result()
  def docs_create(data, opts \\ []) when is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    import_format = Keyword.fetch!(opts, :import_format)

    arg =
      %{import_format: import_format}
      |> Api.put_opt_if(:parent_folder_id, opts)

    HTTP.content_upload("paper/docs/create", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc """
  POST `paper/docs/update` (content upload).

  ## Options
  * `:import_format` (required)
  * `:doc_update_policy` (required)
  * `:revision` (required)
  """
  @spec docs_update(String.t(), binary(), opts()) :: result()
  def docs_update(doc_id, data, opts \\ []) when is_binary(doc_id) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg = %{
      doc_id: doc_id,
      import_format: Keyword.fetch!(opts, :import_format),
      doc_update_policy: Keyword.fetch!(opts, :doc_update_policy),
      revision: Keyword.fetch!(opts, :revision)
    }

    HTTP.content_upload("paper/docs/update", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc """
  POST `paper/docs/download` (content download).

  ## Options
  * `:export_format` (required) — e.g. `"markdown"`, `"html"`
  """
  @spec docs_download(String.t(), opts()) :: result()
  def docs_download(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg = %{
      doc_id: doc_id,
      export_format: Keyword.fetch!(opts, :export_format)
    }

    HTTP.content_download("paper/docs/download", arg, client: client)
  end

  @doc "POST `paper/docs/archive`."
  @spec docs_archive(String.t(), opts()) :: result()
  def docs_archive(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/archive",
      body: %{doc_id: doc_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/permanently_delete`."
  @spec docs_permanently_delete(String.t(), opts()) :: result()
  def docs_permanently_delete(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/permanently_delete",
      body: %{doc_id: doc_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Docs users
  # ---------------------------------------------------------------------------

  @doc "POST `paper/docs/users/add`."
  @spec docs_users_add(String.t(), [map()], opts()) :: result()
  def docs_users_add(doc_id, members, opts \\ []) when is_binary(doc_id) and is_list(members) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{doc_id: doc_id, members: members}
      |> Api.put_opt_if(:quiet, opts)
      |> Api.put_opt_if(:custom_message, opts)

    HTTP.rpc("paper/docs/users/add", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `paper/docs/users/list`."
  @spec docs_users_list(String.t(), opts()) :: result()
  def docs_users_list(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{doc_id: doc_id}
      |> Api.put_opt_if(:limit, opts)
      |> Api.put_opt_if(:filter_by, opts)

    HTTP.rpc("paper/docs/users/list", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `paper/docs/users/list/continue`."
  @spec docs_users_list_continue(String.t(), opts()) :: result()
  def docs_users_list_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/users/list/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/users/remove`."
  @spec docs_users_remove(String.t(), map(), opts()) :: result()
  def docs_users_remove(doc_id, member, opts \\ []) when is_binary(doc_id) and is_map(member) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/users/remove",
      body: %{doc_id: doc_id, member: member},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Folder users / info / sharing policy
  # ---------------------------------------------------------------------------

  @doc "POST `paper/docs/folder_users/list`."
  @spec docs_folder_users_list(String.t(), opts()) :: result()
  def docs_folder_users_list(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body = %{doc_id: doc_id} |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("paper/docs/folder_users/list",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/folder_users/list/continue`."
  @spec docs_folder_users_list_continue(String.t(), opts()) :: result()
  def docs_folder_users_list_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/folder_users/list/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/get_folder_info`."
  @spec docs_get_folder_info(String.t(), opts()) :: result()
  def docs_get_folder_info(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/get_folder_info",
      body: %{doc_id: doc_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/sharing_policy/get`."
  @spec docs_sharing_policy_get(String.t(), opts()) :: result()
  def docs_sharing_policy_get(doc_id, opts \\ []) when is_binary(doc_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/sharing_policy/get",
      body: %{doc_id: doc_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/docs/sharing_policy/set`."
  @spec docs_sharing_policy_set(String.t(), map(), opts()) :: result()
  def docs_sharing_policy_set(doc_id, sharing_policy, opts \\ [])
      when is_binary(doc_id) and is_map(sharing_policy) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("paper/docs/sharing_policy/set",
      body: %{doc_id: doc_id, sharing_policy: sharing_policy},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `paper/folders/create`."
  @spec folders_create(String.t(), opts()) :: result()
  def folders_create(name, opts \\ []) when is_binary(name) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body = %{name: name} |> Api.put_opt_if(:parent_folder_id, opts)

    HTTP.rpc("paper/folders/create", body: body, decode: Api.decode_opt(opts), client: client)
  end
end
