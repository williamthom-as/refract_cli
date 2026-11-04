defmodule Refract.CLI.ReleaseTest do
  use Refract.CLI.Case, async: true

  @moduletag :release
  @moduletag timeout: 60_000

  @refract Path.expand("_build/prod/rel/refract_cli/bin/refract")

  @columns """
  #  column       header
  1  Customer ID  " Customer ID "
  2  Name         Name
  3  Email        Email
  4  col_3        (blank)
  5  Balance      Balance
  6  Balance_2    Balance
  """

  test "the built command runs a command, with an open stdin that is never read" do
    assert System.cmd(@refract, ["columns", "--input", fixture("customers.csv")]) == {@columns, 0}
  end

  @tag :tmp_dir
  test "an argument with spaces reaches the command whole", %{tmp_dir: dir} do
    path = Path.join(dir, "my customers.csv")
    File.cp!(fixture("customers.csv"), path)

    assert System.cmd(@refract, ["columns", "--input", path]) == {@columns, 0}
  end

  test "piped in from the shell" do
    assert System.cmd("sh", ["-c", "cat #{fixture("customers.csv")} | #{@refract} columns"]) ==
             {@columns, 0}
  end

  test "a failing command exits 2 from the shell, its error on stderr" do
    assert {"refract: cannot read missing.csv: no such file\n", 2} =
             System.cmd(@refract, ["columns", "--input", "missing.csv"], stderr_to_stdout: true)
  end
end
