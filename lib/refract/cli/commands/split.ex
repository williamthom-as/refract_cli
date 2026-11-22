defmodule Refract.CLI.Commands.Split do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Layout
  alias Refract.CLI.Option
  alias Refract.Table.ColumnNames

  @impl Refract.CLI.Command
  def name, do: "split"

  @impl Refract.CLI.Command
  def summary, do: "rows into files, so many a file or one per value"

  @impl Refract.CLI.Command
  def example, do: "refract split --by Status --input accounts.csv --output out/accounts.csv"

  @impl Refract.CLI.Command
  def options do
    [
      output: %Option{
        type: :string,
        value: "FILE",
        text: "names the files, accounts.csv gives accounts_1.csv or accounts_open.csv",
        required: true
      },
      rows: %Option{type: :integer, value: "N", text: "this many rows a file"},
      by: %Option{
        type: :list,
        value: "COLUMN",
        text: "a file per value, repeat for a file per combination"
      }
    ]
  end

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    output = Keyword.fetch!(options, :output)

    with {:ok, mode} <- split_mode(Keyword.get(options, :rows), Keyword.fetch!(options, :by)),
         {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, by_columns(mode)),
         {:ok, rows} <- Input.rows(input) do
      {:answer,
       split_answer(by_columns(mode), ColumnNames.from(header), parts(mode, rows, output))}
    end
  end

  defp split_mode(nil, []), do: {:usage, "give --rows N or --by COLUMN"}
  defp split_mode(nil, by), do: {:ok, {:by, by}}
  defp split_mode(rows, []) when rows > 0, do: {:ok, {:rows, rows}}
  defp split_mode(_rows, []), do: {:usage, "--rows must be a whole number above 0"}
  defp split_mode(_rows, _by), do: {:usage, "give --rows or --by, not both"}

  defp by_columns({:by, by}), do: by
  defp by_columns({:rows, _rows}), do: []

  defp parts({:rows, count}, rows, output) do
    rows
    |> Enum.chunk_every(count)
    |> Enum.with_index(1)
    |> Enum.map(fn {chunk, index} -> {[], part_path(output, index), chunk} end)
  end

  defp parts({:by, by}, rows, output) do
    {parts, _taken} =
      rows
      |> Refract.Rows.group(by: by, blanks: :keep)
      |> Enum.map_reduce(MapSet.new(), &group_part(&1, &2, output))

    parts
  end

  defp group_part({values, occurrences}, taken, output) do
    name = values |> Enum.map_join("_", &name_part/1) |> free_name(taken, 1)
    rows = Enum.map(occurrences, fn {_position, row} -> row end)

    {{values, part_path(output, name), rows}, MapSet.put(taken, String.downcase(name))}
  end

  defp name_part(value) when value in ["", nil], do: "blank"
  defp name_part(value), do: value |> to_string() |> String.replace(~r/[^A-Za-z0-9._-]/u, "_")

  defp free_name(name, taken, count) do
    candidate = numbered_name(name, count)

    taken
    |> MapSet.member?(String.downcase(candidate))
    |> free_or_next(candidate, name, taken, count)
  end

  defp free_or_next(false, candidate, _name, _taken, _count), do: candidate
  defp free_or_next(true, _candidate, name, taken, count), do: free_name(name, taken, count + 1)

  defp numbered_name(name, 1), do: name
  defp numbered_name(name, count), do: "#{name}_#{count}"

  defp part_path(output, suffix),
    do: "#{Path.rootname(output)}_#{suffix}#{Path.extname(output)}"

  defp split_answer(by, _header, []),
    do: %Answer{
      title: "no rows, no files written",
      table: Refract.Table.new(nil, by ++ ["file", "rows"], %{}, [])
    }

  defp split_answer(by, header, parts) do
    columns = by ++ ["file", "rows"]

    %Answer{
      table: parts_table(columns, by, parts, fn value -> value end),
      shown: parts_table(columns, by, parts, &Layout.shown_value/1),
      writes: Enum.map(parts, fn {_values, path, rows} -> {path, header, rows} end)
    }
  end

  defp parts_table(columns, by, parts, show),
    do: Refract.Table.new(nil, columns, %{}, Enum.map(parts, &part_row(&1, by, show)))

  defp part_row({values, path, rows}, by, show) do
    by
    |> Enum.zip(Enum.map(values, show))
    |> Map.new()
    |> Map.merge(%{"file" => path, "rows" => length(rows)})
  end
end
