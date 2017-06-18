defmodule Trains do
  alias Trains.{Parser, Graph, Routes}

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
    run_testsuite(graph)
  end

  defp run_testsuite(graph) do
    test_path(graph, "A-B-C", 1)
    test_path(graph, "A-D", 2)
    test_path(graph, "A-D-C", 3)
    test_path(graph, "A-E-B-C-D", 4)
    test_path(graph, "A-E-D", 5)
  end

  defp test_path(graph, path, test_number) do
    {:ok, parsed_path} = Parser.parse_path(path)
    case Graph.route(graph, parsed_path) do
      {:ok, route} -> IO.puts(format_output(test_number, Routes.distance(route)))
      {:error, reason} -> IO.puts(format_output(test_number, error_message(reason)))
      _ -> IO.puts(format_output(test_number, "THIS SHOULD NOT HAPPEN!"))
    end
  end

  defp format_output(test_number, message) do
    "Output ##{test_number}: #{message}"
  end

  defp error_message(reason) do
    case reason do
      :no_such_route -> "NO SUCH ROUTE"
      _ -> "Ooops! Something broke!"
    end
  end

  defp load_graph(config) do
    {:ok, routes} = Trains.Parser.parse_routes(config)
    {:ok, graph} = Trains.Graph.new(routes)
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
