defmodule Refract.CLI.StatsTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  test "the fixture's stats" do
    assert refract(["stats", "--input", fixture("customers.csv")]) == %{
             code: 0,
             out: """
             test/fixtures/customers.csv  4 rows  6 columns
             column       blanks  distinct  most common
             Customer ID       0         3  C-002 (2)
             Name              0         4  Acme Pty Ltd (1)
             Email             1         3  ops@acme.test (1)
             col_3             0         3  15/02/2024 (2)
             Balance           0         4  1250.00 (1)
             Balance_2         0         4  1250.00 (1)
             """,
             err: ""
           }
  end

  test "piped in, the input is named stdin" do
    csv = File.read!(fixture("customers.csv"))

    assert %{code: 0, out: "stdin  4 rows  6 columns\n" <> _rest, err: ""} =
             refract(["stats"], stdin: csv)
  end

  test "--csv gives a row per column" do
    assert refract(["stats", "--input", fixture("customers.csv"), "--csv"]) == %{
             code: 0,
             out: """
             column,blanks,distinct,most_common,most_common_count
             Customer ID,0,3,C-002,2
             Name,0,4,Acme Pty Ltd,1
             Email,1,3,ops@acme.test,1
             col_3,0,3,15/02/2024,2
             Balance,0,4,1250.00,1
             Balance_2,0,4,1250.00,1
             """,
             err: ""
           }
  end

  test "a tie for most common takes the first in the file, an all blank column has none" do
    assert refract(["stats", "--input", fixture("ties.csv")]) == %{
             code: 0,
             out: """
             test/fixtures/ties.csv  4 rows  2 columns
             column  blanks  distinct  most common
             code         0         2  B (2)
             note         4         0  -
             """,
             err: ""
           }
  end

  test "a file holding only a header" do
    assert refract(["stats", "--input", fixture("header_only.csv")]) == %{
             code: 0,
             out: """
             test/fixtures/header_only.csv  0 rows  2 columns
             column  blanks  distinct  most common
             id           0         0  -
             name         0         0  -
             """,
             err: ""
           }
  end
end
