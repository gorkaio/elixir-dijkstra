defmodule Trains.Routes do

  @moduledoc """
  Routes module
  """

  @valid_name_regex ~r/^\p{Lu}$/u

  defmodule Route do
    @moduledoc "Route structure"
    @enforce_keys [:origin, :destination, :distance]
    defstruct [origin: nil, destination: nil, distance: 0]
  end

  alias Trains.Routes.Route

  @doc """
  Create new Route

  ## Examples

    # Valid routes are properly created
    iex> Trains.Routes.new("A", "B", 5)
    {:ok, %Trains.Routes.Route{origin: "A", destination: "B", distance: 5}}

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
    route = %Route{origin: origin, destination: destination, distance: distance}
    if is_valid?(route) do
      {:ok, route}
    else
      {:error, :invalid_route}
    end
  end

  @doc """
  Validates a given route

  ## Examples

    # Routes with same origin and destination are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "A", destination: "A", distance: 9})
    false

    # Routes with non capital single character town names are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "a", destination: "B", distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "A", destination: "BZ", distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "", destination: "B", distance: 9})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: :c, destination: "B", distance: 9})
    false

    # Routes with a single capitalized special char as town name are valid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "Ñ", destination: "Ö", distance: 9})
    true

    # Routes with negative distance are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "A", destination: "B", distance: -3})
    false

    # Routes with non integer distances are invalid
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "", destination: "B", distance: "9"})
    false
    iex> Trains.Routes.is_valid?(%Trains.Routes.Route{origin: "", destination: "B", distance: :error})
    false
  """
  def is_valid?(%Route{origin: origin, destination: destination, distance: distance}) do
    valid_town?(origin) && valid_town?(destination)
      && origin != destination
      && valid_distance(distance)
  end

  defp valid_town?(town_name) when is_binary(town_name) do
    Regex.match?(@valid_name_regex, town_name)
  end

  defp valid_town?(_) do
    false
  end

  defp valid_distance(distance) when is_integer(distance) do
    distance >= 0
  end

  defp valid_distance(_) do
    false
  end
end
