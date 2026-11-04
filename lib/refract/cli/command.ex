defmodule Refract.CLI.Command do
  @moduledoc """
  behaviour for a `refract` command, built in or from a plugin.

  `use Refract.CLI.Command` gives the defaults: no switches of its own, one input.

  a command is stateless, `run/1` takes a context and returns a result that CLI mod
  reads, outputs and exits.

  - `{:answer, %Refract.CLI.Answer{}}` something found out, a report or with `--csv` rows
  - `{:data, %Refract.Table{}}` rows, csv by default, `--output` or `--table`
  - `{:error, message}`
  """

  @type result ::
          {:answer, Refract.CLI.Answer.t()} | {:data, Refract.Table.t()} | {:error, String.t()}

  @callback name() :: String.t()

  @callback summary() :: String.t()

  @callback example() :: String.t()

  @callback switches() :: OptionParser.options()

  @callback input() :: :one | :none

  @callback run(Refract.CLI.Ctx.t()) :: result()

  defmacro __using__(_opts) do
    quote do
      @behaviour Refract.CLI.Command

      @impl Refract.CLI.Command
      def switches, do: []

      @impl Refract.CLI.Command
      def input, do: :one

      defoverridable switches: 0, input: 0
    end
  end
end
