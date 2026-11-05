defmodule Refract.CLI.HelpTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  alias Refract.CLI.Commands

  test "--help lists this build's commands and plugins" do
    assert %{code: 0, out: out, err: ""} = refract(["--help"])

    for command <- Commands.all() do
      assert out =~ ~r/^\s+#{command.name()}\s/m
    end

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

  test "where --help shows the kinds of match" do
    assert %{code: 0, out: out} = refract(["where", "--help"])
    assert out =~ "usage: refract where --match MATCH..."
    assert out =~ ~r/^\s+--match MATCH\s+COLUMN=TEXT, !=, >, >=, <, <=/m
  end
end
