defmodule Refract.CLI do
  @moduledoc """
  the `refract` command:
  - `main/1` is the entry
  - `run/2` runs a command and returns exit code (0 nothing found, 1 something found, 2 an error)
  """

  alias Refract.CLI.Commands
  alias Refract.CLI.Ctx
  alias Refract.CLI.Help
  alias Refract.CLI.Option
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

  @type stdin :: String.t() | :terminal | {:pipe, IO.device()}

  @type switches :: [{atom(), :boolean | :string | :integer | :keep}]

  @spec main([String.t()]) :: no_return()

  def main(argv), do: argv |> run(stdin: stdin_source()) |> System.halt()

  @spec run([String.t()], [{:stdin, stdin()} | {:out, IO.device()} | {:err, IO.device()}]) ::
          0 | 1 | 2

  def run(argv, opts) do
    opts = Keyword.validate!(opts, [:stdin, out: :stdio, err: :stderr])
    stdin = Keyword.fetch!(opts, :stdin)
    out = Keyword.fetch!(opts, :out)
    err = Keyword.fetch!(opts, :err)

    argv
    |> run_command(stdin, out)
    |> print_result(out, err)
  end

  @spec common() :: switches()

  def common, do: @common

  defp run_command([], _stdin, _out), do: {:help, :stderr}
  defp run_command(["--help" | _args], _stdin, _out), do: {:help, :stdout}

  defp run_command([name | args], stdin, out),
    do: name |> Commands.fetch() |> parse_options(name, args, stdin, out)

  defp parse_options({:ok, command}, _name, args, stdin, out) do
    args
    |> OptionParser.parse(strict: @common ++ own_switches(command))
    |> check_options(command, stdin, out)
  end

  defp parse_options(:error, name, _args, _stdin, _out),
    do: {:error, "unknown command #{name}, see refract --help"}

  defp check_options({_opts, _args, [{switch, _value} | _invalid]}, command, _stdin, _out),
    do: {:usage, command, "unknown option #{switch}"}

  defp check_options({_opts, [arg | _args], []}, command, _stdin, _out),
    do: {:usage, command, "unexpected argument #{arg}"}

  defp check_options({opts, [], []}, command, stdin, out),
    do: opts |> Keyword.get(:help, false) |> help_or_run(command, opts, stdin, out)

  defp help_or_run(true, command, _opts, _stdin, _out), do: {:command_help, command}

  defp help_or_run(false, command, opts, stdin, out) do
    with :ok <- check_required(command, opts),
         {:ok, ctx} <- Ctx.new(command, opts, stdin, out),
         {kind, _result} = result when kind in [:answer, :data] <- command.run(ctx) do
      Output.render(result, ctx)
    else
      {:usage, message} -> {:usage, command, message}
      error -> error
    end
  end

  defp own_switches(command),
    do: Enum.map(command.options(), &own_switch/1)

  defp own_switch({name, %Option{type: :list}}), do: {name, :keep}
  defp own_switch({name, %Option{type: type}}), do: {name, type}

  defp check_required(command, opts) do
    command.options()
    |> Enum.find(fn {name, %Option{required: required}} ->
      required and not Keyword.has_key?(opts, name)
    end)
    |> required_result()
  end

  defp required_result(nil), do: :ok
  defp required_result({name, _option}), do: {:usage, "#{Help.flag_name(name)} is required"}

  defp print_result({:ok, code}, _out, _err), do: code

  defp print_result({:help, :stdout}, out, _err), do: write_output(out, Help.entry_text(), 0)
  defp print_result({:help, :stderr}, _out, err), do: write_output(err, Help.entry_text(), 2)

  defp print_result({:command_help, command}, out, _err),
    do: write_output(out, Help.command(command), 0)

  defp print_result({:usage, command, message}, _out, err) do
    write_output(
      err,
      "refract #{command.name()}: #{message}\nusage: #{Help.usage(command)}\n",
      2
    )
  end

  defp print_result({:error, message}, _out, err),
    do: write_output(err, "refract: #{message}\n", 2)

  defp write_output(device, text, code) do
    IO.write(device, text)
    code
  end

  defp stdin_source, do: stdin_source(stdin_terminal?())

  defp stdin_source(true), do: :terminal
  defp stdin_source(false), do: {:pipe, :stdio}

  defp stdin_terminal?, do: :prim_tty.isatty(:stdin)
end
