defmodule Noizu.Dropbox.Api.SharingTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.Sharing
  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token")

  setup do
    Mimic.stub(Finch, :request, fn request, _n, _o ->
      case request.path do
        "/2/sharing/create_shared_link_with_settings" ->
          body = Jason.decode!(request.body)
          assert body["path"] == "/doc.txt"

          FinchStub.json_response(200, %{
            "url" => "https://www.dropbox.com/s/x/doc.txt?dl=0",
            "name" => "doc.txt",
            "path_lower" => "/doc.txt",
            ".tag" => "file"
          })

        "/2/sharing/list_shared_links" ->
          FinchStub.json_response(200, %{
            "links" => [
              %{"url" => "https://www.dropbox.com/s/x/doc.txt?dl=0", "name" => "doc.txt"}
            ],
            "has_more" => false
          })

        "/2/sharing/revoke_shared_link" ->
          assert Jason.decode!(request.body)["url"] =~ "dropbox.com"
          FinchStub.json_response(200, nil)

        other ->
          FinchStub.json_response(404, %{error_summary: other})
      end
    end)

    :ok
  end

  test "create_shared_link_with_settings" do
    assert {:ok, result} =
             Sharing.create_shared_link_with_settings("/doc.txt", client: @client)

    assert result[:url] =~ "dropbox.com" or result["url"] =~ "dropbox.com"
  end

  test "list_shared_links" do
    assert {:ok, result} = Sharing.list_shared_links(client: @client)
    links = result[:links] || result["links"]
    assert is_list(links)
    assert length(links) == 1
  end

  test "revoke_shared_link" do
    assert {:ok, _} =
             Sharing.revoke_shared_link("https://www.dropbox.com/s/x/doc.txt?dl=0",
               client: @client
             )
  end
end
