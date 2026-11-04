defmodule Refract.CLI.FileShape do
  @moduledoc false

  alias Refract.Table.ColumnNames

  @spec from_header(String.t(), [Refract.cell()]) :: Refract.Shape.t()

  def from_header(name, header) do
    key = header |> ColumnNames.from() |> Enum.zip(header) |> first_named_key()

    Refract.Shape.new(
      name: name,
      spec: Refract.Table.spec(header: [columns: %{key => [key]}, min_matches: 1])
    )
  end

  defp first_named_key(columns) do
    Enum.find_value(columns, fn {key, cell} -> if not blank?(cell), do: key end)
  end

  defp blank?(nil), do: true
  defp blank?(cell), do: cell |> to_string() |> String.trim() == ""
end
