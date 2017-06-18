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
    {:ok, %{"A" => %{3 => ["B"]}}}
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
          "A" => %{3 => ["B"]},
          "B" => %{5 => ["C"], 10 => ["D"]}
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
          "A" => %{3 => ["B"]}
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
    case graph = add_route(%{}, routes) do
      {:error, e} -> {:error, e}
      _ -> {:ok, graph}
    end
  end

  @doc """
  Get towns one step away from the given one

  ## Examples

    iex> Trains.Graph.nearby(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A")
    ["B", "C", "F"]

    iex> Trains.Graph.nearby(%{"A" => %{1 => ["B","C"], 3 => ["F"]}}, "Z")
    []
  """
  def nearby(graph, town) do
    Map.get(graph, town, [])
      |> Enum.map(fn v -> elem(v, 1) end)
      |> Enum.reduce([], &(&1 ++ &2))
      |> Enum.sort()
  end

  @doc """
  Get nearest town optionally excluding some

  ## Examples

      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A")
      ["C", "F"]

      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F"])
      ["C"]

      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F", "C"])
      ["B"]

      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F", "C", "B"])
      []

      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "Z", ["F", "C", "B"])
      []
  """
  def nearest(graph, town, excluding \\ []) do
    if !Map.has_key?(graph, town) or Enum.empty?(nearby(graph, town) -- excluding) do
      []
    else
      Map.get(graph, town)
        |> Enum.map(fn x -> %{elem(x, 0) => elem(x, 1) -- excluding} end)
        |> Enum.reduce(&Map.merge/2)
        |> Enum.filter(fn x -> !Enum.empty?(elem(x, 1)) end)
        |> Enum.min_by(fn x -> elem(x, 0) end)
        |> elem(1)
        |> Enum.sort()
    end
  end

  @doc """
  Get distance from origin to destination

  ## Examples

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "B")
    3

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "F")
    1

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "Z")
    nil

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "A")
    nil

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "B", "A")
    nil
  """
  def distance(graph, origin, destination) do
    distance = Map.get(graph, origin, %{})
        |> Enum.find(fn x -> Enum.member?(elem(x, 1), destination) end)
    if distance != nil, do: elem(distance, 0), else: nil
  end

  defp add_route(graph, [%Route{origin: origin, destination: destination, distance: distance} | rest]) do
    graph =
      if Enum.member?(nearby(graph, origin), destination) do
        if distance(graph, origin, destination) != distance, do: {:error, :duplicate_route}, else: graph
      else
        Map.update(
          graph,
          origin,
          %{distance => [destination]},
          &add_destination_to_origin(&1, destination, distance)
        )
      end

    add_route(graph, rest)
  end

  defp add_route(graph, []) do
    graph
  end

  def add_destination_to_origin(origin, destination, distance) do
    Map.update(origin, distance, [destination], &(&1 ++ [destination]))
  end
end