defmodule Trains.Parser do
  alias Trains.Routes

  @route_regex ~r/^(?<origin>\p{Lu})(?<destination>\p{Lu})(?<distance>[0-9]+)$/
  @path_regex ~r/^\p{Lu}(-\p{Lu})+$/

  @moduledoc """
  Documentation for Trains Parser.
  """

  @doc """
  Parse route information from a comma separared route steps string
  Each step should be:
   - A single capital letter for origin
   - A single capital letter for destination
   - A positive integer for distance

  ## Examples

      # Valid routes are parsed
      iex> Trains.Parser.parse_routes("AB5, BC4")
      {
        :ok,
        [
          %Trains.Routes.Route{stops: ["A", "B"], distance: 5},
          %Trains.Routes.Route{stops: ["B", "C"], distance: 4}
        ]
      }

      # Routes with same origin and destination are invalid
      iex> Trains.Parser.parse_routes("AA5")
      {:error, :invalid_input}

      # Non well formatted routes are invalid
      iex> Trains.Parser.parse_routes("NNN")
      {:error, :invalid_input}

      # Empty input is also valid
      iex> Trains.Parser.parse_routes("")
      {:ok, []}

  """
  def parse_routes(info) when is_binary(info) do
    pieces = String.split(info, ~r/\s*,\s*/, trim: true)
    routes = pieces
      |> Enum.map(&String.trim(&1))
      |> Enum.map(&parse_route(&1))
      |> Enum.map(fn {:ok, route} -> route end)
    {:ok, routes}
  rescue
    _ -> {:error, :invalid_input}
  end

  def parse_routes(_) do
    {:error, :invalid_input}
  end

  @doc """
  Parses a route path and returns its stops

  ## Examples

    iex> Trains.Parser.parse_path("A-B-C-D")
    {:ok, ["A", "B", "C", "D"]}

    iex> Trains.Parser.parse_path("A")
    {:error, :invalid_input}

    iex> Trains.Parser.parse_path("A-B-C-")
    {:error, :invalid_input}

    iex> Trains.Parser.parse_path("ABC")
    {:error, :invalid_input}
  """
  def parse_path(path) do
    if Regex.match?(@path_regex, path) do
      {:ok, String.split(path, "-")}
    else
      {:error, :invalid_input}
    end
  end

  defp parse_route(string) do
    values = Regex.named_captures(@route_regex, string)
    Routes.new(values["origin"], values["destination"], String.to_integer(values["distance"]))
  end
end
