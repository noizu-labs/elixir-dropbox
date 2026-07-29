defmodule Noizu.Dropbox.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/noizu-labs/elixir-dropbox"

  def project do
    [
      app: :noizu_dropbox,
      name: "Noizu Dropbox",
      description: description(),
      package: package(),
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      # Thin API wrapper modules keep line coverage moderate; core HTTP/OAuth
      # paths are exercised heavily. Raise as more endpoint suites land.
      test_coverage: [summary: [threshold: 30]]
    ]
  end

  def application do
    [
      mod: {Noizu.Dropbox.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:finch, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mimic, "~> 1.0", only: :test},
      {:junit_formatter, "~> 3.3", only: :test}
    ]
  end

  defp description do
    """
    Full Dropbox API v2 client for Elixir — RPC endpoints, content
    upload/download, OAuth2 (short-lived tokens, refresh, PKCE), and
    user namespaces (files, sharing, users, paper, file requests, and more).
    """
  end

  defp package do
    [
      name: "noizu_dropbox",
      licenses: ["MIT"],
      maintainers: ["Keith Brings"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Dropbox API" =>
          "https://www.dropbox.com/developers/documentation/http/documentation",
        "Noizu Labs" => "https://github.com/noizu-labs"
      },
      files: ~w(
        lib
        .formatter.exs
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        Core: [
          Noizu.Dropbox,
          Noizu.Dropbox.Client,
          Noizu.Dropbox.Error,
          Noizu.Dropbox.HTTP,
          Noizu.Dropbox.OAuth
        ],
        "API — Files": [Noizu.Dropbox.Api.Files],
        "API — Sharing": [Noizu.Dropbox.Api.Sharing],
        "API — Users & Account": [
          Noizu.Dropbox.Api.Users,
          Noizu.Dropbox.Api.Account,
          Noizu.Dropbox.Api.Auth,
          Noizu.Dropbox.Api.Check,
          Noizu.Dropbox.Api.OpenID
        ],
        "API — Collaboration": [
          Noizu.Dropbox.Api.Paper,
          Noizu.Dropbox.Api.FileRequests,
          Noizu.Dropbox.Api.Contacts,
          Noizu.Dropbox.Api.FileProperties
        ],
        Structs: ~r/Noizu\.Dropbox\.Struct\./
      ]
    ]
  end
end
