defmodule Refract.CLI.HelpTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  test "--help lists this build's commands and plugins" do
    assert %{code: 0, out: out, err: ""} = refract(["--help"])
    assert out =~ ~r/^\s+columns\s/m
    assert out =~ ~r/^\s+stats\s/m
    assert out =~ "plugins: none"
  end

  test "a command's --help shows its usage and an example" do
    assert %{code: 0, out: out, err: ""} = refract(["stats", "--help"])
    assert out =~ "usage: refract stats [--input FILE]"
    assert out =~ "refract stats --input customers.csv"
  end

  test "refract alone prints the help to stderr" do
    assert %{code: 2, out: "", err: err} = refract([])
    assert err =~ ~r/^\s+columns\s/m
  end

  test "a command's own switch shows in its usage and options" do
    assert %{code: 0, out: out} = refract(["duplicates", "--help"])
    assert out =~ "usage: refract duplicates --col COLUMN..."
    assert out =~ ~r/^\s+--col COLUMN\s/m
  end

  test "--help lists the slice 2 commands" do
    assert %{code: 0, out: out} = refract(["--help"])
    assert out =~ ~r/^\s+duplicates\s/m
    assert out =~ ~r/^\s+distinct\s/m
  end
end
