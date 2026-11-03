defmodule Refract.CLI.ColumnsTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  @table """
  #  column       header
  1  Customer ID  " Customer ID "
  2  Name         Name
  3  Email        Email
  4  col_3        (blank)
  5  Balance      Balance
  6  Balance_2    Balance
  """

  @csv """
  position,column,header
  1,Customer ID, Customer ID\s
  2,Name,Name
  3,Email,Email
  4,col_3,
  5,Balance,Balance
  6,Balance_2,Balance
  """

  test "a messy header gives each position, key and header as written" do
    assert refract(["columns", "--input", fixture("customers.csv")]) ==
             %{code: 0, out: @table, err: ""}
  end

  test "piped in gives the same" do
    csv = File.read!(fixture("customers.csv"))

    assert refract(["columns"], stdin: csv) == %{code: 0, out: @table, err: ""}
  end

  test "--csv gives the answer as rows" do
    assert refract(["columns", "--input", fixture("customers.csv"), "--csv"]) ==
             %{code: 0, out: @csv, err: ""}
  end

  @tag :tmp_dir
  test "--csv --output writes the rows to the file, nothing on stdout", %{tmp_dir: dir} do
    path = Path.join(dir, "columns.csv")

    assert refract(["columns", "--input", fixture("customers.csv"), "--csv", "--output", path]) ==
             %{code: 0, out: "", err: ""}

    assert File.read!(path) == @csv
  end

  test "a file holding only a header" do
    assert refract(["columns", "--input", fixture("header_only.csv")]) == %{
             code: 0,
             out: """
             #  column  header
             1  id      id
             2  name    name
             """,
             err: ""
           }
  end

  test "the keys are the row keys stream gives" do
    {:ok, rows} = Refract.CSV.stream(fixture("customers.csv"))
    keys = rows |> Enum.at(0) |> Map.keys() |> Enum.sort()

    %{out: out} = refract(["columns", "--input", fixture("customers.csv"), "--csv"])

    columns =
      out
      |> String.split("\n", trim: true)
      |> Enum.drop(1)
      |> Enum.map(&(&1 |> String.split(",") |> Enum.at(1)))
      |> Enum.sort()

    assert columns == keys
  end
end
