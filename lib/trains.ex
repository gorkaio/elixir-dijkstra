defmodule Trains do
  alias Trains.{Parser, Graph}

  @moduledoc """
  Trains module
  """

  def main(args) do
    args |> parse_args |> process
  end

  def process([]) do
    IO.puts "Usage: trains --config=\"AB5,AC7,BC3\""
  end

  def process(options) do
    graph = load_graph(options[:config])
  end

  defp load_graph(config) do
    {:ok, routes} = Trains.Parser.parse(config)
    {:ok, graph} = Trains.Graph.new(routes)
    IO.puts "Loaded config:"
    Enum.map(routes, &IO.puts("\t#{&1.origin}->#{&1.destination}: #{&1.distance}"))
    graph
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(
      args,
      switches: [config: :string]
    )
    options
  end
end
