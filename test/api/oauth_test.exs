defmodule Noizu.Dropbox.OAuthTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Error
  alias Noizu.Dropbox.OAuth
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(app_key: "APP", app_secret: "SEC", access_token: "old", refresh_token: "ref")

  test "token exchange posts form body" do
    Mimic.expect(Finch, :request, fn %Finch.Request{
                                       host: "api.dropboxapi.com",
                                       path: path,
                                       headers: headers,
                                       body: body
                                     },
                                     _n,
                                     _o ->
      assert path == "/oauth2/token"
      assert header(headers, "content-type") == "application/x-www-form-urlencoded"
      form = URI.decode_query(body)
      assert form["grant_type"] == "authorization_code"
      assert form["code"] == "authcode"
      assert form["redirect_uri"] == "https://example.com/cb"
      FinchStub.json_response(200, %{
        "access_token" => "at",
        "refresh_token" => "rt",
        "expires_in" => 14400,
        "token_type" => "bearer"
      })
    end)

    assert {:ok, %{"access_token" => "at", "refresh_token" => "rt"}} =
             OAuth.token(
               code: "authcode",
               redirect_uri: "https://example.com/cb",
               client: @client
             )
  end

  test "refresh_token grant" do
    Mimic.expect(Finch, :request, fn %Finch.Request{body: body}, _n, _o ->
      form = URI.decode_query(body)
      assert form["grant_type"] == "refresh_token"
      assert form["refresh_token"] == "ref"
      FinchStub.json_response(200, %{"access_token" => "new-at", "expires_in" => 14400})
    end)

    assert {:ok, %{"access_token" => "new-at"}} =
             OAuth.refresh_token("ref", client: @client)
  end

  test "refresh_client updates access_token" do
    Mimic.expect(Finch, :request, fn _req, _n, _o ->
      FinchStub.json_response(200, %{"access_token" => "brand-new", "expires_in" => 10})
    end)

    assert {:ok, %Client{access_token: "brand-new"}, _} = OAuth.refresh_client(@client)
  end

  test "refresh_client without refresh_token errors" do
    bare = Client.new(access_token: "x")
    assert {:error, %Error{tag: :config}} = OAuth.refresh_client(bare)
  end

  test "authorize_url includes PKCE params" do
    pair = OAuth.pkce_pair()

    url =
      OAuth.authorize_url(
        client_id: "APP",
        redirect_uri: "https://example.com/cb",
        code_challenge: pair.code_challenge,
        code_challenge_method: pair.method,
        token_access_type: "offline"
      )

    assert url =~ "code_challenge="
    assert url =~ "code_challenge_method=S256"
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == name, do: v
    end)
  end
end
