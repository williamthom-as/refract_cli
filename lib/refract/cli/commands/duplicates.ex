defmodule Refract.CLI.Commands.Duplicates do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Option
  alias Refract.Table.ColumnNames

  @impl Refract.CLI.Command
  def name, do: "duplicates"

  @impl Refract.CLI.Command
  def summary, do: "values, or combinations of columns, on more than one row, with their lines"

  @impl Refract.CLI.Command
  def example, do: ~s(refract duplicates --col "Account No" --input accounts.csv)

  @impl Refract.CLI.Command
  def options do
    [
      col: %Option{
        type: :keep,
        value: "COLUMN",
        text: "a column key, repeat for columns taken together",
        required: true
      }
    ]
  end

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    columns = Keyword.get_values(options, :col)

    with {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, columns),
         {:ok, rows} <- Input.rows(input) do
      repeated = rows |> Refract.Rows.group(by: columns) |> Enum.filter(&repeated?/1)

      {:answer, duplicates_answer(columns, ColumnNames.from(header), repeated)}
    end
  end

  defp repeated?({_values, [_first, _second | _rest]}), do: true
  defp repeated?({_values, _occurrences}), do: false

  defp duplicates_answer(columns, _keys, []) do
    %Answer{
      title: "no duplicates in #{Enum.join(columns, " and ")}",
      table: Refract.Table.new(nil, columns, %{}, [])
    }
  end

  defp duplicates_answer(columns, keys, repeated) do
    %Answer{
      table: Refract.Table.new(nil, keys, %{}, duplicated_rows(repeated)),
      shown:
        Refract.Table.new(
          nil,
          columns ++ ["lines"],
          %{},
          Enum.map(repeated, &shown_row(&1, columns))
        ),
      footer: footer(columns, repeated),
      found: true
    }
  end

  defp duplicated_rows(repeated) do
    Enum.flat_map(repeated, fn {_values, occurrences} ->
      Enum.map(occurrences, &elem(&1, 1))
    end)
  end

  defp shown_row({values, occurrences}, columns) do
    columns
    |> Enum.zip(values)
    |> Map.new()
    |> Map.put(
      "lines",
      Enum.map_join(occurrences, ", ", fn {position, _row} -> file_line(position) end)
    )
  end

  defp footer(columns, repeated) do
    rows =
      repeated |> Enum.map(fn {_values, occurrences} -> length(occurrences) end) |> Enum.sum()

    "#{duplicated_count(columns, length(repeated))}, #{rows} rows"
  end

  defp duplicated_count([_column], 1), do: "1 duplicated value"
  defp duplicated_count([_column], count), do: "#{count} duplicated values"
  defp duplicated_count(_columns, 1), do: "1 duplicated combination"
  defp duplicated_count(_columns, count), do: "#{count} duplicated combinations"

  defp file_line(position), do: position + 1
end
