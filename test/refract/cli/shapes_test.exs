defmodule Refract.CLI.ShapesTest do
  use Refract.CLI.Case, async: true

  @moduletag timeout: 10_000

  defp env, do: %{"REFRACT_SHAPES" => fixture("shapes")}

  test "the shapes by name, a file that cannot be read under them" do
    assert refract(["shapes"], env: env()) == %{
             code: 0,
             out: """
             name      version  file
             accounts        1  accounts.yml
             invoice         2  invoice.yml
             broken.yml cannot be read: invalid_value header
             """,
             err: ""
           }
  end

  @tag :tmp_dir
  test "--shapes, else REFRACT_SHAPES, else HOME/.refract/shapes", %{tmp_dir: dir} do
    flag_folder = Path.join(dir, "flag")
    home_folder = Path.join([dir, ".refract", "shapes"])

    for {folder, file} <- [{flag_folder, "invoice.yml"}, {home_folder, "accounts.yml"}] do
      File.mkdir_p!(folder)
      File.cp!(fixture("shapes/#{file}"), Path.join(folder, file))
    end

    assert %{code: 0, out: "name" <> _ = out} =
             refract(["shapes", "--shapes", flag_folder], env: env())

    assert out =~ "invoice.yml" and not (out =~ "accounts.yml")

    assert %{code: 0, out: out} = refract(["shapes"], env: env())
    assert out =~ "broken.yml"

    assert %{code: 0, out: out} = refract(["shapes"], env: %{"HOME" => dir})
    assert out =~ "accounts.yml" and not (out =~ "invoice.yml")

    assert %{code: 0, out: out} =
             refract(["shapes"], env: %{"REFRACT_SHAPES" => "", "HOME" => dir})

    assert out =~ "accounts.yml"
  end

  test "no shapes folder" do
    assert refract(["shapes", "--shapes", "test/fixtures/none"]) == %{
             code: 2,
             out: "",
             err:
               "refract: no shapes folder test/fixtures/none, set REFRACT_SHAPES or give --shapes DIR\n"
           }

    assert %{code: 2, err: "refract: no shapes folder, set REFRACT_SHAPES" <> _} =
             refract(["shapes"])
  end
end
