defmodule Refract.CLI.ErrorsTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  test "a missing file" do
    path = fixture("missing.csv")

    assert refract(["columns", "--input", path]) ==
             %{code: 2, out: "", err: "refract: cannot read #{path}: no such file\n"}
  end

  test "a file no reader in this build takes" do
    assert refract(["columns", "--input", "crm.xlsx"]) == %{
             code: 2,
             out: "",
             err: "refract: no reader for .xlsx files, add one with: refract plugins add xlsx\n"
           }
  end

  test "an unknown option gives the command's usage" do
    assert refract(["stats", "--input", fixture("customers.csv"), "--rows", "5"]) == %{
             code: 2,
             out: "",
             err: """
             refract stats: unknown option --rows
             usage: refract stats [--input FILE] [--output FILE] [--csv] [--input-opts K=V]... [--output-opts K=V]...
             """
           }
  end

  test "an unknown command" do
    assert refract(["nope", "--input", fixture("customers.csv")]) ==
             %{code: 2, out: "", err: "refract: unknown command nope, see refract --help\n"}
  end
end
