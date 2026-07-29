defmodule Noizu.DropboxTest do
  use ExUnit.Case, async: true

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Error
  alias Noizu.Dropbox.OAuth
  alias Noizu.Dropbox.Struct.Account
  alias Noizu.Dropbox.Struct.ListFolderResult
  alias Noizu.Dropbox.Struct.Metadata

  test "client/1 builds from options" do
    client = Noizu.Dropbox.client(access_token: "tok", app_key: "key")
    assert %Client{access_token: "tok", app_key: "key"} = client
  end

  test "as_user / as_admin set select headers fields" do
    client =
      Client.new(access_token: "t")
      |> Client.as_user("dbmid:user")

    assert client.select_user == "dbmid:user"
    assert client.select_admin == nil

    admin = Client.as_admin(client, "dbmid:admin")
    assert admin.select_admin == "dbmid:admin"
    assert admin.select_user == nil
  end

  test "require_token errors without token" do
    assert {:error, %Error{tag: :config}} = Client.require_token(Client.new(access_token: nil))
  end

  test "Metadata.from_json maps .tag and fields" do
    meta =
      Metadata.from_json(%{
        ".tag": "file",
        name: "a.txt",
        path_display: "/a.txt",
        id: "id:1",
        size: 3
      })

    assert meta.tag == "file"
    assert meta.name == "a.txt"
    assert meta.size == 3
  end

  test "ListFolderResult.from_json maps entries" do
    result =
      ListFolderResult.from_json(%{
        entries: [%{".tag": "folder", name: "docs", path_display: "/docs", id: "id:f"}],
        cursor: "c1",
        has_more: false
      })

    assert %ListFolderResult{cursor: "c1", has_more: false} = result
    assert [%Metadata{tag: "folder", name: "docs"}] = result.entries
  end

  test "Account.from_json" do
    account =
      Account.from_json(%{
        account_id: "dbid:1",
        email: "a@b.com",
        name: %{display_name: "A"},
        account_type: %{".tag": "basic"}
      })

    assert account.account_id == "dbid:1"
    assert account.account_type == "basic"
  end

  test "Error.from_response extracts summary and tag" do
    err =
      Error.from_response(409, %{
        error_summary: "path/not_found/...",
        error: %{".tag": "path", path: %{".tag": "not_found"}}
      })

    assert err.status == 409
    assert err.summary =~ "path/not_found"
    assert err.tag == "path"
  end

  test "OAuth.pkce_pair returns S256 challenge" do
    pair = OAuth.pkce_pair()
    assert is_binary(pair.code_verifier)
    assert is_binary(pair.code_challenge)
    assert pair.method == "S256"
    assert byte_size(pair.code_verifier) > 20
  end

  test "OAuth.authorize_url builds query" do
    url =
      OAuth.authorize_url(
        client_id: "APPKEY",
        redirect_uri: "https://example.com/cb",
        token_access_type: "offline",
        scope: "files.content.read"
      )

    assert url =~ "https://www.dropbox.com/oauth2/authorize?"
    assert url =~ "client_id=APPKEY"
    assert url =~ "token_access_type=offline"
    assert url =~ "redirect_uri="
  end

  test "OAuth.authorize_url requires client_id" do
    assert {:error, %Error{tag: :config}} =
             OAuth.authorize_url(client: Client.new(app_key: nil))
  end
end
