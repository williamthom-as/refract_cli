defmodule Refract.CLI.Opts do
  @moduledoc false

  @type pair :: {String.t(), term()}

  @spec parse([String.t()], String.t()) :: {:ok, [pair()]} | {:error, String.t()}

  def parse(texts, flag) do
    texts
    |> Enum.reduce_while({:ok, []}, &add_pair(&1, &2, flag))
    |> reverse_pairs()
  end

  @spec to_options([pair()], keyword(), String.t()) :: {:ok, keyword()} | {:error, String.t()}

  def to_options(pairs, defaults, owner) do
    known = Map.new(defaults, fn {key, _default} -> {Atom.to_string(key), key} end)

    pairs
    |> Enum.reduce_while({:ok, []}, &add_known_option(&1, &2, known, owner))
    |> reverse_pairs()
  end

  defp add_pair(text, {:ok, pairs}, flag) do
    text
    |> String.split("=", parts: 2)
    |> split_pair(text, flag)
    |> collect_pair(pairs)
  end

  defp split_pair([key, value], _text, _flag) when key != "",
    do: {:ok, {key, convert_value(value)}}

  defp split_pair(_parts, text, flag), do: {:error, "#{flag} takes key=value, got #{text}"}

  defp add_known_option({key, value}, {:ok, options}, known, owner) do
    known
    |> Map.fetch(key)
    |> known_option(key, value, owner)
    |> collect_pair(options)
  end

  defp known_option({:ok, atom}, _key, value, _owner), do: {:ok, {atom, value}}
  defp known_option(:error, key, _value, owner), do: {:error, "#{owner} does not take #{key}"}

  defp collect_pair({:ok, pair}, pairs), do: {:cont, {:ok, [pair | pairs]}}
  defp collect_pair(error, _pairs), do: {:halt, error}

  defp reverse_pairs({:ok, pairs}), do: {:ok, Enum.reverse(pairs)}
  defp reverse_pairs(error), do: error

  defp convert_value("true"), do: true
  defp convert_value("false"), do: false
  defp convert_value(value), do: value |> Integer.parse() |> whole_number(value)

  defp whole_number({number, ""}, _value), do: number
  defp whole_number(_parsed, value), do: value
end
