defmodule Refract.CLI.Help do
  @moduledoc false

  alias Refract.CLI.Commands
  alias Refract.CLI.Option
  alias Refract.CLI.Plugins

  @options [
    input: {"--input FILE", "read FILE, else what is piped in"},
    output: {"--output FILE", "write rows to FILE, its extension picks the format"},
    csv: {"--csv", "the answer as csv rows"},
    table: {"--table", "the rows as a readable table"},
    input_opts: {"--input-opts K=V", "a reader option, repeat the flag for more"},
    output_opts: {"--output-opts K=V", "a writer option, repeat the flag for more"}
  ]

  @spec entry_text() :: String.t()

  def entry_text do
    """
    refract - quick answers and data jobs on csv files

    usage: refract COMMAND [options]   (refract COMMAND --help for its options)

    commands
    #{command_lines()}
    plugins: #{plugin_names()}
    """
  end

  @spec command(module()) :: String.t()

  def command(command) do
    """
    refract #{command.name()} - #{command.summary()}

    usage: #{usage(command)}

    options
    #{option_lines(command)}
    example
      #{command.example()}
    """
  end

  @spec usage(module()) :: String.t()

  def usage(command),
    do: Enum.join(["refract #{command.name()}" | Enum.map(flags(command), &usage_flag/1)], " ")

  @spec flag_name(atom()) :: String.t()

  def flag_name(name), do: "--" <> (name |> Atom.to_string() |> String.replace("_", "-"))

  defp flags(command) do
    {required, optional} =
      command.options()
      |> Enum.map(&own_flag/1)
      |> Enum.split_with(fn {_flag, _text, required, _repeat} -> required end)

    required ++ optional ++ common_flags(command)
  end

  defp own_flag({name, %Option{type: type, value: value, text: text, required: required}}),
    do: {flag_text(name, value), text, required, type == :keep}

  defp flag_text(name, nil), do: flag_name(name)
  defp flag_text(name, value), do: "#{flag_name(name)} #{value}"

  defp common_flags(command) do
    @options
    |> Keyword.take(flag_names(command.kind(), command.input()))
    |> Enum.map(fn {name, {flag, text}} ->
      {flag, text, false, name in [:input_opts, :output_opts]}
    end)
  end

  defp flag_names(:answer, :one), do: [:input, :output, :csv, :input_opts, :output_opts]
  defp flag_names(:answer, :none), do: [:output, :csv, :output_opts]
  defp flag_names(:data, :one), do: [:input, :output, :table, :input_opts, :output_opts]
  defp flag_names(:data, :none), do: [:output, :table, :output_opts]

  defp usage_flag({flag, _text, true, repeat}), do: flag <> repeat_mark(repeat)
  defp usage_flag({flag, _text, false, repeat}), do: "[#{flag}]" <> repeat_mark(repeat)

  defp repeat_mark(true), do: "..."
  defp repeat_mark(false), do: ""

  defp command_lines do
    commands = Enum.map(Commands.all(), &{&1.name(), &1.summary()})
    aligned_lines(commands)
  end

  defp option_lines(command) do
    command
    |> flags()
    |> Enum.map(fn {flag, text, _required, _repeat} -> {flag, text} end)
    |> aligned_lines()
  end

  defp aligned_lines(pairs) do
    width = pairs |> Enum.map(fn {left, _right} -> String.length(left) end) |> Enum.max()

    Enum.map_join(pairs, fn {left, right} ->
      "  #{String.pad_trailing(left, width)}  #{right}\n"
    end)
  end

  defp plugin_names, do: Plugins.names() |> Enum.join(", ") |> none_if_blank()

  defp none_if_blank(""), do: "none"
  defp none_if_blank(names), do: names
end
