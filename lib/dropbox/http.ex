defmodule Noizu.Dropbox.HTTP do
  @moduledoc """
  Low-level HTTP helpers for Dropbox API v2.

  Dropbox uses three styles of endpoints:

  * **RPC** — JSON body in, JSON body out (`api.dropboxapi.com`)
  * **Content upload** — binary body in, JSON metadata out; args in `Dropbox-API-Arg`
  * **Content download** — binary body out; args in `Dropbox-API-Arg`;
    metadata in `Dropbox-API-Result` response header
  """

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Error

  @type options :: keyword() | map() | nil
  @type result :: {:ok, term()} | {:error, Error.t()}
  @type download_result ::
          {:ok, %{metadata: map(), body: binary(), headers: list()}} | {:error, Error.t()}

  # ---------------------------------------------------------------------------
  # Public: RPC
  # ---------------------------------------------------------------------------

  @doc """
  Call an RPC endpoint (`POST` JSON → JSON).

  ## Options
  * `:client` — `%Noizu.Dropbox.Client{}` (default: `Client.default()`)
  * `:body` — request map (default: `%{}` or `nil` for no body)
  * `:decode` — `:atoms` (default), `:strings`, `:raw`, or a module with `from_json/1`
  * `:auth` — `:user` (default bearer token), `:app` (basic app key/secret), `:none`
  * `:headers` — extra headers
  * `:timeout` — receive timeout override
  """
  @spec rpc(String.t(), options()) :: result()
  def rpc(path, opts \\ []) do
    opts = normalize_opts(opts)
    client = client(opts)
    url = url(client.api_base, path)
    body = Keyword.get(opts, :body, %{})

    with {:ok, client} <- maybe_require_token(client, opts),
         {:ok, encoded} <- encode_body(body),
         {:ok, headers} <- build_headers(client, opts, :rpc) do
      request(:post, url, headers, encoded, client, opts)
      |> decode_json_response(opts)
    end
  end

  @doc "RPC with an empty JSON object body (`null` is also accepted by some endpoints)."
  @spec rpc_empty(String.t(), options()) :: result()
  def rpc_empty(path, opts \\ []) do
    opts
    |> normalize_opts()
    |> Keyword.put(:body, Keyword.get(normalize_opts(opts), :body, nil))
    |> then(&rpc(path, &1))
  end

  # ---------------------------------------------------------------------------
  # Public: Content upload
  # ---------------------------------------------------------------------------

  @doc """
  Content-upload endpoint: binary body, args via `Dropbox-API-Arg` header.
  """
  @spec content_upload(String.t(), binary(), map(), options()) :: result()
  def content_upload(path, data, arg, opts \\ []) when is_binary(data) do
    opts = normalize_opts(opts)
    client = client(opts)
    url = url(client.content_base, path)

    with {:ok, client} <- Client.require_token(client),
         {:ok, arg_json} <- Jason.encode(arg || %{}),
         {:ok, headers} <-
           build_headers(client, opts, :content_upload, [{"Dropbox-API-Arg", arg_json}]) do
      request(:post, url, headers, data, client, opts)
      |> decode_json_response(opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Public: Content download
  # ---------------------------------------------------------------------------

  @doc """
  Content-download endpoint: returns `%{metadata: map, body: binary, headers: list}`.
  """
  @spec content_download(String.t(), map(), options()) :: download_result()
  def content_download(path, arg, opts \\ []) do
    opts = normalize_opts(opts)
    client = client(opts)
    url = url(client.content_base, path)
    method = Keyword.get(opts, :method, :post)

    with {:ok, client} <- Client.require_token(client),
         {:ok, arg_json} <- Jason.encode(arg || %{}),
         {:ok, headers} <-
           build_headers(client, opts, :content_download, [{"Dropbox-API-Arg", arg_json}]) do
      case do_request(method, url, headers, nil, client, opts) do
        {:ok, %Finch.Response{status: status, body: body, headers: resp_headers}}
        when status in 200..299 ->
          metadata = decode_result_header(resp_headers)
          {:ok, %{metadata: metadata, body: body, headers: resp_headers}}

        {:ok, %Finch.Response{status: status, body: body}} ->
          {:error, Error.from_response(status, decode_error_body(body))}

        {:error, reason} ->
          {:error, Error.transport(reason)}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Public: Notify (longpoll)
  # ---------------------------------------------------------------------------

  @doc "Call a notify-domain endpoint (e.g. `files/list_folder/longpoll`)."
  @spec notify(String.t(), options()) :: result()
  def notify(path, opts \\ []) do
    opts = normalize_opts(opts)
    client = client(opts)
    url = url(client.notify_base, path)
    body = Keyword.get(opts, :body, %{})

    with {:ok, encoded} <- encode_body(body),
         {:ok, headers} <- build_headers(client, Keyword.put(opts, :auth, :none), :rpc) do
      request(:post, url, headers, encoded, client, opts)
      |> decode_json_response(opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Public: OAuth form POST
  # ---------------------------------------------------------------------------

  @doc "POST `application/x-www-form-urlencoded` (token endpoints)."
  @spec form_post(String.t(), keyword() | map(), options()) :: result()
  def form_post(url, form, opts \\ []) do
    opts = normalize_opts(opts)
    client = client(opts)
    body = URI.encode_query(Enum.into(form, %{}))

    headers =
      [
        {"Content-Type", "application/x-www-form-urlencoded"},
        {"Accept", "application/json"}
      ]
      |> maybe_basic_auth(client, opts)
      |> Kernel.++(Keyword.get(opts, :headers, []))

    request(:post, url, headers, body, client, opts)
    |> decode_json_response(Keyword.put(opts, :decode, Keyword.get(opts, :decode, :strings)))
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp request(method, url, headers, body, client, opts) do
    case do_request(method, url, headers, body, client, opts) do
      {:ok, %Finch.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, status, resp_body}

      {:ok, %Finch.Response{status: status, body: resp_body}} ->
        {:error, Error.from_response(status, decode_error_body(resp_body))}

      {:error, reason} ->
        {:error, Error.transport(reason)}
    end
  end

  defp do_request(method, url, headers, body, client, opts) do
    timeout = Keyword.get(opts, :timeout, client.receive_timeout)
    pool_timeout = Keyword.get(opts, :pool_timeout, client.pool_timeout)

    case Application.get_env(:noizu_dropbox, :request_fun) do
      fun when is_function(fun, 1) ->
        # Test / custom transport hook (visible across processes).
        # Receives a map and must return `{:ok, %Finch.Response{}} | {:error, term}`.
        fun.(%{
          method: method,
          url: url,
          headers: headers,
          body: body,
          client: client,
          opts: opts
        })

      fun when is_function(fun, 4) ->
        fun.(method, url, headers, body)

      _ ->
        Finch.build(method, url, headers, body)
        |> Finch.request(client.finch,
          receive_timeout: timeout,
          pool_timeout: pool_timeout,
          request_timeout: timeout
        )
    end
  end

  defp decode_json_response({:ok, _status, body}, opts) do
    case Keyword.get(opts, :decode, :atoms) do
      :raw ->
        {:ok, body}

      :strings ->
        decode_json(body, keys: :strings)

      :atoms ->
        decode_json(body, keys: :atoms)

      module when is_atom(module) ->
        with {:ok, json} <- decode_json(body, keys: :atoms) do
          {:ok, apply(module, :from_json, [json])}
        end
    end
  end

  defp decode_json_response({:error, _} = err, _opts), do: err

  defp decode_json("", _opts), do: {:ok, nil}
  defp decode_json(nil, _opts), do: {:ok, nil}

  defp decode_json(body, opts) when is_binary(body) do
    case Jason.decode(body, opts) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, Error.codec(reason)}
    end
  end

  defp decode_error_body(body) when is_binary(body) do
    case Jason.decode(body, keys: :atoms) do
      {:ok, json} -> json
      _ -> body
    end
  end

  defp decode_error_body(body), do: body

  defp decode_result_header(headers) do
    headers
    |> Enum.find_value(fn
      {"dropbox-api-result", value} -> value
      {"Dropbox-API-Result", value} -> value
      _ -> nil
    end)
    |> case do
      nil ->
        %{}

      value ->
        value
        |> URI.decode()
        |> then(fn v ->
          case Jason.decode(v, keys: :atoms) do
            {:ok, json} -> json
            _ -> %{}
          end
        end)
    end
  end

  # Dropbox RPC endpoints with no args expect the JSON literal `null`.
  defp encode_body(nil), do: {:ok, "null"}
  defp encode_body(body) when is_binary(body), do: {:ok, body}

  defp encode_body(body) when is_map(body) or is_list(body) do
    case Jason.encode(body) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, Error.codec(reason)}
    end
  end

  defp build_headers(client, opts, style, extra \\ []) do
    auth = Keyword.get(opts, :auth, :user)

    base =
      case style do
        :rpc -> [{"Content-Type", "application/json"}, {"Accept", "application/json"}]
        :content_upload -> [{"Content-Type", "application/octet-stream"}]
        :content_download -> []
      end

    headers =
      base
      |> Kernel.++(auth_headers(client, auth))
      |> Kernel.++(team_headers(client))
      |> Kernel.++(path_root_header(client))
      |> Kernel.++(extra)
      |> Kernel.++(Keyword.get(opts, :headers, []))

    {:ok, headers}
  end

  defp auth_headers(%Client{access_token: token}, :user)
       when is_binary(token) and token != "" do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp auth_headers(%Client{app_key: key, app_secret: secret}, :app)
       when is_binary(key) and is_binary(secret) do
    creds = Base.encode64("#{key}:#{secret}")
    [{"Authorization", "Basic #{creds}"}]
  end

  defp auth_headers(_client, :none), do: []
  defp auth_headers(_client, :user), do: []
  defp auth_headers(_client, :app), do: []

  defp maybe_basic_auth(headers, %Client{app_key: key, app_secret: secret}, opts)
       when is_binary(key) and is_binary(secret) do
    if Keyword.get(opts, :basic_auth, true) do
      creds = Base.encode64("#{key}:#{secret}")
      [{"Authorization", "Basic #{creds}"} | headers]
    else
      headers
    end
  end

  defp maybe_basic_auth(headers, _client, _opts), do: headers

  defp team_headers(%Client{select_user: user}) when is_binary(user) and user != "" do
    [{"Dropbox-API-Select-User", user}]
  end

  defp team_headers(%Client{select_admin: admin}) when is_binary(admin) and admin != "" do
    [{"Dropbox-API-Select-Admin", admin}]
  end

  defp team_headers(_), do: []

  defp path_root_header(%Client{path_root: nil}), do: []

  defp path_root_header(%Client{path_root: root}) when is_binary(root) do
    [{"Dropbox-API-Path-Root", root}]
  end

  defp path_root_header(%Client{path_root: root}) when is_map(root) do
    case Jason.encode(root) do
      {:ok, json} -> [{"Dropbox-API-Path-Root", json}]
      _ -> []
    end
  end

  defp maybe_require_token(client, opts) do
    case Keyword.get(opts, :auth, :user) do
      :user -> Client.require_token(client)
      _ -> {:ok, client}
    end
  end

  defp client(opts), do: Keyword.get(opts, :client) || Client.default()

  defp normalize_opts(nil), do: []
  defp normalize_opts(opts) when is_list(opts), do: opts
  defp normalize_opts(opts) when is_map(opts), do: Map.to_list(opts)

  defp url(base, path) do
    base = Client.normalize_base(base)
    path = String.trim_leading(path, "/")
    base <> path
  end
end
