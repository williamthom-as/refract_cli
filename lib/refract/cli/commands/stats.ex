defmodule Refract.CLI.Commands.Stats do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.FileShape
  alias Refract.CLI.Input
  alias Refract.Profile.Column
  alias Refract.Table.ColumnNames

  @profile_opts [header_row: 1, columns: :all, values: true, fuzzy: false, max_lines: 1]

  @impl Refract.CLI.Command
  def name, do: "stats"

  @impl Refract.CLI.Command
  def summary, do: "per column: blanks, distinct values, the most common value"

  @impl Refract.CLI.Command
  def example, do: "refract stats --input customers.csv"

  @impl Refract.CLI.Command
  def run(%Ctx{input: input}) do
    with {:ok, header} <- Input.header(input),
         {:ok, result} <- profile(input, header),
         do: {:answer, stats_answer(input, ColumnNames.from(header), result)}
  end

  defp profile(%Input{name: name, source: source, reader: reader, opts: opts} = input, header) do
    with {:error, reason} <-
           reader.profile(source, FileShape.from_header(name, header), @profile_opts ++ opts),
         do: {:error, Input.read_error(input, reason)}
  end

  defp stats_answer(%Input{name: name}, keys, %Refract.Profile.Result{
         rows: rows,
         columns: columns
       }) do
    stats = Enum.map(keys, &{&1, Map.fetch!(columns, &1)})

    %Answer{
      title: "#{name}  #{rows} rows  #{length(keys)} columns",
      table:
        Refract.Table.new(
          nil,
          ["column", "blanks", "distinct", "most_common", "most_common_count"],
          %{},
          Enum.map(stats, &stats_row/1)
        ),
      shown:
        Refract.Table.new(
          nil,
          ["column", "blanks", "distinct", "most common"],
          %{},
          Enum.map(stats, &shown_row/1)
        )
    }
  end

  defp stats_row({key, %Column{blanks: blanks} = column}) do
    {value, count} = most_common(column)

    %{
      "column" => key,
      "blanks" => blanks,
      "distinct" => distinct(column),
      "most_common" => value,
      "most_common_count" => count
    }
  end

  defp shown_row({key, %Column{blanks: blanks} = column}) do
    %{
      "column" => key,
      "blanks" => blanks,
      "distinct" => distinct(column),
      "most common" => column |> most_common() |> shown_most_common()
    }
  end

  defp most_common(%Column{
         values: [%Refract.Profile.Variant{value: value, count: count} | _rest]
       }),
       do: {value, count}

  defp most_common(%Column{}), do: {nil, nil}

  defp shown_most_common({nil, nil}), do: "-"
  defp shown_most_common({value, count}), do: "#{value} (#{count})"

  defp distinct(%Column{capped: true}), do: "5000+"
  defp distinct(%Column{distinct: distinct}), do: distinct
end
