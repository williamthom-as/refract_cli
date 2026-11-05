defmodule Refract.CLI.Match do
  @moduledoc false

  alias Refract.Parse
  alias Refract.Rows
  alias Refract.Validate

  @enforce_keys [:column, :rule, :keep]

  defstruct [:column, :rule, :keep]

  @type t :: %__MODULE__{
          column: String.t(),
          rule: Refract.Validate.Rules.rule(),
          keep: :pass | :fail
        }

  @pattern ~r/^([^=!<>~:]+)(!=|>=|<=|=|>|<|~|:)(.+)$/su

  @bounds %{">=" => :min, "<=" => :max, ">" => :above, "<" => :below}

  @spec read_all([String.t()]) :: {:ok, [t()]} | {:usage, String.t()}

  def read_all(texts) do
    texts
    |> Enum.reduce_while({:ok, []}, &add_match/2)
    |> reverse_matches()
  end

  @spec all_pass?([t()], Refract.row()) :: boolean()

  def all_pass?(matches, row), do: Enum.all?(matches, &keeps_row?(&1, row))

  defp add_match(text, {:ok, matches}) do
    case read_match(text) do
      {:ok, match} -> {:cont, {:ok, [match | matches]}}
      usage -> {:halt, usage}
    end
  end

  defp reverse_matches({:ok, matches}), do: {:ok, Enum.reverse(matches)}
  defp reverse_matches(usage), do: usage

  defp read_match(text) do
    case Regex.run(@pattern, text, capture: :all_but_first) do
      [column, operator, value] -> match(String.trim(column), operator, value, text)
      nil -> unreadable(text)
    end
  end

  defp match(column, "=", value, _text), do: {:ok, new(column, {:in, [value]}, :pass)}
  defp match(column, "!=", value, _text), do: {:ok, new(column, {:in, [value]}, :fail)}
  defp match(column, ":", "present", _text), do: {:ok, new(column, :required, :pass)}
  defp match(column, ":", "blank", _text), do: {:ok, new(column, :required, :fail)}
  defp match(_column, ":", _word, text), do: unreadable(text)

  defp match(column, "~", value, text),
    do: value |> Regex.compile("u") |> regex_match(column, value, text)

  defp match(column, operator, value, text),
    do: value |> Parse.number(currency: true) |> bound_match(column, operator, value, text)

  defp regex_match({:ok, regex}, column, _value, _text), do: {:ok, new(column, regex, :pass)}

  defp regex_match({:error, _reason}, _column, value, text),
    do: {:usage, "#{value} in #{text} is not a regular expression"}

  defp bound_match({:ok, number}, column, operator, _value, _text),
    do: {:ok, new(column, {Map.fetch!(@bounds, operator), number}, :pass)}

  defp bound_match({:error, _reason}, _column, _operator, value, text),
    do: {:usage, "#{value} in #{text} is not a number"}

  defp unreadable(text), do: {:usage, "cannot read the match #{text}"}

  defp new(column, rule, keep), do: %__MODULE__{column: column, rule: rule, keep: keep}

  defp keeps_row?(%__MODULE__{column: column} = match, row),
    do: row |> Rows.blank?(column) |> keeps_value?(match, Map.fetch!(row, column))

  defp keeps_value?(true, %__MODULE__{keep: keep}, _cell), do: keep == :fail

  defp keeps_value?(false, %__MODULE__{rule: rule, keep: keep}, cell),
    do: Validate.passes?(rule, cell) == (keep == :pass)
end
