defmodule Refract.CLI.Case do
  use ExUnit.CaseTemplate

  import ExUnit.CaptureIO

  using do
    quote do
      import Refract.CLI.Case
    end
  end

  def fixture(name), do: Path.join(["test", "fixtures", name])

  def refract(argv, opts \\ []) do
    stdin = Keyword.get(opts, :stdin, :terminal)

    {{code, out}, err} =
      with_io(:standard_error, fn ->
        with_io([input: piped(stdin)], fn -> Refract.CLI.run(argv, stdin: stdin) end)
      end)

    %{code: code, out: out, err: err}
  end

  defp piped(:terminal), do: ""
  defp piped(text), do: text
end
