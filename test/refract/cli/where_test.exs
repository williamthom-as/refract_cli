defmodule Refract.CLI.WhereTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  @header "Account No,Customer,Email,Opened On,col_4,Amount,Amount_2,Status\n"

  defp accounts, do: fixture("accounts.csv")

  defp where(matches),
    do: refract(["where" | Enum.flat_map(matches, &["--match", &1])] ++ ["--input", accounts()])

  defp kept_customers(%{code: 0, out: @header <> rows, err: ""}) do
    rows
    |> String.split("\n", trim: true)
    |> Enum.map(&(&1 |> String.split(",") |> Enum.at(1)))
  end

  defp usage_error(message),
    do: "refract where: #{message}\nusage: refract where --match MATCH"

  test "every match must hold" do
    assert where(["Status=open", "Amount>100"]) == %{
             code: 0,
             out:
               @header <>
                 """
                 A-1001,Acme Pty Ltd,ops@acme.test,31/01/2024,note,1250.00,1250.00,open
                 A-1005,Hooli,team@hooli.test,29/02/2024,,1250.00,1250.00,open
                 """,
             err: ""
           }
  end

  test "!= keeps a blank cell, it is not the text" do
    assert kept_customers(where(["Status!=closed"])) ==
             ["Acme Pty Ltd", "Initech", "Globex Corp", "Umbrella", "Hooli"]
  end

  test "bounds: >= and <= hold at the bound, > and < do not" do
    assert kept_customers(where(["Amount>=1250"])) == ["Acme Pty Ltd", "Hooli"]
    assert kept_customers(where(["Amount<=0"])) == ["Globex", "Initech"]
    assert where(["Amount>1250"]) == %{code: 0, out: @header, err: ""}
  end

  test ":blank and :present" do
    assert kept_customers(where(["Email:blank"])) == ["Globex", "Umbrella"]

    assert kept_customers(where(["Email:present"])) ==
             ["Acme Pty Ltd", "Initech", "Globex Corp", "Hooli"]
  end

  test "~ is a regular expression, (?i) ignores case" do
    assert kept_customers(where(["Customer~^Glob"])) == ["Globex", "Globex Corp"]
    assert kept_customers(where(["Customer~(?i)hooli"])) == ["Hooli"]
  end

  test "a cell that is not a number fails a bound" do
    assert where(["Opened On>0"]) == %{code: 0, out: @header, err: ""}
  end

  test "piped in, the same rows" do
    assert %{code: 0} =
             result = refract(["where", "--match", "Email:blank"], stdin: File.read!(accounts()))

    assert kept_customers(result) == ["Globex", "Umbrella"]
  end

  test "a match that cannot be read is a usage error" do
    for {match, message} <- [
          {"Status", "cannot read the match Status"},
          {"Email:empty", "cannot read the match Email:empty"},
          {"Status=", "cannot read the match Status="},
          {"Amount>abc", "abc in Amount>abc is not a number"},
          {"Customer~(", "( in Customer~( is not a regular expression"}
        ] do
      assert %{code: 2, out: "", err: err} = where([match])
      assert String.starts_with?(err, usage_error(message))
    end
  end

  test "an unknown column" do
    assert where(["Acct=1"]) == %{
             code: 2,
             out: "",
             err: "refract: no column Acct in test/fixtures/accounts.csv, see refract columns\n"
           }
  end

  test "--match is required" do
    assert %{code: 2, out: "", err: err} = refract(["where", "--input", accounts()])
    assert String.starts_with?(err, usage_error("--match is required"))
  end
end
