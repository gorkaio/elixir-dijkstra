defmodule Trains.Graph do
  alias Trains.Routes.Route

  @moduledoc """
  Routes graph
  """

  @doc """
  Creates a new graph

  ## Examples

    # Graph is generated from routes
    iex> Trains.Graph.new([%Trains.Routes.Route{origin: "A", destination: "B", distance: 3}])
    {:ok, %{"A" => %{"B" => 3}}}
    iex> Trains.Graph.new(
    ...>    [
    ...>      %Trains.Routes.Route{origin: "A", destination: "B", distance: 3},
    ...>      %Trains.Routes.Route{origin: "B", destination: "C", distance: 5},
    ...>      %Trains.Routes.Route{origin: "B", destination: "D", distance: 10}
    ...>    ]
    ...> )
    {
      :ok,
      %{
          "A" => %{"B" => 3},
          "B" => %{"C" => 5, "D" => 10}
      }
    }

    # Duplicate routes with same distance are ignored
    iex> Trains.Graph.new(
    ...>    [
    ...>      %Trains.Routes.Route{origin: "A", destination: "B", distance: 3},
    ...>      %Trains.Routes.Route{origin: "A", destination: "B", distance: 3}
    ...>    ]
    ...> )
    {
      :ok,
      %{
          "A" => %{"B" => 3}
      }
    }

    # Duplicate routes with different distances are rejected
    iex> Trains.Graph.new(
    ...>    [
    ...>      %Trains.Routes.Route{origin: "A", destination: "B", distance: 3},
    ...>      %Trains.Routes.Route{origin: "A", destination: "B", distance: 10}
    ...>    ]
    ...> )
    {:error, :duplicate_route}

    # Graph might be empty
    iex> Trains.Graph.new([])
    {:ok, %{}}
  """
  def new(routes) do
    case graph = add(%{}, routes) do
      {:error, e} -> {:error, e}
      _ -> {:ok, graph}
    end
  end

  defp add(graph, [%Route{origin: origin, destination: destination, distance: distance} | rest]) do

    graph =
      if !has_origin?(graph, origin) do
        add_origin(graph, origin)
      else
        graph
      end

    value = get_in(graph, [origin, destination])
    if value != nil && value != distance do
      {:error, :duplicate_route}
    else
      graph = put_in(graph, [origin, destination], distance)
      add(graph, rest)
    end
  end

  defp add(graph, []) do
    graph
  end

  defp has_origin?(graph, origin) do
    Map.has_key?(graph, origin)
  end

  defp add_origin(graph, origin) do
    Map.put(graph, origin, %{})
  end
end