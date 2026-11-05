defmodule Refract.CLI.Commands do
  @moduledoc false

  alias Refract.CLI.Commands.Columns
  alias Refract.CLI.Commands.Distinct
  alias Refract.CLI.Commands.Duplicates
  alias Refract.CLI.Commands.Stats

  @commands [Columns, Stats, Duplicates, Distinct]

  @spec all() :: [module()]

  def all, do: @commands

  @spec fetch(String.t()) :: {:ok, module()} | :error

  def fetch(name), do: @commands |> Enum.find(&(&1.name() == name)) |> fetch_result()

  defp fetch_result(nil), do: :error
  defp fetch_result(command), do: {:ok, command}
end
