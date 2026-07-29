defmodule Noizu.Dropbox.Struct.ListFolderResult do
  @moduledoc "Result of `files/list_folder` and `files/list_folder/continue`."

  alias Noizu.Dropbox.Struct.Metadata

  @type t :: %__MODULE__{
          entries: [Metadata.t()],
          cursor: String.t() | nil,
          has_more: boolean()
        }

  defstruct entries: [], cursor: nil, has_more: false

  def from_json(nil), do: nil

  def from_json(%{} = json) do
    entries = json[:entries] || json["entries"] || []

    %__MODULE__{
      entries: Metadata.from_json(entries),
      cursor: json[:cursor] || json["cursor"],
      has_more: json[:has_more] || json["has_more"] || false
    }
  end
end
