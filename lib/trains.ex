defmodule Trains do
  alias Trains.{Parser, Graph}

  @moduledoc """
  Trains module
  """

  def load_routes(routes_string) do
    {:ok, routes} = Parser.parse(routes_string)
    graph = routes
      |> Graph.new()
  end
end
