defmodule Refract.CLI.ShapesShowTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  defp env, do: %{"REFRACT_SHAPES" => fixture("shapes")}

  test "the columns, the headers they match and their rules" do
    assert refract(["shapes", "show", "--shape", "accounts"], env: env()) == %{
             code: 0,
             out: """
             accounts, version 1 (accounts.yml)
             column      header      rules
             account_no  account no  is required, must be unique
             amount      amount      must be a number, must be at least 0
             customer    customer
             email       email       is required
             opened_on   opened on   must be a date (dmy)
             status      status      is required, must be one of open, closed
             """,
             err: ""
           }
  end

  test "an unknown shape" do
    assert refract(["shapes", "show", "--shape", "acme"], env: env()) == %{
             code: 2,
             out: "",
             err: "refract: no shape acme in test/fixtures/shapes, see refract shapes\n"
           }
  end

  test "--shape is required" do
    assert %{code: 2, err: err} = refract(["shapes", "show"], env: env())

    assert String.starts_with?(
             err,
             "refract shapes show: --shape is required\nusage: refract shapes show --shape NAME"
           )
  end

  @tag :tmp_dir
  test "two files with one name", %{tmp_dir: dir} do
    for file <- ["a.yml", "b.yml"],
        do: File.cp!(fixture("shapes/accounts.yml"), Path.join(dir, file))

    assert refract(["shapes", "show", "--shape", "accounts", "--shapes", dir]) == %{
             code: 2,
             out: "",
             err: "refract: shape accounts is in 2 files: a.yml, b.yml\n"
           }
  end

  test "--help is this command's, a word after shapes that is no command is an argument" do
    assert %{code: 0, out: out} = refract(["shapes", "show", "--help"])
    assert out =~ "usage: refract shapes show --shape NAME"

    assert %{code: 2, err: "refract shapes: unexpected argument nope\n" <> _} =
             refract(["shapes", "nope"], env: env())
  end
end
