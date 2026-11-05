defmodule Refract.CLI.DuplicatesTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  @account_no """
  Account No  lines
  A-1002      3, 5
  1 duplicated value, 2 rows
  """

  defp accounts, do: fixture("accounts.csv")

  test "a repeated value in one column, with its lines" do
    assert refract(["duplicates", "--col", "Account No", "--input", accounts()]) ==
             %{code: 1, out: @account_no, err: ""}
  end

  test "no repeats" do
    assert refract(["duplicates", "--col", "Customer", "--input", accounts()]) ==
             %{code: 0, out: "no duplicates in Customer\n", err: ""}
  end

  test "two columns together, a row blank in either is skipped" do
    assert refract(["duplicates", "--col", "Amount", "--col", "Status", "--input", accounts()]) ==
             %{
               code: 1,
               out: """
               Amount   Status  lines
               1250.00  open    2, 7
               1 duplicated combination, 2 rows
               """,
               err: ""
             }
  end

  test "--csv gives every duplicated row under the row keys" do
    assert refract(["duplicates", "--col", "Account No", "--input", accounts(), "--csv"]) == %{
             code: 1,
             out: """
             Account No,Customer,Email,Opened On,col_4,Amount,Amount_2,Status
             A-1002,Globex,,15/02/2024,,0,0,closed
             A-1002,Globex Corp,accounts@globex.test,15/02/2024,dup?,10.00,10.00,open
             """,
             err: ""
           }
  end

  test "piped in, the same lines" do
    assert refract(["duplicates", "--col", "Account No"], stdin: File.read!(accounts())) ==
             %{code: 1, out: @account_no, err: ""}
  end

  test "--col is required" do
    assert %{
             code: 2,
             out: "",
             err:
               "refract duplicates: --col is required\nusage: refract duplicates --col COLUMN" <>
                 _rest
           } = refract(["duplicates", "--input", accounts()])
  end

  test "an unknown column" do
    assert refract(["duplicates", "--col", "Acct", "--input", accounts()]) == %{
             code: 2,
             out: "",
             err: "refract: no column Acct in #{accounts()}, see refract columns\n"
           }
  end
end
