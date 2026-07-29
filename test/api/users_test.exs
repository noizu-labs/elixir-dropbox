defmodule Noizu.Dropbox.Api.UsersTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.Users
  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Struct.Account
  alias Noizu.Dropbox.Struct.SpaceUsage
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token")

  setup do
    Mimic.stub(Finch, :request, fn request, _name, _opts ->
      case request.path do
        "/2/users/get_current_account" ->
          assert request.body == "null"

          FinchStub.json_response(200, %{
            "account_id" => "dbid:abc",
            "email" => "user@example.com",
            "name" => %{"display_name" => "User"},
            "account_type" => %{".tag" => "pro"}
          })

        "/2/users/get_space_usage" ->
          FinchStub.json_response(200, %{
            "used" => 100,
            "allocation" => %{".tag" => "individual", "allocated" => 1000}
          })

        other ->
          FinchStub.json_response(404, %{error_summary: other})
      end
    end)

    :ok
  end

  test "get_current_account" do
    assert {:ok, %Account{account_id: "dbid:abc", email: "user@example.com", account_type: "pro"}} =
             Users.get_current_account(client: @client)
  end

  test "get_space_usage" do
    assert {:ok, %SpaceUsage{used: 100}} = Users.get_space_usage(client: @client)
  end
end
