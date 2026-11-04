defmodule Refract.CLI do
  @moduledoc """
  the `refract` command:
  - `main/1` is the entry
  - `run/2` runs a command and returns exit code (0 nothing found, 1 something found, 2 an error)
  """

  alias Refract.CLI.Commands
  alias Refract.CLI.Ctx
  alias Refract.CLI.Help
  alias Refract.CLI.Output

  @common [
    input: :string,
    output: :string,
    csv: :boolean,
    table: :boolean,
    input_opts: :keep,
    output_opts: :keep,
    help: :boolean
  ]

  @type stdin :: String.t() | :terminal

  @spec main([String.t()]) :: no_return()

  def main(argv), do: argv |> run(stdin: read_stdin()) |> System.halt()

  @spec run([String.t()], [{:stdin, stdin()}]) :: 0 | 1 | 2

  def run(argv, opts) do
    opts = Keyword.validate!(opts, [:stdin])
    stdin = Keyword.fetch!(opts, :stdin)

    argv
    |> run_command(stdin)
    |> print_result()
  end

  @spec common() :: OptionParser.options()

  def common, do: @common

  defp run_command([], _stdin), do: {:help, :stderr}
  defp run_command(["--help" | _args], _stdin), do: {:help, :stdout}

  defp run_command([name | args], stdin),
    do: name |> Commands.fetch() |> parse_options(name, args, stdin)

  defp parse_options({:ok, command}, _name, args, stdin) do
    args
    |> OptionParser.parse(strict: @common ++ command.switches())
    |> check_options(command, stdin)
  end

  defp parse_options(:error, name, _args, _stdin),
    do: {:error, "unknown command #{name}, see refract --help"}

  defp check_options({_opts, _args, [{switch, _value} | _invalid]}, command, _stdin),
    do: {:usage, command, "unknown option #{switch}"}

  defp check_options({_opts, [arg | _args], []}, command, _stdin),
    do: {:usage, command, "unexpected argument #{arg}"}

  defp check_options({opts, [], []}, command, stdin),
    do: opts |> Keyword.get(:help, false) |> help_or_run(command, opts, stdin)

  defp help_or_run(true, command, _opts, _stdin), do: {:command_help, command}

  defp help_or_run(false, command, opts, stdin) do
    with {:ok, ctx} <- Ctx.new(command, opts, stdin),
         {kind, _result} = result when kind in [:answer, :data] <- command.run(ctx),
         do: Output.render(result, ctx)
  end

  defp print_result({:ok, code}), do: code

  defp print_result({:help, :stdout}), do: write_output(:stdio, Help.text(), 0)
  defp print_result({:help, :stderr}), do: write_output(:stderr, Help.text(), 2)
  defp print_result({:command_help, command}), do: write_output(:stdio, Help.command(command), 0)

  defp print_result({:usage, command, message}) do
    write_output(
      :stderr,
      "refract #{command.name()}: #{message}\nusage: #{Help.usage(command)}\n",
      2
    )
  end

  defp print_result({:error, message}), do: write_output(:stderr, "refract: #{message}\n", 2)

  defp write_output(device, text, code) do
    IO.write(device, text)
    code
  end

  defp read_stdin, do: read_stdin(stdin_terminal?())

  defp read_stdin(true), do: :terminal
  defp read_stdin(false), do: :stdio |> IO.read(:eof) |> piped_text()

  defp piped_text(:eof), do: ""
  defp piped_text(text), do: text

  defp stdin_terminal?, do: :prim_tty.isatty(:stdin)
end
