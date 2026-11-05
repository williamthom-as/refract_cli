defmodule Refract.CLI.DistinctTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 30_000

  @status """
  Status   count
  open         4
  closed       1
  (blank)      1
  """

  defp accounts, do: fixture("accounts.csv")

  test "one column, most common first, blanks last" do
    assert refract(["distinct", "--col", "Status", "--input", accounts()]) ==
             %{code: 0, out: @status, err: ""}
  end

  test "two columns, a table each" do
    assert refract(["distinct", "--col", "Status", "--col", "Opened On", "--input", accounts()]) ==
             %{
               code: 0,
               out:
                 @status <>
                   """

                   Opened On   count
                   15/02/2024      2
                   31/01/2024      1
                   03/03/2024      1
                   29/02/2024      1
                   (blank)         1
                   """,
               err: ""
             }
  end

  test "--csv gives a row per value, a blank value empty" do
    assert refract(["distinct", "--col", "Status", "--input", accounts(), "--csv"]) == %{
             code: 0,
             out: """
             column,value,count
             Status,open,4
             Status,closed,1
             Status,,1
             """,
             err: ""
           }
  end

  test "--col is required" do
    assert %{
             code: 2,
             out: "",
             err:
               "refract distinct: --col is required\nusage: refract distinct --col COLUMN" <>
                 _rest
           } = refract(["distinct", "--input", accounts()])
  end

  test "an unknown column" do
    assert refract(["distinct", "--col", "Acct", "--input", accounts()]) == %{
             code: 2,
             out: "",
             err: "refract: no column Acct in #{accounts()}, see refract columns\n"
           }
  end
end
