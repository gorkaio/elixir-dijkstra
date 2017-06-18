defmodule Trains.Routes do

  @moduledoc """
  Routes module

  This modules allows creating basic two step routes like the ones that will be used to set up the Graph,
  and it also provides a way to add stops to a basic route and update its distance following some validation rules.

  String.Chars protocol is implemented for Route so we can print out the results.

  """

  @valid_name_regex ~r/^\p{Lu}$/u

  alias Trains.Routes.Route

  defmodule Route do
    @moduledoc "Route structure"
    @enforce_keys [:stops, :distance]
    @type route :: %Route{stops: List.t, distance: non_neg_integer}
    defstruct [stops: [], distance: 0]
  end

  defimpl String.Chars, for: Route do
    @doc """
    Prints a route

    ## Examples

      iex> Trains.Routes.to_string(%Trains.Routes.Route{stops: [], distance: 0})
      ""
      iex> Trains.Routes.to_string(%Trains.Routes.Route{stops: ["A","B"], distance: 10})
      "A-B"
      iex> Trains.Routes.to_string(%Trains.Routes.Route{stops: ["A","B","C"], distance: 15}
      "A-B-C"
    """
    def to_string(route), do: Enum.reduce(route.stops, &(&1 <> "-" <> &2))
  end


  @doc """
  Create new Route

  ## Examples

    # Valid routes are properly created
    iex> Trains.Routes.new("A", "B", 5)
    {:ok, %Trains.Routes.Route{stops: ["A","B"], distance: 5}}

    # Routes with non integer distances are rejected
    iex> Trains.Routes.new("A", "B", "9")
    {:error, :invalid_route}
    iex> Trains.Routes.new("A", "B", :error)
    {:error, :invalid_route}

    # Routes with negative distances are rejected
    iex> Trains.Routes.new("A", "B", -3)
    {:error, :invalid_route}

    # Routes with same origin and destination are rejected
    iex> Trains.Routes.new("A", "A", 9)
    {:error, :invalid_route}

    # Routes with non single character origin or destination are rejected
    iex> Trains.Routes.new("AZ", "B", 10)
    {:error, :invalid_route}
    iex> Trains.Routes.new("A", "WUT", 20)
    {:error, :invalid_route}
  """
  def new(origin, destination, distance) do
    route = %Route{stops: [origin, destination], distance: distance}
    if is_valid?(route) && origin != destination do
      {:ok, route}
    else
      {:error, :invalid_route}
    end
  end

  @doc """
  Adds a stop to a given route

  ## Examples

    iex> Trains.Routes.add_stop(%Trains.Routes.Route{stops: ["A", "C"], distance: 10}, "B", 5)
    {:ok, %Trains.Routes.Route{stops: ["A", "C", "B"], distance: 15}}

    iex> Trains.Routes.add_stop(%Trains.Routes.Route{stops: ["A", "C"], distance: 5}, :error, 5)
    {:error, :invalid_route}

    # It does not allow negative distances
    iex> Trains.Routes.add_stop(%Trains.Routes.Route{stops: ["A", "C"], distance: 5}, "B", -5)
    {:error, :invalid_route}

    # It does not allow adding next step equal to current destination
    iex> Trains.Routes.add_stop(%Trains.Routes.Route{stops: ["A", "C"], distance: 5}, "C", 2)
    {:error, :invalid_route}
  """
  def add_stop(%Route{} = route, town, distance) do
    if (valid_town?(town) && valid_distance?(distance) && destination(route) != town) do
      {:ok, %Route{stops: route.stops ++ [town], distance: distance(route) + distance}}
    else
      {:error, :invalid_route}
    end
  end

  @doc """
  Validates a given route

  ## Examples

    # Empty routes are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: [], distance: 9})
    false

    # Routes with a single town are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["A"], distance: 9})
    false

    # Routes with non capital single character town names are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["a","B"], distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["A","BZ"], distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["","B"], distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: [:c,"B"], distance: 9})
    false

    # Routes with a single capitalized special char as town name are valid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["Ñ", "Ö"], distance: 9})
    true

    # Routes with negative distance are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["A","B"], distance: -3})
    false

    # Routes with non integer distances are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["A","B"], distance: "9"})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{stops: ["A","B"], distance: :error})
    false
  """
  def is_valid?(%Route{stops: stops, distance: distance}) do
    Enum.count(stops) > 1
      && Enum.all?(stops, &valid_town?(&1))
      && valid_distance?(distance)
  end

  @doc """
  Get origin for route

  ## Examples

    iex> Trains.Routes.origin(%Trains.Routes.Route{stops: ["C", "A", "F"], distance: 10})
    "C"
  """
  def origin(%Route{stops: [origin|_], distance: _}) do
    origin
  end

  @doc """
  Get destination for route

  ## Examples

    iex> Trains.Routes.destination(%Trains.Routes.Route{stops: ["C", "A", "F"], distance: 10})
    "F"
  """
  def destination(%Route{stops: stops, distance: _}) do
    hd(Enum.reverse(stops))
  end

  @doc """
  Get distance for route

  ## Examples

    iex> Trains.Routes.distance(%Trains.Routes.Route{stops: ["C", "A", "F"], distance: 10})
    10
  """
  def distance(%Route{stops: _, distance: distance}) do
    distance
  end

  @doc """
  Get destination for route

  ## Examples

    iex> Trains.Routes.num_stops(%Trains.Routes.Route{stops: ["A","B"], distance: 7})
    1

    iex> Trains.Routes.num_stops(%Trains.Routes.Route{stops: ["C", "A", "F"], distance: 10})
    2
  """
  def num_stops(%Route{stops: stops, distance: _}) do
    Enum.count(stops) - 1
  end

  defp valid_town?(town_name) when is_binary(town_name) do
    Regex.match?(@valid_name_regex, town_name)
  end

  defp valid_town?(_) do
    false
  end

  # Distances cannot be negative, yet we allow zero as a valid distance to allow boarding on a different station
  # of the same city if that happend to occur. This could be a little YAGNI, but I think it is worthy for the cost.
  defp valid_distance?(distance) when is_integer(distance) do
    distance >= 0
  end

  defp valid_distance?(_) do
    false
  end
end
