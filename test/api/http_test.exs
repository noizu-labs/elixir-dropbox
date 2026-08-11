defmodule Noizu.Dropbox.HTTPTest do
  use ExUnit.Case, async: false
  use Mimic

  setup do
    Application.delete_env(:noizu_dropbox, :request_fun)

    on_exit(fn ->
      Application.delete_env(:noizu_dropbox, :request_fun)
    end)
  end

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Error
  alias Noizu.Dropbox.HTTP
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "tok")

  test "rpc success decodes atoms by default" do
    Mimic.expect(Finch, :request, fn %Finch.Request{host: "api.dropboxapi.com"}, _n, _o ->
      FinchStub.json_response(200, %{"ok" => true, "n" => 1})
    end)

    assert {:ok, %{ok: true, n: 1}} = HTTP.rpc("check/user", body: %{query: "ping"}, client: @client)
  end

  test "rpc can decode string keys" do
    Mimic.expect(Finch, :request, fn _req, _n, _o ->
      FinchStub.json_response(200, %{"ok" => true})
    end)

    assert {:ok, %{"ok" => true}} =
             HTTP.rpc("check/user", body: %{}, client: @client, decode: :strings)
  end

  test "rpc maps HTTP errors to Error" do
    Mimic.expect(Finch, :request, fn _req, _n, _o ->
      FinchStub.json_response(409, %{
        "error_summary" => "path/not_found/...",
        "error" => %{".tag" => "path"}
      })
    end)

    assert {:error, %Error{status: 409, tag: "path", summary: summary}} =
             HTTP.rpc("files/get_metadata", body: %{path: "/nope"}, client: @client)

    assert summary =~ "path/not_found"
  end

  test "rpc without token fails config" do
    bare = Client.new(access_token: nil)

    assert {:error, %Error{tag: :config}} =
             HTTP.rpc("files/list_folder", body: %{path: ""}, client: bare)
  end

  test "content_upload sets Dropbox-API-Arg and octet-stream" do
    Mimic.expect(Finch, :request, fn %Finch.Request{host: host, headers: headers, body: body},
                                     _n,
                                     _o ->
      assert host == "content.dropboxapi.com"
      assert body == "payload"
      assert header(headers, "content-type") == "application/octet-stream"
      arg = header(headers, "dropbox-api-arg") |> Jason.decode!()
      assert arg["path"] == "/x.txt"
      FinchStub.json_response(200, %{"name" => "x.txt"})
    end)

    assert {:ok, %{name: "x.txt"}} =
             HTTP.content_upload(
               "files/upload",
               "payload",
               %{path: "/x.txt"},
               client: @client
             )
  end

  test "content_download returns metadata from Dropbox-API-Result" do
    Mimic.expect(Finch, :request, fn %Finch.Request{host: "content.dropboxapi.com"}, _n, _o ->
      FinchStub.download_response(200, %{"name" => "a.txt", "size" => 2}, "ab")
    end)

    assert {:ok, %{metadata: meta, body: "ab"}} =
             HTTP.content_download("files/download", %{path: "/a.txt"}, client: @client)

    assert meta[:name] == "a.txt" or meta["name"] == "a.txt"
  end

  test "transport failures become Error.transport" do
    Mimic.expect(Finch, :request, fn _req, _n, _o ->
      {:error, :timeout}
    end)

    assert {:error, %Error{tag: :transport, reason: :timeout}} =
             HTTP.rpc("check/user", body: %{}, client: @client)
  end

  test "app auth uses basic credentials" do
    client = Client.new(app_key: "key", app_secret: "secret", access_token: nil)

    Mimic.expect(Finch, :request, fn %Finch.Request{headers: headers}, _n, _o ->
      auth = header(headers, "authorization")
      assert auth == "Basic " <> Base.encode64("key:secret")
      FinchStub.json_response(200, %{"result" => "pong"})
    end)

    assert {:ok, %{result: "pong"}} =
             HTTP.rpc("check/app", body: %{query: "pong"}, client: client, auth: :app)
  end

  test "select_user header is sent" do
    client = Client.new(access_token: "tok") |> Client.as_user("dbmid:1")

    Mimic.expect(Finch, :request, fn %Finch.Request{headers: headers}, _n, _o ->
      assert header(headers, "dropbox-api-select-user") == "dbmid:1"
      FinchStub.json_response(200, %{})
    end)

    assert {:ok, _} = HTTP.rpc("files/list_folder", body: %{path: ""}, client: client)
  end

  test "null body is encoded as JSON null" do
    Mimic.expect(Finch, :request, fn %Finch.Request{body: body}, _n, _o ->
      assert body == "null"
      FinchStub.json_response(200, %{"account_id" => "dbid:1"})
    end)

    assert {:ok, %{account_id: "dbid:1"}} =
             HTTP.rpc("users/get_current_account", body: nil, client: @client)
  end

  test "rpc auto-refreshes on 401 and retries once" do
    client =
      Client.new(
        access_token: "stale",
        refresh_token: "ref-token",
        app_key: "APP",
        app_secret: "SEC"
      )

    Process.put(:api_call_count, 0)

    Application.put_env(:noizu_dropbox, :request_fun, fn %{url: url, headers: headers} ->
      cond do
        String.contains?(url, "/oauth2/token") ->
          FinchStub.json_response(200, %{"access_token" => "fresh-token", "expires_in" => 14400})

        true ->
          count = Process.get(:api_call_count, 0) + 1
          Process.put(:api_call_count, count)

          if count == 2 do
            assert header(headers, "authorization") == "Bearer fresh-token"
          end

          if count == 1 do
            FinchStub.json_response(401, %{"error_summary" => "expired_access_token/."})
          else
            FinchStub.json_response(200, %{"ok" => true})
          end
      end
    end)

    assert {:ok, %{ok: true}} = HTTP.rpc("check/user", body: %{query: "ping"}, client: client)
    assert Process.get(:api_call_count, 0) == 2
  end

  test "rpc 401 without refresh_token returns error and does not retry" do
    Process.put(:api_call_count, 0)

    Application.put_env(:noizu_dropbox, :request_fun, fn %{url: url} ->
      unless String.contains?(url, "/oauth2/token") do
        count = Process.get(:api_call_count, 0) + 1
        Process.put(:api_call_count, count)
      end

      FinchStub.json_response(401, %{"error_summary" => "expired_access_token/."})
    end)

    assert {:error, %Error{status: 401}} =
             HTTP.rpc("check/user", body: %{query: "ping"}, client: @client)

    assert Process.get(:api_call_count, 0) == 1
  end

  test "content_download auto-refreshes on 401 and retries once" do
    client =
      Client.new(
        access_token: "stale",
        refresh_token: "ref-token",
        app_key: "APP",
        app_secret: "SEC"
      )

    Process.put(:download_call_count, 0)

    Application.put_env(:noizu_dropbox, :request_fun, fn %{url: url} ->
      cond do
        String.contains?(url, "/oauth2/token") ->
          FinchStub.json_response(200, %{"access_token" => "fresh-dl", "expires_in" => 14400})

        true ->
          count = Process.get(:download_call_count, 0) + 1
          Process.put(:download_call_count, count)

          if count == 1 do
            FinchStub.json_response(401, %{"error_summary" => "expired/."})
          else
            FinchStub.download_response(200, %{"name" => "a.txt", "size" => 2}, "ab")
          end
      end
    end)

    assert {:ok, %{body: "ab"}} =
             HTTP.content_download("files/download", %{path: "/a.txt"}, client: client)

    assert Process.get(:download_call_count, 0) == 2
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == name, do: v
    end)
  end
end
