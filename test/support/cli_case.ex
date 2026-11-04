defmodule Refract.CLI.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Refract.CLI.Case
    end
  end

  def fixture(name), do: Path.join(["test", "fixtures", name])

  def refract(argv, opts \\ []) do
    {:ok, out} = StringIO.open("")
    {:ok, err} = StringIO.open("")

    code = Refract.CLI.run(argv, stdin: Keyword.get(opts, :stdin, :terminal), out: out, err: err)

    %{code: code, out: written(out), err: written(err)}
  end

  defp written(device), do: device |> StringIO.contents() |> elem(1)
end
