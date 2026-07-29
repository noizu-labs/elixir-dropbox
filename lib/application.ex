defmodule Noizu.Dropbox.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Noizu.Dropbox.Finch}
    ]

    opts = [strategy: :one_for_one, name: Noizu.Dropbox.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
