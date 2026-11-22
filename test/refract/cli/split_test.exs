defmodule Refract.CLI.SplitTest do
  use Refract.CLI.Case, async: true

  @moduletag :tmp_dir
  @moduletag timeout: 10_000

  @header "Account No,Customer,Email,Opened On,col_4,Amount,Amount_2,Status\n"

  @first_four """
  A-1001,Acme Pty Ltd,ops@acme.test,31/01/2024,note,1250.00,1250.00,open
  A-1002,Globex,,15/02/2024,,0,0,closed
  A-1003,Initech,it@initech.test,03/03/2024,,"\t-42.50","\t-42.50",open
  A-1002,Globex Corp,accounts@globex.test,15/02/2024,dup?,10.00,10.00,open
  """

  @last_two """
  A-1004,Umbrella,,,,99.95,99.95,
  A-1005,Hooli,team@hooli.test,29/02/2024,,1250.00,1250.00,open
  """

  defp split(dir, args, opts \\ []),
    do: refract(["split", "--output", Path.join(dir, "accounts.csv") | args], opts)

  defp words(out), do: out |> String.split("\n", trim: true) |> Enum.map(&String.split/1)

  defp read(dir, name), do: File.read!(Path.join(dir, name))

  test "--rows writes so many rows a file, each with the header", %{tmp_dir: dir} do
    assert %{code: 0, out: out, err: ""} =
             split(dir, ["--rows", "4", "--input", fixture("accounts.csv")])

    assert words(out) == [
             ["file", "rows"],
             [Path.join(dir, "accounts_1.csv"), "4"],
             [Path.join(dir, "accounts_2.csv"), "2"]
           ]

    assert read(dir, "accounts_1.csv") == @header <> @first_four
    assert read(dir, "accounts_2.csv") == @header <> @last_two
  end

  test "--by writes a file per value, most rows first", %{tmp_dir: dir} do
    assert %{code: 0, out: out, err: ""} =
             split(dir, ["--by", "Status", "--input", fixture("accounts.csv")])

    assert words(out) == [
             ["Status", "file", "rows"],
             ["open", Path.join(dir, "accounts_open.csv"), "4"],
             ["closed", Path.join(dir, "accounts_closed.csv"), "1"],
             ["(blank)", Path.join(dir, "accounts_blank.csv"), "1"]
           ]

    assert read(dir, "accounts_blank.csv") == @header <> "A-1004,Umbrella,,,,99.95,99.95,\n"
  end

  test "--csv gives the answer as csv on stdout and never in --output", %{tmp_dir: dir} do
    assert split(dir, ["--by", "Status", "--input", fixture("accounts.csv"), "--csv"]) == %{
             code: 0,
             out: """
             Status,file,rows
             open,#{dir}/accounts_open.csv,4
             closed,#{dir}/accounts_closed.csv,1
             ,#{dir}/accounts_blank.csv,1
             """,
             err: ""
           }

    refute File.exists?(Path.join(dir, "accounts.csv"))
  end

  test "--by twice is a file per combination with unsafe characters made _", %{tmp_dir: dir} do
    args = ["--by", "Status", "--by", "Opened On", "--input", fixture("accounts.csv"), "--csv"]

    assert split(dir, args) == %{
             code: 0,
             out: """
             Status,Opened On,file,rows
             open,31/01/2024,#{dir}/accounts_open_31_01_2024.csv,1
             closed,15/02/2024,#{dir}/accounts_closed_15_02_2024.csv,1
             open,03/03/2024,#{dir}/accounts_open_03_03_2024.csv,1
             open,15/02/2024,#{dir}/accounts_open_15_02_2024.csv,1
             ,,#{dir}/accounts_blank_blank.csv,1
             open,29/02/2024,#{dir}/accounts_open_29_02_2024.csv,1
             """,
             err: ""
           }
  end

  test "values that clean to one name get _2", %{tmp_dir: dir} do
    output = Path.join(dir, "part.csv")

    assert %{code: 0, out: out} =
             refract(["split", "--by", "k", "--output", output, "--csv"], stdin: "k\na/b\na?b\n")

    assert out == "k,file,rows\na/b,#{dir}/part_a_b.csv,1\na?b,#{dir}/part_a_b_2.csv,1\n"
    assert read(dir, "part_a_b.csv") == "k\na/b\n"
    assert read(dir, "part_a_b_2.csv") == "k\na?b\n"
  end

  test "names that differ only by case get _2", %{tmp_dir: dir} do
    output = Path.join(dir, "part.csv")

    assert %{code: 0} =
             refract(["split", "--by", "k", "--output", output], stdin: "k\nOpen\nopen\n")

    assert read(dir, "part_Open.csv") == "k\nOpen\n"
    assert read(dir, "part_open_2.csv") == "k\nopen\n"
  end

  test "the --output folder is made", %{tmp_dir: dir} do
    output = Path.join([dir, "out", "nested", "accounts.csv"])

    assert %{code: 0} =
             refract([
               "split",
               "--rows",
               "4",
               "--output",
               output,
               "--input",
               fixture("accounts.csv")
             ])

    assert [dir, "out", "nested"] |> Path.join() |> File.ls!() |> Enum.sort() ==
             ["accounts_1.csv", "accounts_2.csv"]
  end

  test "--output-opts go to every file, not the answer", %{tmp_dir: dir} do
    args = [
      "--rows",
      "4",
      "--input",
      fixture("accounts.csv"),
      "--output-opts",
      "bom=true",
      "--csv"
    ]

    assert %{code: 0, out: "file,rows\n" <> _} = split(dir, args)
    assert "﻿" <> @header <> _ = read(dir, "accounts_1.csv")
    assert "﻿" <> @header <> _ = read(dir, "accounts_2.csv")
  end

  test "no rows, no files", %{tmp_dir: dir} do
    assert split(dir, ["--rows", "4", "--input", fixture("header_only.csv")]) ==
             %{code: 0, out: "no rows, no files written\n", err: ""}

    assert File.ls!(dir) == []
  end

  test "piped in", %{tmp_dir: dir} do
    assert %{code: 0} = split(dir, ["--rows", "4"], stdin: File.read!(fixture("accounts.csv")))
    assert read(dir, "accounts_1.csv") == @header <> @first_four
    assert read(dir, "accounts_2.csv") == @header <> @last_two
  end

  describe "errors, nothing written" do
    test "neither --rows nor --by", %{tmp_dir: dir} do
      assert %{code: 2, out: "", err: err} = split(dir, ["--input", fixture("accounts.csv")])

      assert String.starts_with?(
               err,
               "refract split: give --rows N or --by COLUMN\n" <>
                 "usage: refract split --output FILE [--rows N] [--by COLUMN]..."
             )

      assert File.ls!(dir) == []
    end

    test "both --rows and --by", %{tmp_dir: dir} do
      assert %{code: 2, err: "refract split: give --rows or --by, not both\n" <> _} =
               split(dir, ["--rows", "4", "--by", "Status", "--input", fixture("accounts.csv")])

      assert File.ls!(dir) == []
    end

    test "--rows below 1", %{tmp_dir: dir} do
      for rows <- ["0", "-1"] do
        assert %{code: 2, err: "refract split: --rows must be a whole number above 0\n" <> _} =
                 split(dir, ["--rows", rows, "--input", fixture("accounts.csv")])
      end

      assert File.ls!(dir) == []
    end

    test "an unknown --by column", %{tmp_dir: dir} do
      assert split(dir, ["--by", "Acct", "--input", fixture("accounts.csv")]) == %{
               code: 2,
               out: "",
               err: "refract: no column Acct in test/fixtures/accounts.csv, see refract columns\n"
             }

      assert File.ls!(dir) == []
    end

    test "no --output" do
      assert %{code: 2, err: err} =
               refract(["split", "--rows", "4", "--input", fixture("accounts.csv")])

      assert String.starts_with?(
               err,
               "refract split: --output is required\nusage: refract split --output FILE"
             )
    end

    test "an --output folder that is a file", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "afile"), "")
      output = Path.join([dir, "afile", "accounts.csv"])

      assert %{code: 2, out: "", err: "refract: cannot make " <> _} =
               refract([
                 "split",
                 "--rows",
                 "4",
                 "--output",
                 output,
                 "--input",
                 fixture("accounts.csv")
               ])
    end
  end
end
