defmodule Noizu.Dropbox.Api.Contacts do
  @moduledoc """
  Dropbox `contacts/*` endpoints.
  """

  use Noizu.Dropbox.Api

  @doc "POST `contacts/delete_manual_contacts` — empty/`null` body."
  @spec delete_manual_contacts(opts()) :: result()
  def delete_manual_contacts(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("contacts/delete_manual_contacts",
      body: nil,
      decode: Api.decode_opt(opts),
      client: client
    )
  end

  @doc "POST `contacts/delete_manual_contacts_batch`."
  @spec delete_manual_contacts_batch([String.t()], opts()) :: result()
  def delete_manual_contacts_batch(email_addresses, opts \\ []) when is_list(email_addresses) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("contacts/delete_manual_contacts_batch",
      body: %{email_addresses: email_addresses},
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
