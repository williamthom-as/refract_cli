defmodule Refract.CLI.Ctx do
  @moduledoc false

  alias Refract.CLI.Input
  alias Refract.CLI.Opts

  @enforce_keys [:command, :out]

  defstruct [
    :command,
    :out,
    :input,
    :output,
    csv: false,
    table: false,
    output_opts: [],
    options: []
  ]

  @type t :: %__MODULE__{
          command: module(),
          out: IO.device(),
          input: Input.t() | nil,
          output: Path.t() | nil,
          csv: boolean(),
          table: boolean(),
          output_opts: [Refract.CLI.Opts.pair()],
          options: keyword()
        }

  @spec new(module(), keyword(), Refract.CLI.stdin(), IO.device()) ::
          {:ok, t()} | {:error, String.t()}

  def new(command, opts, stdin, out) do
    {common, options} = Keyword.split(opts, Keyword.keys(Refract.CLI.common()))

    with {:ok, output_opts} <-
           Opts.parse(Keyword.get_values(common, :output_opts), "--output-opts"),
         {:ok, input} <- resolve_input(command.input(), common, stdin) do
      {:ok,
       %__MODULE__{
         command: command,
         out: out,
         input: input,
         output: Keyword.get(common, :output),
         csv: Keyword.get(common, :csv, false),
         table: Keyword.get(common, :table, false),
         output_opts: output_opts,
         options: options
       }}
    end
  end

  defp resolve_input(:none, _common, _stdin), do: {:ok, nil}

  defp resolve_input(:one, common, stdin),
    do: Input.resolve(Keyword.get(common, :input), Keyword.get_values(common, :input_opts), stdin)
end
