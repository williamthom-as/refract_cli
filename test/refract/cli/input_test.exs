defmodule Refract.CLI.InputTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  test "--input-opts passes a reader option" do
    assert %{code: 0, out: out, err: ""} =
             refract([
               "columns",
               "--input",
               fixture("semicolons.csv"),
               "--input-opts",
               "separator=;"
             ])

    assert out == """
           #  column  header
           1  id      id
           2  name    name
           """
  end

  @tag :tmp_dir
  test "--output-opts passes a writer option, true and false become booleans", %{tmp_dir: dir} do
    path = Path.join(dir, "columns.csv")
    argv = ["columns", "--input", fixture("header_only.csv"), "--csv", "--output", path]

    assert %{code: 0} = refract(argv ++ ["--output-opts", "bom=true"])
    assert <<0xEF, 0xBB, 0xBF, "position,column,header\n", _rest::binary>> = File.read!(path)
  end

  test "an option the reader does not take is the reader's error" do
    assert refract(["columns", "--input", fixture("customers.csv"), "--input-opts", "sheet=Jul"]) ==
             %{code: 2, out: "", err: "refract: the csv reader does not take sheet\n"}
  end

  test "an option without a value is an error" do
    assert refract(["columns", "--input", fixture("customers.csv"), "--input-opts", "sheet"]) ==
             %{code: 2, out: "", err: "refract: --input-opts takes key=value, got sheet\n"}
  end

  test "no input and nothing piped" do
    assert refract(["columns"], stdin: :terminal) ==
             %{code: 2, out: "", err: "refract: no input, give --input FILE or pipe one in\n"}
  end

  test "an empty pipe" do
    assert refract(["columns"], stdin: "") ==
             %{code: 2, out: "", err: "refract: the input is empty, no header\n"}
  end
end
