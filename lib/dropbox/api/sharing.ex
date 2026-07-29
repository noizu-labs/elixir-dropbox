defmodule Noizu.Dropbox.Api.Sharing do
  @moduledoc """
  Dropbox `sharing/*` endpoints — folders, files, members, and shared links.
  """

  use Noizu.Dropbox.Api

  # ---------------------------------------------------------------------------
  # Shared folders
  # ---------------------------------------------------------------------------

  @doc "POST `sharing/share_folder`."
  @spec share_folder(String.t(), opts()) :: result()
  def share_folder(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt_if(:acl_update_policy, opts)
      |> Api.put_opt_if(:force_async, opts)
      |> Api.put_opt_if(:member_policy, opts)
      |> Api.put_opt_if(:shared_link_policy, opts)
      |> Api.put_opt_if(:viewer_info_policy, opts)
      |> Api.put_opt_if(:access_inheritance, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/share_folder", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `sharing/update_folder_policy`."
  @spec update_folder_policy(String.t(), opts()) :: result()
  def update_folder_policy(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id}
      |> Api.put_opt_if(:member_policy, opts)
      |> Api.put_opt_if(:acl_update_policy, opts)
      |> Api.put_opt_if(:viewer_info_policy, opts)
      |> Api.put_opt_if(:shared_link_policy, opts)
      |> Api.put_opt_if(:link_settings, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/update_folder_policy",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/update_folder_member`."
  @spec update_folder_member(String.t(), map(), map() | String.t(), opts()) :: result()
  def update_folder_member(shared_folder_id, member, access_level, opts \\ [])
      when is_binary(shared_folder_id) and is_map(member) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/update_folder_member",
      body: %{
        shared_folder_id: shared_folder_id,
        member: member,
        access_level: access_level
      },
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/transfer_folder`."
  @spec transfer_folder(String.t(), String.t(), opts()) :: result()
  def transfer_folder(shared_folder_id, to_dropbox_id, opts \\ [])
      when is_binary(shared_folder_id) and is_binary(to_dropbox_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/transfer_folder",
      body: %{shared_folder_id: shared_folder_id, to_dropbox_id: to_dropbox_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/unshare_folder`."
  @spec unshare_folder(String.t(), opts()) :: result()
  def unshare_folder(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id}
      |> Api.put_opt(:leave_a_copy, opts, false)

    HTTP.rpc("sharing/unshare_folder", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `sharing/unmount_folder`."
  @spec unmount_folder(String.t(), opts()) :: result()
  def unmount_folder(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/unmount_folder",
      body: %{shared_folder_id: shared_folder_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/mount_folder`."
  @spec mount_folder(String.t(), opts()) :: result()
  def mount_folder(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/mount_folder",
      body: %{shared_folder_id: shared_folder_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/relinquish_folder_membership`."
  @spec relinquish_folder_membership(String.t(), opts()) :: result()
  def relinquish_folder_membership(shared_folder_id, opts \\ [])
      when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id}
      |> Api.put_opt(:leave_a_copy, opts, false)

    HTTP.rpc("sharing/relinquish_folder_membership",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/relinquish_file_membership`."
  @spec relinquish_file_membership(String.t(), opts()) :: result()
  def relinquish_file_membership(file, opts \\ []) when is_binary(file) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/relinquish_file_membership",
      body: %{file: file},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/relinquish_access` (legacy alias path if needed by clients)."
  @spec relinquish_access(String.t(), opts()) :: result()
  def relinquish_access(shared_folder_id, opts \\ []) do
    relinquish_folder_membership(shared_folder_id, opts)
  end

  @doc "POST `sharing/add_folder_member`."
  @spec add_folder_member(String.t(), [map()], opts()) :: result()
  def add_folder_member(shared_folder_id, members, opts \\ [])
      when is_binary(shared_folder_id) and is_list(members) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id, members: members}
      |> Api.put_opt(:quiet, opts, false)
      |> Api.put_opt_if(:custom_message, opts)

    HTTP.rpc("sharing/add_folder_member",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/remove_folder_member`."
  @spec remove_folder_member(String.t(), map(), opts()) :: result()
  def remove_folder_member(shared_folder_id, member, opts \\ [])
      when is_binary(shared_folder_id) and is_map(member) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id, member: member}
      |> Api.put_opt(:leave_a_copy, opts, false)

    HTTP.rpc("sharing/remove_folder_member",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_folder_members`."
  @spec list_folder_members(String.t(), opts()) :: result()
  def list_folder_members(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id}
      |> Api.put_opt_if(:actions, opts)
      |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("sharing/list_folder_members",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_folder_members/continue`."
  @spec list_folder_members_continue(String.t(), opts()) :: result()
  def list_folder_members_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/list_folder_members/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_folders`."
  @spec list_folders(opts()) :: result()
  def list_folders(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{}
      |> Api.put_opt_if(:limit, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/list_folders", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `sharing/list_folders/continue`."
  @spec list_folders_continue(String.t(), opts()) :: result()
  def list_folders_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/list_folders/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_mountable_folders`."
  @spec list_mountable_folders(opts()) :: result()
  def list_mountable_folders(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{}
      |> Api.put_opt_if(:limit, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/list_mountable_folders",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_mountable_folders/continue`."
  @spec list_mountable_folders_continue(String.t(), opts()) :: result()
  def list_mountable_folders_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/list_mountable_folders/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/get_folder_metadata`."
  @spec get_folder_metadata(String.t(), opts()) :: result()
  def get_folder_metadata(shared_folder_id, opts \\ []) when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{shared_folder_id: shared_folder_id}
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/get_folder_metadata",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Shared files
  # ---------------------------------------------------------------------------

  @doc "POST `sharing/add_file_member`."
  @spec add_file_member(String.t(), [map()], opts()) :: result()
  def add_file_member(file, members, opts \\ []) when is_binary(file) and is_list(members) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{file: file, members: members}
      |> Api.put_opt(:quiet, opts, false)
      |> Api.put_opt_if(:custom_message, opts)
      |> Api.put_opt_if(:access_level, opts)
      |> Api.put_opt_if(:add_message_as_comment, opts)

    HTTP.rpc("sharing/add_file_member", body: body, decode: Api.decode_opt(opts), client: client)
  end

  @doc "POST `sharing/remove_file_member_2`."
  @spec remove_file_member_2(String.t(), map(), opts()) :: result()
  def remove_file_member_2(file, member, opts \\ []) when is_binary(file) and is_map(member) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/remove_file_member_2",
      body: %{file: file, member: member},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/update_file_member`."
  @spec update_file_member(String.t(), map(), map() | String.t(), opts()) :: result()
  def update_file_member(file, member, access_level, opts \\ [])
      when is_binary(file) and is_map(member) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/update_file_member",
      body: %{file: file, member: member, access_level: access_level},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc """
  POST `sharing` file policy helper.

  Accepts policy-related opts (`:member_policy`, `:acl_update_policy`,
  `:viewer_info_policy`, `:shared_link_policy`, `:actions`) and posts them
  with the file path/id. Prefer `modify_shared_link_settings/3` for link
  settings and `update_file_member/4` for per-member access levels.
  """
  @spec update_file_policy(String.t(), opts()) :: result()
  def update_file_policy(file, opts \\ []) when is_binary(file) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{file: file}
      |> Api.put_opt_if(:member_policy, opts)
      |> Api.put_opt_if(:acl_update_policy, opts)
      |> Api.put_opt_if(:viewer_info_policy, opts)
      |> Api.put_opt_if(:shared_link_policy, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/update_file_policy",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_file_members`."
  @spec list_file_members(String.t(), opts()) :: result()
  def list_file_members(file, opts \\ []) when is_binary(file) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{file: file}
      |> Api.put_opt_if(:actions, opts)
      |> Api.put_opt_if(:include_inherited, opts)
      |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("sharing/list_file_members",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_file_members/batch`."
  @spec list_file_members_batch([String.t()], opts()) :: result()
  def list_file_members_batch(files, opts \\ []) when is_list(files) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{files: files}
      |> Api.put_opt_if(:limit, opts)

    HTTP.rpc("sharing/list_file_members/batch",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_file_members/continue`."
  @spec list_file_members_continue(String.t(), opts()) :: result()
  def list_file_members_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/list_file_members/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/get_file_metadata`."
  @spec get_file_metadata(String.t(), opts()) :: result()
  def get_file_metadata(file, opts \\ []) when is_binary(file) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{file: file}
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/get_file_metadata",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/get_file_metadata/batch`."
  @spec get_file_metadata_batch([String.t()], opts()) :: result()
  def get_file_metadata_batch(files, opts \\ []) when is_list(files) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{files: files}
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/get_file_metadata/batch",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_received_files`."
  @spec list_received_files(opts()) :: result()
  def list_received_files(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{}
      |> Api.put_opt_if(:limit, opts)
      |> Api.put_opt_if(:actions, opts)

    HTTP.rpc("sharing/list_received_files",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_received_files/continue`."
  @spec list_received_files_continue(String.t(), opts()) :: result()
  def list_received_files_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/list_received_files/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/unshare_file`."
  @spec unshare_file(String.t(), opts()) :: result()
  def unshare_file(file, opts \\ []) when is_binary(file) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/unshare_file",
      body: %{file: file},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/set_access_inheritance`."
  @spec set_access_inheritance(String.t(), map() | String.t(), opts()) :: result()
  def set_access_inheritance(shared_folder_id, access_inheritance, opts \\ [])
      when is_binary(shared_folder_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/set_access_inheritance",
      body: %{
        shared_folder_id: shared_folder_id,
        access_inheritance: access_inheritance
      },
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Shared links
  # ---------------------------------------------------------------------------

  @doc "POST `sharing/create_shared_link_with_settings`."
  @spec create_shared_link_with_settings(String.t(), opts()) :: result()
  def create_shared_link_with_settings(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt_if(:settings, opts)

    HTTP.rpc("sharing/create_shared_link_with_settings",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/create_shared_link` (legacy)."
  @spec create_shared_link(String.t(), opts()) :: result()
  def create_shared_link(path, opts \\ []) when is_binary(path) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{path: path}
      |> Api.put_opt_if(:short_url, opts)
      |> Api.put_opt_if(:pending_upload, opts)

    HTTP.rpc("sharing/create_shared_link",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/list_shared_links`."
  @spec list_shared_links(opts()) :: result()
  def list_shared_links(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{}
      |> Api.put_opt_if(:path, opts)
      |> Api.put_opt_if(:cursor, opts)
      |> Api.put_opt_if(:direct_only, opts)

    HTTP.rpc("sharing/list_shared_links",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/modify_shared_link_settings`."
  @spec modify_shared_link_settings(String.t(), map(), opts()) :: result()
  def modify_shared_link_settings(url, settings, opts \\ [])
      when is_binary(url) and is_map(settings) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{url: url, settings: settings}
      |> Api.put_opt_if(:remove_expiration, opts)

    HTTP.rpc("sharing/modify_shared_link_settings",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/revoke_shared_link`."
  @spec revoke_shared_link(String.t(), opts()) :: result()
  def revoke_shared_link(url, opts \\ []) when is_binary(url) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/revoke_shared_link",
      body: %{url: url},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/get_shared_link_metadata`."
  @spec get_shared_link_metadata(String.t(), opts()) :: result()
  def get_shared_link_metadata(url, opts \\ []) when is_binary(url) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{url: url}
      |> Api.put_opt_if(:path, opts)
      |> Api.put_opt_if(:link_password, opts)

    HTTP.rpc("sharing/get_shared_link_metadata",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/get_shared_link_file` (content download)."
  @spec get_shared_link_file(String.t(), opts()) :: result()
  def get_shared_link_file(url, opts \\ []) when is_binary(url) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    arg =
      %{url: url}
      |> Api.put_opt_if(:path, opts)
      |> Api.put_opt_if(:link_password, opts)

    HTTP.content_download("sharing/get_shared_link_file", arg, client: client)
  end

  @doc "POST `sharing/get_shared_links` (legacy)."
  @spec get_shared_links(opts()) :: result()
  def get_shared_links(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body = %{} |> Api.put_opt_if(:path, opts)

    HTTP.rpc("sharing/get_shared_links",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Job status
  # ---------------------------------------------------------------------------

  @doc "POST `sharing/check_job_status`."
  @spec check_job_status(String.t(), opts()) :: result()
  def check_job_status(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/check_job_status",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/check_share_job_status`."
  @spec check_share_job_status(String.t(), opts()) :: result()
  def check_share_job_status(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/check_share_job_status",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `sharing/check_remove_member_job_status`."
  @spec check_remove_member_job_status(String.t(), opts()) :: result()
  def check_remove_member_job_status(async_job_id, opts \\ []) when is_binary(async_job_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("sharing/check_remove_member_job_status",
      body: %{async_job_id: async_job_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
