defmodule Refract.CLI.Commands.Where do
  @moduledoc false

  use Refract.CLI.Command

  alias Refract.CLI.Ctx
  alias Refract.CLI.Input
  alias Refract.CLI.Match
  alias Refract.CLI.Option
  alias Refract.Table.ColumnNames

  @impl Refract.CLI.Command
  def name, do: "where"

  @impl Refract.CLI.Command
  def summary, do: "the rows where every match holds"

  @impl Refract.CLI.Command
  def example,
    do: ~s(refract where --match "Status=open" --match "Amount>100" --input accounts.csv)

  @impl Refract.CLI.Command
  def options do
    [
      match: %Option{
        type: :list,
        value: "MATCH",
        text:
          "COLUMN=TEXT, !=, >, >=, <, <=, COLUMN:blank, COLUMN:present or COLUMN~REGEX; " <>
            "repeat, every one must hold",
        required: true
      }
    ]
  end

  @impl Refract.CLI.Command
  def kind, do: :data

  @impl Refract.CLI.Command
  def run(%Ctx{input: input, options: options}) do
    with {:ok, matches} <- Match.read_all(Keyword.fetch!(options, :match)),
         {:ok, header} <- Input.header(input),
         :ok <- Input.check_columns(input, header, Enum.map(matches, & &1.column)),
         {:ok, rows} <- Input.rows(input) do
      kept = Stream.filter(rows, &Match.all_pass?(matches, &1))

      {:data, Refract.Table.new(nil, ColumnNames.from(header), %{}, kept)}
    end
  end
end
