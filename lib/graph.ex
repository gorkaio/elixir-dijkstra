defmodule Trains.Graph do
  alias Trains.Routes.Route

  @moduledoc """
  Routes graph

  `Trains.Graph` handles the initial directed graph configuration and every function related to route calculation.
  """

  @doc """
  Creates a new graph

  ## Parameters

    - routes: `%Trains.Routes.Route{}` used to build the graph

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
      {:ok, %{"A" => %{3 => ["B"]}, "B" => %{5 => ["C"], 10 => ["D"]}}}

      # Duplicate routes with same distance are ignored
      iex> Trains.Graph.new(
      ...>    [
      ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3},
      ...>      %Trains.Routes.Route{stops: ["A", "B"], distance: 3}
      ...>    ]
      ...> )
      {:ok, %{"A" => %{3 => ["B"]}}}

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

  ## Parameters

    - graph: routes graph
    - town: Town to explore

  ## Examples

      # Gets every town one step away
      iex> Trains.Graph.nearby(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A")
      ["B", "C", "F"]

      # Return empty list for unkown towns
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
  Get nearest towns, sorted alphabetically and optionally excluding some of them

  ## Parameters

    - graph: routes graph
    - town: Town to explore
    - excluding: Towns to exclude from the resulting list (default: [])

  ## Examples
      
      # Gets every nearest town when not given any excluded towns
      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A")
      ["C", "F"]

      # Filters one excluded town
      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F"])
      ["C"]

      # Filters multiple excluded towns
      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F", "C"])
      ["B"]

      # Returns empty list if every nearest town is excluded
      iex> Trains.Graph.nearest(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", ["F", "C", "B"])
      []

      # Returns empty list for unknown towns
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
  Get distance from one step away towns, origin to destination

  ## Parameters
  
    - graph: routes graph
    - origin: Origin town
    - destination: Destination town
    
  ## Examples

      iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "B")
      {:ok, 3}
  
      iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "F")
      {:ok, 1}

      # Returns error if no such route exists
      iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "Z")
      {:error, :no_such_route}
  
      # Returns error when given same origin and destination town
      iex> Trains.Graph.distance(%{"A" => %{1 => ["F","C"], 3 => ["B"]}}, "A", "A")
      {:error, :no_such_route}
  
      # Returns error when there is no destination available from given origin
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

  ## Parameters
  
    - graph: routes graph
    - path: list of towns describing a route
    
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
           {:ok, route} <- _route(graph, next_path, %Route{stops: [origin, next_stop], distance: distance}),
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

  ## Parameters

    - graph: routes graph
    - origin: origin town
    - destination: destination town
    - opts: options (default: [max_stops: nil, num_stops: nil, max_distance: nil])
      - max_stops: The maximum number of stops desired (can't be used with `num_stops`)
      - num_stops: The exact number of stops desired (can't be used with `max_stops`)
      - max_distance: The maximum distance desired

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

      # It does not work with max_distance less than one
      iex> Trains.Graph.trips(%{}, "A", "A", [max_distance: 0])
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
          %Trains.Routes.Route{stops: ["C", "D", "C"], distance: 16},
          %Trains.Routes.Route{stops: ["C", "E", "B", "C"], distance: 9}
        ]
      }

      # It finds complex trips with exact number of stops
      iex> Trains.Graph.trips(
      ...>  %{
      ...>    "A" => %{5 => ["B", "D"], 7 => ["E"]},
      ...>    "B" => %{4 => ["C"]},
      ...>    "C" => %{8 => ["D"], 2 => ["E"]},
      ...>    "D" => %{8 => ["C"], 6 => ["E"]},
      ...>    "E" => %{3 => ["B"]},
      ...>  },
      ...>  "A",
      ...>  "C",
      ...>  [num_stops: 4]
      ...> )
      {
        :ok,
        [
          %Trains.Routes.Route{distance: 25, stops: ["A", "B", "C", "D", "C"]},
          %Trains.Routes.Route{distance: 29, stops: ["A", "D", "C", "D", "C"]},
          %Trains.Routes.Route{distance: 18, stops: ["A", "D", "E", "B", "C"]}
        ]
      }

      # It finds trips with maximum distance
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
      ...>  [max_distance: 30]
      ...> )
      {
        :ok,
        [
          %Trains.Routes.Route{distance: 16, stops: ["C", "D", "C"]},
          %Trains.Routes.Route{distance: 25, stops: ["C", "D", "C", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 21, stops: ["C", "D", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 30, stops: ["C", "D", "E", "B", "C", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 9, stops: ["C", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 25, stops: ["C", "E", "B", "C", "D", "C"]},
          %Trains.Routes.Route{distance: 30, stops: ["C", "E", "B", "C", "D", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 18, stops: ["C", "E", "B", "C", "E", "B", "C"]},
          %Trains.Routes.Route{distance: 27, stops: ["C", "E", "B", "C", "E", "B", "C", "E", "B", "C"]}
        ]
      }
  """
  def trips(graph, origin, destination, opts \\ [max_stops: nil, num_stops: nil, max_distance: nil]) do
    if trips_valid_opts?(opts) do

      mapper = &_trips(
        graph,
        destination,
        (with {:ok, distance} <- distance(graph, origin, &1),
              {:ok, route} <- Trains.Routes.new(origin, &1, distance), do: route),
        opts
      )

      routes = nearby(graph, origin)
        |> Enum.map(mapper)
        |> List.flatten()

      {:ok, routes}
    else
      {:error, :invalid_options}
    end
  end

  defp _trips(graph, destination, route, opts, routes \\ []) do
    current_stop = Trains.Routes.destination(route)
    mapper = &_trips(
      graph,
      destination,
      (with {:ok, distance} <- distance(graph, current_stop, &1),
            {:ok, route} <- Trains.Routes.add_stop(route, &1, distance), do: route),
      opts,
      routes
    )

    if trips_valid_route?(route, destination, opts), do: routes = routes ++ [route]
    if continue_trip_search?(route, opts) do
      routes = routes ++ (nearby(graph, current_stop) |> Enum.map(mapper))
    end

    routes
  end

  defp trips_valid_opts?(opts) do
    (opts[:num_stops] == nil || opts[:max_stops] == nil) &&
    (opts[:num_stops] == nil || opts[:num_stops] >= 1) &&
    (opts[:max_stops] == nil || opts[:max_stops] >= 1) &&
    (opts[:max_distance] == nil || opts[:max_distance] >= 1)
  end

  defp trips_valid_route?(%Route{} = route, destination, opts) do
    Trains.Routes.destination(route) == destination &&
    (opts[:num_stops] == nil || opts[:num_stops] == Trains.Routes.num_stops(route)) &&
    (opts[:max_stops] == nil || opts[:max_stops] >= Trains.Routes.num_stops(route)) &&
    (opts[:max_distance] == nil || opts[:max_distance] >= Trains.Routes.distance(route))
  end

  defp continue_trip_search?(%Route{} = route, opts) do
    (opts[:max_distance] == nil || opts[:max_distance] > Trains.Routes.distance(route)) &&
    (opts[:max_stops] == nil || opts[:max_stops] > Trains.Routes.num_stops(route)) &&
    (opts[:num_stops] == nil || opts[:num_stops] > Trains.Routes.num_stops(route))
  end

  @doc """
  Find the shortest route between two towns

  ## Parameters
    - graph: routes graph
    - origin: origin town
    - destination: destination town

  ## Examples

      # It finds the shortest route with direct paths
      iex> Trains.Graph.shortest_route(
      ...>  %{
      ...>    "A" => %{5 => ["B", "D"], 7 => ["E"]},
      ...>    "B" => %{4 => ["C"]},
      ...>    "C" => %{8 => ["D"], 2 => ["E"]},
      ...>    "D" => %{8 => ["C"], 6 => ["E"]},
      ...>    "E" => %{3 => ["B"]},
      ...>  },
      ...>  "A",
      ...>  "B"
      ...> )
      {:ok, %Trains.Routes.Route{distance: 5, stops: ["A", "B"]}}

      # It finds the shortest route with direct paths
      iex> Trains.Graph.shortest_route(
      ...>  %{
      ...>    "A" => %{5 => ["B", "D"], 7 => ["E"]},
      ...>    "B" => %{4 => ["C"]},
      ...>    "C" => %{8 => ["D"], 2 => ["E"]},
      ...>    "D" => %{8 => ["C"], 6 => ["E"]},
      ...>    "E" => %{3 => ["B"]},
      ...>  },
      ...>  "A",
      ...>  "C"
      ...> )
      {:ok, %Trains.Routes.Route{distance: 9, stops: ["A", "B", "C"]}}

      # It finds the shortest cyclic routes
      iex> Trains.Graph.shortest_route(
      ...>  %{
      ...>    "A" => %{5 => ["B", "D"], 7 => ["E"]},
      ...>    "B" => %{4 => ["C"]},
      ...>    "C" => %{8 => ["D"], 2 => ["E"]},
      ...>    "D" => %{8 => ["C"], 6 => ["E"]},
      ...>    "E" => %{3 => ["B"]},
      ...>  },
      ...>  "C",
      ...>  "C"
      ...> )
      {:ok, %Trains.Routes.Route{distance: 9, stops: ["C", "E", "B", "C"]}}
  """
  def shortest_route(graph, origin, destination) do
    [route|_] = nearest(graph, origin, [])
      |> Enum.map(
        &_shortest_route(
            graph,
            destination,
            (with {:ok, distance} <- distance(graph, origin, &1),
                  {:ok, route} <- Trains.Routes.new(origin, &1, distance), do: route)
        ))
      |> Enum.filter(&(&1 != nil))

    {:ok, route}
  end

  defp _shortest_route(graph, destination, %Route{} = route) do
    current_stop = Trains.Routes.destination(route)
    if current_stop !== destination do
      [route|_] = nearest(graph, current_stop, route.stops -- [destination])
        |> Enum.map(
            &_shortest_route(
            graph,
            destination,
            (with {:ok, distance} <- distance(graph, current_stop, &1),
                  {:ok, route} <- Trains.Routes.add_stop(route, &1, distance), do: route)
          ))
    end
    route
  end

  defp _route(graph, [stop|rest], %Route{} = route) do
    with {:ok, distance} <- distance(graph, Trains.Routes.destination(route), stop),
         {:ok, route} <- _route(graph, rest, %Route{stops: route.stops ++ [stop], distance: route.distance + distance}),
    do: {:ok, route}
  end

  defp _route(graph, [stop|[]], %Route{} = route) do
    with {:ok, distance} <- distance(graph, Trains.Routes.destination(route), stop),
         {:ok, route} <- _route(graph, [], %Route{stops: route.stops ++ [stop], distance: route.distance + distance}),
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

  defp add_destination_to_origin(origin, destination, distance) do
    Map.update(origin, distance, [destination], &(&1 ++ [destination]))
  end
end
