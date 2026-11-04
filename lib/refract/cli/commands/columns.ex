defmodule Refract.CLI.Commands.Columns do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.Table.ColumnNames

  @impl Refract.CLI.Command
  def name, do: "columns"

  @impl Refract.CLI.Command
  def summary, do: "the columns of a file: position, key, header as written"

  @impl Refract.CLI.Command
  def example, do: "refract columns --input customers.csv"

  @impl Refract.CLI.Command
  def run(%Ctx{input: input}) do
    with {:ok, header} <- Input.header(input), do: {:answer, columns_answer(header)}
  end

  defp columns_answer(header) do
    columns =
      header
      |> ColumnNames.from()
      |> Enum.zip(header)
      |> Enum.with_index(1)

    %Answer{
      table: table(["position", "column", "header"], columns, &header_cell/1),
      shown: table(["#", "column", "header"], columns, &shown_header/1)
    }
  end

  defp table([position, column, header] = names, columns, header_text) do
    rows =
      Enum.map(columns, fn {{key, cell}, index} ->
        %{position => index, column => key, header => header_text.(cell)}
      end)

    Refract.Table.new(nil, names, %{}, rows)
  end

  defp header_cell(nil), do: ""
  defp header_cell(cell), do: to_string(cell)

  defp shown_header(cell), do: cell |> header_cell() |> shown_text()

  defp shown_text(text), do: text |> String.trim() |> shown_text(text)

  defp shown_text("", _text), do: "(blank)"
  defp shown_text(text, text), do: text
  defp shown_text(_trimmed, text), do: ~s("#{text}")
end
