defmodule Noizu.Dropbox.Api.FilesTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Noizu.Dropbox.Api.Files
  alias Noizu.Dropbox.Client
  alias Noizu.Dropbox.Struct.ListFolderResult
  alias Noizu.Dropbox.Struct.Metadata
  alias Noizu.Dropbox.Test.FinchStub

  @client Client.new(access_token: "test-token")

  setup do
    Mimic.stub(Finch, :request, fn request, _name, _opts ->
      handle(request)
    end)

    :ok
  end

  test "list_folder decodes ListFolderResult" do
    assert {:ok, %ListFolderResult{entries: entries, has_more: false}} =
             Files.list_folder("", client: @client)

    assert [%Metadata{name: "readme.md", tag: "file"}] = entries
  end

  test "get_metadata returns Metadata" do
    assert {:ok, %Metadata{name: "readme.md", path_display: "/readme.md"}} =
             Files.get_metadata("/readme.md", client: @client)
  end

  test "upload posts to content host with Dropbox-API-Arg" do
    assert {:ok, %Metadata{name: "hi.txt"}} =
             Files.upload("/hi.txt", "hi", client: @client, mode: "overwrite")
  end

  test "download returns body and metadata" do
    assert {:ok, %{metadata: meta, body: body}} =
             Files.download("/hi.txt", client: @client)

    assert body == "hi"
    assert meta[:name] == "hi.txt" or meta["name"] == "hi.txt"
  end

  test "create_folder_v2" do
    assert {:ok, result} = Files.create_folder("/docs", client: @client)
    assert result[:metadata][:name] == "docs" or result[:metadata]["name"] == "docs" or
             match?(%{metadata: %{name: "docs"}}, result)
  end

  test "missing token returns config error" do
    bare = Client.new(access_token: nil)

    assert {:error, %Noizu.Dropbox.Error{tag: :config}} =
             Files.list_folder("", client: bare)
  end

  # ---------------------------------------------------------------------------

  defp handle(%Finch.Request{host: "api.dropboxapi.com", path: path, headers: headers, body: body}) do
    assert_auth(headers)

    cond do
      path == "/2/files/list_folder" ->
        assert Jason.decode!(body)["path"] == ""

        FinchStub.json_response(200, %{
          entries: [
            %{
              ".tag" => "file",
              "name" => "readme.md",
              "path_display" => "/readme.md",
              "id" => "id:1",
              "size" => 10
            }
          ],
          cursor: "cur",
          has_more: false
        })

      path == "/2/files/get_metadata" ->
        FinchStub.json_response(200, %{
          ".tag" => "file",
          "name" => "readme.md",
          "path_display" => "/readme.md",
          "id" => "id:1",
          "size" => 10
        })

      path == "/2/files/create_folder_v2" ->
        FinchStub.json_response(200, %{
          metadata: %{
            ".tag" => "folder",
            "name" => "docs",
            "path_display" => "/docs",
            "id" => "id:f"
          }
        })

      true ->
        FinchStub.json_response(404, %{error_summary: "unknown path #{path}"})
    end
  end

  defp handle(%Finch.Request{
         host: "content.dropboxapi.com",
         path: path,
         headers: headers,
         body: body
       }) do
    assert_auth(headers)
    arg = header(headers, "dropbox-api-arg") |> Jason.decode!()

    cond do
      path == "/2/files/upload" ->
        assert arg["path"] == "/hi.txt"
        assert body == "hi"

        FinchStub.json_response(200, %{
          ".tag" => "file",
          "name" => "hi.txt",
          "path_display" => "/hi.txt",
          "id" => "id:2",
          "size" => 2
        })

      path == "/2/files/download" ->
        assert arg["path"] == "/hi.txt"

        FinchStub.download_response(
          200,
          %{
            ".tag" => "file",
            "name" => "hi.txt",
            "path_display" => "/hi.txt",
            "id" => "id:2",
            "size" => 2
          },
          "hi"
        )

      true ->
        FinchStub.json_response(404, %{error_summary: "unknown content path #{path}"})
    end
  end

  defp assert_auth(headers) do
    assert header(headers, "authorization") == "Bearer test-token"
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == name, do: v
    end)
  end
end
