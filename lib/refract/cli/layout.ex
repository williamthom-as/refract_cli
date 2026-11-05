defmodule Refract.CLI.Layout do
  @moduledoc false

  @gap "  "

  @spec text(Refract.Table.t()) :: String.t()

  def text(%Refract.Table{header: header, rows: rows}) do
    lines = [
      header | Enum.map(rows, fn row -> Enum.map(header, &cell_text(Map.get(row, &1))) end)
    ]

    columns = Enum.zip_with(lines, & &1)
    widths = Enum.map(columns, fn cells -> cells |> Enum.map(&String.length/1) |> Enum.max() end)
    sides = Enum.map(columns, &align_side/1)

    lines
    |> Enum.map_join(&(layout_line(&1, widths, sides) <> "\n"))
  end

  defp layout_line(cells, widths, sides) do
    [cells, widths, sides]
    |> Enum.zip_with(fn [cell, width, side] -> pad_cell(cell, width, side) end)
    |> Enum.join(@gap)
    |> String.trim_trailing()
  end

  defp pad_cell(cell, width, :left), do: String.pad_trailing(cell, width)
  defp pad_cell(cell, width, :right), do: String.pad_leading(cell, width)

  defp align_side([_header | values]), do: values |> Enum.all?(&number?/1) |> side(values)

  defp side(true, [_ | _]), do: :right
  defp side(_numbers, _values), do: :left

  defp number?(text), do: match?({_number, ""}, Integer.parse(text))

  defp cell_text(nil), do: ""
  defp cell_text(cell), do: to_string(cell)
end
