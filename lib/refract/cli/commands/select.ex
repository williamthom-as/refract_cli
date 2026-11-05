defmodule Refract.CLI.Commands.Select do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Option

  @impl Refract.CLI.Command
  def name, do: "select"

  @impl Refract.CLI.Command
  def summary, do: "only the columns given, in that order"

  @impl Refract.CLI.Command
  def example, do: "refract select --col Customer --col Amount --input accounts.csv"

  @impl Refract.CLI.Command
  def options do
    [
      col: %Option{
        type: :list,
        value: "COLUMN",
        text: "a column key, repeat for more, written in the order given",
        required: true
      }
    ]
  end

  @impl Refract.CLI.Command
  def kind, do: :data

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    columns = options |> Keyword.fetch!(:col) |> Enum.uniq()

    with {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, columns),
         {:ok, rows} <- Input.rows(input) do
      {:data, Refract.Table.new(nil, columns, %{}, Refract.Rows.take(rows, columns))}
    end
  end
end
