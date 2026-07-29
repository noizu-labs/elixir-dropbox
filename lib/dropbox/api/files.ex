defmodule Noizu.Dropbox.Api.Files do
  @moduledoc """
  Dropbox `files/*` endpoints — listing, upload/download, copy/move/delete,
  search, revisions, locks, tags, thumbnails, and upload sessions.
  """

  use Noizu.Dropbox.Api

  alias Noizu.Dropbox.Struct.ListFolderResult
  alias Noizu.Dropbox.Struct.Metadata

  # ---------------------------------------------------------------------------
  # Metadata & listing
  # ---------------------------------------------------------------------------

  @doc "POST `files/get_metadata`."
  @spec get_metadata(String.t(), opts()) :: result()
  def get_metadata(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt_if(:include_media_info, opts)
      |> Api.put_opt_if(:include_deleted, opts)
      |> Api.put_opt_if(:include_has_explicit_shared_members, opts)
      |> Api.put_opt_if(:include_property_groups, opts)

    HTTP.rpc("files/get_metadata",
      body: body,
      decode: Api.decode_opt(opts, Metadata),
      client: client
    )
  end

  @doc "POST `files/list_folder`. Use `path: \"\"` for the root folder."
  @spec list_folder(String.t(), opts()) :: result()
  def list_folder(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt(:recursive, opts, false)
      |> Api.put_opt_if(:include_media_info, opts)
      |> Api.put_opt_if(:include_deleted, opts)
      |> Api.put_opt_if(:include_has_explicit_shared_members, opts)
      |> Api.put_opt_if(:include_mounted_folders, opts)
      |> Api.put_opt_if(:include_non_downloadable_files, opts)
      |> Api.put_opt_if(:include_property_groups, opts)
      |> Api.put_opt_if(:limit, opts)
      |> Api.put_opt_if(:shared_link, opts)

    HTTP.rpc("files/list_folder",
      body: body,
      decode: Api.decode_opt(opts, ListFolderResult),
      client: client
    )
  end

  @doc "POST `files/list_folder/continue`."
  @spec list_folder_continue(String.t(), opts()) :: result()
  def list_folder_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/list_folder/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts, ListFolderResult),
      client: client
    )
  end

  @doc "POST `files/list_folder/get_latest_cursor`."
  @spec list_folder_get_latest_cursor(String.t(), opts()) :: result()
  def list_folder_get_latest_cursor(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt(:recursive, opts, false)
      |> Api.put_opt_if(:include_media_info, opts)
      |> Api.put_opt_if(:include_deleted, opts)
      |> Api.put_opt_if(:include_has_explicit_shared_members, opts)
      |> Api.put_opt_if(:include_mounted_folders, opts)
      |> Api.put_opt_if(:include_non_downloadable_files, opts)
      |> Api.put_opt_if(:include_property_groups, opts)

    HTTP.rpc("files/list_folder/get_latest_cursor",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/list_folder/longpoll` (notify host; no user auth)."
  @spec list_folder_longpoll(String.t(), opts()) :: result()
  def list_folder_longpoll(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    timeout = Keyword.get(opts, :timeout, 30)
    body = %{cursor: cursor, timeout: timeout}

    HTTP.notify("files/list_folder/longpoll",
      body: body,
      decode: Api.decode_opt(opts),
      client: client,
      timeout: Keyword.get(opts, :receive_timeout, (timeout + 30) * 1000)
    )
  end

  @doc "Paginate `list_folder` until `has_more` is false. Returns atom-key maps."
  @spec list_folder_all(String.t(), opts()) :: result()
  def list_folder_all(path, opts \\ []) when is_binary(path) do
    opts =
      opts
      |> Api.normalize_opts()
      |> Keyword.put(:decode, :atoms)

    case list_folder(path, opts) do
      {:ok, first} ->
        collect_pages(first, first[:entries] || [], opts)

      error ->
        error
    end
  end

  defp collect_pages(%{has_more: false} = result, entries, _opts) do
    {:ok, %{result | entries: entries}}
  end

  defp collect_pages(%{has_more: true, cursor: cursor}, entries, opts) do
    case list_folder_continue(cursor, opts) do
      {:ok, page} ->
        collect_pages(page, entries ++ (page[:entries] || []), opts)

      error ->
        error
    end
  end

  # ---------------------------------------------------------------------------
  # Upload / download
  # ---------------------------------------------------------------------------

  @doc """
  POST `files/upload` (max ~150 MB). For larger files use upload sessions.

  ## Options
  * `:mode` — `"add"` | `"overwrite"` | `%{".tag" => "update", "update" => rev}`
  * `:autorename`, `:mute`, `:strict_conflict`, `:client_modified`, `:property_groups`
  """
  @spec upload(String.t(), binary(), opts()) :: result()
  def upload(path, data, opts \\ []) when is_binary(path) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg =
      %{path: path}
      |> Api.put_opt(:mode, opts, "add")
      |> Api.put_opt(:autorename, opts, false)
      |> Api.put_opt(:mute, opts, false)
      |> Api.put_opt(:strict_conflict, opts, false)
      |> Api.put_opt_if(:client_modified, opts)
      |> Api.put_opt_if(:property_groups, opts)

    HTTP.content_upload("files/upload", data, arg,
      decode: Api.decode_opt(opts, Metadata),
      client: client
    )
  end

  @doc "POST `files/download` — returns `%{metadata: map, body: binary, headers: list}`."
  @spec download(String.t(), opts()) :: result()
  def download(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{path: path} |> Api.put_opt_if(:rev, opts)
    HTTP.content_download("files/download", arg, client: client)
  end

  @doc "Download and write body to a local file path."
  @spec download_to_file(Path.t(), String.t(), opts()) :: result()
  def download_to_file(local_path, remote_path, opts \\ [])
      when is_binary(local_path) and is_binary(remote_path) do
    with {:ok, %{metadata: meta, body: body}} <- download(remote_path, opts),
         :ok <- File.write(local_path, body) do
      {:ok, meta}
    end
  end

  @doc "POST `files/download_zip`."
  @spec download_zip(String.t(), opts()) :: result()
  def download_zip(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    HTTP.content_download("files/download_zip", %{path: path}, client: client)
  end

  @doc "POST `files/export` (Paper / Google docs etc.)."
  @spec export(String.t(), opts()) :: result()
  def export(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{path: path} |> Api.put_opt_if(:export_format, opts)
    HTTP.content_download("files/export", arg, client: client)
  end

  @doc "POST `files/get_preview`."
  @spec get_preview(String.t(), opts()) :: result()
  def get_preview(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{path: path} |> Api.put_opt_if(:rev, opts)
    HTTP.content_download("files/get_preview", arg, client: client)
  end

  @doc "POST `files/get_thumbnail`."
  @spec get_thumbnail(String.t(), opts()) :: result()
  def get_thumbnail(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg =
      %{path: path}
      |> Api.put_opt(:format, opts, "jpeg")
      |> Api.put_opt(:size, opts, "w64h64")
      |> Api.put_opt(:mode, opts, "strict")

    HTTP.content_download("files/get_thumbnail", arg, client: client)
  end

  @doc "POST `files/get_thumbnail_v2`."
  @spec get_thumbnail_v2(map(), opts()) :: result()
  def get_thumbnail_v2(resource, opts \\ []) when is_map(resource) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg =
      %{resource: resource}
      |> Api.put_opt(:format, opts, "jpeg")
      |> Api.put_opt(:size, opts, "w64h64")
      |> Api.put_opt(:mode, opts, "strict")

    HTTP.content_download("files/get_thumbnail_v2", arg, client: client)
  end

  @doc "POST `files/get_thumbnail_batch`."
  @spec get_thumbnail_batch([map()], opts()) :: result()
  def get_thumbnail_batch(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/get_thumbnail_batch",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/get_temporary_link`."
  @spec get_temporary_link(String.t(), opts()) :: result()
  def get_temporary_link(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/get_temporary_link",
      body: %{path: path},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/get_temporary_upload_link`."
  @spec get_temporary_upload_link(map(), opts()) :: result()
  def get_temporary_upload_link(commit_info, opts \\ []) when is_map(commit_info) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{commit_info: commit_info} |> Api.put_opt(:duration, opts, 14_400.0)

    HTTP.rpc("files/get_temporary_upload_link",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Upload sessions (large files)
  # ---------------------------------------------------------------------------

  @doc "POST `files/upload_session/start`."
  @spec upload_session_start(binary(), opts()) :: result()
  def upload_session_start(data \\ "", opts \\ [])

  def upload_session_start(data, opts) when is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{} |> Api.put_opt(:close, opts, false) |> Api.put_opt_if(:session_type, opts)

    HTTP.content_upload("files/upload_session/start", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/upload_session/append_v2`."
  @spec upload_session_append_v2(map(), binary(), opts()) :: result()
  def upload_session_append_v2(cursor, data, opts \\ [])
      when is_map(cursor) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{cursor: cursor} |> Api.put_opt(:close, opts, false)

    HTTP.content_upload("files/upload_session/append_v2", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/upload_session/finish`."
  @spec upload_session_finish(map(), map(), binary(), opts()) :: result()
  def upload_session_finish(cursor, commit, data \\ "", opts \\ [])

  def upload_session_finish(cursor, commit, data, opts)
      when is_map(cursor) and is_map(commit) and is_list(data) and opts == [] do
    upload_session_finish(cursor, commit, "", data)
  end

  def upload_session_finish(cursor, commit, data, opts)
      when is_map(cursor) and is_map(commit) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{cursor: cursor, commit: commit}

    HTTP.content_upload("files/upload_session/finish", data, arg,
      decode: Api.decode_opt(opts, Metadata),
      client: client
    )
  end

  @doc "POST `files/upload_session/start_batch`."
  @spec upload_session_start_batch(pos_integer(), opts()) :: result()
  def upload_session_start_batch(num_sessions, opts \\ []) when is_integer(num_sessions) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{num_sessions: num_sessions} |> Api.put_opt_if(:session_type, opts)

    HTTP.rpc("files/upload_session/start_batch",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/upload_session/finish_batch_v2`."
  @spec upload_session_finish_batch_v2([map()], opts()) :: result()
  def upload_session_finish_batch_v2(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/upload_session/finish_batch_v2",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/upload_session/finish_batch/check`."
  @spec upload_session_finish_batch_check(String.t(), opts()) :: result()
  def upload_session_finish_batch_check(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/upload_session/finish_batch/check",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc """
  Convenience: upload arbitrary-size binary using sessions (4 MB chunks by default).

  ## Options
  * `:chunk_size` — bytes per chunk (default 4_194_304)
  * `:mode` — commit mode (default `"overwrite"`)
  * `:autorename` — passed to commit (default `false`)
  """
  @spec upload_large(String.t(), binary(), opts()) :: result()
  def upload_large(path, data, opts \\ []) when is_binary(path) and is_binary(data) do
    opts = Api.normalize_opts(opts)
    chunk_size = Keyword.get(opts, :chunk_size, 4 * 1024 * 1024)
    mode = Keyword.get(opts, :mode, "overwrite")
    size = byte_size(data)

    if size <= chunk_size do
      upload(path, data, Keyword.put(opts, :mode, mode))
    else
      <<first::binary-size(^chunk_size), rest::binary>> = data

      with {:ok, %{session_id: session_id}} <- upload_session_start(first, opts),
           {:ok, offset} <- append_chunks(session_id, chunk_size, rest, chunk_size, opts) do
        commit = %{
          path: path,
          mode: mode,
          autorename: Keyword.get(opts, :autorename, false)
        }

        cursor = %{session_id: session_id, offset: offset}
        upload_session_finish(cursor, commit, "", opts)
      end
    end
  end

  defp append_chunks(_session_id, offset, <<>>, _chunk_size, _opts), do: {:ok, offset}

  defp append_chunks(session_id, offset, data, chunk_size, opts)
       when byte_size(data) <= chunk_size do
    cursor = %{session_id: session_id, offset: offset}

    case upload_session_append_v2(cursor, data, Keyword.put(opts, :close, true)) do
      {:ok, _} -> {:ok, offset + byte_size(data)}
      {:error, _} = err -> err
    end
  end

  defp append_chunks(session_id, offset, data, chunk_size, opts) do
    <<chunk::binary-size(^chunk_size), rest::binary>> = data
    cursor = %{session_id: session_id, offset: offset}

    case upload_session_append_v2(cursor, chunk, opts) do
      {:ok, _} ->
        append_chunks(session_id, offset + chunk_size, rest, chunk_size, opts)

      {:error, _} = err ->
        err
    end
  end

  # ---------------------------------------------------------------------------
  # Copy / move / delete / restore
  # ---------------------------------------------------------------------------

  @doc "POST `files/copy_v2`."
  @spec copy_v2(String.t(), String.t(), opts()) :: result()
  def copy_v2(from_path, to_path, opts \\ [])
      when is_binary(from_path) and is_binary(to_path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{from_path: from_path, to_path: to_path}
      |> Api.put_opt(:autorename, opts, false)
      |> Api.put_opt(:allow_ownership_transfer, opts, false)
      |> Api.put_opt_if(:allow_shared_folder, opts)

    HTTP.rpc("files/copy_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "Alias for `copy_v2/3`."
  @spec copy(String.t(), String.t(), opts()) :: result()
  def copy(from_path, to_path, opts \\ []), do: copy_v2(from_path, to_path, opts)

  @doc "POST `files/copy_batch_v2`."
  @spec copy_batch_v2([map()], opts()) :: result()
  def copy_batch_v2(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{entries: entries} |> Api.put_opt(:autorename, opts, false)

    HTTP.rpc("files/copy_batch_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `files/copy_batch/check_v2`."
  @spec copy_batch_check_v2(String.t(), opts()) :: result()
  def copy_batch_check_v2(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/copy_batch/check_v2",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/copy_reference/get`."
  @spec copy_reference_get(String.t(), opts()) :: result()
  def copy_reference_get(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/copy_reference/get",
      body: %{path: path},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/copy_reference/save`."
  @spec copy_reference_save(String.t(), String.t(), opts()) :: result()
  def copy_reference_save(copy_reference, path, opts \\ [])
      when is_binary(copy_reference) and is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/copy_reference/save",
      body: %{copy_reference: copy_reference, path: path},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/move_v2`."
  @spec move_v2(String.t(), String.t(), opts()) :: result()
  def move_v2(from_path, to_path, opts \\ [])
      when is_binary(from_path) and is_binary(to_path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{from_path: from_path, to_path: to_path}
      |> Api.put_opt(:autorename, opts, false)
      |> Api.put_opt(:allow_ownership_transfer, opts, false)
      |> Api.put_opt_if(:allow_shared_folder, opts)

    HTTP.rpc("files/move_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "Alias for `move_v2/3`."
  @spec move(String.t(), String.t(), opts()) :: result()
  def move(from_path, to_path, opts \\ []), do: move_v2(from_path, to_path, opts)

  @doc "POST `files/move_batch_v2`."
  @spec move_batch_v2([map()], opts()) :: result()
  def move_batch_v2(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{entries: entries}
      |> Api.put_opt(:autorename, opts, false)
      |> Api.put_opt(:allow_ownership_transfer, opts, false)

    HTTP.rpc("files/move_batch_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `files/move_batch/check_v2`."
  @spec move_batch_check_v2(String.t(), opts()) :: result()
  def move_batch_check_v2(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/move_batch/check_v2",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/delete_v2`."
  @spec delete_v2(String.t(), opts()) :: result()
  def delete_v2(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{path: path} |> Api.put_opt_if(:parent_rev, opts)

    HTTP.rpc("files/delete_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "Alias for `delete_v2/2`."
  @spec delete(String.t(), opts()) :: result()
  def delete(path, opts \\ []), do: delete_v2(path, opts)

  @doc "POST `files/delete_batch`."
  @spec delete_batch([map()], opts()) :: result()
  def delete_batch(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/delete_batch",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/delete_batch/check`."
  @spec delete_batch_check(String.t(), opts()) :: result()
  def delete_batch_check(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/delete_batch/check",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/permanently_delete`."
  @spec permanently_delete(String.t(), opts()) :: result()
  def permanently_delete(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{path: path} |> Api.put_opt_if(:parent_rev, opts)

    HTTP.rpc("files/permanently_delete",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/restore`."
  @spec restore(String.t(), String.t(), opts()) :: result()
  def restore(path, rev, opts \\ []) when is_binary(path) and is_binary(rev) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/restore",
      body: %{path: path, rev: rev},
      decode: Api.decode_opt(opts, Metadata),
      client: client
    )
  end

  @doc "POST `files/list_revisions`."
  @spec list_revisions(String.t(), opts()) :: result()
  def list_revisions(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt(:mode, opts, "path")
      |> Api.put_opt(:limit, opts, 10)

    HTTP.rpc("files/list_revisions", body: body, decode: Api.decode_opt(opts), client: client)
  end

  # ---------------------------------------------------------------------------
  # Folders
  # ---------------------------------------------------------------------------

  @doc "POST `files/create_folder_v2`."
  @spec create_folder_v2(String.t(), opts()) :: result()
  def create_folder_v2(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    body = %{path: path} |> Api.put_opt(:autorename, opts, false)

    HTTP.rpc("files/create_folder_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "Alias for `create_folder_v2/2`."
  @spec create_folder(String.t(), opts()) :: result()
  def create_folder(path, opts \\ []), do: create_folder_v2(path, opts)

  @doc "POST `files/create_folder_batch`."
  @spec create_folder_batch([String.t()], opts()) :: result()
  def create_folder_batch(paths, opts \\ []) when is_list(paths) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{paths: paths}
      |> Api.put_opt(:autorename, opts, false)
      |> Api.put_opt(:force_async, opts, false)

    HTTP.rpc("files/create_folder_batch",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/create_folder_batch/check`."
  @spec create_folder_batch_check(String.t(), opts()) :: result()
  def create_folder_batch_check(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/create_folder_batch/check",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Search / save_url / locks / tags / paper
  # ---------------------------------------------------------------------------

  @doc "POST `files/search_v2`."
  @spec search_v2(String.t(), opts()) :: result()
  def search_v2(query, opts \\ []) when is_binary(query) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{query: query}
      |> Api.put_opt_if(:options, opts)
      |> Api.put_opt_if(:match_field_options, opts)
      |> Api.put_opt_if(:include_highlights, opts)

    HTTP.rpc("files/search_v2", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "Alias for `search_v2/2`."
  @spec search(String.t(), opts()) :: result()
  def search(query, opts \\ []), do: search_v2(query, opts)

  @doc "POST `files/search/continue_v2`."
  @spec search_continue_v2(String.t(), opts()) :: result()
  def search_continue_v2(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/search/continue_v2",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/save_url`."
  @spec save_url(String.t(), String.t(), opts()) :: result()
  def save_url(path, url, opts \\ []) when is_binary(path) and is_binary(url) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/save_url",
      body: %{path: path, url: url},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/save_url/check_job_status`."
  @spec save_url_check_job_status(String.t(), opts()) :: result()
  def save_url_check_job_status(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/save_url/check_job_status",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/get_file_lock_batch`."
  @spec get_file_lock_batch([map()], opts()) :: result()
  def get_file_lock_batch(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/get_file_lock_batch",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/lock_file_batch`."
  @spec lock_file_batch([map()], opts()) :: result()
  def lock_file_batch(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/lock_file_batch",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/unlock_file_batch`."
  @spec unlock_file_batch([map()], opts()) :: result()
  def unlock_file_batch(entries, opts \\ []) when is_list(entries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/unlock_file_batch",
      body: %{entries: entries},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/tags/add`."
  @spec tags_add(String.t(), String.t(), opts()) :: result()
  def tags_add(path, tag_text, opts \\ []) when is_binary(path) and is_binary(tag_text) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/tags/add",
      body: %{path: path, tag_text: tag_text},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/tags/get`."
  @spec tags_get([String.t()], opts()) :: result()
  def tags_get(paths, opts \\ []) when is_list(paths) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/tags/get",
      body: %{paths: paths},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/tags/remove`."
  @spec tags_remove(String.t(), String.t(), opts()) :: result()
  def tags_remove(path, tag_text, opts \\ []) when is_binary(path) and is_binary(tag_text) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("files/tags/remove",
      body: %{path: path, tag_text: tag_text},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/paper/create` (content upload)."
  @spec paper_create(String.t(), binary(), String.t() | atom(), opts()) :: result()
  def paper_create(path, data, import_format, opts \\ [])
      when is_binary(path) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)
    arg = %{path: path, import_format: import_format}

    HTTP.content_upload("files/paper/create", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `files/paper/update` (content upload)."
  @spec paper_update(String.t(), binary(), String.t() | atom(), String.t() | atom(), opts()) ::
          result()
  def paper_update(path, data, import_format, doc_update_policy, opts \\ [])
      when is_binary(path) and is_binary(data) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg =
      %{
        path: path,
        import_format: import_format,
        doc_update_policy: doc_update_policy
      }
      |> Api.put_opt_if(:paper_revision, opts)

    HTTP.content_upload("files/paper/update", data, arg,
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
