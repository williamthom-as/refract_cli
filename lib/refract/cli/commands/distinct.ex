defmodule Refract.CLI.Commands.Distinct do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Option

  @impl Refract.CLI.Command
  def name, do: "distinct"

  @impl Refract.CLI.Command
  def summary, do: "the values in columns with their counts, most common first"

  @impl Refract.CLI.Command
  def example, do: "refract distinct --col Status --input accounts.csv"

  @impl Refract.CLI.Command
  def options do
    [
      col: %Option{
        type: :list,
        value: "COLUMN",
        text: "a column key, repeat for a table each",
        required: true
      }
    ]
  end

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    columns = Keyword.fetch!(options, :col)

    with {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, columns),
         {:ok, rows} <- Input.rows(input) do
      {:answer, distinct_answer(Enum.map(columns, &{&1, value_counts(rows, &1)}))}
    end
  end

  defp value_counts(rows, column) do
    rows
    |> Refract.Rows.group(by: column, blanks: :keep, keep_rows: false)
    |> Enum.map(fn {[value], positions} -> {value, length(positions)} end)
    |> Enum.split_with(fn {value, _count} -> value not in ["", nil] end)
    |> then(fn {values, blanks} -> values ++ blanks end)
  end

  defp distinct_answer(counted) do
    %Answer{
      table:
        Refract.Table.new(
          nil,
          ["column", "value", "count"],
          %{},
          Enum.flat_map(counted, &csv_rows/1)
        ),
      shown: Enum.map(counted, &shown_table/1)
    }
  end

  defp csv_rows({column, counts}) do
    Enum.map(counts, fn {value, count} ->
      %{"column" => column, "value" => value, "count" => count}
    end)
  end

  defp shown_table({column, counts}) do
    rows =
      Enum.map(counts, fn {value, count} -> %{column => shown_value(value), "count" => count} end)

    Refract.Table.new(nil, [column, "count"], %{}, rows)
  end

  defp shown_value(value) when value in ["", nil], do: "(blank)"
  defp shown_value(value), do: value
end
