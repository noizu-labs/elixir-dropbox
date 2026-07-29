defmodule Noizu.Dropbox.Test.FinchStub do
  @moduledoc false

  def json_response(status, nil) do
    {:ok,
     %Finch.Response{
       status: status,
       body: "null",
       headers: [{"content-type", "application/json"}]
     }}
  end

  def json_response(status, body) when is_map(body) or is_list(body) do
    {:ok,
     %Finch.Response{
       status: status,
       body: Jason.encode!(body),
       headers: [{"content-type", "application/json"}]
     }}
  end

  def json_response(status, body) when is_binary(body) do
    {:ok, %Finch.Response{status: status, body: body, headers: []}}
  end

  def download_response(status, metadata, body) do
    {:ok,
     %Finch.Response{
       status: status,
       body: body,
       headers: [
         {"dropbox-api-result", Jason.encode!(metadata)},
         {"content-type", "application/octet-stream"}
       ]
     }}
  end
end
