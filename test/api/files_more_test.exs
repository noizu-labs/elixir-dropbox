defmodule Noizu.Dropbox.Api.FilesMoreTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.Files
  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Struct.ListFolderResult
  alias Noizu.Dropbox.Struct.Metadata
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token")

  test "list_folder_all paginates until has_more false" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    Mimic.stub(Finch, :request, fn request, _n, _o ->
      n = Agent.get_and_update(agent, fn x -> {x, x + 1} end)

      case {request.path, n} do
        {"/2/files/list_folder", 0} ->
          FinchStub.json_response(200, %{
            "entries" => [%{".tag" => "file", "name" => "a.txt", "path_display" => "/a.txt", "id" => "1"}],
            "cursor" => "c1",
            "has_more" => true
          })

        {"/2/files/list_folder/continue", 1} ->
          assert Jason.decode!(request.body)["cursor"] == "c1"

          FinchStub.json_response(200, %{
            "entries" => [%{".tag" => "file", "name" => "b.txt", "path_display" => "/b.txt", "id" => "2"}],
            "cursor" => "c2",
            "has_more" => false
          })

        {path, page} ->
          FinchStub.json_response(500, %{error_summary: "unexpected #{path} page=#{page}"})
      end
    end)

    assert {:ok, result} = Files.list_folder_all("", client: @client)
    entries = result[:entries] || result.entries
    names = Enum.map(entries, fn e -> e[:name] || e.name || e["name"] end)
    assert names == ["a.txt", "b.txt"]
  after
    :ok
  end

  test "move_v2 and delete_v2" do
    Mimic.stub(Finch, :request, fn request, _n, _o ->
      case request.path do
        "/2/files/move_v2" ->
          body = Jason.decode!(request.body)
          assert body["from_path"] == "/a.txt"
          assert body["to_path"] == "/b.txt"

          FinchStub.json_response(200, %{
            "metadata" => %{
              ".tag" => "file",
              "name" => "b.txt",
              "path_display" => "/b.txt",
              "id" => "id:1"
            }
          })

        "/2/files/delete_v2" ->
          body = Jason.decode!(request.body)
          assert body["path"] == "/b.txt"

          FinchStub.json_response(200, %{
            "metadata" => %{
              ".tag" => "file",
              "name" => "b.txt",
              "path_display" => "/b.txt",
              "id" => "id:1"
            }
          })

        "/2/files/search_v2" ->
          body = Jason.decode!(request.body)
          assert body["query"] == "readme"

          FinchStub.json_response(200, %{
            "matches" => [%{"metadata" => %{"metadata" => %{"name" => "readme.md"}}}],
            "has_more" => false
          })

        "/2/files/get_temporary_link" ->
          FinchStub.json_response(200, %{
            "metadata" => %{"name" => "a.txt"},
            "link" => "https://dl.dropboxusercontent.com/x"
          })

        other ->
          FinchStub.json_response(404, %{error_summary: other})
      end
    end)

    assert {:ok, _} = Files.move_v2("/a.txt", "/b.txt", client: @client)
    assert {:ok, _} = Files.delete_v2("/b.txt", client: @client)
    assert {:ok, search} = Files.search_v2("readme", client: @client)
    assert (search[:matches] || search["matches"]) |> length() == 1
    assert {:ok, %{link: link}} = Files.get_temporary_link("/a.txt", client: @client)
    assert link =~ "dropbox"
  end

  test "copy_v2 returns metadata wrapper" do
    Mimic.expect(Finch, :request, fn %Finch.Request{path: "/2/files/copy_v2", body: body}, _n, _o ->
      assert Jason.decode!(body)["from_path"] == "/src"
      assert Jason.decode!(body)["to_path"] == "/dst"

      FinchStub.json_response(200, %{
        "metadata" => %{".tag" => "folder", "name" => "dst", "path_display" => "/dst", "id" => "f"}
      })
    end)

    assert {:ok, result} = Files.copy_v2("/src", "/dst", client: @client)
    meta = result[:metadata] || result["metadata"]
    assert meta[:name] == "dst" or meta["name"] == "dst"
  end

  test "list_folder default decode is ListFolderResult" do
    Mimic.expect(Finch, :request, fn _req, _n, _o ->
      FinchStub.json_response(200, %{
        "entries" => [%{".tag" => "folder", "name" => "docs", "path_display" => "/docs", "id" => "id:d"}],
        "cursor" => "c",
        "has_more" => false
      })
    end)

    assert {:ok, %ListFolderResult{entries: [%Metadata{name: "docs"}]}} =
             Files.list_folder("/docs", client: @client)
  end
end
