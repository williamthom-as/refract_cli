defmodule Refract.CLI.DropTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  defp accounts, do: fixture("accounts.csv")

  test "the other columns, in the file's order" do
    assert refract([
             "drop",
             "--col",
             "Email",
             "--col",
             "col_4",
             "--col",
             "Amount_2",
             "--input",
             accounts()
           ]) == %{
             code: 0,
             out: """
             Account No,Customer,Opened On,Amount,Status
             A-1001,Acme Pty Ltd,31/01/2024,1250.00,open
             A-1002,Globex,15/02/2024,0,closed
             A-1003,Initech,03/03/2024,-42.50,open
             A-1002,Globex Corp,15/02/2024,10.00,open
             A-1004,Umbrella,,99.95,
             A-1005,Hooli,29/02/2024,1250.00,open
             """,
             err: ""
           }
  end

  test "an unknown column" do
    assert refract(["drop", "--col", "Acct", "--input", accounts()]) == %{
             code: 2,
             out: "",
             err: "refract: no column Acct in test/fixtures/accounts.csv, see refract columns\n"
           }
  end

  test "dropping every column is a usage error" do
    columns = [
      "Account No",
      "Customer",
      "Email",
      "Opened On",
      "col_4",
      "Amount",
      "Amount_2",
      "Status"
    ]

    assert %{code: 2, out: "", err: err} =
             refract(["drop" | Enum.flat_map(columns, &["--col", &1])] ++ ["--input", accounts()])

    assert String.starts_with?(err, "refract drop: that leaves no columns\nusage: refract drop")
  end
end
