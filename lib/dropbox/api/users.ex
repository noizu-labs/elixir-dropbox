defmodule Noizu.Dropbox.Api.Users do
  @moduledoc """
  Dropbox `users/*` endpoints — account info and space usage.
  """

  use Noizu.Dropbox.Api

  alias Noizu.Dropbox.Struct.Account
  alias Noizu.Dropbox.Struct.SpaceUsage

  @doc "POST `users/get_current_account` — empty/`null` body."
  @spec get_current_account(opts()) :: result()
  def get_current_account(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("users/get_current_account",
      body: nil,
      decode: Api.decode_opt(opts, Account),
      client: client
    )
  end

  @doc "POST `users/get_account`."
  @spec get_account(String.t(), opts()) :: result()
  def get_account(account_id, opts \\ []) when is_binary(account_id) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("users/get_account",
      body: %{account_id: account_id},
      decode: Api.decode_opt(opts, Account),
      client: client
    )
  end

  @doc "POST `users/get_account_batch`."
  @spec get_account_batch([String.t()], opts()) :: result()
  def get_account_batch(account_ids, opts \\ []) when is_list(account_ids) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("users/get_account_batch",
      body: %{account_ids: account_ids},
      decode: Api.decode_opt(opts, Account),
      client: client
    )
  end

  @doc "POST `users/get_space_usage` — empty/`null` body."
  @spec get_space_usage(opts()) :: result()
  def get_space_usage(opts \\ []) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("users/get_space_usage",
      body: nil,
      decode: Api.decode_opt(opts, SpaceUsage),
      client: client
    )
  end

  @doc "POST `users/features/get_values`."
  @spec features_get_values([map() | String.t() | atom()], opts()) :: result()
  def features_get_values(features, opts \\ []) when is_list(features) do
    client = Api.client(opts)
    opts = Api.normalize_opts(opts)

    HTTP.rpc("users/features/get_values",
      body: %{features: features},
      decode: Api.decode_opt(opts),
      client: client
    )
  end
end
