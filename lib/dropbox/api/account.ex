defmodule Noizu.Dropbox.Api.Account do
  @moduledoc """
  Dropbox `account/*` endpoints.
  """

  use Noizu.Dropbox.Api

  @doc """
  POST `account/set_profile_photo`.

  `photo_arg` is typically:

      %{".tag" => "base64_data", "base64_data" => "..."}
  """
  @spec set_profile_photo(map(), opts()) :: result()
  def set_profile_photo(photo_arg, opts \\ []) when is_map(photo_arg) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("account/set_profile_photo",
      body: %{photo: photo_arg},
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
