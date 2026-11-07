defmodule Refract.CLI.Commands do
  @moduledoc false

  alias Refract.CLI.Commands.Columns
  alias Refract.CLI.Commands.Distinct
  alias Refract.CLI.Commands.Drop
  alias Refract.CLI.Commands.Duplicates
  alias Refract.CLI.Commands.Select
  alias Refract.CLI.Commands.Shapes
  alias Refract.CLI.Commands.Stats
  alias Refract.CLI.Commands.Where

  @commands [Columns, Stats, Duplicates, Distinct, Select, Drop, Where, Shapes]

  @spec all() :: [module()]

  def all, do: @commands

  @spec fetch([String.t()]) :: {:ok, module(), [String.t()]} | :error

  def fetch([first, second | args] = words) do
    case named("#{first} #{second}") do
      nil -> fetch_one(words)
      command -> {:ok, command, args}
    end
  end

  def fetch(words), do: fetch_one(words)

  defp fetch_one([name | args]), do: name |> named() |> fetch_result(args)

  defp named(name), do: Enum.find(@commands, &(&1.name() == name))

  defp fetch_result(nil, _args), do: :error
  defp fetch_result(command, args), do: {:ok, command, args}
end
