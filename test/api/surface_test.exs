defmodule Noizu.Dropbox.Api.SurfaceTest do
  @moduledoc """
  Smoke-calls thin API wrappers so every public module exercises at least one path.
  """
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.{
    Account,
    Contacts,
    FileProperties,
    FileRequests,
    OpenID,
    Paper
  }

  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token")

  setup do
    Mimic.stub(Finch, :request, fn request, _n, _o ->
      case request.path do
        "/2/account/set_profile_photo" ->
          FinchStub.json_response(200, %{"profile_photo_url" => "https://example.com/p.jpg"})

        "/2/contacts/delete_manual_contacts" ->
          FinchStub.json_response(200, nil)

        "/2/contacts/delete_manual_contacts_batch" ->
          FinchStub.json_response(200, nil)

        "/2/file_requests/create" ->
          FinchStub.json_response(200, %{"id" => "fr1", "url" => "https://www.dropbox.com/request/x"})

        "/2/file_requests/list_v2" ->
          FinchStub.json_response(200, %{"file_requests" => [], "cursor" => "c", "has_more" => false})

        "/2/file_requests/count" ->
          FinchStub.json_response(200, %{"file_request_count" => 0})

        "/2/file_properties/templates/list_for_user" ->
          FinchStub.json_response(200, %{"template_ids" => []})

        "/2/file_properties/templates/get_for_user" ->
          FinchStub.json_response(200, %{"name" => "t", "description" => "d", "fields" => []})

        "/2/openid/userinfo" ->
          FinchStub.json_response(200, %{"sub" => "dbid:1", "email" => "a@b.com"})

        "/2/paper/docs/list" ->
          FinchStub.json_response(200, %{"doc_ids" => [], "cursor" => %{"value" => "c", "expiration" => nil}, "has_more" => false})

        "/2/paper/docs/get_metadata" ->
          FinchStub.json_response(200, %{"doc_id" => "d1", "title" => "Doc"})

        _ ->
          FinchStub.json_response(200, %{})
      end
    end)

    :ok
  end

  test "account set_profile_photo" do
    photo = %{".tag" => "base64_data", "base64_data" => Base.encode64("img")}
    assert {:ok, _} = Account.set_profile_photo(photo, client: @client)
  end

  test "contacts delete helpers" do
    assert {:ok, _} = Contacts.delete_manual_contacts(client: @client)
    assert {:ok, _} = Contacts.delete_manual_contacts_batch(["a@b.com"], client: @client)
  end

  test "file_requests create/list/count" do
    assert {:ok, %{id: "fr1"}} =
             FileRequests.create("Send me files", "/inbox", client: @client)

    assert {:ok, %{file_requests: []}} = FileRequests.list_v2(client: @client)
    assert {:ok, %{file_request_count: 0}} = FileRequests.count(client: @client)
  end

  test "file_properties templates list/get" do
    assert {:ok, %{template_ids: []}} = FileProperties.templates_list_for_user(client: @client)
    assert {:ok, %{name: "t"}} = FileProperties.templates_get_for_user("ptid:1", client: @client)
  end

  test "openid userinfo" do
    assert {:ok, %{sub: "dbid:1"}} = OpenID.userinfo(client: @client)
  end

  test "paper docs list and metadata" do
    assert {:ok, %{doc_ids: []}} = Paper.docs_list(client: @client)
    assert {:ok, %{doc_id: "d1"}} = Paper.docs_get_metadata("d1", client: @client)
  end
end
