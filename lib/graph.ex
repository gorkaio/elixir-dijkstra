defmodule Trains.Graph do
  alias Trains.Routes.Route

  @moduledoc """
  Routes graph
  """

  @doc """
  Creates a new graph

  ## Examples

    # Graph is generated from routes
    iex> Trains.Graph.new([%Trains.Routes.Route{stops: ["A","B"], distance: 3}])
    {:ok, %{"A" => %{3 => ["B"]}}}
    iex> Trains.Graph.new(
    ...>    [
    ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3},
    ...>      %Trains.Routes.Route{stops: ["B", "C"], distance: 5},
    ...>      %Trains.Routes.Route{stops: ["B", "D"], distance: 10}
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
    ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3},
    ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3}
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
    ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3},
    ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 10}
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
    {:ok, 3}

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "F")
    {:ok, 1}

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "Z")
    {:error, :no_such_route}

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "A")
    {:error, :no_such_route}

    iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "B", "A")
    {:error, :no_such_route}
  """
  def distance(graph, origin, destination) do
    distance = Map.get(graph, origin, %{})
        |> Enum.find(fn x -> Enum.member?(elem(x, 1), destination) end)
    if distance != nil, do: {:ok, elem(distance, 0)}, else: {:error, :no_such_route}
  end

  @doc """
  Calculate route between two towns

  ## Examples

    # Single town paths are not allowed
    iex> Trains.Graph.route(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, ["A"])
    {:error, :invalid_path}

    # Empty paths are not allowed
    iex> Trains.Graph.route(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, [])
    {:error, :invalid_path}

    # It traces simple routes
    iex> Trains.Graph.route(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, ["A", "B"])
    {:ok, %Trains.Routes.Route{stops: ["A", "B"], distance: 3}}

    # It traces complex routes
    iex> Trains.Graph.route(
    ...>  %{
    ...>    "A" => %{3 => ["B"], 5 => ["C", "D"]},
    ...>    "B" => %{5 => ["C"], 10 => ["D"], 4 => ["A"]},
    ...>    "C" => %{2 => ["B"], 7 => ["D"]}
    ...>  },
    ...>  ["A", "C", "B", "A"]
    ...> )
    {:ok, %Trains.Routes.Route{stops: ["A", "C", "B", "A"], distance: 11}}
  """
  def route(graph, [origin|rest] = path) when is_list(path) do
    if Enum.count(path) > 1 do
      [next_stop|next_path] = rest
      with {:ok, distance} <- distance(graph, origin, next_stop),
           {:ok, route} <- _route(graph, next_path, %Route{stops: [origin,next_stop], distance: distance}),
      do: {:ok, route}
    else
      {:error, :invalid_path}
    end
  end

  def route(_graph, _) do
    {:error, :invalid_path}
  end

  defp _route(graph, [stop|rest], %Route{} = route) do
    with {:ok, distance} <- distance(graph, Trains.Routes.destination(route), stop),
         {:ok, route} <- _route(graph, rest, %Route{stops: route.stops ++ [stop], distance: route.distance + distance}),
    do: {:ok, route}
  end

  defp _route(graph, [stop|[]], %Route{} = route) do
    with {:ok, distance} <- distance(graph, Trains.Routes.destination(route), stop),
         {:ok, route} <- _route(graph, [], %Route{stops: route.stops ++ [stop], distance: route.distance + distance }),
    do: {:ok, route}
  end

  defp _route(_graph, [], %Route{} = route) do
    {:ok, route}
  end

  defp add_route(graph, [%Route{} = route | rest]) do
    origin = Trains.Routes.origin(route)
    destination = Trains.Routes.destination(route)
    graph =
      if Enum.member?(nearby(graph, origin), destination) do
        {:ok, distance} = distance(graph, origin, destination)
        if distance != route.distance, do: {:error, :duplicate_route}, else: graph
      else
        Map.update(
          graph,
          origin,
          %{route.distance => [destination]},
          &add_destination_to_origin(&1, destination, route.distance)
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