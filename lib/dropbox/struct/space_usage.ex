defmodule Noizu.Dropbox.Struct.SpaceUsage do
  @moduledoc "Result of `users/get_space_usage`."

  @type t :: %__MODULE__{
          used: non_neg_integer() | nil,
          allocation: map() | nil,
          raw: map()
        }

  defstruct [:used, :allocation, :raw]

  def from_json(nil), do: nil

  def from_json(%{} = json) do
    %__MODULE__{
      used: json[:used] || json["used"],
      allocation: json[:allocation] || json["allocation"],
      raw: json
    }
  end
end
