defmodule Noizu.Dropbox.Struct.Metadata do
  @moduledoc """
  File / folder / deleted metadata returned by many `files/*` endpoints.
  """

  @type t :: %__MODULE__{
          tag: String.t() | nil,
          name: String.t() | nil,
          path_lower: String.t() | nil,
          path_display: String.t() | nil,
          id: String.t() | nil,
          client_modified: String.t() | nil,
          server_modified: String.t() | nil,
          rev: String.t() | nil,
          size: non_neg_integer() | nil,
          is_downloadable: boolean() | nil,
          content_hash: String.t() | nil,
          symlink_info: map() | nil,
          sharing_info: map() | nil,
          property_groups: list() | nil,
          has_explicit_shared_members: boolean() | nil,
          export_info: map() | nil,
          media_info: map() | nil,
          raw: map()
        }

  defstruct [
    :tag,
    :name,
    :path_lower,
    :path_display,
    :id,
    :client_modified,
    :server_modified,
    :rev,
    :size,
    :is_downloadable,
    :content_hash,
    :symlink_info,
    :sharing_info,
    :property_groups,
    :has_explicit_shared_members,
    :export_info,
    :media_info,
    :raw
  ]

  def from_json(nil), do: nil
  def from_json(list) when is_list(list), do: Enum.map(list, &from_json/1)

  def from_json(%{} = json) do
    tag = json[:".tag"] || json[".tag"]

    %__MODULE__{
      tag: tag,
      name: json[:name] || json["name"],
      path_lower: json[:path_lower] || json["path_lower"],
      path_display: json[:path_display] || json["path_display"],
      id: json[:id] || json["id"],
      client_modified: json[:client_modified] || json["client_modified"],
      server_modified: json[:server_modified] || json["server_modified"],
      rev: json[:rev] || json["rev"],
      size: json[:size] || json["size"],
      is_downloadable: json[:is_downloadable] || json["is_downloadable"],
      content_hash: json[:content_hash] || json["content_hash"],
      symlink_info: json[:symlink_info] || json["symlink_info"],
      sharing_info: json[:sharing_info] || json["sharing_info"],
      property_groups: json[:property_groups] || json["property_groups"],
      has_explicit_shared_members:
        json[:has_explicit_shared_members] || json["has_explicit_shared_members"],
      export_info: json[:export_info] || json["export_info"],
      media_info: json[:media_info] || json["media_info"],
      raw: json
    }
  end
end
