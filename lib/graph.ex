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

  @doc """
  Calculate trips for given origin and destination

  Optionally, you may provide `max_stops` as the maximum number of stops desired, or
  `num_stops`for an exact match.

  ## Examples

    # It does not work with both num_stops and max_stops
    iex> Trains.Graph.trips(%{}, "A", "A", [num_stops: 3, max_stops: 3])
    {:error, :invalid_options}

    # It does not work with num_stops less than one
    iex> Trains.Graph.trips(%{}, "A", "A", [num_stops: 0])
    {:error, :invalid_options}

    # It does not work with max_stops less than one
    iex> Trains.Graph.trips(%{}, "A", "A", [max_stops: 0])
    {:error, :invalid_options}

    # It finds simple trips
    iex> Trains.Graph.trips(
    ...>  %{
    ...>    "A" => %{3 => ["B"], 5 => ["C"]},
    ...>    "B" => %{5 => ["C"], 9 => ["D"], 4 => ["A"]},
    ...>    "C" => %{2 => ["B"], 3 => ["D"]}
    ...>  },
    ...>  "B",
    ...>  "C",
    ...>  [max_stops: 1]
    ...> )
    {:ok, [%Trains.Routes.Route{stops: ["B", "C"], distance: 5}]}

    # It finds more complex trips
    iex> Trains.Graph.trips(
    ...>  %{
    ...>    "A" => %{5 => ["B", "D"], 7 => ["E"]},
    ...>    "B" => %{4 => ["C"]},
    ...>    "C" => %{8 => ["D"], 2 => ["E"]},
    ...>    "D" => %{8 => ["C"], 6 => ["E"]},
    ...>    "E" => %{3 => ["B"]},
    ...>  },
    ...>  "C",
    ...>  "C",
    ...>  [max_stops: 3]
    ...> )
    {
      :ok,
      [
        %Trains.Routes.Route{stops: ["C", "E", "B", "C"], distance: 9},
        %Trains.Routes.Route{stops: ["C", "D", "C"], distance: 16},
      ]
    }
  """
  def trips(graph, origin, destination, opts \\ [max_stops: nil, num_stops: nil]) do
    if (trips_valid_opts?(opts)) do
      routes = nearby(graph, origin)
        |> Enum.map(&(_trips(graph, (with {:ok, route} <- route(graph, [origin] ++ [&1]), do: route), destination, opts)))
        |> List.flatten()
      {:ok, routes}
    else
      {:error, :invalid_options}
    end
  end

  defp _trips(graph, %Route{} = route, destination, opts) do
    if continue_trip_search?(route, opts) do
      last_stop = Trains.Routes.destination(route)
      nearby(graph, last_stop)
        |> Enum.map(&(_trips(graph, (with {:ok, route} <- _route(graph, [&1], route), do: route), destination, opts)))
    else
      if Trains.Routes.destination(route) == destination, do: [route], else: []
    end
  end

  defp trips_valid_opts?(opts) do
    !(
      (opts[:num_stops] !== nil && opts[:max_stops] !== nil) ||
      (opts[:num_stops] !== nil && opts[:num_stops] < 1) ||
      (opts[:max_stops] !== nil && opts[:max_stops] < 1)
     )
  end

  defp continue_trip_search?(%Route{} = route, opts) do
    stops = Trains.Routes.num_stops(route)
    (opts[:max_stops] !== nil && opts[:max_stops] > stops) || (opts[:num_stops] !== nil && opts[:num_stops] > stops)
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