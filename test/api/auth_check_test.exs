defmodule Noizu.Dropbox.Api.AuthCheckTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.Auth
  alias Noizu.Dropbox.Api.Check
  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token", app_key: "k", app_secret: "s")

  test "auth token_revoke posts null body" do
    Mimic.expect(Finch, :request, fn %Finch.Request{path: path, body: body}, _n, _o ->
      assert path == "/2/auth/token/revoke"
      assert body == "null"
      FinchStub.json_response(200, nil)
    end)

    assert {:ok, _} = Auth.token_revoke(client: @client)
  end

  test "check user" do
    Mimic.expect(Finch, :request, fn %Finch.Request{path: path, body: body}, _n, _o ->
      assert path == "/2/check/user"
      assert Jason.decode!(body)["query"] == "ping"
      FinchStub.json_response(200, %{"result" => "ping"})
    end)

    assert {:ok, %{result: "ping"}} = Check.user("ping", client: @client)
  end

  test "check app uses app auth" do
    Mimic.expect(Finch, :request, fn %Finch.Request{path: path, headers: headers}, _n, _o ->
      assert path == "/2/check/app"
      auth = Enum.find_value(headers, fn {k, v} -> if String.downcase(k) == "authorization", do: v end)
      assert auth =~ "Basic "
      FinchStub.json_response(200, %{"result" => "pong"})
    end)

    assert {:ok, %{result: "pong"}} = Check.app("pong", client: @client)
  end
end
