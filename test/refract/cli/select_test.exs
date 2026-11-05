defmodule Refract.CLI.SelectTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  @customer_amount """
  Customer,Amount
  Acme Pty Ltd,1250.00
  Globex,0
  Initech,-42.50
  Globex Corp,10.00
  Umbrella,99.95
  Hooli,1250.00
  """

  defp accounts, do: fixture("accounts.csv")

  defp select_args, do: ["select", "--col", "Customer", "--col", "Amount"]

  test "the columns given, in that order" do
    assert refract(select_args() ++ ["--input", accounts()]) ==
             %{code: 0, out: @customer_amount, err: ""}
  end

  test "--table lays the rows out" do
    assert refract(select_args() ++ ["--input", accounts(), "--table"]) == %{
             code: 0,
             out: """
             Customer      Amount
             Acme Pty Ltd  1250.00
             Globex        0
             Initech       -42.50
             Globex Corp   10.00
             Umbrella      99.95
             Hooli         1250.00
             """,
             err: ""
           }
  end

  test "piped in, the same lines" do
    assert refract(select_args(), stdin: File.read!(accounts())) ==
             %{code: 0, out: @customer_amount, err: ""}
  end

  test "the rows of where piped on" do
    %{code: 0, out: kept} =
      refract(["where", "--match", "Email:blank", "--input", accounts()])

    assert refract(["select", "--col", "Customer"], stdin: kept) ==
             %{code: 0, out: "Customer\nGlobex\nUmbrella\n", err: ""}
  end

  @tag :tmp_dir
  test "--output writes the file, formulas escaped, nothing on stdout", %{tmp_dir: dir} do
    path = Path.join(dir, "out.csv")

    assert refract(select_args() ++ ["--input", accounts(), "--output", path]) ==
             %{code: 0, out: "", err: ""}

    assert File.read!(path) ==
             String.replace(@customer_amount, "-42.50", ~s("\t-42.50"))
  end

  test "--col is required" do
    assert %{code: 2, out: "", err: err} = refract(["select", "--input", accounts()])
    assert String.starts_with?(err, "refract select: --col is required\nusage: refract select")
  end

  test "an unknown column" do
    assert refract(["select", "--col", "Acct", "--input", accounts()]) == %{
             code: 2,
             out: "",
             err: "refract: no column Acct in test/fixtures/accounts.csv, see refract columns\n"
           }
  end
end
