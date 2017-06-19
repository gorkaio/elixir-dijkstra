# Trains

_Trains_ is my take on the first ThoughtWorks tech assignment.

## Problem description

The local commuter railroad services a number of towns in Kiwiland.  Because of monetary concerns, all of the tracks
are 'one-way.'  That is, a route from Kaitaia to Invercargill does not imply the existence of a route from Invercargill
to Kaitaia.  In fact, even if both of these routes do happen to exist, they are distinct and are not necessarily the
same distance!
 
The purpose of this problem is to help the railroad provide its customers with information about the routes.
In particular, you will compute the distance along a certain route, the number of different routes between two towns,
and the shortest route between two towns.
 
### Input:  A directed graph where a node represents a town and an edge represents a route between two towns.
The weighting of the edge represents the distance between the two towns. A given route will never appear more than
once, and for a given route, the starting and ending town will not be the same town.
 
### Output: For test input 1 through 5, if no such route exists, output 'NO SUCH ROUTE'. Otherwise, follow the route
as given; do not make any extra stops!  For example, the first problem means to start at city A, then travel
directly to city B (a distance of 5), then directly to city C (a distance of 4).
1. The distance of the route `A-B-C`.
2. The distance of the route `A-D`.
3. The distance of the route `A-D-C`.
4. The distance of the route `A-E-B-C-D`.
5. The distance of the route `A-E-D`.
6. The number of trips starting at `C` and ending at `C` with *a maximum of 3 stops*. In the sample data below,
   there are two such trips: `C-D-C` (2 stops). and `C-E-B-C` (3 stops).
7. The number of trips starting at `A` and ending at `C` *with exactly 4 stops*. In the sample data below,
   there are three such trips: `A` to `C` (via `B,C,D`); `A` to `C` (via `D,C,D`); and `A` to `C` (via `D,E,B`).
8. The length of *the shortest route* (in terms of distance to travel) from `A` to `C`.
9. The length of *the shortest route* (in terms of distance to travel) from `B` to `B`.
10. The *number of different routes* from `C` to `C` with a *distance of less than 30*. In the sample data,
   the trips are: `CDC`, `CEBC`, `CEBCDC`, `CDCEBC`, `CDEBC`, `CEBCEBC`, `CEBCEBCEBC`.
 
### Test Input
For the test input, the towns are named using the first few letters of the alphabet from `A` to `D`. A route between
two towns (`A` to `B`) with a distance of 5 is represented as `AB5`.

*Graph*: `AB5, BC4, CD8, DC8, DE6, AD5, CE2, EB3, AE7`

*Expected Output*:
```
Output #1: 9
Output #2: 5
Output #3: 13
Output #4: 22
Output #5: NO SUCH ROUTE
Output #6: 2
Output #7: 3
Output #8: 9
Output #9: 9
Output #10: 7
```

## Solution

First of all: *why Elixir?*

There's a technical reason for that, of course: I think functional programming better fits this kind of problems and
Elixir absolutely beats the performance of my daily language, PHP. But that is not the real reason why I chose Elixir,
for good or bad.

In the previous interview you recommended me to use PHP for the assignment as this is the language I'm more used to, the
one I work with everyday and that I've being using professionally for many years. In fact that would have been much
easier for me, and the resulting code would be much nicer, well structured and clean.

But, as a matter of fact, PHP is not either in the proposed languages for the assignments and is probably not what I
would be using in my daily work at ThoughtWorks. So I thought it would be fair to use a language I'm not used to, one
that I'm just learning to use based on a paradigm I have not seen since my University years, and prove what I would be
capable of doing when confronted with a new language. Even if that implies that it took me more time than I expected
and the result is not as clean and well implemented as it would have been in PHP. There are many thing that could be
improved in this code, and I'm aware of some of them. But, all in all, I think it was the right decision.

*About the design decisions I made*, you can take a look at the documentation. I tried to use the ubiquitous language
derived from the problem description and model each part of the system accordingly. A `route` joins two or more `towns`,
first one of which is the `origin` and last the `destination`, and there is a certain `distance` that separates them.
A `graph` is composed of simple two step routes that configure the railroad map that will be used to calculate `trips`
following a certain route, `path` being the breadcrumb of such route. The `graph` is responsible for calculating the
possible routes between two towns: either using a certain criteria (maximum stops, maximum distance, fixed number of
stops) or finding the shortest route available between `origin` and `destination`.

I also implemented a basic parser capable of understanding basic `route` and `path` definitions in order to configure
the system and simplify the tests.

And, finally, there's the main `Trains` module that receives a `graph` configuration from the command line, parses it
and runs the proposed tests, rendering their output.

### Installation

If you don't have `Elixir` installed, you will need to install it following the [official installation docs](https://elixir-lang.org/install.html).

As an alternative method, you might use Docker. We will see both methods bellow.

You will first need to install dev dependencies to be able to generate docs:

  - With Elixir: `mix deps.get`
  - With Docker: `docker run -it --rm -v$(pwd):/app -w/app elixir bash -c "mix deps.get"`

### Build

You can build the app using the following command:

  - With Elixir: `MIX_ENV=prod mix escript.build`
  - With Docker: `docker run -it --rm -eMIX_ENV=prod -v$(pwd):/app -w/app elixir bash -c "mix escript.build"`
  
### Run

To run the app you must provide the graph configuration it will work with:

`./trains --config="AB5,BC4,CD8,DC8,DE6,AD5,CE2,EB3,AE7"`

This will run the proposed tests and show its output on the console.

## Run tests

Ro run all the tests, use the following command:

  - With Elixir: `mix test`
  - With Docker: `docker run -it --rm -v$(pwd):/app -w/app elixir bash -c "mix test"`

## Generate documentation

This documentation, and all the API docs, are generated using:

  - With Elixir: `mix docs`
  - With Docker: `docker run -it --rm -v$(pwd):/app -w/app elixir bash -c "mix docs"`
  
Once generated, you will find it in `/doc` folder, HTML formatted.

