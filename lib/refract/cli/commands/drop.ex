defmodule Refract.CLI.Commands.Drop do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Option
  alias Refract.Table.ColumnNames

  @impl Refract.CLI.Command
  def name, do: "drop"

  @impl Refract.CLI.Command
  def summary, do: "every column but the ones given"

  @impl Refract.CLI.Command
  def example, do: "refract drop --col Email --col col_4 --input accounts.csv"

  @impl Refract.CLI.Command
  def options do
    [
      col: %Option{
        type: :list,
        value: "COLUMN",
        text: "a column key, repeat for more",
        required: true
      }
    ]
  end

  @impl Refract.CLI.Command
  def kind, do: :data

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    columns = Keyword.fetch!(options, :col)

    with {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, columns),
         {:ok, kept} <- kept_columns(ColumnNames.from(header), columns),
         {:ok, rows} <- Input.rows(input) do
      {:data, Refract.Table.new(nil, kept, %{}, Refract.Rows.take(rows, kept))}
    end
  end

  defp kept_columns(keys, columns), do: keys |> Enum.reject(&(&1 in columns)) |> kept_result()

  defp kept_result([]), do: {:usage, "that leaves no columns"}
  defp kept_result(kept), do: {:ok, kept}
end
