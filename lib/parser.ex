defmodule Trains.Parser do
  alias Trains.Routes

  @route_regex ~r/^(?<origin>[A-Z])(?<destination>[A-Z])(?<distance>[0-9]+)$/

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
      iex> Trains.Parser.parse("AB5, BC4")
      {
        :ok,
        [
          %Trains.Routes.Route{origin: "A", destination: "B", distance: 5},
          %Trains.Routes.Route{origin: "B", destination: "C", distance: 4}
        ]
      }

      # Routes with same origin and destination are invalid
      iex> Trains.Parser.parse("AA5")
      {:error, :invalid_input}

      # Non well formatted routes are invalid
      iex> Trains.Parser.parse("NNN")
      {:error, :invalid_input}

      # Empty input is also valid
      iex> Trains.Parser.parse("")
      {:ok, []}

  """
  def parse(info) when is_binary(info) do
    pieces = String.split(info, ~r/\s*,\s*/, trim: true)
    routes = pieces
      |> Enum.map(&String.trim(&1))
      |> Enum.map(&parse_route(&1))
      |> Enum.map(fn {:ok, route} -> route end)
    {:ok, routes}
  rescue
    _ -> {:error, :invalid_input}
  end

  def parse(_) do
    {:error, :invalid_input}
  end

  defp parse_route(string) do
    values = Regex.named_captures(@route_regex, string)
    Routes.new(values["origin"], values["destination"], String.to_integer(values["distance"]))
  end
end
