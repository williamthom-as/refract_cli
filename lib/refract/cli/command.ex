defmodule Refract.CLI.Command do
  @moduledoc """
  behaviour for a `refract` command, built in or from a plugin.

  `use Refract.CLI.Command` gives the defaults: no options of its own, one input, an answer (`kind/0` `:data` for rows).

  a command is stateless, `run/1` takes a context and returns a result that CLI mod
  reads, outputs and exits.

  - `{:answer, %Refract.CLI.Answer{}}` something found out, a report or with `--csv` rows
  - `{:data, %Refract.Table{}}` rows, csv by default, `--output` or `--table`
  - `{:usage, message}` the options were wrong, shown with the command's usage
  - `{:error, message}`
  """

  @type result ::
          {:answer, Refract.CLI.Answer.t()}
          | {:data, Refract.Table.t()}
          | {:usage, String.t()}
          | {:error, String.t()}

  @callback name() :: String.t()

  @callback summary() :: String.t()

  @callback example() :: String.t()

  @callback options() :: [{atom(), Refract.CLI.Option.t()}]

  @callback input() :: :one | :none

  @callback kind() :: :answer | :data

  @callback run(Refract.CLI.Ctx.t()) :: result()

  defmacro __using__(_opts) do
    quote do
      @behaviour Refract.CLI.Command

      @impl Refract.CLI.Command
      def options, do: []

      @impl Refract.CLI.Command
      def input, do: :one

      @impl Refract.CLI.Command
      def kind, do: :answer

      defoverridable options: 0, input: 0, kind: 0
    end
  end
end
