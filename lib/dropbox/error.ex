defmodule Noizu.Dropbox.Error do
  @moduledoc """
  Structured error returned by Dropbox API calls.
  """

  defexception [:message, :status, :body, :reason, :summary, :tag]

  @type t :: %__MODULE__{
          message: String.t(),
          status: pos_integer() | nil,
          body: term(),
          reason: term(),
          summary: String.t() | nil,
          tag: String.t() | atom() | nil
        }

  @impl true
  def message(%__MODULE__{message: msg}) when is_binary(msg), do: msg
  def message(%__MODULE__{summary: summary}) when is_binary(summary), do: summary
  def message(%__MODULE__{status: status, reason: reason}),
    do: "Dropbox API error status=#{inspect(status)} reason=#{inspect(reason)}"

  @doc "Build an error from an HTTP response body (JSON map or raw)."
  @spec from_response(pos_integer(), term()) :: t()
  def from_response(status, body) do
    {summary, tag} = extract_summary(body)

    %__MODULE__{
      message: summary || "HTTP #{status}",
      status: status,
      body: body,
      reason: :http_error,
      summary: summary,
      tag: tag
    }
  end

  @doc "Build a transport / client-side error."
  @spec transport(term()) :: t()
  def transport(reason) do
    %__MODULE__{
      message: "transport error: #{inspect(reason)}",
      status: nil,
      body: nil,
      reason: reason,
      summary: nil,
      tag: :transport
    }
  end

  @doc "Build an encoding/decoding error."
  @spec codec(term()) :: t()
  def codec(reason) do
    %__MODULE__{
      message: "codec error: #{inspect(reason)}",
      status: nil,
      body: nil,
      reason: reason,
      summary: nil,
      tag: :codec
    }
  end

  @doc "Missing configuration (token, credentials, etc.)."
  @spec config(String.t()) :: t()
  def config(message) do
    %__MODULE__{
      message: message,
      status: nil,
      body: nil,
      reason: :config,
      summary: message,
      tag: :config
    }
  end

  defp extract_summary(%{"error_summary" => summary} = body) do
    tag =
      case body do
        %{"error" => %{".tag" => t}} -> t
        %{"error" => t} when is_binary(t) -> t
        _ -> nil
      end

    {summary, tag}
  end

  defp extract_summary(%{error_summary: summary} = body) do
    tag =
      case body do
        %{error: %{".tag": t}} -> t
        %{error: t} when is_binary(t) -> t
        _ -> nil
      end

    {summary, tag}
  end

  defp extract_summary(body) when is_binary(body), do: {body, nil}
  defp extract_summary(_), do: {nil, nil}
end
