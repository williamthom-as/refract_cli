defmodule Refract.CLI.Commands.Validate do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Option
  alias Refract.CLI.ShapesFolder
  alias Refract.Validate.Issue

  @impl Refract.CLI.Command
  def name, do: "validate"

  @impl Refract.CLI.Command
  def summary, do: "a file against a shape: every issue with its line"

  @impl Refract.CLI.Command
  def example, do: "refract validate --shape accounts --input accounts.csv"

  @impl Refract.CLI.Command
  def options do
    [
      {:shape,
       %Option{
         type: :string,
         value: "NAME",
         text: "the shape's name, see refract shapes",
         required: true
       }},
      {:identify_by,
       %Option{
         type: :list,
         value: "COLUMN",
         text: "a shape column shown beside each issue, repeat for more"
       }},
      {:no_values, %Option{type: :boolean, value: nil, text: "leave the cells' values out"}},
      ShapesFolder.option()
    ]
  end

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options} = ctx) do
    identify_by = Keyword.fetch!(options, :identify_by)
    values = not Keyword.get(options, :no_values, false)

    with {:ok, folder} <- ShapesFolder.locate(ctx),
         {:ok, _file, shape} <- ShapesFolder.fetch(folder, Keyword.fetch!(options, :shape)),
         :ok <- check_identify_by(shape, identify_by),
         {:ok, result} <-
           Input.validate(input, shape, values: values, identify_by: identify_by(identify_by)) do
      {:answer, validate_answer(result.issues, input, shape, {identify_by, values})}
    end
  end

  defp identify_by([]), do: nil
  defp identify_by(columns), do: columns

  defp check_identify_by(shape, columns) do
    case Enum.reject(columns, &Map.has_key?(shape.spec.header.columns, &1)) do
      [] ->
        :ok

      [column | _rest] ->
        {:error, "no column #{column} in shape #{shape.name}, see refract shapes show"}
    end
  end

  defp validate_answer([], input, shape, columns) do
    %Answer{
      title: "#{input.name} fits #{shape.name}, no issues",
      table: Refract.Table.new(nil, csv_columns(columns), %{}, [])
    }
  end

  defp validate_answer(issues, _input, _shape, columns) do
    rows = Enum.map(issues, &issue_row/1)

    %Answer{
      table: Refract.Table.new(nil, csv_columns(columns), %{}, rows),
      shown: Refract.Table.new(nil, shown_columns(columns), %{}, Enum.map(rows, &shown_row/1)),
      footer:
        "#{count_text(length(issues), "issue")} on #{count_text(rows_with_issues(issues), "row")}",
      found: true
    }
  end

  defp csv_columns(columns), do: shown_columns(columns) ++ ["first_line"]

  defp shown_columns({identify_by, values}),
    do: ["line"] ++ identify_by ++ ["column", "issue"] ++ value_column(values)

  defp value_column(true), do: ["value"]
  defp value_column(false), do: []

  defp issue_row(%Issue{} = issue) do
    Map.merge(issue.record || %{}, %{
      "line" => issue.line,
      "column" => issue_column(issue),
      "issue" => Issue.describe_rule(issue.rule),
      "value" => issue.value,
      "first_line" => issue.first_line
    })
  end

  defp issue_column(%Issue{column: nil, field: field}) when is_binary(field), do: "field #{field}"
  defp issue_column(%Issue{column: column}), do: column

  defp shown_row(%{"first_line" => nil} = row), do: row

  defp shown_row(%{"first_line" => line} = row),
    do: Map.update!(row, "issue", &"#{&1}, first on line #{line}")

  defp rows_with_issues(issues),
    do: issues |> Enum.map(& &1.line) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> length()

  defp count_text(1, noun), do: "1 #{noun}"
  defp count_text(count, noun), do: "#{count} #{noun}s"
end
