defmodule Refract.CLI.ValidateTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  @issues """
  line  column      issue                            value
     3  email       is required
     4  amount      must be at least 0               -42.50
     5  account_no  must be unique, first on line 3  A-1002
     6  email       is required
     6  status      is required
  5 issues on 4 rows
  """

  defp env, do: %{"REFRACT_SHAPES" => fixture("shapes")}

  defp validate(args, opts \\ []),
    do: refract(["validate", "--shape", "accounts" | args], Keyword.put_new(opts, :env, env()))

  test "every issue with its line, exit 1" do
    assert validate(["--input", fixture("accounts.csv")]) == %{code: 1, out: @issues, err: ""}
  end

  test "--identify-by adds the column, --no-values takes the values out" do
    assert validate([
             "--input",
             fixture("accounts.csv"),
             "--identify-by",
             "account_no",
             "--no-values"
           ]) == %{
             code: 1,
             out: """
             line  account_no  column      issue
                3  A-1002      email       is required
                4  A-1003      amount      must be at least 0
                5  A-1002      account_no  must be unique, first on line 3
                6  A-1004      email       is required
                6  A-1004      status      is required
             5 issues on 4 rows
             """,
             err: ""
           }
  end

  test "--csv gives one row per issue" do
    assert validate(["--input", fixture("accounts.csv"), "--csv"]) == %{
             code: 1,
             out: """
             line,column,issue,value,first_line
             3,email,is required,,
             4,amount,must be at least 0,-42.50,
             5,account_no,must be unique,A-1002,3
             6,email,is required,,
             6,status,is required,,
             """,
             err: ""
           }
  end

  test "a file that fits" do
    assert validate(["--input", fixture("accounts_clean.csv")]) ==
             %{
               code: 0,
               out: "test/fixtures/accounts_clean.csv fits accounts, no issues\n",
               err: ""
             }
  end

  test "piped in" do
    assert validate([], stdin: File.read!(fixture("accounts.csv"))) ==
             %{code: 1, out: @issues, err: ""}

    assert validate([], stdin: File.read!(fixture("accounts_clean.csv"))) ==
             %{code: 0, out: "stdin fits accounts, no issues\n", err: ""}
  end

  test "a file the shape does not fit" do
    assert validate(["--input", fixture("customers.csv")]) == %{
             code: 2,
             out: "",
             err:
               "refract: the accounts header is not in test/fixtures/customers.csv " <>
                 "(1 of 6 columns found: email)\n"
           }
  end

  test "an unknown shape" do
    assert refract(["validate", "--shape", "acme", "--input", fixture("accounts.csv")],
             env: env()
           ) ==
             %{
               code: 2,
               out: "",
               err: "refract: no shape acme in test/fixtures/shapes, see refract shapes\n"
             }
  end

  test "an --identify-by column the shape does not have" do
    assert validate(["--input", fixture("accounts.csv"), "--identify-by", "acct"]) == %{
             code: 2,
             out: "",
             err: "refract: no column acct in shape accounts, see refract shapes show\n"
           }
  end

  test "--shape is required" do
    assert %{code: 2, err: err} =
             refract(["validate", "--input", fixture("accounts.csv")], env: env())

    assert String.starts_with?(
             err,
             "refract validate: --shape is required\nusage: refract validate --shape NAME"
           )
  end
end
