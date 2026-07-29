defmodule Noizu.Dropbox.Api.FileProperties do
  @moduledoc """
  Dropbox `file_properties/*` endpoints — property groups and templates.
  """

  use Noizu.Dropbox.Api

  # ---------------------------------------------------------------------------
  # Properties
  # ---------------------------------------------------------------------------

  @doc "POST `file_properties/properties/add`."
  @spec properties_add(String.t(), [map()], opts()) :: result()
  def properties_add(path, property_groups, opts \\ [])
      when is_binary(path) and is_list(property_groups) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/properties/add",
      body: %{path: path, property_groups: property_groups},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/properties/overwrite`."
  @spec properties_overwrite(String.t(), [map()], opts()) :: result()
  def properties_overwrite(path, property_groups, opts \\ [])
      when is_binary(path) and is_list(property_groups) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/properties/overwrite",
      body: %{path: path, property_groups: property_groups},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/properties/remove`."
  @spec properties_remove(String.t(), [String.t()], opts()) :: result()
  def properties_remove(path, property_template_ids, opts \\ [])
      when is_binary(path) and is_list(property_template_ids) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/properties/remove",
      body: %{path: path, property_template_ids: property_template_ids},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/properties/update`."
  @spec properties_update(String.t(), [map()], opts()) :: result()
  def properties_update(path, update_property_groups, opts \\ [])
      when is_binary(path) and is_list(update_property_groups) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/properties/update",
      body: %{path: path, update_property_groups: update_property_groups},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/properties/search`."
  @spec properties_search([map()], opts()) :: result()
  def properties_search(queries, opts \\ []) when is_list(queries) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{queries: queries}
      |> Api.put_opt_if(:template_filter, opts)

    HTTP.rpc("file_properties/properties/search",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/properties/search/continue`."
  @spec properties_search_continue(String.t(), opts()) :: result()
  def properties_search_continue(cursor, opts \\ []) when is_binary(cursor) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/properties/search/continue",
      body: %{cursor: cursor},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  # ---------------------------------------------------------------------------
  # Templates (user)
  # ---------------------------------------------------------------------------

  @doc "POST `file_properties/templates/add_for_user`."
  @spec templates_add_for_user(String.t(), String.t(), [map()], opts()) :: result()
  def templates_add_for_user(name, description, fields, opts \\ [])
      when is_binary(name) and is_binary(description) and is_list(fields) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/templates/add_for_user",
      body: %{name: name, description: description, fields: fields},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/templates/get_for_user`."
  @spec templates_get_for_user(String.t(), opts()) :: result()
  def templates_get_for_user(template_id, opts \\ []) when is_binary(template_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/templates/get_for_user",
      body: %{template_id: template_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/templates/list_for_user` — empty/`null` body."
  @spec templates_list_for_user(opts()) :: result()
  def templates_list_for_user(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/templates/list_for_user",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/templates/remove_for_user`."
  @spec templates_remove_for_user(String.t(), opts()) :: result()
  def templates_remove_for_user(template_id, opts \\ []) when is_binary(template_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("file_properties/templates/remove_for_user",
      body: %{template_id: template_id},
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `file_properties/templates/update_for_user`."
  @spec templates_update_for_user(String.t(), opts()) :: result()
  def templates_update_for_user(template_id, opts \\ []) when is_binary(template_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    body =
      %{template_id: template_id}
      |> Api.put_opt_if(:name, opts)
      |> Api.put_opt_if(:description, opts)
      |> Api.put_opt_if(:add_fields, opts)

    HTTP.rpc("file_properties/templates/update_for_user",
      body: body,
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
