defmodule Refract.CLI.Commands.ShapesShow do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Answer
  alias Refract.CLI.Ctx
  alias Refract.CLI.Option
  alias Refract.CLI.ShapesFolder
  alias Refract.Shape
  alias Refract.Validate.Issue
  alias Refract.Validate.Rules

  @impl Refract.CLI.Command
  def name, do: "shapes show"

  @impl Refract.CLI.Command
  def summary, do: "a shape readable: its columns, the headers they match, their rules"

  @impl Refract.CLI.Command
  def example, do: "refract shapes show --shape accounts"

  @impl Refract.CLI.Command
  def options do
    [
      {:shape, %Option{type: :string, value: "NAME", text: "the shape's name", required: true}},
      ShapesFolder.option()
    ]
  end

  @impl Refract.CLI.Command
  def input, do: :none

  @impl Refract.CLI.Command
  def run(%Ctx{options: options} = ctx) do
    with {:ok, folder} <- ShapesFolder.locate(ctx),
         {:ok, file, shape} <- ShapesFolder.fetch(folder, Keyword.fetch!(options, :shape)),
         do: {:answer, shape_answer(file, shape)}
  end

  defp shape_answer(file, %Shape{validation: validation} = shape) do
    %Answer{
      title: "#{shape.name}, version #{shape.version} (#{file})",
      table: Refract.Table.new(nil, ["column", "header", "rules"], %{}, column_rows(shape)),
      footer: together_text(validation.unique)
    }
  end

  defp column_rows(%Shape{spec: spec, validation: validation}) do
    spec.header.columns
    |> Enum.sort()
    |> Enum.map(fn {column, aliases} ->
      %{
        "column" => column,
        "header" => Enum.map_join(aliases, ", ", &alias_text/1),
        "rules" => rules_text(column, validation)
      }
    end)
  end

  defp alias_text(%Regex{} = regex), do: inspect(regex)
  defp alias_text(text), do: text

  defp rules_text(column, %Rules{columns: columns, unique: unique}) do
    columns
    |> Map.get(column, [])
    |> Kernel.++(unique_rule([column] in unique))
    |> Enum.map_join(", ", &Issue.describe_rule/1)
  end

  defp unique_rule(true), do: [:unique]
  defp unique_rule(false), do: []

  defp together_text(unique) do
    case for [_, _ | _] = columns <- unique, do: Issue.describe_rule({:unique, columns}) do
      [] -> nil
      lines -> Enum.join(lines, "\n")
    end
  end
end
